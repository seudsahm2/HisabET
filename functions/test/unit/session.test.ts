import { describe, expect, it } from 'vitest';
import { SESSION_TTL_MS } from '../../src/config.js';
import {
  decideComplete,
  decideOpen,
  isPhoneTakenByOther,
  type SessionState,
} from '../../src/verification/session.js';

const T0 = 1_000_000;
const TG = 42;

function session(overrides: Partial<SessionState> = {}): SessionState {
  return { uid: 'u1', status: 'pending', createdAtMs: T0, ...overrides };
}

describe('decideOpen', () => {
  it('opens a fresh pending session', () => {
    expect(decideOpen(session(), TG, T0 + 1000)).toBe('open');
  });

  it('re-opens for the same Telegram account (idempotent /start)', () => {
    expect(decideOpen(session({ status: 'awaiting_contact', telegramUserId: TG }), TG, T0)).toBe('open');
  });

  it('refuses a second Telegram account once bound', () => {
    expect(decideOpen(session({ status: 'awaiting_contact', telegramUserId: 7 }), TG, T0)).toBe(
      'other_telegram_account',
    );
  });

  it('expires after the TTL', () => {
    expect(decideOpen(session(), TG, T0 + SESSION_TTL_MS + 1)).toBe('expired');
  });

  it('reports terminal states', () => {
    expect(decideOpen(session({ status: 'verified' }), TG, T0)).toBe('already_verified');
    expect(decideOpen(session({ status: 'failed' }), TG, T0)).toBe('closed');
  });
});

describe('decideComplete', () => {
  const awaiting = session({ status: 'awaiting_contact', telegramUserId: TG });

  it('completes an awaiting session for the bound account', () => {
    expect(decideComplete(awaiting, TG, T0 + 1000)).toBe('complete');
  });

  it('ignores a session bound to someone else', () => {
    expect(decideComplete(awaiting, 7, T0)).toBe('not_awaiting');
  });

  it('cannot complete before /start bound it', () => {
    expect(decideComplete(session(), TG, T0)).toBe('not_awaiting');
  });

  it('expires after the TTL', () => {
    expect(decideComplete(awaiting, TG, T0 + SESSION_TTL_MS + 1)).toBe('expired');
  });

  it('is idempotent once verified', () => {
    expect(decideComplete(session({ status: 'verified', telegramUserId: TG }), TG, T0)).toBe('already_verified');
  });
});

describe('isPhoneTakenByOther', () => {
  it('is free when nobody holds it', () => {
    expect(isPhoneTakenByOther('u1', {})).toBe(false);
  });
  it('is free when the same user holds it', () => {
    expect(isPhoneTakenByOther('u1', { claimUid: 'u1', authUid: 'u1' })).toBe(false);
  });
  it('is taken by another claim', () => {
    expect(isPhoneTakenByOther('u1', { claimUid: 'u2' })).toBe(true);
  });
  it('is taken by another Firebase Auth phone account even without a claim', () => {
    expect(isPhoneTakenByOther('u1', { authUid: 'u2' })).toBe(true);
  });
});
