import { timingSafeEqual } from 'node:crypto';
import type { TelegramUpdate } from './types.js';

/** Header Telegram sends with the `secret_token` given to `setWebhook`. */
export const SECRET_HEADER = 'x-telegram-bot-api-secret-token';

export interface WebhookRequest {
  method: string;
  header(name: string): string | undefined;
  body: unknown;
}

export interface WebhookResponse {
  status(code: number): WebhookResponse;
  send(body?: string): unknown;
}

/**
 * HTTP layer for the bot webhook: authenticates the caller, then delegates.
 *
 * The URL of a Cloud Function is public, so without the secret check anyone
 * could POST a forged update claiming any `user_id` and phone number. The
 * secret is compared in constant time.
 *
 * Status codes matter to Telegram: 2xx acknowledges the update; anything else
 * makes Telegram retry it later. Malformed updates are acknowledged (retrying
 * won't fix them), handler failures are not (a transient Firestore error
 * should be retried, and the handler is idempotent).
 */
export function createWebhook(
  secret: string,
  handle: (update: TelegramUpdate) => Promise<void>,
  logError: (message: string, error: unknown) => void = console.error,
) {
  const expected = Buffer.from(secret, 'utf8');

  return async (req: WebhookRequest, res: WebhookResponse): Promise<void> => {
    if (req.method !== 'POST') {
      res.status(405).send();
      return;
    }

    const provided = Buffer.from(req.header(SECRET_HEADER) ?? '', 'utf8');
    if (expected.length === 0 || provided.length !== expected.length || !timingSafeEqual(provided, expected)) {
      res.status(401).send();
      return;
    }

    const update = req.body as TelegramUpdate | undefined;
    if (!update || typeof update !== 'object' || typeof update.update_id !== 'number') {
      res.status(200).send();
      return;
    }

    try {
      await handle(update);
      res.status(200).send();
    } catch (error) {
      logError('telegram update failed', error);
      res.status(500).send();
    }
  };
}
