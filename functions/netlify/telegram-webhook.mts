/**
 * Telegram bot webhook on Netlify Functions — the free hosting option
 * (no Firebase Blaze plan, no card). Same logic as the Cloud Functions entry
 * in src/index.ts; see TELEGRAM_PHONE_VERIFICATION.md → "Free hosting".
 *
 * Environment (Netlify → Site configuration → Environment variables, all
 * marked secret): FIREBASE_SERVICE_ACCOUNT, TELEGRAM_BOT_TOKEN,
 * TELEGRAM_WEBHOOK_SECRET.
 */
import type { Config } from '@netlify/functions';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { adminApp, requireEnv } from '../src/admin.js';
import { TelegramBotClient } from '../src/telegram/client.js';
import { createFetchWebhook } from '../src/telegram/fetch-webhook.js';
import { handleUpdate } from '../src/telegram/handler.js';
import { FirestoreVerificationStore } from '../src/verification/firestore-store.js';

let webhook: ((request: Request) => Promise<Response>) | undefined;

function build() {
  const app = adminApp();
  const store = new FirestoreVerificationStore(getFirestore(app), getAuth(app));
  const bot = new TelegramBotClient(requireEnv('TELEGRAM_BOT_TOKEN'));
  return createFetchWebhook(
    requireEnv('TELEGRAM_WEBHOOK_SECRET'),
    (update) =>
      handleUpdate(update, {
        store,
        bot,
        now: Date.now,
        // Outcomes only — never phone numbers or Telegram ids.
        log: (event, data) => console.log(JSON.stringify({ event, ...data })),
      }),
    (message, error) => console.error(message, error),
  );
}

export default async (request: Request): Promise<Response> => {
  webhook ??= build(); // reused across warm invocations
  return webhook(request);
};

export const config: Config = { path: '/telegram-webhook' };
