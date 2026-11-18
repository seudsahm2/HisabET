/**
 * HisabET Cloud Functions.
 *
 * - `telegramWebhook`     — Telegram bot webhook that verifies a user's phone
 *                           number from their Telegram account.
 * - `cleanupPhoneVerifications` — daily removal of stale verification sessions.
 * - `releasePhoneClaimsOnDelete` — frees a deleted account's phone numbers.
 *
 * Setup and deployment: TELEGRAM_PHONE_VERIFICATION.md at the repo root.
 */
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import * as v1 from 'firebase-functions/v1';
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { TelegramBotClient } from './telegram/client.js';
import { handleUpdate } from './telegram/handler.js';
import { createWebhook } from './telegram/webhook.js';
import { FirestoreVerificationStore } from './verification/firestore-store.js';

initializeApp();

/** From @BotFather. Lives only in Secret Manager. */
const botToken = defineSecret('TELEGRAM_BOT_TOKEN');
/** Random string also passed to setWebhook as `secret_token`. */
const webhookSecret = defineSecret('TELEGRAM_WEBHOOK_SECRET');
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
