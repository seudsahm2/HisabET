/**
 * Security rules for the B2B tender board and for reading a counterparty's
 * ledger. Run with `npm run test:emulator`.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-hisabet',
    firestore: { rules: readFileSync(resolve(__dirname, '../../../firestore.rules'), 'utf8') },
  });
});
afterAll(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const as = (uid: string) => env.authenticatedContext(uid).firestore();

async function seed(path: string, data: Record<string, unknown>) {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), data));
}

const verified = (roles: string[]) => ({ name: 'x', roles, phone: '+251900000000', phoneVerified: true, phoneVerificationMethod: 'telegram' });

describe('tenders', () => {
  const tender = (overrides: Record<string, unknown> = {}) => ({
    importerUid: 'sup',
    importerName: 'Supplier',
    itemNumber: '588-2',
    cartons: 10,
    seriesSize: 6,
    price: 1200,
    status: 'open',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  beforeEach(async () => {
    await seed('users/sup', verified(['supplier']));
    await seed('users/legacy', verified(['Importer']));
    await seed('users/broker', verified(['broker']));
    await seed('users/broker2', verified(['broker']));
    await seed('users/unverified', { name: 'x', roles: ['supplier'] });
  });

  it('lets any signed-in user read the board', async () => {
    await seed('tenders/t1', { ...tender(), createdAt: Timestamp.now() });
    await assertSucceeds(getDocs(query(collection(as('broker'), 'tenders'), where('status', '==', 'open'))));
  });

  it('lets a verified supplier post', async () => {
    await assertSucceeds(addDoc(collection(as('sup'), 'tenders'), tender()));
  });

  it('accepts legacy Importer profiles as suppliers', async () => {
    await assertSucceeds(addDoc(collection(as('legacy'), 'tenders'), tender({ importerUid: 'legacy' })));
  });

  it('refuses posting by a non-supplier, an unverified supplier, or on behalf of someone', async () => {
    await assertFails(addDoc(collection(as('broker'), 'tenders'), tender({ importerUid: 'broker' })));
    await assertFails(addDoc(collection(as('unverified'), 'tenders'), tender({ importerUid: 'unverified' })));
    await assertFails(addDoc(collection(as('broker'), 'tenders'), tender()));
  });

  it('refuses invalid tenders', async () => {
    const db = as('sup');
    await assertFails(addDoc(collection(db, 'tenders'), tender({ cartons: 0 })));
    await assertFails(addDoc(collection(db, 'tenders'), tender({ price: -5 })));
    await assertFails(addDoc(collection(db, 'tenders'), tender({ status: 'won' })));
    await assertFails(addDoc(collection(db, 'tenders'), tender({ winnerUid: 'broker' })));
    await assertFails(addDoc(collection(db, 'tenders'), tender({ itemNumber: '' })));
  });

  describe('winning', () => {
    beforeEach(() => seed('tenders/t1', { ...tender(), createdAt: Timestamp.now() }));
    const win = (uid: string, overrides: Record<string, unknown> = {}) =>
      updateDoc(doc(as(uid), 'tenders/t1'), { status: 'won', winnerUid: uid, wonAt: serverTimestamp(), ...overrides });

    it('lets a verified broker win an open tender', async () => {
      await assertSucceeds(win('broker'));
    });

    it('refuses a second winner once won', async () => {
      await win('broker');
      await assertFails(win('broker2'));
    });

    it('refuses winning your own tender', async () => {
      await assertFails(win('sup'));
    });

    it('refuses winning on behalf of someone else', async () => {
      await assertFails(win('broker', { winnerUid: 'broker2' }));
    });

    it('refuses changing the terms while claiming', async () => {
      await assertFails(win('broker', { price: 1 }));
    });

    it('refuses an unverified winner', async () => {
      await assertFails(win('unverified'));
    });

    it('lets the supplier withdraw only while open', async () => {
      await assertFails(deleteDoc(doc(as('broker'), 'tenders/t1')));
      await assertSucceeds(deleteDoc(doc(as('sup'), 'tenders/t1')));
    });

    it('refuses withdrawing a won tender', async () => {
      await win('broker');
      await assertFails(deleteDoc(doc(as('sup'), 'tenders/t1')));
    });
  });
});

describe('reading a counterparty ledger by phone', () => {
  const MINE = '+251911223344';
  const THEIRS = '+251922334455';

  beforeEach(async () => {
    await seed(`phone_claims/${MINE}`, { uid: 'me', method: 'telegram', claimedAt: Timestamp.now() });
    await seed('users/seller/transactions/tx1', {
      creator_phone: THEIRS,
      contact_phone: MINE,
      amount: '288000',
    });
  });

  it('lets the holder of the contact number read the entry', async () => {
    await assertSucceeds(getDoc(doc(as('me'), 'users/seller/transactions/tx1')));
  });

  it('refuses every other signed-in user (the old leak)', async () => {
    await assertFails(getDoc(doc(as('stranger'), 'users/seller/transactions/tx1')));
  });

  it('allows the app’s subcollection query filtered to my number', async () => {
    const q = query(collection(as('me'), 'users/seller/transactions'), where('contact_phone', '==', MINE));
    await assertSucceeds(getDocs(q));
  });

  it('allows the app’s collection-group query filtered to my number', async () => {
    const q = query(
      collectionGroup(as('me'), 'transactions'),
      where('creator_phone', '==', THEIRS),
      where('contact_phone', '==', MINE),
    );
    await assertSucceeds(getDocs(q));
  });

  it('refuses a query for someone else’s number', async () => {
    const q = query(collection(as('stranger'), 'users/seller/transactions'), where('contact_phone', '==', MINE));
    await assertFails(getDocs(q));
  });

  it('refuses an unfiltered sweep', async () => {
    await assertFails(getDocs(collectionGroup(as('me'), 'transactions')));
  });

  it('still lets the ledger owner and a UID-linked contact read', async () => {
    await seed('users/seller/transactions/tx2', { contact_uid: 'buddy', amount: '1' });
    await assertSucceeds(getDoc(doc(as('seller'), 'users/seller/transactions/tx1')));
    await assertSucceeds(getDoc(doc(as('buddy'), 'users/seller/transactions/tx2')));
  });
});
