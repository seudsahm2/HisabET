/**
 * HisabET Cloud Functions.
 *
 * - `telegramOidc` / `telegramCallback` — "Log In with Telegram" (official
 *                           OpenID Connect): sign in or verify with the
 *                           Telegram phone number.
 * - `telegramWebhook`     — the bot's chat webhook (legacy share-contact flow).
 * - `cleanupPhoneVerifications` — daily removal of stale verification sessions.
 * - `releasePhoneClaimsOnDelete` — frees a deleted account's phone numbers.
 *
 * Setup and deployment: TELEGRAM_PHONE_VERIFICATION.md at the repo root.
 */
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret, defineString } from 'firebase-functions/params';
import * as v1 from 'firebase-functions/v1';
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { TelegramBotClient } from './telegram/client.js';
import { handleUpdate } from './telegram/handler.js';
import { FirestorePhoneAccounts } from './accounts/phone-accounts.js';
import { TelegramOidcClient } from './telegram/oidc.js';
import { createOidcExchange } from './telegram/oidc-exchange.js';
import { createWebhook } from './telegram/webhook.js';
import { FirestoreVerificationStore } from './verification/firestore-store.js';

initializeApp();

/** From @BotFather. Lives only in Secret Manager. */
const botToken = defineSecret('TELEGRAM_BOT_TOKEN');
/** Random string also passed to setWebhook as `secret_token`. */
const webhookSecret = defineSecret('TELEGRAM_WEBHOOK_SECRET');
/** "Log In with Telegram": bot id (public) and client secret (BotFather → Login Widget). */
const telegramClientId = defineString('TELEGRAM_CLIENT_ID');
const telegramClientSecret = defineSecret('TELEGRAM_CLIENT_SECRET');
/** Closest Cloud Functions region to Ethiopia. Used by every function. */
const region = 'europe-west1';

const store = () => new FirestoreVerificationStore(getFirestore(), getAuth());

export const telegramWebhook = onRequest(
  {
    region,
    secrets: [botToken, webhookSecret],
    memory: '256MiB',
    maxInstances: 10,
    // Telegram expects a quick answer; nothing here should take long.
    timeoutSeconds: 30,
  },
  async (req, res) => {
    const bot = new TelegramBotClient(botToken.value());
    const webhook = createWebhook(
      webhookSecret.value(),
      (update) =>
        handleUpdate(update, {
          store: store(),
          bot,
          now: Date.now,
          // Outcomes only — never phone numbers or Telegram ids in logs.
          log: (event, data) => logger.info(event, data),
        }),
      (message, error) => logger.error(message, error),
    );
    await webhook(req, res);
  },
);

/** Express-style request → web-standard Request, for the shared handlers. */
function toWebRequest(req: { method: string; protocol: string; originalUrl: string; header(n: string): string | undefined; get(n: string): string | undefined; body?: unknown }): Request {
  const url = `${req.protocol}://${req.get('host')}${req.originalUrl}`;
  return new Request(url, {
    method: req.method,
    headers: { authorization: req.header('authorization') ?? '', 'content-type': 'application/json' },
    body: req.method === 'POST' ? JSON.stringify(req.body ?? {}) : undefined,
  });
}

/** "Log In with Telegram" code exchange — see src/telegram/oidc-exchange.ts. */
export const telegramOidc = onRequest(
  { region, secrets: [telegramClientSecret], memory: '256MiB', maxInstances: 10, timeoutSeconds: 30 },
  async (req, res) => {
    const auth = getAuth();
    const request = toWebRequest(req);
    const oidc = new TelegramOidcClient({
      clientId: telegramClientId.value(),
      clientSecret: telegramClientSecret.value(),
      redirectUri: `${new URL(request.url).origin}/telegramCallback`,
    });
    const exchange = createOidcExchange({
      identify: (code, verifier) => oidc.identify(code, verifier),
      verifyFirebaseIdToken: async (token) => {
        const decoded = await auth.verifyIdToken(token);
        return { uid: decoded.uid, signInProvider: decoded.firebase?.sign_in_provider };
      },
      accounts: new FirestorePhoneAccounts(getFirestore(), auth),
      createCustomToken: (uid) => auth.createCustomToken(uid),
      now: Date.now,
      log: (event, data) => logger.info(event, data),
      logError: (message, error) => logger.error(message, error),
    });
    const response = await exchange(request);
    res.status(response.status).type('application/json').send(await response.text());
  },
);

/** OAuth redirect_uri for "Log In with Telegram". */
export const telegramCallback = onRequest({ region, memory: '128MiB' }, async (req, res) => {
  const response = await (await import('./telegram/oidc-exchange.js')).telegramCallback(toWebRequest(req));
  res.status(response.status).set('location', response.headers.get('location') ?? '').send(await response.text());
});

export const cleanupPhoneVerifications = onSchedule(
  { region, schedule: 'every 24 hours', memory: '256MiB' },
  async () => {
    const deleted = await store().deleteStaleSessions(Date.now());
    logger.info('phone_verifications_cleanup', { deleted });
  },
);

/**
 * Runs for every account deletion — from the app's "Delete account" flow
 * and from the Firebase console alike — so a deleted account never keeps a
 * number locked away from its next owner.
 */
export const releasePhoneClaimsOnDelete = v1
  .region(region)
  .auth.user()
  .onDelete(async (user) => {
    const released = await store().releaseClaimsOf(user.uid);
    logger.info('phone_claims_released', { released });
  });
