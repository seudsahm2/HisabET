import { beforeEach, describe, expect, it } from 'vitest';
import type { BotClient, ReplyKeyboard } from '../../src/telegram/client.js';
import { handleUpdate } from '../../src/telegram/handler.js';
import { Messages } from '../../src/telegram/messages.js';
import type { TelegramMessage, TelegramUpdate } from '../../src/telegram/types.js';
import type { CompleteResult, ConsumeResult, OpenResult, VerificationStore } from '../../src/verification/store.js';

const TG = 42;
const CHAT = 4200;
const SESSION = 'a'.repeat(43);

class FakeBot implements BotClient {
  sent: { chatId: number; text: string; keyboard: ReplyKeyboard }[] = [];
  async sendMessage(chatId: number, text: string, keyboard: ReplyKeyboard = 'none') {
    this.sent.push({ chatId, text, keyboard });
  }
  get last() {
    return this.sent[this.sent.length - 1];
  }
}

class FakeStore implements VerificationStore {
  openResult: OpenResult = { kind: 'opened', purpose: 'verify', accountLabel: 'Ahmed · s***m@gmail.com' };
  completeResult: CompleteResult = { kind: 'verified', phone: '+251911223344', purpose: 'verify' };
  opened: unknown[][] = [];
  completed: unknown[][] = [];
  async openSession(...args: [string, number, number]) {
    this.opened.push(args);
    return this.openResult;
  }
  async completeWithPhone(...args: [number, string, number, string?]) {
    this.completed.push(args);
    return this.completeResult;
  }
  async consumeSignIn(): Promise<ConsumeResult> {
    return { kind: 'not_found' };
  }
}

function update(message: Partial<TelegramMessage>): TelegramUpdate {
  return {
    update_id: 1,
    message: {
      message_id: 1,
      from: { id: TG, is_bot: false, first_name: 'Ahmed' },
      chat: { id: CHAT, type: 'private' },
      ...message,
    },
  };
}

describe('handleUpdate', () => {
  let bot: FakeBot;
  let store: FakeStore;
  const run = (u: TelegramUpdate) => handleUpdate(u, { bot, store, now: () => 123 });

  beforeEach(() => {
    bot = new FakeBot();
    store = new FakeStore();
  });

  describe('/start', () => {
    it('opens the session and asks for the contact with the share button', async () => {
      await run(update({ text: `/start ${SESSION}` }));
      expect(store.opened).toEqual([[SESSION, TG, 123]]);
      expect(bot.last).toEqual({
        chatId: CHAT,
        text: Messages.askForContact('Ahmed · s***m@gmail.com'),
        keyboard: 'share_contact',
      });
    });

    it('uses sign-in wording for a sign-in session', async () => {
      store.openResult = { kind: 'opened', purpose: 'signin' };
      await run(update({ text: `/start ${SESSION}` }));
      expect(bot.last).toEqual({ chatId: CHAT, text: Messages.askForSignInContact, keyboard: 'share_contact' });
    });

    it('shows help for a bare /start without touching the store', async () => {
      await run(update({ text: '/start' }));
      expect(store.opened).toEqual([]);
      expect(bot.last.text).toBe(Messages.help);
    });

    it('rejects a malformed session id without touching the store', async () => {
      await run(update({ text: '/start ../../users/x' }));
      expect(store.opened).toEqual([]);
      expect(bot.last.text).toBe(Messages.invalidLink);
    });

    it.each([
      [{ kind: 'expired' } as OpenResult, Messages.expired],
      [{ kind: 'not_found' } as OpenResult, Messages.invalidLink],
      [{ kind: 'closed' } as OpenResult, Messages.invalidLink],
      [{ kind: 'other_telegram_account' } as OpenResult, Messages.otherAccount],
    ])('explains %o', async (result, text) => {
      store.openResult = result;
      await run(update({ text: `/start ${SESSION}` }));
      expect(bot.last.text).toBe(text);
      expect(bot.last.keyboard).toBe('remove');
    });
  });

  describe('contact', () => {
    const ownContact = { phone_number: '251911223344', first_name: 'Ahmed', user_id: TG };

    it('verifies the sender’s own contact', async () => {
      await run(update({ contact: ownContact }));
      expect(store.completed).toEqual([[TG, '+251911223344', 123, 'Ahmed']]);
      expect(bot.last).toEqual({ chatId: CHAT, text: Messages.verified('+251911223344'), keyboard: 'remove' });
    });

    it('refuses a forwarded contact belonging to someone else', async () => {
      await run(update({ contact: { ...ownContact, user_id: 999 } }));
      expect(store.completed).toEqual([]);
      expect(bot.last.text).toBe(Messages.notOwnContact);
    });

    it('refuses a typed-in contact with no Telegram account', async () => {
      await run(update({ contact: { phone_number: '251911223344', first_name: 'X' } }));
      expect(store.completed).toEqual([]);
      expect(bot.last.text).toBe(Messages.notOwnContact);
    });

    it('refuses anonymous +888 numbers', async () => {
      await run(update({ contact: { ...ownContact, phone_number: '88812345678' } }));
      expect(store.completed).toEqual([]);
      expect(bot.last.text).toBe(Messages.anonymousNumber);
    });

    it.each([
      [{ kind: 'phone_in_use' } as CompleteResult, Messages.phoneInUse],
      [{ kind: 'expired' } as CompleteResult, Messages.expired],
      [{ kind: 'no_active_session' } as CompleteResult, Messages.noActiveSession],
      [{ kind: 'already_verified', phone: '+251911223344', purpose: 'verify' } as CompleteResult, Messages.verified('+251911223344')],
      [{ kind: 'verified', phone: '+251911223344', purpose: 'signin' } as CompleteResult, Messages.signedIn('+251911223344')],
      [{ kind: 'account_error' } as CompleteResult, Messages.accountError],
    ])('explains %o', async (result, text) => {
      store.completeResult = result;
      await run(update({ contact: ownContact }));
      expect(bot.last.text).toBe(text);
    });
  });

  it('ignores group chats', async () => {
    await run(update({ chat: { id: CHAT, type: 'group' }, text: `/start ${SESSION}` }));
    expect(bot.sent).toEqual([]);
    expect(store.opened).toEqual([]);
  });

  it('ignores other bots', async () => {
    await run(update({ from: { id: TG, is_bot: true, first_name: 'bot' }, text: `/start ${SESSION}` }));
    expect(bot.sent).toEqual([]);
  });

  it('answers any other text with help', async () => {
    await run(update({ text: 'hello' }));
    expect(bot.last.text).toBe(Messages.help);
  });
});
