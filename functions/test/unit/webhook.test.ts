import { describe, expect, it, vi } from 'vitest';
import { createWebhook, SECRET_HEADER, type WebhookRequest } from '../../src/telegram/webhook.js';

const SECRET = 's3cr3t-value';

function request(overrides: Partial<{ method: string; secret: string | undefined; body: unknown }> = {}): WebhookRequest {
  const { method = 'POST', body = { update_id: 1 } } = overrides;
  // Not a destructuring default: an explicit `undefined` must mean "no header".
  const secret = 'secret' in overrides ? overrides.secret : SECRET;
  return {
    method,
    header: (name) => (name.toLowerCase() === SECRET_HEADER ? secret : undefined),
    body,
  };
}

function response() {
  const res = { code: 0, status(code: number) { res.code = code; return res; }, send: () => undefined };
  return res;
}

describe('createWebhook', () => {
  it('passes an authenticated update to the handler', async () => {
    const handle = vi.fn().mockResolvedValue(undefined);
    const res = response();
    await createWebhook(SECRET, handle)(request(), res);
    expect(handle).toHaveBeenCalledWith({ update_id: 1 });
    expect(res.code).toBe(200);
  });

  it.each([
    ['missing', undefined],
    ['wrong', 'nope-nope-no'],
    ['different length', 'x'],
  ])('rejects a %s secret with 401 and never runs the handler', async (_, secret) => {
    const handle = vi.fn();
    const res = response();
    await createWebhook(SECRET, handle)(request({ secret }), res);
    expect(res.code).toBe(401);
    expect(handle).not.toHaveBeenCalled();
  });

  it('fails closed when no secret is configured', async () => {
    const handle = vi.fn();
    const res = response();
    await createWebhook('', handle)(request({ secret: '' }), res);
    expect(res.code).toBe(401);
  });

  it('rejects non-POST', async () => {
    const res = response();
    await createWebhook(SECRET, vi.fn())(request({ method: 'GET' }), res);
    expect(res.code).toBe(405);
  });

  it('acknowledges a malformed body so Telegram stops retrying it', async () => {
    const handle = vi.fn();
    const res = response();
    await createWebhook(SECRET, handle)(request({ body: 'garbage' }), res);
    expect(res.code).toBe(200);
    expect(handle).not.toHaveBeenCalled();
  });

  it('returns 500 on handler failure so Telegram retries', async () => {
    const res = response();
    await createWebhook(SECRET, vi.fn().mockRejectedValue(new Error('firestore down')), () => {})(request(), res);
    expect(res.code).toBe(500);
  });
});
