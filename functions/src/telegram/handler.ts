import { SESSION_ID_PATTERN } from '../config.js';
import { normalizeTelegramPhone } from '../phone/normalize.js';
import type { VerificationStore } from '../verification/store.js';
import type { BotClient } from './client.js';
import { Messages } from './messages.js';
import type { TelegramMessage, TelegramUpdate } from './types.js';

export interface HandlerDeps {
  store: VerificationStore;
  bot: BotClient;
  now: () => number;
  log?: (event: string, data: Record<string, unknown>) => void;
}

/**
 * Turns one Telegram update into at most one reply.
 *
 * Telegram redelivers an update until the webhook answers 2xx, so every path
 * here must be safe to run twice — the store operations are idempotent and a
 * repeated reply is harmless.
 */
export async function handleUpdate(update: TelegramUpdate, deps: HandlerDeps): Promise<void> {
  const message = update.message;
  // Private chats with humans only. Groups and other bots are ignored silently.
  if (!message?.from || message.from.is_bot || message.chat.type !== 'private') return;

  if (message.contact) {
    await handleContact(message, deps);
    return;
  }

  const text = message.text?.trim() ?? '';
  if (text.startsWith('/start')) {
    await handleStart(message, text.slice('/start'.length).trim(), deps);
    return;
  }

  await deps.bot.sendMessage(message.chat.id, Messages.help);
}

async function handleStart(message: TelegramMessage, payload: string, deps: HandlerDeps): Promise<void> {
  const chatId = message.chat.id;
  const telegramUserId = message.from!.id;

  if (payload === '') {
    await deps.bot.sendMessage(chatId, Messages.help);
    return;
  }
  // Reject malformed ids before touching the database.
  if (!SESSION_ID_PATTERN.test(payload)) {
    await deps.bot.sendMessage(chatId, Messages.invalidLink);
    return;
  }

  const result = await deps.store.openSession(payload, telegramUserId, deps.now());
  deps.log?.('telegram_session_open', { result: result.kind });

  switch (result.kind) {
    case 'opened':
      await deps.bot.sendMessage(chatId, Messages.askForContact(result.accountLabel), 'share_contact');
      return;
    case 'expired':
      await deps.bot.sendMessage(chatId, Messages.expired, 'remove');
      return;
    case 'other_telegram_account':
      await deps.bot.sendMessage(chatId, Messages.otherAccount, 'remove');
      return;
    case 'already_verified':
      await deps.bot.sendMessage(chatId, '✅ This number is already verified. You can go back to HisabET.', 'remove');
      return;
    case 'not_found':
    case 'closed':
      await deps.bot.sendMessage(chatId, Messages.invalidLink, 'remove');
      return;
  }
}

async function handleContact(message: TelegramMessage, deps: HandlerDeps): Promise<void> {
  const chatId = message.chat.id;
  const telegramUserId = message.from!.id;
  const contact = message.contact!;

  // The heart of the security model: Telegram sets `user_id` on a contact to
  // the account it belongs to. Only when that equals the sender is this the
  // sender's own, Telegram-verified number. A forwarded or typed-in contact
  // has a different or missing `user_id` and proves nothing.
  if (contact.user_id !== telegramUserId) {
    deps.log?.('telegram_contact_rejected', { reason: 'not_own_contact' });
    await deps.bot.sendMessage(chatId, Messages.notOwnContact, 'share_contact');
    return;
  }

  const phone = normalizeTelegramPhone(contact.phone_number);
  if (!phone.ok) {
    deps.log?.('telegram_contact_rejected', { reason: phone.reason });
    await deps.bot.sendMessage(
      chatId,
      phone.reason === 'anonymous_number' ? Messages.anonymousNumber : Messages.invalidNumber,
      'remove',
    );
    return;
  }

  const result = await deps.store.completeWithPhone(telegramUserId, phone.e164, deps.now());
  deps.log?.('telegram_session_complete', { result: result.kind });

  switch (result.kind) {
    case 'verified':
    case 'already_verified':
      await deps.bot.sendMessage(chatId, Messages.verified(result.phone), 'remove');
      return;
    case 'phone_in_use':
      await deps.bot.sendMessage(chatId, Messages.phoneInUse, 'remove');
      return;
    case 'expired':
      await deps.bot.sendMessage(chatId, Messages.expired, 'remove');
      return;
    case 'no_active_session':
      await deps.bot.sendMessage(chatId, Messages.noActiveSession, 'remove');
      return;
  }
}
