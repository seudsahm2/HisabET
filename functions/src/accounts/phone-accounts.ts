import type { Auth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { Collections, TELEGRAM_METHOD } from '../config.js';
import { isPhoneTakenByOther, resolveSignInAccount } from '../verification/session.js';

export type AttachResult = 'attached' | 'phone_in_use';

export class AccountCreationError extends Error {}

/**
 * Accounts keyed by a proven phone number. Every write keeps the invariant
 * enforced elsewhere by the rules: one `phone_claims/{E.164}` document per
 * number, owned by exactly one account, matching that account's `phone`.
 */
export interface PhoneAccounts {
  /** "Verify with Telegram": put [phone] on the existing account [uid]. */
  attachPhone(uid: string, phone: string, nowMs: number): Promise<AttachResult>;

  /**
   * "Continue with Telegram": the account that owns [phone], created (with
   * the phone already verified) if none does.
   */
  accountForPhone(phone: string, nowMs: number, displayName?: string): Promise<{ uid: string; created: boolean }>;
}

export class FirestorePhoneAccounts implements PhoneAccounts {
  constructor(
    private readonly db: Firestore,
    private readonly auth: Auth,
  ) {}

  private claim(phone: string) {
    return this.db.collection(Collections.claims).doc(phone);
  }

  private user(uid: string) {
    return this.db.collection(Collections.users).doc(uid);
  }

  async attachPhone(uid: string, phone: string, nowMs: number): Promise<AttachResult> {
    const now = Timestamp.fromMillis(nowMs);
    const authUid = await this.authUidForPhone(phone);

    return this.db.runTransaction(async (tx): Promise<AttachResult> => {
      const claimSnap = await tx.get(this.claim(phone));
      const userSnap = await tx.get(this.user(uid));
      const previous = userSnap.get('phone');
      const previousRef =
        typeof previous === 'string' && previous !== '' && previous !== phone ? this.claim(previous) : null;
      const previousSnap = previousRef ? await tx.get(previousRef) : null;

      const claimUid = claimSnap.exists ? claimSnap.get('uid') : undefined;
      if (isPhoneTakenByOther(uid, { claimUid, authUid })) return 'phone_in_use';

      tx.set(this.claim(phone), { uid, method: TELEGRAM_METHOD, claimedAt: now });
      // Changing number: free the old one, but only if this account owns it.
      if (previousRef && previousSnap?.get('uid') === uid) tx.delete(previousRef);
      tx.set(this.user(uid), verifiedPhoneFields(phone, now), { merge: true });
      return 'attached';
    });
  }

  async accountForPhone(phone: string, nowMs: number, displayName?: string): Promise<{ uid: string; created: boolean }> {
    const now = Timestamp.fromMillis(nowMs);
    // Auth lookups can't join a transaction, so this runs first; the claim
    // document read inside the transaction is what settles races.
    const authUid = await this.authUidForPhone(phone);
    const newUid = this.db.collection(Collections.users).doc().id;

    const outcome = await this.db.runTransaction(async (tx) => {
      const claimSnap = await tx.get(this.claim(phone));
      const claimUid: string | undefined = claimSnap.exists ? claimSnap.get('uid') : undefined;
      if (claimUid) return { uid: claimUid, created: false };

      // An SMS-era account without a claim, or nobody: the number is claimed now.
      const uid = resolveSignInAccount({ authUid }) ?? newUid;
      tx.set(this.claim(phone), { uid, method: TELEGRAM_METHOD, claimedAt: now });
      tx.set(this.user(uid), verifiedPhoneFields(phone, now), { merge: true });
      return { uid, created: authUid === undefined };
    });

    // Created only after its claim committed, so two simultaneous sign-ins
    // for one new number can never produce two accounts.
    if (outcome.created) {
      try {
        await this.auth.createUser({ uid: outcome.uid, phoneNumber: phone, displayName: displayName || undefined });
      } catch (error) {
        const batch = this.db.batch();
        batch.delete(this.claim(phone));
        batch.delete(this.user(outcome.uid));
        await batch.commit();
        throw new AccountCreationError(`createUser failed: ${(error as { code?: string }).code ?? 'unknown'}`);
      }
    }
    return outcome;
  }

  private async authUidForPhone(phone: string): Promise<string | undefined> {
    try {
      return (await this.auth.getUserByPhoneNumber(phone)).uid;
    } catch (error) {
      if ((error as { code?: string }).code === 'auth/user-not-found') return undefined;
      throw error;
    }
  }
}

function verifiedPhoneFields(phone: string, now: Timestamp) {
  return {
    phone,
    phoneVerified: true,
    phoneVerificationMethod: TELEGRAM_METHOD,
    phoneVerifiedAt: now,
    // An unverified display number is superseded by the proven one.
    contactPhone: FieldValue.delete(),
  };
}
