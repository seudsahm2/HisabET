/**
 * Shared constants for phone verification.
 *
 * Collection names and the session-id format are also encoded in
 * `firestore.rules` and in the Flutter client
 * (`lib/features/phone_identity/`). Change all three together.
 */

export const Collections = {
  /** One document per verification attempt, created by the app. */
  sessions: 'phone_verifications',
  /** `phone_claims/{E.164}` — the uniqueness index: one owner per number. */
  claims: 'phone_claims',
  /** `telegram_links/{telegramUserId}` — the session a Telegram user is completing. Server-only. */
  telegramLinks: 'telegram_links',
  users: 'users',
} as const;

/** How long a session stays usable after the app creates it. */
export const SESSION_TTL_MS = 10 * 60 * 1000;

/** Sessions older than this are deleted by the daily cleanup job. */
export const SESSION_RETENTION_MS = 24 * 60 * 60 * 1000;

/**
 * Telegram's `/start` payload allows 1–64 chars of `[A-Za-z0-9_-]`. The app
 * generates 43 chars (32 random bytes, base64url), well past guessable.
 */
export const SESSION_ID_PATTERN = /^[A-Za-z0-9_-]{32,64}$/;

/** Value stored in `users.phoneVerificationMethod` and `phone_claims.method`. */
export const TELEGRAM_METHOD = 'telegram';
