import { describe, expect, it } from 'vitest';
import { maskEmail, normalizeTelegramPhone } from '../../src/phone/normalize.js';

describe('normalizeTelegramPhone', () => {
  it.each([
    ['251911223344', '+251911223344'],
    ['+251911223344', '+251911223344'],
    ['+251 91 122 3344', '+251911223344'],
    ['4915112345678', '+4915112345678'],
  ])('%s -> %s', (raw, e164) => {
    expect(normalizeTelegramPhone(raw)).toEqual({ ok: true, e164 });
  });

  it.each([undefined, null, '', '123', '0911223344', '1234567890123456'])('rejects %s as invalid', (raw) => {
    expect(normalizeTelegramPhone(raw)).toEqual({ ok: false, reason: 'invalid' });
  });

  it('refuses anonymous +888 Fragment numbers', () => {
    expect(normalizeTelegramPhone('+88801234567')).toEqual({ ok: false, reason: 'anonymous_number' });
  });
});

describe('maskEmail', () => {
  it('keeps first and last character of the local part', () => {
    expect(maskEmail('seudsahm@gmail.com')).toBe('s***m@gmail.com');
  });
  it('handles very short local parts', () => {
    expect(maskEmail('ab@x.com')).toBe('a***@x.com');
  });
  it('never echoes a malformed value', () => {
    expect(maskEmail('not-an-email')).toBe('***');
  });
});
