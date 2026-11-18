import { describe, expect, it, vi } from 'vitest';
import { AccountCreationError } from '../../src/accounts/phone-accounts.js';
import { OidcError } from '../../src/telegram/oidc.js';
import { createOidcExchange, telegramCallback } from '../../src/telegram/oidc-exchange.js';

const VERIFIER = 'a'.repeat(43);
const identity = { telegramId: '555', phone: '+251966143454', name: 'Seud' };

function deps() {
  return {
    identify: vi.fn().mockResolvedValue(identity),
    verifyFirebaseIdToken: vi.fn().mockResolvedValue({ uid: 'google-user', signInProvider: 'google.com' }),
    accounts: {
      attachPhone: vi.fn().mockResolvedValue('attached'),
      accountForPhone: vi.fn().mockResolvedValue({ uid: 'phone-user', created: true }),
    },
    createCustomToken: vi.fn().mockResolvedValue('custom-token'),
    now: () => 42,
  };
}

const post = (body: unknown, bearer?: string) =>
  new Request('https://h/telegram-oidc', {
    method: 'POST',
    headers: bearer ? { authorization: `Bearer ${bearer}` } : {},
    body: JSON.stringify(body),
  });

describe('createOidcExchange', () => {
  it('signs in: returns a custom token for the phone owner', async () => {
    const d = deps();
    const res = await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ token: 'custom-token', created: true });
    expect(d.identify).toHaveBeenCalledWith('c', VERIFIER);
    expect(d.accounts.accountForPhone).toHaveBeenCalledWith('+251966143454', 42, 'Seud');
    expect(d.createCustomToken).toHaveBeenCalledWith('phone-user');
    expect(d.verifyFirebaseIdToken).not.toHaveBeenCalled();
  });

  it('verifies: attaches the number to the signed-in account and issues no token', async () => {
    const d = deps();
    const res = await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }, 'id-token'));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ phone: '+251966143454' });
    expect(d.accounts.attachPhone).toHaveBeenCalledWith('google-user', '+251966143454', 42);
    expect(d.createCustomToken).not.toHaveBeenCalled();
  });

  it('reports a number held by another account when verifying', async () => {
    const d = deps();
    d.accounts.attachPhone.mockResolvedValue('phone_in_use');
    const res = await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }, 'id-token'));
    expect(res.status).toBe(409);
    expect(await res.json()).toEqual({ error: 'phone_in_use' });
  });

  it('rejects a bad Firebase ID token before contacting Telegram', async () => {
    const d = deps();
    d.verifyFirebaseIdToken.mockRejectedValue(new Error('bad'));
    expect((await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }, 'x'))).status).toBe(401);
    expect(d.identify).not.toHaveBeenCalled();
  });

  it('refuses anonymous callers', async () => {
    const d = deps();
    d.verifyFirebaseIdToken.mockResolvedValue({ uid: 'a', signInProvider: 'anonymous' });
    expect((await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }, 'x'))).status).toBe(403);
  });

  it.each([[{ code: '', codeVerifier: VERIFIER }], [{ code: 'c', codeVerifier: 'short' }], [{ code: 'c' }]])(
    'rejects malformed input %o',
    async (body) => {
      const d = deps();
      expect((await createOidcExchange(d)(post(body))).status).toBe(400);
      expect(d.identify).not.toHaveBeenCalled();
    },
  );

  it.each([
    ['exchange_failed', 400],
    ['invalid_token', 401],
    ['phone_missing', 422],
    ['phone_invalid', 422],
  ] as const)('maps Telegram failure %s to %i', async (failure, status) => {
    const d = deps();
    d.identify.mockRejectedValue(new OidcError(failure));
    const res = await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }));
    expect(res.status).toBe(status);
    expect(await res.json()).toEqual({ error: failure });
  });

  it('answers 502 when Telegram is unreachable', async () => {
    const d = deps();
    d.identify.mockRejectedValue(new TypeError('fetch failed'));
    expect((await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }))).status).toBe(502);
  });

  it('answers account_error when the account cannot be created', async () => {
    const d = deps();
    d.accounts.accountForPhone.mockRejectedValue(new AccountCreationError('x'));
    const res = await createOidcExchange(d)(post({ code: 'c', codeVerifier: VERIFIER }));
    expect(res.status).toBe(500);
    expect(await res.json()).toEqual({ error: 'account_error' });
  });
});

describe('telegramCallback', () => {
  it('forwards only the OAuth result to the app scheme', () => {
    const res = telegramCallback(new Request('https://h/telegram-callback?code=abc&state=xyz&evil=1'));
    expect(res.status).toBe(302);
    expect(res.headers.get('location')).toBe('hisabet://telegram-auth?code=abc&state=xyz');
  });

  it('forwards a denial', () => {
    const res = telegramCallback(new Request('https://h/telegram-callback?error=access_denied&state=s'));
    expect(res.headers.get('location')).toBe('hisabet://telegram-auth?state=s&error=access_denied');
  });
});
