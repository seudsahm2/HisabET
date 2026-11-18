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

export type FailureReason = 'expired' | 'phone_in_use';

export interface SessionState {
  uid: string;
  status: SessionStatus;
  createdAtMs: number;
  telegramUserId?: number;
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
