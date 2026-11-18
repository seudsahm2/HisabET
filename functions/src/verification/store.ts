import type { SessionPurpose } from './session.js';

/**
 * Persistence boundary for Telegram phone verification.
 *
 * The bot handler only talks to this interface. Production uses
 * `FirestoreVerificationStore`; unit tests use an in-memory fake, so the
 * conversation logic is tested without an emulator and the Firestore code is
 * tested separately against one.
 */

export type OpenResult =
  | { kind: 'opened'; purpose: 'verify'; accountLabel: string }
  | { kind: 'opened'; purpose: 'signin' }
  | { kind: 'not_found' }
  | { kind: 'expired' }
  | { kind: 'closed' }
  | { kind: 'already_verified' }
  | { kind: 'other_telegram_account' };

export type CompleteResult =
  | { kind: 'verified'; phone: string; purpose: SessionPurpose }
  | { kind: 'already_verified'; phone: string; purpose: SessionPurpose }
  | { kind: 'no_active_session' }
  | { kind: 'expired' }
  | { kind: 'phone_in_use' }
  /** signin: the account could not be created (logged server-side). */
  | { kind: 'account_error' };

export type ConsumeResult =
  | { kind: 'ok'; uid: string }
  | { kind: 'not_found' | 'not_owner' | 'not_signin' | 'not_ready' | 'already_used' | 'expired' };

export interface VerificationStore {
  /**
   * Binds session [sessionId] to the Telegram account that opened the link
   * and moves it to `awaiting_contact`. Idempotent for the same account.
   */
  openSession(sessionId: string, telegramUserId: number, nowMs: number): Promise<OpenResult>;

  /**
   * Completes the session this Telegram account opened, claiming [phoneE164]
   * for that session's HisabET user — atomically, so two accounts can never
   * end up holding the same number.
   */
  completeWithPhone(
    telegramUserId: number,
    phoneE164: string,
    nowMs: number,
    telegramFirstName?: string,
  ): Promise<CompleteResult>;

  /**
   * signin only: marks the session used and returns the account the app may
   * sign into. Single use, owner only — see `decideConsume`.
   */
  consumeSignIn(sessionId: string, callerUid: string, nowMs: number): Promise<ConsumeResult>;
}
