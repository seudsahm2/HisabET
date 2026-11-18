import type { Auth } from 'firebase-admin/auth';
import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { Collections, SESSION_RETENTION_MS, TELEGRAM_METHOD } from '../config.js';
import { maskEmail } from '../phone/normalize.js';
import {
  decideComplete,
  decideConsume,
  decideOpen,
  isPhoneTakenByOther,
  resolveSignInAccount,
  type SessionPurpose,
  type SessionState,
  type SessionStatus,
} from './session.js';
import type { CompleteResult, ConsumeResult, OpenResult, VerificationStore } from './store.js';

const STATUSES: readonly SessionStatus[] = ['pending', 'awaiting_contact', 'verified', 'failed'];

/** Reads a session document defensively; anything malformed is treated as absent. */
export function parseSession(data: DocumentData | undefined): SessionState | null {
  if (!data) return null;
  const { uid, status, createdAt, telegramUserId, purpose, signInUid, consumedAt, completedAt } = data;
  if (typeof uid !== 'string' || uid === '') return null;
  if (!STATUSES.includes(status)) return null;
  if (!(createdAt instanceof Timestamp)) return null;
  return {
    uid,
    status,
    createdAtMs: createdAt.toMillis(),
    purpose: purpose === 'signin' ? 'signin' : 'verify',
    telegramUserId: typeof telegramUserId === 'number' ? telegramUserId : undefined,
    signInUid: typeof signInUid === 'string' ? signInUid : undefined,
    consumed: consumedAt instanceof Timestamp,
    completedAtMs: completedAt instanceof Timestamp ? completedAt.toMillis() : undefined,
  };
}

export class FirestoreVerificationStore implements VerificationStore {
  constructor(
    private readonly db: Firestore,
    private readonly auth: Auth,
  ) {}

  private session(id: string) {
    return this.db.collection(Collections.sessions).doc(id);
  }

  private link(telegramUserId: number) {
    return this.db.collection(Collections.telegramLinks).doc(String(telegramUserId));
  }

  private claim(phone: string) {
    return this.db.collection(Collections.claims).doc(phone);
  }

  private user(uid: string) {
    return this.db.collection(Collections.users).doc(uid);
  }

  async openSession(sessionId: string, telegramUserId: number, nowMs: number): Promise<OpenResult> {
    const now = Timestamp.fromMillis(nowMs);
    const sessionRef = this.session(sessionId);

    type Outcome =
      | { kind: 'opened'; uid: string; purpose: SessionPurpose }
      | Exclude<OpenResult, { kind: 'opened' }>;

    const outcome = await this.db.runTransaction(async (tx): Promise<Outcome> => {
      const snap = await tx.get(sessionRef);
      const session = parseSession(snap.data());
      if (!session) return { kind: 'not_found' };

      const decision = decideOpen(session, telegramUserId, nowMs);
      switch (decision) {
        case 'open':
          tx.update(sessionRef, { status: 'awaiting_contact', telegramUserId, openedAt: now });
          // Points this Telegram account at the session it is completing, so
          // the contact message (which carries no session id) can find it.
          tx.set(this.link(telegramUserId), { sessionId, updatedAt: now });
          return { kind: 'opened', uid: session.uid, purpose: session.purpose };
        case 'expired':
          tx.update(sessionRef, { status: 'failed', failureReason: 'expired', updatedAt: now });
          return { kind: 'expired' };
        default:
          return { kind: decision };
      }
    });

    if (outcome.kind !== 'opened') return outcome;
    // A sign-in session belongs to a throwaway anonymous account: nothing to name.
    if (outcome.purpose === 'signin') return { kind: 'opened', purpose: 'signin' };
    return { kind: 'opened', purpose: 'verify', accountLabel: await this.describeAccount(outcome.uid) };
  }

  async completeWithPhone(
    telegramUserId: number,
    phone: string,
    nowMs: number,
    telegramFirstName?: string,
  ): Promise<CompleteResult> {
    const now = Timestamp.fromMillis(nowMs);
    // Auth lookups cannot join a Firestore transaction, so this runs first.
    // The window it leaves is closed by the claim document: Firebase Auth
    // users write their claim when they save their profile.
    const authUid = await this.authUidForPhone(phone);
    const linkRef = this.link(telegramUserId);
    // Pre-allocated in case a sign-in has to create a brand-new account.
    const newUid = this.db.collection(Collections.users).doc().id;

    const result = await this.db.runTransaction(async (tx): Promise<CompleteResult & { createdUid?: string }> => {
      // Firestore transactions require every read before the first write.
      const linkSnap = await tx.get(linkRef);
      const sessionId = linkSnap.get('sessionId');
      if (typeof sessionId !== 'string') return { kind: 'no_active_session' };

      const sessionRef = this.session(sessionId);
      const sessionSnap = await tx.get(sessionRef);
      const session = parseSession(sessionSnap.data());
      if (!session) {
        tx.delete(linkRef);
        return { kind: 'no_active_session' };
      }

      const decision = decideComplete(session, telegramUserId, nowMs);
      if (decision === 'already_verified') {
        return { kind: 'already_verified', phone: String(sessionSnap.get('phone') ?? phone), purpose: session.purpose };
      }
      if (decision === 'not_awaiting') return { kind: 'no_active_session' };
      if (decision === 'expired') {
        tx.update(sessionRef, { status: 'failed', failureReason: 'expired', updatedAt: now });
        tx.delete(linkRef);
        return { kind: 'expired' };
      }

      const claimSnap = await tx.get(this.claim(phone));
      const claimUid: string | undefined = claimSnap.exists ? claimSnap.get('uid') : undefined;

      if (session.purpose === 'signin') {
        return this.completeSignIn(tx, { sessionRef, linkRef, phone, now, claimUid, authUid, newUid, telegramFirstName });
      }
      return this.completeVerify(tx, { session, sessionRef, linkRef, phone, now, claimUid, authUid });
    });

    // A new account is created only after its claim is committed, so two
    // racing sign-ins for one number can never both create one.
    if (result.kind === 'verified' && result.createdUid) {
      try {
        await this.auth.createUser({
          uid: result.createdUid,
          phoneNumber: phone,
          displayName: telegramFirstName?.trim() || undefined,
        });
      } catch (error) {
        await this.rollBackNewAccount(result.createdUid, phone, linkRef);
        console.error('telegram sign-in: createUser failed', (error as { code?: string }).code);
        return { kind: 'account_error' };
      }
    }
    const { createdUid: _ignored, ...publicResult } = result as CompleteResult & { createdUid?: string };
    return publicResult;
  }

  /** `verify`: put the number on the account that started the session. */
  private async completeVerify(
    tx: Transaction,
    p: {
      session: SessionState;
      sessionRef: DocumentReference;
      linkRef: DocumentReference;
      phone: string;
      now: Timestamp;
      claimUid?: string;
      authUid?: string;
    },
  ): Promise<CompleteResult> {
    const uid = p.session.uid;
    const userRef = this.user(uid);
    const userSnap = await tx.get(userRef);

    const previousPhone = userSnap.get('phone');
    const previousClaimRef =
      typeof previousPhone === 'string' && previousPhone !== '' && previousPhone !== p.phone
        ? this.claim(previousPhone)
        : null;
    const previousClaimSnap = previousClaimRef ? await tx.get(previousClaimRef) : null;

    if (isPhoneTakenByOther(uid, { claimUid: p.claimUid, authUid: p.authUid })) {
      tx.update(p.sessionRef, { status: 'failed', failureReason: 'phone_in_use', updatedAt: p.now });
      tx.delete(p.linkRef);
      return { kind: 'phone_in_use' };
    }

    tx.set(this.claim(p.phone), { uid, method: TELEGRAM_METHOD, claimedAt: p.now });
    // Changing number: free the old one, but only if this user owns it.
    if (previousClaimRef && previousClaimSnap?.get('uid') === uid) {
      tx.delete(previousClaimRef);
    }
    tx.set(userRef, this.verifiedPhoneFields(p.phone, p.now), { merge: true });
    tx.update(p.sessionRef, { status: 'verified', phone: p.phone, completedAt: p.now });
    tx.delete(p.linkRef);
    return { kind: 'verified', phone: p.phone, purpose: 'verify' };
  }

  /**
   * `signin`: the number *is* the account. Sign into its owner, or reserve
   * it for a new account that is created right after the transaction.
   */
  private async completeSignIn(
    tx: Transaction,
    p: {
      sessionRef: DocumentReference;
      linkRef: DocumentReference;
      phone: string;
      now: Timestamp;
      claimUid?: string;
      authUid?: string;
      newUid: string;
      telegramFirstName?: string;
    },
  ): Promise<CompleteResult & { createdUid?: string }> {
    const existing = resolveSignInAccount({ claimUid: p.claimUid, authUid: p.authUid });
    const uid = existing ?? p.newUid;

    if (!p.claimUid) {
      // Existing phone-auth account without a claim, or a new account:
      // either way the number becomes theirs now.
      tx.set(this.claim(p.phone), { uid, method: TELEGRAM_METHOD, claimedAt: p.now });
      tx.set(this.user(uid), this.verifiedPhoneFields(p.phone, p.now), { merge: true });
    }
    tx.update(p.sessionRef, {
      status: 'verified',
      phone: p.phone,
      signInUid: uid,
      completedAt: p.now,
    });
    tx.delete(p.linkRef);
    return { kind: 'verified', phone: p.phone, purpose: 'signin', createdUid: existing ? undefined : uid };
  }

  async consumeSignIn(sessionId: string, callerUid: string, nowMs: number): Promise<ConsumeResult> {
    const ref = this.session(sessionId);
    return this.db.runTransaction(async (tx): Promise<ConsumeResult> => {
      const session = parseSession((await tx.get(ref)).data());
      if (!session) return { kind: 'not_found' };
      const decision = decideConsume(session, callerUid, nowMs);
      if (decision !== 'ok') return { kind: decision };
      tx.update(ref, { consumedAt: Timestamp.fromMillis(nowMs) });
      return { kind: 'ok', uid: session.signInUid! };
    });
  }

  /** Deletes sessions older than the retention window. Returns how many. */
  async deleteStaleSessions(nowMs: number, batchSize = 300): Promise<number> {
    const cutoff = Timestamp.fromMillis(nowMs - SESSION_RETENTION_MS);
    let deleted = 0;
    for (;;) {
      const stale = await this.db
        .collection(Collections.sessions)
        .where('createdAt', '<', cutoff)
        .limit(batchSize)
        .get();
      if (stale.empty) return deleted;
      const batch = this.db.batch();
      stale.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      deleted += stale.size;
    }
  }

  /** Frees every number held by [uid]. Called when the account is deleted. */
  async releaseClaimsOf(uid: string): Promise<number> {
    const owned = await this.db.collection(Collections.claims).where('uid', '==', uid).get();
    if (owned.empty) return 0;
    const batch = this.db.batch();
    owned.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    return owned.size;
  }

  private verifiedPhoneFields(phone: string, now: Timestamp) {
    return {
      phone,
      phoneVerified: true,
      phoneVerificationMethod: TELEGRAM_METHOD,
      phoneVerifiedAt: now,
      // An unverified display number is superseded by the proven one.
      contactPhone: FieldValue.delete(),
    };
  }

  /** Undo a sign-in whose account could not be created, so the number is not stranded. */
  private async rollBackNewAccount(uid: string, phone: string, linkRef: DocumentReference) {
    const batch = this.db.batch();
    batch.delete(this.claim(phone));
    batch.delete(this.user(uid));
    batch.delete(linkRef);
    await batch.commit();
    const sessions = await this.db.collection(Collections.sessions).where('signInUid', '==', uid).get();
    if (!sessions.empty) {
      const fail = this.db.batch();
      sessions.docs.forEach((d) => fail.update(d.ref, { status: 'failed', failureReason: 'account_error', signInUid: FieldValue.delete() }));
      await fail.commit();
    }
  }

  private async authUidForPhone(phone: string): Promise<string | undefined> {
    try {
      return (await this.auth.getUserByPhoneNumber(phone)).uid;
    } catch (error) {
      if ((error as { code?: string }).code === 'auth/user-not-found') return undefined;
      throw error;
    }
  }

  /**
   * How the bot names the account being verified, so someone tricked into
   * opening another person's link can see it is not their account.
   */
  private async describeAccount(uid: string): Promise<string> {
    const [profile, authUser] = await Promise.all([
      this.user(uid).get(),
      this.auth.getUser(uid).catch(() => null),
    ]);
    const name = profile.get('name');
    const email = authUser?.email;
    const parts = [
      typeof name === 'string' && name.trim() !== '' ? name.trim() : null,
      email ? maskEmail(email) : null,
    ].filter((part): part is string => part !== null);
    return parts.length > 0 ? parts.join(' · ') : 'your HisabET account';
  }
}

export type { SessionPurpose };
