class PhoneUtil {
  /// Normalises a phone number to E.164 (e.g. `+251911223344`).
  ///
  /// Handles how Ethiopian numbers are actually written and stored in phone
  /// books — both networks:
  /// - Ethio Telecom `09…` and Safaricom Ethiopia `07…`
  /// - local `0911 22 33 44`, bare `911223344`, `251911223344`,
  ///   `+251 91 122 3344`, `00251911223344`
  ///
  /// Anything else is returned with formatting stripped, so foreign numbers
  /// already written with `+` pass through unchanged.
  static String normalize(String phone) {
    if (phone.isEmpty) return phone;

    // Keep digits and a leading +.
    var cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('00')) cleaned = '+${cleaned.substring(2)}';

    // Local mobile: 09xxxxxxxx (Ethio Telecom) / 07xxxxxxxx (Safaricom).
    if (RegExp(r'^0[79]\d{8}$').hasMatch(cleaned)) {
      return '+251${cleaned.substring(1)}';
    }

    // Without the trunk zero: 9xxxxxxxx / 7xxxxxxxx.
    if (RegExp(r'^[79]\d{8}$').hasMatch(cleaned)) {
      return '+251$cleaned';
    }

    // Country code without the plus.
    if (RegExp(r'^251\d{9}$').hasMatch(cleaned)) {
      return '+$cleaned';
    }

    return cleaned;
  }

  /// True for a plausible E.164 number after [normalize].
  static bool isValidE164(String phone) => RegExp(r'^\+\d{8,15}$').hasMatch(phone);
}
