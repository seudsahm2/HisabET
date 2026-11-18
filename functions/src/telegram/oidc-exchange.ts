import type { PhoneAccounts } from '../accounts/phone-accounts.js';
import { AccountCreationError } from '../accounts/phone-accounts.js';
import { OidcError, type TelegramIdentity } from './oidc.js';

export interface OidcExchangeDeps {
  identify(code: string, codeVerifier: string): Promise<TelegramIdentity>;
  /** Firebase Admin `verifyIdToken`, reduced to what is needed. */
  verifyFirebaseIdToken(idToken: string): Promise<{ uid: string; signInProvider?: string }>;
  accounts: PhoneAccounts;
  createCustomToken(uid: string): Promise<string>;
  now(): number;
  log?: (event: string, data: Record<string, unknown>) => void;
  logError?: (message: string, error: unknown) => void;
}

// RFC 7636: 43–128 chars of the unreserved set.
const VERIFIER = /^[A-Za-z0-9\-._~]{43,128}$/;

/**
 * `POST /telegram-oidc` — finishes "Log In with Telegram".
 *
 * Body: `{ code, codeVerifier }` from the redirect and the app's PKCE pair.
 *
 * - **No `Authorization` header → sign in.** Returns `{ token }`, a Firebase
 *   custom token for the account that owns the Telegram phone number
 *   (created if new). The app calls `signInWithCustomToken`.
 * - **`Authorization: Bearer <Firebase ID token>` of a signed-in user →
 *   verify.** Attaches the number to that account and returns `{ phone }`.
 *
 * The code is single-use and bound to the PKCE verifier, so an intercepted
 * redirect is useless on its own; the client secret stays on the server.
 */
export function createOidcExchange(deps: OidcExchangeDeps): (request: Request) => Promise<Response> {
  const json = (status: number, body: Record<string, unknown>) =>
    new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

  return async (request) => {
    if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });

    let code: unknown;
    let codeVerifier: unknown;
    try {
      ({ code, codeVerifier } = (await request.json()) as { code?: unknown; codeVerifier?: unknown });
    } catch {
      return json(400, { error: 'bad_request' });
    }
    if (typeof code !== 'string' || code.length === 0 || code.length > 2048) return json(400, { error: 'bad_request' });
    if (typeof codeVerifier !== 'string' || !VERIFIER.test(codeVerifier)) return json(400, { error: 'bad_request' });

    // Who is asking: nobody (sign in) or a signed-in account (verify).
    let linkUid: string | undefined;
    const auth = request.headers.get('authorization') ?? '';
    if (auth !== '') {
      const idToken = auth.startsWith('Bearer ') ? auth.slice('Bearer '.length).trim() : '';
      try {
        const caller = await deps.verifyFirebaseIdToken(idToken);
        if (caller.signInProvider === 'anonymous') return json(403, { error: 'not_allowed' });
        linkUid = caller.uid;
      } catch {
        return json(401, { error: 'unauthenticated' });
      }
    }

    let identity: TelegramIdentity;
    try {
      identity = await deps.identify(code, codeVerifier);
    } catch (error) {
      if (error instanceof OidcError) {
        deps.log?.('telegram_oidc_rejected', { reason: error.failure });
        const status = { exchange_failed: 400, invalid_token: 401, phone_missing: 422, phone_invalid: 422 }[error.failure];
        return json(status, { error: error.failure });
      }
      deps.logError?.('telegram oidc identify failed', error);
      return json(502, { error: 'telegram_unavailable' });
    }

    try {
      if (linkUid) {
        const result = await deps.accounts.attachPhone(linkUid, identity.phone, deps.now());
        deps.log?.('telegram_oidc_verify', { result });
        return result === 'attached'
          ? json(200, { phone: identity.phone })
          : json(409, { error: 'phone_in_use' });
      }

      const account = await deps.accounts.accountForPhone(identity.phone, deps.now(), identity.name);
      deps.log?.('telegram_oidc_signin', { created: account.created });
      return json(200, { token: await deps.createCustomToken(account.uid), created: account.created });
    } catch (error) {
      if (error instanceof AccountCreationError) return json(500, { error: 'account_error' });
      deps.logError?.('telegram oidc account step failed', error);
      return json(500, { error: 'internal' });
    }
  };
}

/** Where the app listens for the end of the browser round trip. */
export const APP_CALLBACK = 'hisabet://telegram-auth';

/**
 * `GET /telegram-callback` — the https redirect_uri registered in BotFather.
 * Telegram redirects the browser here; this hands the result to the app via
 * its own URL scheme. Only the OAuth result parameters are forwarded.
 */
export function telegramCallback(request: Request): Response {
  const incoming = new URL(request.url).searchParams;
  const forward = new URLSearchParams();
  for (const key of ['code', 'state', 'error', 'error_description']) {
    const value = incoming.get(key);
    if (value !== null) forward.set(key, value.slice(0, 2048));
  }
  const target = `${APP_CALLBACK}?${forward.toString()}`;
  const escaped = target.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
  return new Response(
    `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width">` +
      `<title>Returning to HisabET</title><p>Returning to HisabET…</p>` +
      `<p><a href="${escaped}">Tap here if the app did not open.</a></p>`,
    { status: 302, headers: { location: target, 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' } },
  );
}
