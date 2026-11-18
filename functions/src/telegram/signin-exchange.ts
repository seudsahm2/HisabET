import { SESSION_ID_PATTERN } from '../config.js';
import type { VerificationStore } from '../verification/store.js';

export interface SignInExchangeDeps {
  /** Firebase Admin `verifyIdToken`, reduced to what is needed. */
  verifyIdToken(idToken: string): Promise<{ uid: string; signInProvider?: string }>;
  store: Pick<VerificationStore, 'consumeSignIn'>;
  createCustomToken(uid: string): Promise<string>;
  deleteUser(uid: string): Promise<void>;
  now(): number;
  logError?: (message: string, error: unknown) => void;
}

/**
 * `POST /telegram-signin` — the last step of "Continue with Telegram".
 *
 * The app started the session from a temporary **anonymous** Firebase
 * account. Once the bot has verified the number, the app sends that
 * account's ID token plus the session id here and gets back a custom token
 * for the real account, which it signs into with `signInWithCustomToken`.
 *
 * Why it is safe:
 * - The ID token proves the caller is the anonymous account that created the
 *   session; the session id alone (which Telegram saw) is not enough.
 * - Only anonymous callers are accepted, so a signed-in user cannot use this
 *   to hop into another account.
 * - A session is exchanged once, and only shortly after verification.
 * - The custom token is returned once and never stored.
 */
export function createSignInExchange(deps: SignInExchangeDeps): (request: Request) => Promise<Response> {
  const json = (status: number, body: Record<string, unknown>) =>
    new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

  return async (request) => {
    if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });

    const auth = request.headers.get('authorization') ?? '';
    const idToken = auth.startsWith('Bearer ') ? auth.slice('Bearer '.length).trim() : '';
    if (!idToken) return json(401, { error: 'unauthenticated' });

    let sessionId: unknown;
    try {
      sessionId = ((await request.json()) as { sessionId?: unknown }).sessionId;
    } catch {
      return json(400, { error: 'bad_request' });
    }
    if (typeof sessionId !== 'string' || !SESSION_ID_PATTERN.test(sessionId)) {
      return json(400, { error: 'bad_request' });
    }

    let caller: { uid: string; signInProvider?: string };
    try {
      caller = await deps.verifyIdToken(idToken);
    } catch {
      return json(401, { error: 'unauthenticated' });
    }
    if (caller.signInProvider !== 'anonymous') return json(403, { error: 'not_anonymous' });

    try {
      const result = await deps.store.consumeSignIn(sessionId, caller.uid, deps.now());
      switch (result.kind) {
        case 'ok': {
          const token = await deps.createCustomToken(result.uid);
          // The temporary account has done its job; don't let them pile up.
          if (result.uid !== caller.uid) {
            await deps.deleteUser(caller.uid).catch((e) => deps.logError?.('anonymous cleanup failed', e));
          }
          return json(200, { token });
        }
        case 'not_ready':
          return json(409, { error: 'not_ready' });
        case 'already_used':
          return json(409, { error: 'already_used' });
        case 'expired':
          return json(410, { error: 'expired' });
        case 'not_signin':
          return json(400, { error: 'not_signin' });
        case 'not_found':
        case 'not_owner':
          // Same answer for both: don't confirm that someone else's session exists.
          return json(404, { error: 'not_found' });
      }
    } catch (error) {
      deps.logError?.('telegram sign-in exchange failed', error);
      return json(500, { error: 'internal' });
    }
  };
}
