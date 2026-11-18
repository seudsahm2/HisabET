/**
 * FirestoreVerificationStore against the Firestore + Auth emulators.
 * Run with `npm run test:emulator`.
 */
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { SESSION_RETENTION_MS, SESSION_TTL_MS } from '../../src/config.js';
import { FirestoreVerificationStore } from '../../src/verification/firestore-store.js';

const PROJECT = 'demo-hisabet';
const PHONE = '+251911223344';
const OLD_PHONE = '+251900000000';
const TG = 42;
const T0 = Date.UTC(2026, 10, 18, 9, 0, 0);

let app: App;
let db: Firestore;
let auth: Auth;
let store: FirestoreVerificationStore;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run through `npm run test:emulator` so the emulators are up.');
  }
  app = initializeApp({ projectId: PROJECT }, 'store-test');
  db = getFirestore(app);
  auth = getAuth(app);
  store = new FirestoreVerificationStore(db, auth);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  const fsHost = process.env.FIRESTORE_EMULATOR_HOST;
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  await fetch(`http://${fsHost}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
});

async function newSession(id: string, uid = 'alice', createdAtMs = T0, purpose?: 'signin') {
  await db.doc(`phone_verifications/${id}`).set({
    uid,
    status: 'pending',
    createdAt: Timestamp.fromMillis(createdAtMs),
    ...(purpose ? { purpose } : {}),
  });
}

const sid = (c: string) => c.repeat(43);

describe('openSession', () => {
  it('binds the session and names the account (masked)', async () => {
    await auth.createUser({ uid: 'alice', email: 'alice@example.com' });
    await db.doc('users/alice').set({ name: 'Alice Shoes' });
    await newSession(sid('a'));

    const result = await store.openSession(sid('a'), TG, T0 + 1000);

    expect(result).toEqual({ kind: 'opened', purpose: 'verify', accountLabel: 'Alice Shoes · a***e@example.com' });
    const session = (await db.doc(`phone_verifications/${sid('a')}`).get()).data();
    expect(session).toMatchObject({ status: 'awaiting_contact', telegramUserId: TG });
    expect((await db.doc(`telegram_links/${TG}`).get()).get('sessionId')).toBe(sid('a'));
  });

  it('marks an expired session failed', async () => {
    await newSession(sid('b'));
    expect(await store.openSession(sid('b'), TG, T0 + SESSION_TTL_MS + 1)).toEqual({ kind: 'expired' });
    expect((await db.doc(`phone_verifications/${sid('b')}`).get()).get('failureReason')).toBe('expired');
  });

  it('reports unknown sessions', async () => {
    expect(await store.openSession(sid('z'), TG, T0)).toEqual({ kind: 'not_found' });
  });
});

describe('completeWithPhone', () => {
  async function opened(id: string, uid = 'alice', tg = TG) {
    await newSession(id, uid);
    await store.openSession(id, tg, T0 + 1000);
  }

  it('claims the number, writes the profile and closes the session', async () => {
    await db.doc('users/alice').set({ name: 'Alice', contactPhone: PHONE });
    await opened(sid('a'));

    expect(await store.completeWithPhone(TG, PHONE, T0 + 2000)).toEqual({ kind: 'verified', phone: PHONE, purpose: 'verify' });

    expect((await db.doc(`phone_claims/${PHONE}`).get()).data()).toMatchObject({ uid: 'alice', method: 'telegram' });
    const user = (await db.doc('users/alice').get()).data()!;
    expect(user).toMatchObject({ name: 'Alice', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'telegram' });
    expect(user.contactPhone).toBeUndefined();
    expect((await db.doc(`phone_verifications/${sid('a')}`).get()).get('status')).toBe('verified');
    expect((await db.doc(`telegram_links/${TG}`).get()).exists).toBe(false);
  });

  it('works before the profile document exists (new Google user)', async () => {
    await opened(sid('a'));
    expect(await store.completeWithPhone(TG, PHONE, T0 + 2000)).toMatchObject({ kind: 'verified' });
    expect((await db.doc('users/alice').get()).get('phone')).toBe(PHONE);
  });

  it('refuses a number claimed by another account', async () => {
    await db.doc(`phone_claims/${PHONE}`).set({ uid: 'bob', method: 'telegram', claimedAt: Timestamp.now() });
    await opened(sid('a'));

    expect(await store.completeWithPhone(TG, PHONE, T0 + 2000)).toEqual({ kind: 'phone_in_use' });

    expect((await db.doc(`phone_claims/${PHONE}`).get()).get('uid')).toBe('bob');
    expect((await db.doc('users/alice').get()).exists).toBe(false);
    expect((await db.doc(`phone_verifications/${sid('a')}`).get()).get('failureReason')).toBe('phone_in_use');
  });

  it('refuses a number another Firebase Auth account signed in with, even with no claim', async () => {
    await auth.createUser({ uid: 'bob', phoneNumber: PHONE });
    await opened(sid('a'));
    expect(await store.completeWithPhone(TG, PHONE, T0 + 2000)).toEqual({ kind: 'phone_in_use' });
  });

  it('lets two accounts race for one number and gives it to exactly one', async () => {
    await opened(sid('a'), 'alice', 1);
    await opened(sid('b'), 'bob', 2);

    const results = await Promise.all([
      store.completeWithPhone(1, PHONE, T0 + 2000),
      store.completeWithPhone(2, PHONE, T0 + 2000),
    ]);

    expect(results.map((r) => r.kind).sort()).toEqual(['phone_in_use', 'verified']);
    const winner = results[0].kind === 'verified' ? 'alice' : 'bob';
    expect((await db.doc(`phone_claims/${PHONE}`).get()).get('uid')).toBe(winner);
  });

  it('releases the previous number when a user changes theirs', async () => {
    await db.doc(`phone_claims/${OLD_PHONE}`).set({ uid: 'alice', method: 'telegram', claimedAt: Timestamp.now() });
    await db.doc('users/alice').set({ phone: OLD_PHONE, phoneVerified: true });
    await opened(sid('a'));

    await store.completeWithPhone(TG, PHONE, T0 + 2000);

    expect((await db.doc(`phone_claims/${OLD_PHONE}`).get()).exists).toBe(false);
    expect((await db.doc(`phone_claims/${PHONE}`).get()).get('uid')).toBe('alice');
  });

  it('is idempotent when Telegram redelivers the contact', async () => {
    await opened(sid('a'));
    await store.completeWithPhone(TG, PHONE, T0 + 2000);
    // The link is gone after success, so a redelivery finds no active session…
    expect(await store.completeWithPhone(TG, PHONE, T0 + 3000)).toEqual({ kind: 'no_active_session' });
    // …and nothing was undone.
    expect((await db.doc(`phone_claims/${PHONE}`).get()).get('uid')).toBe('alice');
  });

  it('refuses when this Telegram account never opened a link', async () => {
    expect(await store.completeWithPhone(TG, PHONE, T0)).toEqual({ kind: 'no_active_session' });
  });

  it('refuses an expired session', async () => {
    await opened(sid('a'));
    expect(await store.completeWithPhone(TG, PHONE, T0 + SESSION_TTL_MS + 1)).toEqual({ kind: 'expired' });
    expect((await db.doc(`phone_claims/${PHONE}`).get()).exists).toBe(false);
  });
});

describe('Telegram sign-in', () => {
  async function signInSession(id: string, anonUid: string, tg = TG) {
    await newSession(id, anonUid, T0, 'signin');
    return store.openSession(id, tg, T0 + 1000);
  }

  it('asks for the contact without naming any account', async () => {
    expect(await signInSession(sid('a'), 'anon1')).toEqual({ kind: 'opened', purpose: 'signin' });
  });

  it('creates a new account for an unknown number, with the phone on it', async () => {
    await signInSession(sid('a'), 'anon1');
    const result = await store.completeWithPhone(TG, PHONE, T0 + 2000, 'Ahmed');
    expect(result).toEqual({ kind: 'verified', phone: PHONE, purpose: 'signin' });

    const session = (await db.doc(`phone_verifications/${sid('a')}`).get()).data()!;
    const uid = session.signInUid as string;
    expect(uid).toBeTruthy();
    expect(uid).not.toBe('anon1');

    const authUser = await auth.getUser(uid);
    expect(authUser.phoneNumber).toBe(PHONE);
    expect(authUser.displayName).toBe('Ahmed');
    expect((await db.doc(`phone_claims/${PHONE}`).get()).get('uid')).toBe(uid);
    expect((await db.doc(`users/${uid}`).get()).data()).toMatchObject({
      phone: PHONE,
      phoneVerified: true,
      phoneVerificationMethod: 'telegram',
    });
  });

  it('signs a returning user into the account that already holds the number', async () => {
    await db.doc(`phone_claims/${PHONE}`).set({ uid: 'existing', method: 'telegram', claimedAt: Timestamp.now() });
    await db.doc('users/existing').set({ name: 'Existing', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'otp' });
    await signInSession(sid('a'), 'anon1');

    await store.completeWithPhone(TG, PHONE, T0 + 2000);

    expect((await db.doc(`phone_verifications/${sid('a')}`).get()).get('signInUid')).toBe('existing');
    // The existing profile is left exactly as it was.
    expect((await db.doc('users/existing').get()).get('phoneVerificationMethod')).toBe('otp');
  });

  it('signs into a phone-login account that predates claims, and claims the number for it', async () => {
    await auth.createUser({ uid: 'smsuser', phoneNumber: PHONE });
    await signInSession(sid('a'), 'anon1');
    await store.completeWithPhone(TG, PHONE, T0 + 2000);
    expect((await db.doc(`phone_verifications/${sid('a')}`).get()).get('signInUid')).toBe('smsuser');
    expect((await db.doc(`phone_claims/${PHONE}`).get()).get('uid')).toBe('smsuser');
  });

  it('gives two simultaneous sign-ins for one new number the same single account', async () => {
    await signInSession(sid('a'), 'anon1', 1);
    await signInSession(sid('b'), 'anon2', 2);

    const results = await Promise.all([
      store.completeWithPhone(1, PHONE, T0 + 2000),
      store.completeWithPhone(2, PHONE, T0 + 2000),
    ]);
    expect(results.every((r) => r.kind === 'verified')).toBe(true);

    const a = (await db.doc(`phone_verifications/${sid('a')}`).get()).get('signInUid');
    const b = (await db.doc(`phone_verifications/${sid('b')}`).get()).get('signInUid');
    expect(a).toBe(b);
    expect((await auth.getUserByPhoneNumber(PHONE)).uid).toBe(a);
  });

  it('exchanges once, for the anonymous owner only', async () => {
    await signInSession(sid('a'), 'anon1');
    await store.completeWithPhone(TG, PHONE, T0 + 2000);

    expect(await store.consumeSignIn(sid('a'), 'intruder', T0 + 3000)).toEqual({ kind: 'not_owner' });
    const ok = await store.consumeSignIn(sid('a'), 'anon1', T0 + 3000);
    expect(ok.kind).toBe('ok');
    expect(await store.consumeSignIn(sid('a'), 'anon1', T0 + 4000)).toEqual({ kind: 'already_used' });
  });

  it('will not exchange before Telegram verified the number', async () => {
    await signInSession(sid('a'), 'anon1');
    expect(await store.consumeSignIn(sid('a'), 'anon1', T0 + 3000)).toEqual({ kind: 'not_ready' });
  });
});

describe('housekeeping', () => {
  it('deletes only sessions past the retention window', async () => {
    await newSession(sid('o'), 'alice', T0 - SESSION_RETENTION_MS - 1);
    await newSession(sid('n'), 'alice', T0);
    expect(await store.deleteStaleSessions(T0)).toBe(1);
    expect((await db.doc(`phone_verifications/${sid('n')}`).get()).exists).toBe(true);
  });

  it('releases every claim of a deleted account', async () => {
    await db.doc(`phone_claims/${PHONE}`).set({ uid: 'alice', method: 'telegram', claimedAt: Timestamp.now() });
    await db.doc(`phone_claims/${OLD_PHONE}`).set({ uid: 'bob', method: 'otp', claimedAt: Timestamp.now() });
    expect(await store.releaseClaimsOf('alice')).toBe(1);
    expect((await db.doc(`phone_claims/${OLD_PHONE}`).get()).exists).toBe(true);
  });
});
