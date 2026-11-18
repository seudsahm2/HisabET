import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> _openExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Opens a bot link in Telegram, falling back to the browser.
///
/// Tries the `tg://` scheme first so the Telegram app opens straight to the
/// bot; if Telegram is not installed that fails, and `https://t.me/...`
/// opens in the browser, which offers to install it.
class TelegramLauncher {
  const TelegramLauncher({UrlOpener open = _openExternally}) : _open = open;

  final UrlOpener _open;

  Future<bool> open({required Uri appLink, required Uri webLink}) async {
    try {
      if (await _open(appLink)) return true;
    } catch (e) {
      // No handler for tg:// — expected when Telegram is not installed.
      debugPrint('[TelegramLauncher] tg:// unavailable, using t.me ($e)');
    }
    try {
      return await _open(webLink);
    } catch (e) {
      debugPrint('[TelegramLauncher] t.me failed: $e');
      return false;
    }
  }
}
