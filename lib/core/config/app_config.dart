/// App-wide configuration that is compiled into every build — debug and
/// release alike — so `flutter run` and `flutter build apk` need no flags.
///
/// **Only public values belong here.** Everything in this file ships inside
/// the app and anyone can read it. That is fine for these: a bot username is
/// visible to everyone who opens the bot, and the backend URL is a public
/// website. Secrets — the bot token, the webhook secret, the Firebase
/// service-account key — live only in the backend's settings (Netlify
/// environment variables) and must never be added here.
///
/// Each value can still be overridden for one build, e.g. to point a test
/// build at a test bot:
///
/// ```powershell
/// flutter run --dart-define=TELEGRAM_BOT_USERNAME=HisabETTestBot
/// ```
abstract final class AppConfig {
  /// The Telegram bot's username, without `@` (must end in "bot").
  /// Enables "Continue with Telegram" and "Verify with Telegram".
  static const String telegramBotUsername = String.fromEnvironment(
    'TELEGRAM_BOT_USERNAME',
    defaultValue: _productionTelegramBot,
  );

  /// Where the HisabET backend is hosted (the Netlify site), e.g.
  /// `hisabet-backend.netlify.app`. Enables "Continue with Telegram".
  static const String backendUrl = String.fromEnvironment(
    'HISABET_BACKEND_URL',
    defaultValue: _productionBackendUrl,
  );

  /// "Log In with Telegram" client id = the bot's numeric id. It is public:
  /// the digits before the ":" in the bot token, and shown in BotFather →
  /// your bot → Login Widget. (The client *secret* stays on the backend.)
  static const String telegramClientId = String.fromEnvironment(
    'TELEGRAM_CLIENT_ID',
    defaultValue: _productionTelegramClientId,
  );

  // ── Production values ─────────────────────────────────────────────────────
  // Fill these in once. Leaving one empty hides the Telegram options in the
  // app instead of showing a button that cannot work.

  static const String _productionTelegramBot = 'hisabetbot';
  static const String _productionBackendUrl = 'hisabet.netlify.app';
  static const String _productionTelegramClientId = '';
}
