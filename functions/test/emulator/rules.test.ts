/**
 * Security-rule tests for phone identity. Run with `npm run test:emulator`
 * (starts the Firestore emulator with the repo's firestore.rules).
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, Timestamp, updateDoc, writeBatch } from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

const PHONE = '+251911223344';
const OTHER = '+251922334455';
const SESSION = 'A'.repeat(43);

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-hisabet',
    firestore: { rules: readFileSync(resolve(__dirname, '../../../firestore.rules'), 'utf8') },
  });
});

afterAll(() => env.cleanup());
beforeEach(() => env.clearFirestore());

/** A user signed in with Google (no phone on the token). */
const google = (uid = 'alice') => env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore();
/** A user whose Firebase Auth record carries [phone] (phone sign-in or SMS link). */
const withPhone = (uid = 'alice', phone = PHONE) => env.authenticatedContext(uid, { phone_number: phone }).firestore();

async function seed(path: string, data: Record<string, unknown>) {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), data));
}

describe('users/{uid} phone identity', () => {
  it('allows ordinary profile writes that do not touch phone fields', async () => {
    await assertSucceeds(setDoc(doc(google(), 'users/alice'), { name: 'Alice', roles: ['broker'] }));
  });

  it('allows an unverified display number in contactPhone', async () => {
    await assertSucceeds(setDoc(doc(google(), 'users/alice'), { name: 'Alice', contactPhone: PHONE }));
  });

  it('refuses a typed-in phone without proof (the old profile-edit hole)', async () => {
    await assertFails(setDoc(doc(google(), 'users/alice'), { name: 'Alice', phone: OTHER }));
  });

  it('refuses claiming a Telegram-verified status from the client', async () => {
    await assertFails(
      setDoc(doc(google(), 'users/alice'), {
        phone: PHONE,
        phoneVerified: true,
        phoneVerificationMethod: 'telegram',
      }),
    );
  });

  it('refuses changing a server-written phone', async () => {
    await seed('users/alice', { name: 'Alice', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'telegram' });
    await assertFails(updateDoc(doc(google(), 'users/alice'), { phone: OTHER }));
  });

  it('lets the profile be edited around a server-written phone', async () => {
    await seed('users/alice', { name: 'Alice', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'telegram' });
    await assertSucceeds(updateDoc(doc(google(), 'users/alice'), { name: 'Alice B.' }));
  });

  it('accepts a Firebase-Auth-proven phone written together with its claim', async () => {
    const db = withPhone();
    const batch = writeBatch(db);
    batch.set(doc(db, `phone_claims/${PHONE}`), { uid: 'alice', method: 'otp', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users/alice'), { phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'otp' }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  it('refuses the proven phone without its claim', async () => {
    await assertFails(
      setDoc(doc(withPhone(), 'users/alice'), { phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'otp' }),
    );
  });

  it('refuses writing a number that differs from the one on the auth token', async () => {
    const db = withPhone('alice', PHONE);
    const batch = writeBatch(db);
    batch.set(doc(db, `phone_claims/${OTHER}`), { uid: 'alice', method: 'otp', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users/alice'), { phone: OTHER, phoneVerified: true, phoneVerificationMethod: 'otp' }, { merge: true });
    await assertFails(batch.commit());
  });
});

describe('phone_claims/{phone}', () => {
  it('refuses a second account claiming a held number', async () => {
    await seed(`phone_claims/${PHONE}`, { uid: 'bob', method: 'telegram', claimedAt: Timestamp.now() });
    const db = withPhone('alice', PHONE);
    const batch = writeBatch(db);
    batch.set(doc(db, `phone_claims/${PHONE}`), { uid: 'alice', method: 'otp', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users/alice'), { phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'otp' }, { merge: true });
    await assertFails(batch.commit());
  });

  it('refuses a claim for someone else', async () => {
    await assertFails(
      setDoc(doc(withPhone('alice'), `phone_claims/${PHONE}`), { uid: 'bob', method: 'otp', claimedAt: serverTimestamp() }),
    );
  });

  it('refuses a client-written telegram claim', async () => {
    await assertFails(
      setDoc(doc(google(), `phone_claims/${PHONE}`), { uid: 'alice', method: 'telegram', claimedAt: serverTimestamp() }),
    );
  });

  it('lets the owner read their claim and anyone check a free number', async () => {
    await seed(`phone_claims/${PHONE}`, { uid: 'alice', method: 'telegram', claimedAt: Timestamp.now() });
    await assertSucceeds(getDoc(doc(google('alice'), `phone_claims/${PHONE}`)));
    await assertSucceeds(getDoc(doc(google('alice'), `phone_claims/${OTHER}`)));
  });

  it('hides who holds a number from other users', async () => {
    await seed(`phone_claims/${PHONE}`, { uid: 'bob', method: 'telegram', claimedAt: Timestamp.now() });
    await assertFails(getDoc(doc(google('alice'), `phone_claims/${PHONE}`)));
  });

  it('lets account deletion release the claim together with the profile', async () => {
    await seed('users/alice', { name: 'Alice', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'telegram' });
    await seed(`phone_claims/${PHONE}`, { uid: 'alice', method: 'telegram', claimedAt: Timestamp.now() });
    const db = google('alice');
    const batch = writeBatch(db);
    batch.delete(doc(db, `phone_claims/${PHONE}`));
    batch.delete(doc(db, 'users/alice'));
    await assertSucceeds(batch.commit());
  });

  it('refuses releasing a claim the profile still uses', async () => {
    await seed('users/alice', { name: 'Alice', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'telegram' });
    await seed(`phone_claims/${PHONE}`, { uid: 'alice', method: 'telegram', claimedAt: Timestamp.now() });
    await assertFails(deleteDoc(doc(google('alice'), `phone_claims/${PHONE}`)));
  });

  it('refuses releasing someone else’s claim', async () => {
    await seed(`phone_claims/${PHONE}`, { uid: 'bob', method: 'telegram', claimedAt: Timestamp.now() });
    await assertFails(deleteDoc(doc(google('alice'), `phone_claims/${PHONE}`)));
  });

  it('never allows edits to an existing claim', async () => {
    await seed(`phone_claims/${PHONE}`, { uid: 'alice', method: 'otp', claimedAt: Timestamp.now() });
    await assertFails(updateDoc(doc(withPhone('alice'), `phone_claims/${PHONE}`), { uid: 'alice' }));
  });
});

describe('phone_verifications/{sessionId}', () => {
  const create = (db = google(), id = SESSION, data: Record<string, unknown> = {}) =>
    setDoc(doc(db, `phone_verifications/${id}`), { uid: 'alice', status: 'pending', createdAt: serverTimestamp(), ...data });

  it('lets a user open their own pending session', async () => {
    await assertSucceeds(create());
  });

  it('refuses a short, guessable session id', async () => {
    await assertFails(create(google(), 'abc'));
  });

  it('refuses a session for another user', async () => {
    await assertFails(create(google(), SESSION, { uid: 'bob' }));
  });

  it('refuses a session that pretends to be verified', async () => {
    await assertFails(create(google(), SESSION, { status: 'verified' }));
  });

  it('refuses extra fields such as a pre-filled phone', async () => {
    await assertFails(create(google(), SESSION, { phone: PHONE }));
  });

  it('lets only the owner read it, and nobody update it', async () => {
    await create();
    await assertSucceeds(getDoc(doc(google('alice'), `phone_verifications/${SESSION}`)));
    await assertFails(getDoc(doc(google('bob'), `phone_verifications/${SESSION}`)));
    await assertFails(updateDoc(doc(google('alice'), `phone_verifications/${SESSION}`), { status: 'verified' }));
  });
});

describe('phone_verifications purpose', () => {
  const anon = (uid = 'anon') =>
    env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
  const make = (db: ReturnType<typeof anon>, uid: string, purpose?: string) =>
    setDoc(doc(db, `phone_verifications/${SESSION}`), {
      uid,
      status: 'pending',
      createdAt: serverTimestamp(),
      ...(purpose ? { purpose } : {}),
    });

  it('lets a temporary anonymous account start a Telegram sign-in', async () => {
    await assertSucceeds(make(anon(), 'anon', 'signin'));
  });

  it('refuses an anonymous account starting a verify (it would reserve a number for a throwaway account)', async () => {
    await assertFails(make(anon(), 'anon', 'verify'));
    await assertFails(make(anon(), 'anon'));
  });

  it('refuses a real account starting a sign-in session', async () => {
    await assertFails(make(google('alice'), 'alice', 'signin'));
  });

  it('accepts verify from a real account, with or without the field', async () => {
    await assertSucceeds(make(google('alice'), 'alice', 'verify'));
  });

  it('refuses unknown purposes', async () => {
    await assertFails(make(google('alice'), 'alice', 'admin'));
  });
});

describe('telegram_links', () => {
  it('is invisible to clients', async () => {
    await assertFails(getDoc(doc(google(), 'telegram_links/42')));
    await assertFails(setDoc(doc(google(), 'telegram_links/42'), { sessionId: SESSION }));
  });
});
