export type PhoneCheck =
  | { ok: true; e164: string }
  | { ok: false; reason: 'invalid' | 'anonymous_number' };

/**
 * Normalises a phone number from a Telegram `Contact` to E.164.
 *
 * Telegram sends international digits, with or without a leading `+`
 * (`251911223344` or `+251911223344`). It never sends a national-format
 * number, so no country inference is done here — guessing would be the
 * wrong kind of helpful for an identity field.
 *
 * `+888` numbers are anonymous Fragment numbers bought on the blockchain,
 * not SIMs. They prove nothing about who someone is, so they are refused.
 */
export function normalizeTelegramPhone(raw: string | undefined | null): PhoneCheck {
  if (!raw) return { ok: false, reason: 'invalid' };

  const digits = raw.replace(/\D/g, '');
  // E.164: at most 15 digits; 8 is a safe floor for any real subscriber number.
  if (digits.length < 8 || digits.length > 15 || digits.startsWith('0')) {
    return { ok: false, reason: 'invalid' };
  }
  if (digits.startsWith('888')) {
    return { ok: false, reason: 'anonymous_number' };
  }
  return { ok: true, e164: `+${digits}` };
}

/** `s***h@gmail.com` — enough for the owner to recognise, useless to anyone else. */
export function maskEmail(email: string): string {
  const at = email.indexOf('@');
  if (at <= 0) return '***';
  const local = email.slice(0, at);
  const domain = email.slice(at);
  if (local.length <= 2) return `${local[0]}***${domain}`;
  return `${local[0]}***${local[local.length - 1]}${domain}`;
}
