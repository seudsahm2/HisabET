import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT, type JWK } from 'jose';

type KeyLike = Awaited<ReturnType<typeof generateKeyPair>>['privateKey'];
import { beforeAll, describe, expect, it, vi } from 'vitest';
import { OidcError, TELEGRAM_ISSUER, TelegramOidcClient } from '../../src/telegram/oidc.js';

const CLIENT_ID = '7123456789';
let privateKey: KeyLike;
let otherKey: KeyLike;
let jwks: ReturnType<typeof createLocalJWKSet>;

beforeAll(async () => {
  const pair = await generateKeyPair('RS256');
  privateKey = pair.privateKey;
  const jwk: JWK = { ...(await exportJWK(pair.publicKey)), kid: 'k1', alg: 'RS256' };
  jwks = createLocalJWKSet({ keys: [jwk] });
  otherKey = (await generateKeyPair('RS256')).privateKey;
});

async function idToken(
  claims: Record<string, unknown>,
  opts: { key?: KeyLike; iss?: string; aud?: unknown; exp?: string } = {},
) {
  return new SignJWT({ aud: (opts.aud ?? Number(CLIENT_ID)) as string, ...claims })
    .setProtectedHeader({ alg: 'RS256', kid: 'k1' })
    .setIssuer(opts.iss ?? TELEGRAM_ISSUER)
    .setSubject('555')
    .setIssuedAt()
    .setExpirationTime(opts.exp ?? '5m')
    .sign(opts.key ?? privateKey);
}

type FetchImpl = NonNullable<ConstructorParameters<typeof TelegramOidcClient>[1]>['fetchImpl'];

const client = (fetchImpl?: FetchImpl) =>
  new TelegramOidcClient(
    { clientId: CLIENT_ID, clientSecret: 'secret', redirectUri: 'https://h.netlify.app/telegram-callback' },
    { keys: jwks, fetchImpl },
  );

const rejects = async (token: string, failure: string) => {
  await expect(client().verify(token)).rejects.toMatchObject({ failure });
};

describe('TelegramOidcClient.verify', () => {
  it('returns the verified phone (E.164), Telegram id and name', async () => {
    const token = await idToken({ phone_number: '251966143454', phone_number_verified: true, name: 'Seud' });
    expect(await client().verify(token)).toEqual({ telegramId: '555', phone: '+251966143454', name: 'Seud' });
  });

  it('accepts a numeric or string audience equal to the bot id', async () => {
    const token = await idToken({ phone_number: '+251966143454' }, { aud: CLIENT_ID });
    expect((await client().verify(token)).phone).toBe('+251966143454');
  });

  it('rejects a token signed by someone else', async () => {
    await rejects(await idToken({ phone_number: '+251966143454' }, { key: otherKey }), 'invalid_token');
  });

  it('rejects the wrong issuer', async () => {
    await rejects(await idToken({ phone_number: '+251966143454' }, { iss: 'https://evil.example' }), 'invalid_token');
  });

  it('rejects a token issued for another bot', async () => {
    await rejects(await idToken({ phone_number: '+251966143454' }, { aud: 999 }), 'invalid_token');
  });

  it('rejects an expired token', async () => {
    await rejects(await idToken({ phone_number: '+251966143454' }, { exp: '-1m' }), 'invalid_token');
  });

  it('reports a declined phone permission', async () => {
    await rejects(await idToken({ name: 'x' }), 'phone_missing');
  });

  it('refuses an unverified or anonymous number', async () => {
    await rejects(await idToken({ phone_number: '+251966143454', phone_number_verified: false }), 'phone_invalid');
    await rejects(await idToken({ phone_number: '+88801234567' }), 'phone_invalid');
  });
});

describe('TelegramOidcClient.exchange', () => {
  it('posts the code with Basic client auth and the PKCE verifier', async () => {
    const fetchImpl = vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ id_token: 'jwt' }) });
    expect(await client(fetchImpl).exchange('the-code', 'v'.repeat(43))).toBe('jwt');

    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('https://oauth.telegram.org/token');
    expect(init.headers.authorization).toBe(`Basic ${Buffer.from(`${CLIENT_ID}:secret`).toString('base64')}`);
    expect(Object.fromEntries(new URLSearchParams(init.body))).toEqual({
      grant_type: 'authorization_code',
      code: 'the-code',
      redirect_uri: 'https://h.netlify.app/telegram-callback',
      client_id: CLIENT_ID,
      code_verifier: 'v'.repeat(43),
    });
  });

  it('fails cleanly, without leaking the secret, when Telegram refuses the code', async () => {
    const fetchImpl = vi.fn().mockResolvedValue({ ok: false, status: 400, json: async () => ({ error: 'invalid_grant' }) });
    const error = await client(fetchImpl)
      .exchange('x', 'v'.repeat(43))
      .catch((e: unknown) => e);
    expect(error).toBeInstanceOf(OidcError);
    expect((error as OidcError).failure).toBe('exchange_failed');
    expect((error as OidcError).message).not.toContain('secret');
  });
});
