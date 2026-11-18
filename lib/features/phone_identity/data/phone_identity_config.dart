import 'package:hisabet/core/config/app_config.dart';

/// Parsed, validated phone-verification settings. The raw values come from
/// [AppConfig] (compiled in, overridable with `--dart-define`).
///
/// With no bot configured the Telegram options are hidden and the SMS-code
/// path is offered on its own. See TELEGRAM_PHONE_VERIFICATION.md.
abstract final class PhoneIdentityConfig {
  /// The bot's @username without the `@`, or null when not configured or
  /// not a valid Telegram bot username.
  static String? get telegramBotUsername => parseBotUsername(AppConfig.telegramBotUsername);

  /// Where the Telegram sign-in exchange lives, or null when not configured.
  static Uri? get backendUrl => parseBackendUrl(AppConfig.backendUrl);

  /// The exchange endpoint, under either host's path.
  static Uri? get telegramSignInUrl =>
      backendUrl?.replace(path: '${backendUrl!.path}/telegram-signin');

  /// Accepts `site.netlify.app` or `https://site.netlify.app/`; https only,
  /// because an ID token is sent to it.
  static Uri? parseBackendUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return Uri(scheme: 'https', host: uri.host, port: uri.hasPort ? uri.port : null, path: path);
  }

  /// Telegram bot usernames: 5–32 chars of `[A-Za-z0-9_]`, starting with a
  /// letter, ending in "bot".
  static String? parseBotUsername(String raw) {
    final name = raw.trim().replaceFirst(RegExp(r'^@'), '');
    final valid = RegExp(r'^[A-Za-z][A-Za-z0-9_]{3,30}[Bb][Oo][Tt]$');
    return valid.hasMatch(name) ? name : null;
  }
}
