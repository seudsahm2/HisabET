# HisabET Merchant Suite Roadmap

This roadmap upgrades HisabET into a complete merchant management platform for stores of all sizes.

## Product Vision

Build an offline-first, mobile-first merchant operating system covering sales, inventory, finance, people, and reporting.

## Core Modules

1. Inventory Management
- Product catalog with SKU, barcode, category, brand
- Stock in/out, adjustments, damage/expiry tracking
- Multi-location support and reorder alerts

2. Sales and Billing
- Fast POS screen with cart, tax, discount, split payment
- Invoice and receipt templates
- Returns, refunds, and exchange flow

3. Purchase and Supplier Management
- Purchase order creation and receiving
- Supplier ledger and payment due tracking
- Landed cost and bill reconciliation

4. Customer and CRM
- Customer profiles with credit limits
- Loyalty points and discount tiers
- Statement sharing via PDF/WhatsApp

5. Finance and Accounting Lite
- Cashbook and bank entries
- Expense tracking with categories
- Profit and loss, receivable/payable summaries

6. Team and Security
- Role-based access control
- Per-action permission matrix
- Audit logs for sensitive actions

7. Analytics and Reporting
- Daily and monthly dashboards
- Top products, slow moving stock, margin reports
- Export CSV/PDF

8. Smart Add-ons
- Scanner integration (barcode/QR)
- Notifications and reminders
- Optional e-commerce order sync (future)

## Delivery Phases

### Phase 1: Foundation (Now)
- Merchant module hub UI
- Feature workspaces for each module
- Security baseline for Firestore rules
- Better error handling and onboarding stability

### Phase 2: Inventory + Sales MVP
- Product CRUD
- Stock movement engine
- POS checkout + invoice generation

### Phase 3: Purchases + Suppliers + Expenses
- Purchase flow and supplier ledger
- Expense categories and recurring costs
- Cashbook sync with transactions

### Phase 4: Reports + Team Permissions
- Dashboard KPIs and advanced reports
- Role management and staff accounts
- Activity audit trail

### Phase 5: Automation + Scale
- Smart reminders, low-stock automation
- Backup/restore and data export
- Optional integrations (marketplace, payment gateways)

## Implementation Principles

- Keep feature modules independent with clear boundaries.
- Build reusable widgets and shared domain models.
- Prefer optimistic/offline-first writes where possible.
- Add tests for business rules before UI-heavy expansion.

## Next 5 Tasks (Recommended)

1. Create Product model + local table + repository.
2. Build Product list/add/edit screens.
3. Create StockMovement model and adjustment flow.
4. Build Sales cart and checkout screen.
5. Generate printable invoice summary.
