import type { Auth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { Collections, SESSION_RETENTION_MS, TELEGRAM_METHOD } from '../config.js';
import { maskEmail } from '../phone/normalize.js';
import {
  decideComplete,
  decideOpen,
  isPhoneTakenByOther,
  type SessionState,
  type SessionStatus,
} from './session.js';
import type { CompleteResult, OpenResult, VerificationStore } from './store.js';

const STATUSES: readonly SessionStatus[] = ['pending', 'awaiting_contact', 'verified', 'failed'];

/** Reads a session document defensively; anything malformed is treated as absent. */
export function parseSession(data: DocumentData | undefined): SessionState | null {
  if (!data) return null;
  const { uid, status, createdAt, telegramUserId } = data;
  if (typeof uid !== 'string' || uid === '') return null;
  if (!STATUSES.includes(status)) return null;
  if (!(createdAt instanceof Timestamp)) return null;
  return {
    uid,
    status,
    createdAtMs: createdAt.toMillis(),
    telegramUserId: typeof telegramUserId === 'number' ? telegramUserId : undefined,
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

    const outcome = await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(sessionRef);
      const session = parseSession(snap.data());
      if (!session) return { kind: 'not_found' as const };

      const decision = decideOpen(session, telegramUserId, nowMs);
      switch (decision) {
        case 'open':
          tx.update(sessionRef, { status: 'awaiting_contact', telegramUserId, openedAt: now });
          // Points this Telegram account at the session it is completing, so
          // the contact message (which carries no session id) can find it.
          tx.set(this.link(telegramUserId), { sessionId, updatedAt: now });
          return { kind: 'opened' as const, uid: session.uid };
        case 'expired':
          tx.update(sessionRef, { status: 'failed', failureReason: 'expired', updatedAt: now });
          return { kind: 'expired' as const };
        default:
          return { kind: decision };
      }
    });

    if (outcome.kind !== 'opened') return outcome;
    return { kind: 'opened', accountLabel: await this.describeAccount(outcome.uid) };
  }

  async completeWithPhone(telegramUserId: number, phone: string, nowMs: number): Promise<CompleteResult> {
    const now = Timestamp.fromMillis(nowMs);
    // Auth lookups cannot join a Firestore transaction, so this runs first.
    // The window it leaves is closed by the claim document: Firebase Auth
    // users write their claim when they save their profile.
    const authUid = await this.authUidForPhone(phone);
    const linkRef = this.link(telegramUserId);

    return this.db.runTransaction(async (tx): Promise<CompleteResult> => {
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
        return { kind: 'already_verified', phone: String(sessionSnap.get('phone') ?? phone) };
      }
      if (decision === 'not_awaiting') return { kind: 'no_active_session' };
      if (decision === 'expired') {
        tx.update(sessionRef, { status: 'failed', failureReason: 'expired', updatedAt: now });
        tx.delete(linkRef);
        return { kind: 'expired' };
      }

      const claimRef = this.claim(phone);
      const userRef = this.user(session.uid);
      const claimSnap = await tx.get(claimRef);
      const userSnap = await tx.get(userRef);

      const previousPhone = userSnap.get('phone');
      const previousClaimRef =
        typeof previousPhone === 'string' && previousPhone !== '' && previousPhone !== phone
          ? this.claim(previousPhone)
          : null;
      const previousClaimSnap = previousClaimRef ? await tx.get(previousClaimRef) : null;

      const claimUid = claimSnap.exists ? claimSnap.get('uid') : undefined;
      if (isPhoneTakenByOther(session.uid, { claimUid, authUid })) {
        tx.update(sessionRef, { status: 'failed', failureReason: 'phone_in_use', updatedAt: now });
        tx.delete(linkRef);
        return { kind: 'phone_in_use' };
      }

      tx.set(claimRef, { uid: session.uid, method: TELEGRAM_METHOD, claimedAt: now });
      // Changing number: free the old one, but only if this user owns it.
      if (previousClaimRef && previousClaimSnap?.get('uid') === session.uid) {
        tx.delete(previousClaimRef);
      }
      tx.set(
        userRef,
        {
          phone,
          phoneVerified: true,
          phoneVerificationMethod: TELEGRAM_METHOD,
          phoneVerifiedAt: now,
          // An unverified display number is superseded by the proven one.
          contactPhone: FieldValue.delete(),
        },
        { merge: true },
      );
      tx.update(sessionRef, { status: 'verified', phone, completedAt: now });
      tx.delete(linkRef);
      return { kind: 'verified', phone };
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
