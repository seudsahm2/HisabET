import { SESSION_TTL_MS } from '../config.js';

/**
 * Lifecycle of a `phone_verifications/{id}` document.
 *
 *   pending ──/start──▶ awaiting_contact ──contact──▶ verified
 *      │                       │
 *      └──────── expired / phone_in_use ──────────▶ failed
 *
 * The app creates `pending`; every later transition is made by the server.
 */
export type SessionStatus = 'pending' | 'awaiting_contact' | 'verified' | 'failed';

export type FailureReason = 'expired' | 'phone_in_use' | 'account_error';

/**
 * - `verify` — attach the number to the account that started the session
 *   (a Google user adding their phone).
 * - `signin` — "Continue with Telegram": find the account that owns the
 *   number, or create one, and sign the app into it. Started from a
 *   temporary anonymous account that is discarded afterwards.
 */
export type SessionPurpose = 'verify' | 'signin';

export interface SessionState {
  uid: string;
  status: SessionStatus;
  createdAtMs: number;
  purpose: SessionPurpose;
  telegramUserId?: number;
  /** signin only: the account the app may now sign into. */
  signInUid?: string;
  /** signin only: set once the app has exchanged the session for a token. */
  consumed?: boolean;
  completedAtMs?: number;
}

export type OpenDecision =
  | 'open'
  | 'expired'
  | 'already_verified'
  | 'closed'
  /** Another Telegram account already opened this link. */
  | 'other_telegram_account';

/** May [telegramUserId] bind this session to their Telegram account? */
export function decideOpen(
  session: SessionState,
  telegramUserId: number,
  nowMs: number,
): OpenDecision {
  if (session.status === 'verified') return 'already_verified';
  if (session.status === 'failed') return 'closed';
  if (isExpired(session, nowMs)) return 'expired';
  if (
    session.telegramUserId !== undefined &&
    session.telegramUserId !== telegramUserId
  ) {
    return 'other_telegram_account';
  }
  return 'open';
}

export type CompleteDecision = 'complete' | 'expired' | 'already_verified' | 'not_awaiting';

/** May a contact shared by [telegramUserId] complete this session? */
export function decideComplete(
  session: SessionState,
  telegramUserId: number,
  nowMs: number,
): CompleteDecision {
  if (session.status === 'verified') return 'already_verified';
  if (session.status !== 'awaiting_contact') return 'not_awaiting';
  if (session.telegramUserId !== telegramUserId) return 'not_awaiting';
  if (isExpired(session, nowMs)) return 'expired';
  return 'complete';
}

export function isExpired(session: SessionState, nowMs: number): boolean {
  return nowMs - session.createdAtMs > SESSION_TTL_MS;
}

/** Who already owns a number, from every source that can hold one. */
export interface PhoneOwnership {
  /** `phone_claims/{phone}.uid`, if the claim exists. */
  claimUid?: string;
  /** Firebase Auth user that signed in with / linked this number, if any. */
  authUid?: string;
}

/** True when the number belongs to someone other than [uid]. */
export function isPhoneTakenByOther(uid: string, owner: PhoneOwnership): boolean {
  return (
    (owner.claimUid !== undefined && owner.claimUid !== uid) ||
    (owner.authUid !== undefined && owner.authUid !== uid)
  );
}

/**
 * Which existing account a Telegram sign-in belongs to, or undefined when a
 * new account must be created. The claim is authoritative; a Firebase Auth
 * phone account without a claim (signed up by SMS) is the fallback.
 */
export function resolveSignInAccount(owner: PhoneOwnership): string | undefined {
  return owner.claimUid ?? owner.authUid;
}

export type ConsumeDecision = 'ok' | 'not_owner' | 'not_signin' | 'not_ready' | 'already_used' | 'expired';

/**
 * May [callerUid] exchange this session for a sign-in token? Only the
 * temporary account that started it, only once, only after Telegram
 * verified the number, and only shortly after.
 */
export function decideConsume(session: SessionState, callerUid: string, nowMs: number): ConsumeDecision {
  if (session.uid !== callerUid) return 'not_owner';
  if (session.purpose !== 'signin') return 'not_signin';
  if (session.status !== 'verified' || !session.signInUid) return 'not_ready';
  if (session.consumed) return 'already_used';
  const since = session.completedAtMs ?? session.createdAtMs;
  if (nowMs - since > SESSION_TTL_MS) return 'expired';
  return 'ok';
}
