import { createRemoteJWKSet, jwtVerify, type JWTPayload, type JWTVerifyGetKey } from 'jose';
import { normalizeTelegramPhone } from '../phone/normalize.js';

/**
 * "Log In with Telegram" — Telegram's official OpenID Connect provider.
 * https://core.telegram.org/bots/telegram-login
 *
 * The app sends the user to oauth.telegram.org (authorization code + PKCE,
 * scopes `openid profile phone`). Telegram shows its own consent screens,
 * including "Allow access to your phone number?", and redirects back with a
 * one-time code. This module turns that code into a verified identity:
 * it exchanges the code using the bot's client secret (which never leaves
 * the server) and verifies the signed ID token against Telegram's keys.
 */

export const TELEGRAM_ISSUER = 'https://oauth.telegram.org';
export const TELEGRAM_TOKEN_URL = 'https://oauth.telegram.org/token';
export const TELEGRAM_JWKS_URL = 'https://oauth.telegram.org/.well-known/jwks.json';

export interface TelegramIdentity {
  /** Telegram's stable user id (`sub`). */
  telegramId: string;
  /** E.164, proven by Telegram (`phone_number`). */
  phone: string;
  name?: string;
}

export type OidcFailure =
  | 'exchange_failed' // Telegram refused the code (expired, reused, wrong verifier/redirect)
  | 'invalid_token' // signature, issuer, audience or expiry check failed
  | 'phone_missing' // the user declined to share their number
  | 'phone_invalid'; // unusable or anonymous (+888) number

export class OidcError extends Error {
  constructor(readonly failure: OidcFailure, detail?: string) {
    super(detail ? `${failure}: ${detail}` : failure);
  }
}

type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string }) =>
  Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>;

export interface TelegramOidcConfig {
  clientId: string;
  clientSecret: string;
  /** Must equal the redirect_uri the app used, and be registered in BotFather. */
  redirectUri: string;
}

export class TelegramOidcClient {
  private readonly keys: JWTVerifyGetKey;

  constructor(
    private readonly config: TelegramOidcConfig,
    options: { keys?: JWTVerifyGetKey; fetchImpl?: FetchLike } = {},
  ) {
    this.keys = options.keys ?? createRemoteJWKSet(new URL(TELEGRAM_JWKS_URL));
    this.fetchImpl = options.fetchImpl ?? (fetch as unknown as FetchLike);
  }

  private readonly fetchImpl: FetchLike;

  /** Code + PKCE verifier → verified Telegram identity with phone number. */
  async identify(code: string, codeVerifier: string): Promise<TelegramIdentity> {
    const idToken = await this.exchange(code, codeVerifier);
    return this.verify(idToken);
  }

  async exchange(code: string, codeVerifier: string): Promise<string> {
    const basic = Buffer.from(`${this.config.clientId}:${this.config.clientSecret}`).toString('base64');
    const response = await this.fetchImpl(TELEGRAM_TOKEN_URL, {
      method: 'POST',
      headers: {
        authorization: `Basic ${basic}`,
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: this.config.redirectUri,
        client_id: this.config.clientId,
        code_verifier: codeVerifier,
      }).toString(),
    });
    const body = (await response.json().catch(() => ({}))) as { id_token?: unknown; error?: unknown };
    if (!response.ok || typeof body.id_token !== 'string') {
      // Telegram's error code only — never the request, which carries the secret.
      throw new OidcError('exchange_failed', `HTTP ${response.status} ${String(body.error ?? '')}`.trim());
    }
    return body.id_token;
  }

  async verify(idToken: string): Promise<TelegramIdentity> {
    let payload: JWTPayload & Record<string, unknown>;
    try {
      ({ payload } = await jwtVerify(idToken, this.keys, { issuer: TELEGRAM_ISSUER }));
    } catch (error) {
      throw new OidcError('invalid_token', (error as Error).name);
    }
    // `aud` is the bot id, which Telegram may encode as a number; compare as strings.
    const audiences = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
    if (!audiences.some((aud) => String(aud) === this.config.clientId)) {
      throw new OidcError('invalid_token', 'audience');
    }
    if (typeof payload.sub !== 'string' && typeof payload.sub !== 'number') {
      throw new OidcError('invalid_token', 'sub');
    }

    const rawPhone = payload.phone_number;
    if (typeof rawPhone !== 'string' || rawPhone === '') throw new OidcError('phone_missing');
    if (payload.phone_number_verified === false) throw new OidcError('phone_invalid', 'unverified');
    const phone = normalizeTelegramPhone(rawPhone);
    if (!phone.ok) throw new OidcError('phone_invalid', phone.reason);

    return {
      telegramId: String(payload.sub),
      phone: phone.e164,
      name: typeof payload.name === 'string' && payload.name.trim() !== '' ? payload.name.trim() : undefined,
    };
  }
}
