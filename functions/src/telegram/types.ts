/**
 * The subset of the Telegram Bot API this backend reads.
 * https://core.telegram.org/bots/api#update
 */

export interface TelegramUser {
  id: number;
  is_bot: boolean;
  first_name: string;
}

export interface TelegramChat {
  id: number;
  type: 'private' | 'group' | 'supergroup' | 'channel';
}

export interface TelegramContact {
  phone_number: string;
  first_name: string;
  /** Present when the contact is a Telegram user. Equals `from.id` only for your own contact. */
  user_id?: number;
}

export interface TelegramMessage {
  message_id: number;
  from?: TelegramUser;
  chat: TelegramChat;
  text?: string;
  contact?: TelegramContact;
}

export interface TelegramUpdate {
  update_id: number;
  message?: TelegramMessage;
}
