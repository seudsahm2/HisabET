/**
 * FirestorePhoneAccounts (Log In with Telegram) against the Firestore + Auth
 * emulators. Run with `npm run test:emulator`.
 */
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { FirestorePhoneAccounts } from '../../src/accounts/phone-accounts.js';

const PROJECT = 'demo-hisabet';
const PHONE = '+251966143454';
const OLD = '+251900000000';
const NOW = Date.UTC(2026, 10, 18);

let app: App;
let db: Firestore;
let auth: Auth;
let accounts: FirestorePhoneAccounts;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run through `npm run test:emulator` so the emulators are up.');
  }
  app = initializeApp({ projectId: PROJECT }, 'phone-accounts-test');
  db = getFirestore(app);
  auth = getAuth(app);
  accounts = new FirestorePhoneAccounts(db, auth);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/accounts`, {
    method: 'DELETE',
  });
});

const claimOwner = async (phone: string) => (await db.doc(`phone_claims/${phone}`).get()).get('uid');

describe('accountForPhone (Continue with Telegram)', () => {
  it('creates a new account with the phone on its Auth record and profile', async () => {
    const { uid, created } = await accounts.accountForPhone(PHONE, NOW, 'Seud');
    expect(created).toBe(true);

    const user = await auth.getUser(uid);
    expect(user.phoneNumber).toBe(PHONE);
    expect(user.displayName).toBe('Seud');
    expect(await claimOwner(PHONE)).toBe(uid);
    expect((await db.doc(`users/${uid}`).get()).data()).toMatchObject({
      phone: PHONE,
      phoneVerified: true,
      phoneVerificationMethod: 'telegram',
    });
  });

  it('returns the existing owner and leaves their profile untouched', async () => {
    await db.doc(`phone_claims/${PHONE}`).set({ uid: 'existing', method: 'otp', claimedAt: Timestamp.now() });
    await db.doc('users/existing').set({ name: 'E', phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'otp' });

    expect(await accounts.accountForPhone(PHONE, NOW)).toEqual({ uid: 'existing', created: false });
    expect((await db.doc('users/existing').get()).get('phoneVerificationMethod')).toBe('otp');
  });

  it('adopts an SMS-era Auth account that has no claim yet', async () => {
    await auth.createUser({ uid: 'smsuser', phoneNumber: PHONE });
    expect(await accounts.accountForPhone(PHONE, NOW)).toEqual({ uid: 'smsuser', created: false });
    expect(await claimOwner(PHONE)).toBe('smsuser');
  });

  it('gives two simultaneous first sign-ins the same single account', async () => {
    const [a, b] = await Promise.all([accounts.accountForPhone(PHONE, NOW), accounts.accountForPhone(PHONE, NOW)]);
    expect(a.uid).toBe(b.uid);
    expect([a.created, b.created].filter(Boolean)).toHaveLength(1);
    expect((await auth.getUserByPhoneNumber(PHONE)).uid).toBe(a.uid);
  });
});

describe('attachPhone (Verify with Telegram)', () => {
  it('attaches a free number to the signed-in account', async () => {
    await db.doc('users/google').set({ name: 'G', contactPhone: PHONE });
    expect(await accounts.attachPhone('google', PHONE, NOW)).toBe('attached');
    expect(await claimOwner(PHONE)).toBe('google');
    const profile = (await db.doc('users/google').get()).data()!;
    expect(profile).toMatchObject({ phone: PHONE, phoneVerified: true, phoneVerificationMethod: 'telegram' });
    expect(profile.contactPhone).toBeUndefined();
  });

  it('refuses a number claimed by another account', async () => {
    await db.doc(`phone_claims/${PHONE}`).set({ uid: 'other', method: 'telegram', claimedAt: Timestamp.now() });
    expect(await accounts.attachPhone('google', PHONE, NOW)).toBe('phone_in_use');
    expect(await claimOwner(PHONE)).toBe('other');
  });

  it('refuses a number another Auth account signed in with', async () => {
    await auth.createUser({ uid: 'other', phoneNumber: PHONE });
    expect(await accounts.attachPhone('google', PHONE, NOW)).toBe('phone_in_use');
  });

  it('releases the previous number when changing', async () => {
    await db.doc(`phone_claims/${OLD}`).set({ uid: 'google', method: 'telegram', claimedAt: Timestamp.now() });
    await db.doc('users/google').set({ phone: OLD, phoneVerified: true });
    await accounts.attachPhone('google', PHONE, NOW);
    expect((await db.doc(`phone_claims/${OLD}`).get()).exists).toBe(false);
    expect(await claimOwner(PHONE)).toBe('google');
  });

  it('is idempotent for the same account', async () => {
    expect(await accounts.attachPhone('google', PHONE, NOW)).toBe('attached');
    expect(await accounts.attachPhone('google', PHONE, NOW)).toBe('attached');
  });
});
