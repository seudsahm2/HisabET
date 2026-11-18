# Phone verification with Telegram

Every HisabET account must have a **verified, unique phone number**. It is how
trading partners find each other and how two ledgers are matched, so an
account without one — or two accounts sharing one — would break
reconciliation for everyone they trade with.

Telegram is the primary way to verify, because almost everyone in Ethiopia
has it and it costs nothing. The Firebase SMS-code path
([PHONE_AUTH_SETUP.md](PHONE_AUTH_SETUP.md)) stays as a fallback.

## Quick start — only what you have to do

Already done steps 1–4 of the setup (bot, rules, key, Netlify)? Then:

1. **Firebase Console → Authentication → Sign-in method → Add new provider → Anonymous → Enable.**
   (Free. "Continue with Telegram" uses a temporary anonymous account for a few seconds.)
2. **Connect the bot to your site** — in the VS Code terminal, from the project folder:
   ```powershell
   powershell -ExecutionPolicy Bypass -File functions\scripts\connect-telegram.ps1
   ```
   It asks for your bot token, your webhook secret and your Netlify address, then checks it worked.
3. **Run the app with your bot and site:**
   ```powershell
   flutter run --dart-define=TELEGRAM_BOT_USERNAME=YourBotName --dart-define=HISABET_BACKEND_URL=your-site.netlify.app
   ```

The sign-in screen now shows **Continue with Telegram** above Continue with Google.

## Two ways Telegram is used

| | Continue with Telegram (sign-in screen) | Verify with Telegram (after Google) |
|---|---|---|
| Who | Anyone, no account needed | Someone who signed in with Google |
| What happens | The Telegram number **is** the account: a returning user gets their account back, a new number gets a new account | The number is added to the Google account |
| Phone afterwards | Verified and unique | Verified and unique |

---

## How it works

```
 HisabET app                       Firestore                    Telegram / backend
 ───────────                       ─────────                    ──────────────────
 1. create session  ───────────▶ phone_verifications/{id}
    (secret 43-char id)            status: pending
 2. open t.me/<bot>?start=<id> ─────────────────────────────▶  /start <id>
                                   status: awaiting_contact ◀── 3. bind session to this
                                                                   Telegram account, show
                                                                   "Share my phone number"
                                                               4. user taps the button
                                                                   → Contact message
                                                               5. contact.user_id == from.id?
                                                                   (own number, not forwarded)
                                   ┌ transaction ──────────────── 6. claim the number
                                   │ phone_claims/{+2519…}           (fails if held by
                                   │ users/{uid}.phone               another account)
                                   └ status: verified
 7. listener sees verified ◀────────
```

Why each piece is there:

| Concern | How it is handled |
|---|---|
| **Is it really their number?** | Telegram registers accounts by SMS, and the bot only accepts a contact whose `user_id` equals the sender's id — i.e. the sender's own number, shared with Telegram's "request contact" button. A forwarded or typed contact is refused. |
| **Uniqueness** | `phone_claims/{E.164}` — the document id *is* the number, so there can only ever be one. The backend claims inside a Firestore transaction; a race between two accounts gives the number to exactly one (tested). It also refuses a number another Firebase Auth account signed in with. |
| **Clients can't fake it** | `firestore.rules` stop the app writing `phone`, `phoneVerified`, `phoneVerificationMethod` or `phoneVerifiedAt` unless Firebase Auth itself proves the number (`request.auth.token.phone_number`) **and** a matching claim is written in the same batch. Telegram results are written only by the backend. |
| **Bot token & admin key** | Only in the host's secret settings (Netlify env vars, or Google Secret Manager on Blaze). Never in the app or the repo. |
| **Forged webhook calls** | The function URL is public, so every request must carry the `X-Telegram-Bot-Api-Secret-Token` header set at `setWebhook`. Compared in constant time. |
| **Phishing a link** | The bot names the account being verified (display name + masked email) before asking for the number, and says to ignore it if the user didn't start it. Links expire after 10 minutes, bind to the first Telegram account that opens them, and are single-use. |
| **Anonymous numbers** | `+888` Fragment numbers are refused — they are bought, not SIMs. |
| **Privacy** | Logs record outcomes only, never numbers or Telegram ids. Claims cannot be listed. The Telegram id is kept only on the private session document. |
| **Deleted accounts** | The app's *Delete account* deletes the profile and releases its claim in one batch. On Blaze, `releasePhoneClaimsOnDelete` also covers accounts deleted from the console. |

### Code map

| Piece | Where |
|---|---|
| Bot conversation (pure, unit tested) | `functions/src/telegram/handler.ts` |
| Webhook auth / HTTP | `functions/src/telegram/webhook.ts` |
| Session rules (expiry, binding) | `functions/src/verification/session.ts` |
| Firestore transactions | `functions/src/verification/firestore-store.ts` |
| Entry points | `functions/netlify/*.mts` (free) · `functions/src/index.ts` (Blaze) |
| Security rules | `firestore.rules` → *Phone identity* section |
| Flutter domain / data / UI | `lib/features/phone_identity/` |
| Gate that requires a verified phone | `lib/core/auth/auth_gate.dart` |

---

## Setup

There are two ways to host the bot. They run the **same code**; only the
entry point differs.

| | **A. Free — Netlify** (recommended now) | **B. Firebase Cloud Functions** |
|---|---|---|
| Cost | $0, no card | $0 usage, but needs the **Blaze** plan (billing account) |
| Firebase plan | Spark (free) is enough | Blaze |
| Entry point | `functions/netlify/*.mts` | `functions/src/index.ts` |
| Account deletion frees the number | the app does it (Delete account) | the app **and** an `onDelete` trigger |

Steps 1, 2 and 5 are the same for both.

### 1. Create the bot

1. In Telegram, open **@BotFather** → `/newbot`.
2. Name: `HisabET`. Username: something ending in `bot`, e.g. `HisabETBot`.
3. Copy the token. Treat it like a password.
4. Optional but recommended, still in BotFather:
   - `/setdescription` → "Verifies your phone number for the HisabET app."
   - `/setuserpic` → the app icon.
   - `/setjoingroups` → **Disable** (the bot is for private chats only).

Generate a webhook secret (keep it for step 4):

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
```

### 2. Deploy the Firestore rules and indexes (free on Spark)

```powershell
npm i -g firebase-tools
firebase login
firebase deploy --only firestore
```

### 3A. Host on Netlify (free)

1. **Service-account key.** Firebase Console → ⚙ Project settings →
   **Service accounts** → **Generate new private key**. This downloads a JSON
   file that is *full admin access* to your project: never commit it, never
   send it to anyone, delete the downloaded file after step 3.
2. Sign up at **netlify.com** (free, no card) with GitHub.
3. **Add new site → Import an existing project →** pick the `HisabET` repo.
   - Branch: the one with this code.
   - **Base directory: `functions`** (everything else comes from
     `functions/netlify.toml`).
4. Before the first deploy, **Site configuration → Environment variables**,
   add three, each marked **Contains secret values**:

   | Key | Value |
   |---|---|
   | `FIREBASE_SERVICE_ACCOUNT` | the whole JSON file's contents |
   | `TELEGRAM_BOT_TOKEN` | the BotFather token |
   | `TELEGRAM_WEBHOOK_SECRET` | the secret from step 1 |

5. Deploy. Your webhook URL is
   `https://<your-site>.netlify.app/telegram-webhook`.
   The daily cleanup job (`cleanup-phone-verifications`) is picked up
   automatically.

> Check Netlify's current free-plan limits and terms before you rely on it in
> production. This workload is tiny (a few requests per verification), but
> limits change.

### 3B. Host on Firebase Cloud Functions (needs Blaze)

```powershell
cd functions
npm ci
firebase functions:secrets:set TELEGRAM_BOT_TOKEN
firebase functions:secrets:set TELEGRAM_WEBHOOK_SECRET
firebase deploy --only functions
```

Webhook URL: `https://europe-west1-<project>.cloudfunctions.net/telegramWebhook`.
If you move from A to B later, re-run step 4 with the new URL and delete the
Netlify site.

### 4. Point Telegram at the webhook

```powershell
$token  = "<bot token>"
$secret = "<webhook secret from step 1>"
$url    = "https://<your-site>.netlify.app/telegram-webhook"   # or the Cloud Functions URL

Invoke-RestMethod "https://api.telegram.org/bot$token/setWebhook" -Method Post -ContentType 'application/json' -Body (@{
  url = $url
  secret_token = $secret
  allowed_updates = @('message')
  drop_pending_updates = $true
} | ConvertTo-Json)

# Check it:
Invoke-RestMethod "https://api.telegram.org/bot$token/getWebhookInfo"
```

`getWebhookInfo` should show the URL and no `last_error_message`.

### 5. Build the app with the bot name

```powershell
flutter run --dart-define=TELEGRAM_BOT_USERNAME=HisabETBot
```

Without it the Telegram button is hidden and only the SMS-code path shows,
so builds made before the backend exists still work.

> **On the free plan, the SMS fallback only works with Firebase test numbers**
> (real SMS needs Blaze). Telegram is the path real users take.

---

## Testing

| What | Command | Needs |
|---|---|---|
| Backend logic (59 tests) | `cd functions; npm test` | nothing |
| Rules + Firestore transactions against the emulators (59 tests) | `cd functions; npm run test:emulator` | Java 11+ |
| Everything backend | `cd functions; npm run test:all` | Java 11+ |
| Flutter domain/data | `flutter test test/features/phone_identity` | nothing |

### Manual end-to-end check

1. Sign in with Google on a fresh account → profile setup shows **Verify with Telegram**.
2. Tap it → Telegram opens on the bot → **Start** → it names your account.
3. Tap **Share my phone number** → bot replies ✅ → the app shows the number as verified without any tap.
4. Sign in with a *second* Google account and repeat with the same Telegram → the bot answers "already linked to another HisabET account"; the app shows the same.
5. In the bot, attach someone else's contact via the 📎 menu → refused.
6. Wait 10 minutes after tapping the button, then share → "expired".

---

## Operations

- **Logs:** Netlify → Logs → Functions (or `firebase functions:log --only telegramWebhook` on Blaze). Events:
  `telegram_session_open`, `telegram_session_complete`, `telegram_contact_rejected`
  — each with an outcome, no personal data.
- **Rotating the bot token:** BotFather `/revoke`, update `TELEGRAM_BOT_TOKEN`
  (Netlify env var, or `firebase functions:secrets:set`), redeploy, re-run step 4.
- **Rotating the webhook secret:** set the secret, redeploy, re-run step 4 with the new value.
- **Stale sessions** are deleted daily by `cleanupPhoneVerifications`.

## Known limits

- **Changing number** works from Profile → Phone number via Telegram. With the
  SMS path, an account that already has a number on its Firebase Auth record
  gets "already has a phone number attached" — Firebase would need
  `updatePhoneNumber`, which is not wired yet.
- **Accounts verified before this change** that have `phone` but no
  `phone_claims` document are asked to verify once more by the
  *Verify your phone* screen. Nothing is migrated silently.
- **A number on a Firebase Auth record that later moves to Telegram on the same
  account** stays on the Auth record, which keeps it reserved for that account.
