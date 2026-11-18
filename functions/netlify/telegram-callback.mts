/** OAuth redirect_uri for "Log In with Telegram": hands the result to the app. */
import type { Config } from '@netlify/functions';
import { telegramCallback } from '../src/telegram/oidc-exchange.js';

export default async (request: Request): Promise<Response> => telegramCallback(request);

export const config: Config = { path: '/telegram-callback' };
