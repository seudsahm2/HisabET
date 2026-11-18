/**
 * "Continue with Telegram" — exchanges a verified sign-in session for a
 * Firebase custom token. See src/telegram/signin-exchange.ts.
 * Same environment as telegram-webhook (only FIREBASE_SERVICE_ACCOUNT is used).
 */
import type { Config } from '@netlify/functions';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { adminApp } from '../src/admin.js';
import { createSignInExchange } from '../src/telegram/signin-exchange.js';
import { FirestoreVerificationStore } from '../src/verification/firestore-store.js';

let exchange: ((request: Request) => Promise<Response>) | undefined;

function build() {
  const app = adminApp();
  const auth = getAuth(app);
  return createSignInExchange({
    verifyIdToken: async (token) => {
      const decoded = await auth.verifyIdToken(token);
      return { uid: decoded.uid, signInProvider: decoded.firebase?.sign_in_provider };
    },
    store: new FirestoreVerificationStore(getFirestore(app), auth),
    createCustomToken: (uid) => auth.createCustomToken(uid),
    deleteUser: (uid) => auth.deleteUser(uid),
    now: Date.now,
    logError: (message, error) => console.error(message, error),
  });
}

export default async (request: Request): Promise<Response> => {
  exchange ??= build();
  return exchange(request);
};

export const config: Config = { path: '/telegram-signin' };
