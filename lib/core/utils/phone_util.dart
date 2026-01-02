class PhoneUtil {
  /// Normalizes phone number to E.164 format (e.g., +251911223344)
  /// Removing spaces, dashes, and handling '09' prefix for Ethiopia.
  static String normalize(String phone) {
    if (phone.isEmpty) return phone;

    // Remove all non-digit characters except leading +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle Ethiopia specific (09... -> +2519...)
    if (cleaned.startsWith('09') && cleaned.length == 10) {
      return '+251${cleaned.substring(1)}';
    }

    // Handle 9... without 0 (e.g. 911223344 -> +251911223344)
    if (cleaned.startsWith('9') && cleaned.length == 9) {
      return '+251$cleaned';
    }

    // Ensure it starts with + if it looks international
    if (!cleaned.startsWith('+') && cleaned.length > 9) {
      // Assume manual entry might need checks, for now return cleaned
      // Or better, if it's 251..., prepend +
      if (cleaned.startsWith('251')) {
        return '+$cleaned';
      }
    }

    return cleaned;
  }
}
