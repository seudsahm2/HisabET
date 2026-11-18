# HisabET — Known Issues Backlog

Findings from a full codebase audit (2026-08-08). Nothing here is fixed yet unless marked.
Ordered by severity. Each entry states the symptom, the root cause with file references, and the fix.

Status legend: `OPEN` · `IN PROGRESS` · `FIXED`

---

## P0 — Feature is dead in production

### 1. B2B Tenders cannot work at all (three independent blockers) — `OPEN` (1 of 3 fixed)

The whole Tenders module is unreachable in a real build. Three separate causes; **1b is fixed, 1a and 1c still block it**.

**1a. Firestore denies every tender read/write.**
`firestore.rules` has no `match /tenders/{id}` block, so the catch-all `match /{document=**} { allow read, write: if false; }` at the bottom blocks everything. `activeTendersProvider` and `myTenderActivityProvider` will always error.
→ Add a `tenders` rule: public read for authenticated users, create restricted to the importer, update of `status`/`winnerUid` restricted to the winner or owner.

**1b. No account can ever qualify as an Importer.** — `FIXED` (2026-08-08)
The gate now parses through `BusinessRole` and checks `BusinessRole.supplier`, which the profile picker offers. Legacy `'Importer'` profiles still pass via the alias in `BusinessRole.tryParse`.

**1c. Winning a tender writes an invalid foreign key.**
`_confirmWin` calls `addTransaction(contactId: tender.importerUid, ...)` — a Firestore UID passed as a local contact primary key. `contacts` has no such row and `PRAGMA foreign_keys = ON` (`app_database.dart:261`), so the insert throws.
→ Resolve/create a local `Contact` for the importer first (match on `linkedUserUid`), then use that contact's local id.

---

## P1 — Data correctness

### 2. `isImporter` is a write-only dead column — `FIXED` (2026-08-08)

Schema v28 folds `is_importer` into `is_supplier` (`UPDATE contacts SET is_supplier = 1 WHERE is_importer = 1`) and migrates `products.business_role` from `'importer'` to `'supplier'`. `importerContactsProvider` became `supplierContactsProvider`, filtering `isSupplier` — which the add-contact screen already had a working checkbox for. The broker's "Bought From (Supplier)" dropdown now populates.

The `is_importer` column is intentionally left in the table: dropping it means rebuilding a table that `transactions` references by foreign key, which is not worth the risk for a flag nothing reads. It is marked deprecated in `lib/core/database/tables/contacts.dart`.

### 3. `checkoutSale` is not wrapped in a DB transaction — `FIXED` (2026-11-18)

`SalesRepositoryImpl.checkoutSale` (`lib/features/sales/data/repositories/sales_repository.dart:38-243`) performs stock validation, the sale insert, promotion redemption, per-item line inserts, per-item stock writes, stock-movement inserts, and the contact balance update — all with **no `_db.transaction()` wrapper**. The `try` block only rethrows; it does not roll back.

A failure partway through the item loop leaves stock deducted for some items and not others, with a sale row already written.
→ Wrap the whole body in `_db.transaction(() async { ... })`, as `addTransaction` already does correctly.

**Resolution:** the whole checkout runs in one `_db.transaction`. Two more defects in the same function were fixed with it: stock was written as `cartSnapshot.stockQuantity - qty` (stale if stock changed after the item entered the cart), now computed from the row read inside the transaction; and the promotion `usedCount` read-modify-write is now an SQL increment. Covered by `test/features/sales/checkout_sale_test.dart`.

### 4. Two different contact-balance code paths that can drift — `FIXED` (2026-11-18)

- `_updateContactBalance` (`transactions_repository.dart:452`) recomputes from scratch: sum of `balanceEffect` over all non-deleted transactions. Self-healing.
- `checkoutSale` (`sales_repository.dart:222-232`) does an incremental `currentBalance + amountOwed`.

Any bug or interruption in the incremental path permanently desynchronises the cached `netBalance` from the transaction history.
→ Have `checkoutSale` call the same full recalculation.

**Resolution:** `recalculateContactBalance` in `lib/features/transactions/data/repositories/contact_balance.dart` is now the only writer of `contacts.net_balance`; both repositories call it.

### 5. Three competing role taxonomies — `FIXED` (2026-08-08)

The same concept is modelled three different ways:

| Place | Values |
|---|---|
| User profile (`users/{uid}.roles`, onboarding) | `Supplier`, `Broker`, `Wholesaler`, `Retailer` |
| Contact flags (`contacts` table) | `isRetailer`, `isWholesaler`, `isBroker`, `isSupplier`, `isImporter` |
| Product (`products.businessRole`) | `importer`, `broker`, `wholesaler`, `retailer` |

Plus a legacy `contacts.role` int enum (`merchant`/`supplier`/`both`) still used by `getCustomerContacts()`.

This was the root cause of 1b and 2.

**Resolution:** `lib/core/domain/business_role.dart` is now the single source of truth — `BusinessRole { supplier, broker, wholesaler, retailer }`, with `tryParse`/`parseAll` accepting legacy capitalised values and mapping `'importer'` onto `supplier`. Roles are persisted as lowercase `storageKey`s.

Every raw-string role comparison was replaced with `BusinessRole` parsing. Three of those were already silently broken by case sensitivity and would have broken further once lowercase keys landed: `add_contact_screen.dart` (import roles from a verified profile), `connection_inbox_screen.dart` (accepting a request), and `contacts_list_screen.dart` (adding from network search + the role display string).

Still legacy and untouched: the `contacts.role` int enum used by `getCustomerContacts()`, and the `importerUid`/`importerName` **field names** inside Firestore `tenders` documents. The latter are stored data keys, not taxonomy — renaming them needs a Firestore data migration.

### 6. Soft-deleted transactions are never removed from the cloud — `OPEN`

`deleteTransaction` (`transactions_repository.dart:347`) reverses inventory and balance locally but never deletes or tombstones the Firestore mirror at `users/{uid}/transactions/{id}`. The counterparty's reconciliation keeps seeing the deleted transaction forever, and it reappears as a permanent `missingLocal` diff.
→ Write a `deleted: true` tombstone on sync and filter it in `streamRemoteTransactions`.

---

## P2 — Security

### 7. Any authenticated user can read any transaction with a phone attached — `OPEN`

`firestore.rules`:
```
allow read: if request.auth != null && resource.data.contact_phone != null;
```
This appears in both the per-user ledger rule and the collection-group rule. Any signed-in user can read any transaction document in the entire database that has a non-null `contact_phone`. The inline comment admits it is "kept lenient".
→ Require the reader's own phone to match: `resource.data.contact_phone == <caller's verified phone>`. Needs the phone on the auth token or a lookup.

### 8. Live Supabase credentials committed for a backend that no longer exists — `FIXED` (2026-11-18)

`lib/core/config/env.dart` contains a real Supabase project URL and anon JWT. `lib/core/network/supabase_service.dart` is an empty compatibility stub; the app is 100% Firebase.
→ Delete both files and the credentials; rotate/delete the Supabase project.

**Resolution:** both files deleted (nothing imported them). **Still to do by hand:** the key remains in git history, so delete or rotate the Supabase project itself.

### 9. Debug test dumps all production user PII — `FIXED` (2026-11-18)

`test/debug_users_test.dart` connects to live Firestore and prints every user's name, email, and phone. It is also why bare `flutter test` hangs — it times out after 10 minutes.
→ Delete the file.

---

## P3 — Incomplete against the spec

### 10. The dual-confirmation loop is unfinished — `OPEN`

`TransactionStatus.{pending, confirmed, disputed}` exists and syncs, but `shoe_import.txt` specifies two behaviours that are not implemented:
- **Auto-confirm after a timeout** (48h) unless disputed. The `contacts` table even has `verificationDeadlineAt` and `verificationTimeoutPolicy` columns for this — unused.
- **Correction-request flow**: "Buyer says he paid 6,000, not 5,000. Accept change?"

This is the core promise of the product — the thing that ends the notebook argument. Without it, reconciliation only *reports* conflicts; it cannot *resolve* them.

### 11. Payments are not threaded to their parent debt — `OPEN`

The spec's "continued from day 3" requires each payment to link to the specific debt it settles, showing `Original / Paid / Balance`. Currently payments are standalone transactions that only affect the net balance. `referenceId` could carry this but nothing enforces or displays it.

### 12. Sample/open-carton tracking missing — `OPEN`

Spec: brokers open one carton as a display sample, so 10 cartons is really 9 full + 1 open, and individual-pair sales should deduct from the open carton first. Inventory only tracks whole cartons.

---

## P4 — Polish

### 13. Working modules advertised as "coming soon" — `FIXED` (2026-08-08)
The dashboard action strip was rebuilt as `AppQuickActions`; Expenses and Reports now push their real screens.

### 14. `widget_test.dart` is stock template code — `FIXED` (2026-11-18)
Tests a counter that does not exist; fails on every run. Deleted. Bare `flutter test` now runs the real suite.

### 15. Analyzer warnings — `FIXED` (2026-08-08)

All 11 warnings cleared: 9 unused imports, 2 unused locals, and
`reconciliation_screen.dart:109` which discarded the result of `ref.refresh(...)`
— switched to `ref.invalidate(...)`, which is what the rest of that screen uses.

`flutter analyze` is now **0 errors, 0 warnings**. Remaining ~151 infos are
deprecated `withOpacity` (use `.withValues()`) and `use_build_context_synchronously`.

Note for future audits: `flutter analyze` prints `warning` lines at column 0
while `info` lines are indented, so a `grep '^\s\+warning'` filter silently
reports zero warnings. Match without the leading-whitespace anchor.

### 16. RBAC is decorative — `OPEN`
`currentRoleProvider` is a `StateProvider` hardcoded to `TeamRole.owner` (`team_providers.dart:31`). Team members are local rows with no linked accounts, and every permission check is client-side with nothing enforced in Firestore rules.

---

## Verified healthy

- `flutter analyze` → **0 errors, 0 warnings**, ~151 info (see issue 15).
- `flutter test test/core test/features` → 9/9 pass (money precision, balance effects, the −147,440 notebook scenario, `0.1 + 0.2 == 0.3`).
- Drift migrations v1→v27 are defensively written with `_hasColumn` guards before every `addColumn`.
- Decimal-as-TEXT money handling is consistent; no `double` in any balance path.
