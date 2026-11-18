/** Daily removal of stale phone-verification sessions (free-hosting option). */
import type { Config } from '@netlify/functions';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { adminApp } from '../src/admin.js';
import { FirestoreVerificationStore } from '../src/verification/firestore-store.js';

export default async (): Promise<void> => {
  const app = adminApp();
  const deleted = await new FirestoreVerificationStore(getFirestore(app), getAuth(app)).deleteStaleSessions(Date.now());
  console.log(JSON.stringify({ event: 'phone_verifications_cleanup', deleted }));
};

export const config: Config = { schedule: '@daily' };
