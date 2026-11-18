import { describe, expect, it, vi } from 'vitest';
import { createSignInExchange, type SignInExchangeDeps } from '../../src/telegram/signin-exchange.js';
import type { ConsumeResult } from '../../src/verification/store.js';

const SESSION = 'b'.repeat(43);

function deps(overrides: Partial<SignInExchangeDeps> = {}, consume: ConsumeResult = { kind: 'ok', uid: 'real' }) {
  const d = {
    verifyIdToken: vi.fn().mockResolvedValue({ uid: 'anon', signInProvider: 'anonymous' }),
    store: { consumeSignIn: vi.fn().mockResolvedValue(consume) },
    createCustomToken: vi.fn().mockResolvedValue('custom-token'),
    deleteUser: vi.fn().mockResolvedValue(undefined),
    now: () => 1000,
    ...overrides,
  };
  return d;
}

const call = (d: SignInExchangeDeps, { token = 'id-token', body = { sessionId: SESSION } as unknown } = {}) =>
  createSignInExchange(d)(
    new Request('https://x/telegram-signin', {
      method: 'POST',
      headers: token ? { authorization: `Bearer ${token}` } : {},
      body: JSON.stringify(body),
    }),
  );

describe('createSignInExchange', () => {
  it('returns a custom token for the real account and removes the temporary one', async () => {
    const d = deps();
    const res = await call(d);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ token: 'custom-token' });
    expect(d.store.consumeSignIn).toHaveBeenCalledWith(SESSION, 'anon', 1000);
    expect(d.createCustomToken).toHaveBeenCalledWith('real');
    expect(d.deleteUser).toHaveBeenCalledWith('anon');
  });

  it('requires a bearer token', async () => {
    expect((await call(deps(), { token: '' })).status).toBe(401);
  });

  it('rejects an invalid ID token', async () => {
    const d = deps({ verifyIdToken: vi.fn().mockRejectedValue(new Error('bad')) });
    expect((await call(d)).status).toBe(401);
  });

  it('refuses callers that are not anonymous (no hopping between real accounts)', async () => {
    const d = deps({ verifyIdToken: vi.fn().mockResolvedValue({ uid: 'google-user', signInProvider: 'google.com' }) });
    expect((await call(d)).status).toBe(403);
    expect(d.store.consumeSignIn).not.toHaveBeenCalled();
  });

  it('rejects a malformed session id before touching the store', async () => {
    const d = deps();
    expect((await call(d, { body: { sessionId: '../x' } })).status).toBe(400);
    expect(d.store.consumeSignIn).not.toHaveBeenCalled();
  });

  it.each([
    [{ kind: 'not_ready' } as ConsumeResult, 409],
    [{ kind: 'already_used' } as ConsumeResult, 409],
    [{ kind: 'expired' } as ConsumeResult, 410],
    [{ kind: 'not_owner' } as ConsumeResult, 404],
    [{ kind: 'not_found' } as ConsumeResult, 404],
  ])('maps %o to HTTP %i and issues no token', async (result, status) => {
    const d = deps({}, result);
    expect((await call(d)).status).toBe(status);
    expect(d.createCustomToken).not.toHaveBeenCalled();
  });

  it('still answers when cleaning up the temporary account fails', async () => {
    const d = deps({ deleteUser: vi.fn().mockRejectedValue(new Error('x')) });
    expect((await call(d)).status).toBe(200);
  });
});
