/**
 * "Log In with Telegram" (OpenID Connect) — exchanges the code for a
 * verified phone number, then signs in or attaches it. See
 * src/telegram/oidc-exchange.ts.
 *
 * Environment (Netlify, secret): FIREBASE_SERVICE_ACCOUNT,
 * TELEGRAM_CLIENT_ID, TELEGRAM_CLIENT_SECRET (BotFather → bot → Login Widget).
 * Optional: TELEGRAM_REDIRECT_URI (default https://<this site>/telegram-callback).
 */
import type { Config } from '@netlify/functions';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { FirestorePhoneAccounts } from '../src/accounts/phone-accounts.js';
import { adminApp, requireEnv } from '../src/admin.js';
import { TelegramOidcClient } from '../src/telegram/oidc.js';
import { createOidcExchange } from '../src/telegram/oidc-exchange.js';

let exchange: ((request: Request) => Promise<Response>) | undefined;

function build(origin: string) {
  const app = adminApp();
  const auth = getAuth(app);
  const oidc = new TelegramOidcClient({
    clientId: requireEnv('TELEGRAM_CLIENT_ID'),
    clientSecret: requireEnv('TELEGRAM_CLIENT_SECRET'),
    redirectUri: process.env.TELEGRAM_REDIRECT_URI || `${origin}/telegram-callback`,
  });
  return createOidcExchange({
    identify: (code, verifier) => oidc.identify(code, verifier),
    verifyFirebaseIdToken: async (token) => {
      const decoded = await auth.verifyIdToken(token);
      return { uid: decoded.uid, signInProvider: decoded.firebase?.sign_in_provider };
    },
    accounts: new FirestorePhoneAccounts(getFirestore(app), auth),
    createCustomToken: (uid) => auth.createCustomToken(uid),
    now: Date.now,
    // Outcomes only — never phone numbers or Telegram ids.
    log: (event, data) => console.log(JSON.stringify({ event, ...data })),
    logError: (message, error) => console.error(message, error),
  });
}

export default async (request: Request): Promise<Response> => {
  exchange ??= build(new URL(request.url).origin);
  return exchange(request);
};

export const config: Config = { path: '/telegram-oidc' };
