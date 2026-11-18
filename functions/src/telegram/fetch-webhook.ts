import type { TelegramUpdate } from './types.js';
import { createWebhook, type WebhookRequest, type WebhookResponse } from './webhook.js';

/**
 * The same webhook as [createWebhook], for hosts built on the web-standard
 * `Request` → `Response` model (Netlify Functions v2, Vercel, Deno, Bun,
 * Cloudflare). Authentication and status-code behaviour are identical; this
 * only adapts the shapes.
 */
export function createFetchWebhook(
  secret: string,
  handle: (update: TelegramUpdate) => Promise<void>,
  logError?: (message: string, error: unknown) => void,
): (request: Request) => Promise<Response> {
  const webhook = createWebhook(secret, handle, logError);

  return async (request: Request): Promise<Response> => {
    let body: unknown;
    if (request.method === 'POST') {
      try {
        body = await request.json();
      } catch {
        body = undefined; // malformed JSON is acknowledged, not retried
      }
    }

    const req: WebhookRequest = {
      method: request.method,
      header: (name) => request.headers.get(name) ?? undefined,
      body,
    };

    let status = 200;
    const res: WebhookResponse = {
      status(code) {
        status = code;
        return res;
      },
      send: () => undefined,
    };

    await webhook(req, res);
    return new Response(null, { status });
  };
}
