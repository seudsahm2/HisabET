/// Build-time configuration for phone verification.
///
/// ```powershell
/// flutter run --dart-define=TELEGRAM_BOT_USERNAME=HisabETBot
/// ```
///
/// With no bot configured, the Telegram option is hidden and the SMS-code
/// path is offered on its own — so a build made before the backend is
/// deployed still works. See TELEGRAM_PHONE_VERIFICATION.md.
abstract final class PhoneIdentityConfig {
  static const String _rawBotUsername =
      String.fromEnvironment('TELEGRAM_BOT_USERNAME');

  /// The bot's @username without the `@`, or null when not configured or
  /// not a valid Telegram bot username.
  static String? get telegramBotUsername => parseBotUsername(_rawBotUsername);

  /// Telegram bot usernames: 5–32 chars of `[A-Za-z0-9_]`, starting with a
  /// letter, ending in "bot".
  static String? parseBotUsername(String raw) {
    final name = raw.trim().replaceFirst(RegExp(r'^@'), '');
    final valid = RegExp(r'^[A-Za-z][A-Za-z0-9_]{3,30}[Bb][Oo][Tt]$');
    return valid.hasMatch(name) ? name : null;
  }
}
