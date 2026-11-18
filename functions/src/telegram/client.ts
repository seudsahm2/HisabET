/** What the conversation needs to show under a message. */
export type ReplyKeyboard =
  /** One button that makes Telegram share the user's own verified number. */
  | 'share_contact'
  /** Clear a previously shown keyboard. */
  | 'remove'
  | 'none';

export interface BotClient {
  sendMessage(chatId: number, text: string, keyboard?: ReplyKeyboard): Promise<void>;
}

export const SHARE_CONTACT_LABEL = '📱 Share my phone number';

type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string }) =>
  Promise<{ ok: boolean; status: number; text(): Promise<string> }>;

/** Thin Bot API client. Plain text only, so no Markdown escaping can go wrong. */
export class TelegramBotClient implements BotClient {
  constructor(
    private readonly token: string,
    private readonly fetchImpl: FetchLike = fetch,
  ) {}

  async sendMessage(chatId: number, text: string, keyboard: ReplyKeyboard = 'none'): Promise<void> {
    const body: Record<string, unknown> = { chat_id: chatId, text };
    if (keyboard === 'share_contact') {
      body.reply_markup = {
        keyboard: [[{ text: SHARE_CONTACT_LABEL, request_contact: true }]],
        resize_keyboard: true,
        one_time_keyboard: true,
      };
    } else if (keyboard === 'remove') {
      body.reply_markup = { remove_keyboard: true };
    }

    const response = await this.fetchImpl(`https://api.telegram.org/bot${this.token}/sendMessage`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      // Never include the URL: it carries the bot token.
      throw new Error(`Telegram sendMessage failed with HTTP ${response.status}: ${await response.text()}`);
    }
  }
}
