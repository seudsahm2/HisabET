import { describe, expect, it, vi } from 'vitest';
import { createFetchWebhook } from '../../src/telegram/fetch-webhook.js';
import { SECRET_HEADER } from '../../src/telegram/webhook.js';

const SECRET = 'web-standard-secret';

const post = (body: string, secret: string | null = SECRET) =>
  new Request('https://example.test/telegram-webhook', {
    method: 'POST',
    headers: secret === null ? {} : { [SECRET_HEADER]: secret },
    body,
  });

describe('createFetchWebhook (Netlify / web-standard hosts)', () => {
  it('passes an authenticated update through and answers 200', async () => {
    const handle = vi.fn().mockResolvedValue(undefined);
    const res = await createFetchWebhook(SECRET, handle)(post('{"update_id":7}'));
    expect(res.status).toBe(200);
    expect(handle).toHaveBeenCalledWith({ update_id: 7 });
  });

  it('refuses a missing or wrong secret with 401', async () => {
    const handle = vi.fn();
    expect((await createFetchWebhook(SECRET, handle)(post('{"update_id":7}', null))).status).toBe(401);
    expect((await createFetchWebhook(SECRET, handle)(post('{"update_id":7}', 'nope'))).status).toBe(401);
    expect(handle).not.toHaveBeenCalled();
  });

  it('acknowledges malformed JSON so Telegram does not retry it', async () => {
    const handle = vi.fn();
    const res = await createFetchWebhook(SECRET, handle)(post('not json'));
    expect(res.status).toBe(200);
    expect(handle).not.toHaveBeenCalled();
  });

  it('answers 500 when handling fails so Telegram retries', async () => {
    const res = await createFetchWebhook(SECRET, vi.fn().mockRejectedValue(new Error('down')), () => {})(
      post('{"update_id":7}'),
    );
    expect(res.status).toBe(500);
  });

  it('rejects GET', async () => {
    const res = await createFetchWebhook(SECRET, vi.fn())(new Request('https://example.test/telegram-webhook'));
    expect(res.status).toBe(405);
  });
});
