import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/phone_identity/data/telegram_login_service.dart';
import 'package:hisabet/features/phone_identity/presentation/providers/phone_identity_providers.dart';

/// "Continue with Telegram" on the sign-in screen (Log In with Telegram).
///
/// Renders nothing when Telegram login isn't configured for this build. On
/// success the Firebase auth state changes and `AuthGate` routes on — this
/// widget never navigates.
class TelegramSignInButton extends ConsumerStatefulWidget {
  const TelegramSignInButton({super.key, this.enabled = true});

  /// False while another sign-in method is in progress.
  final bool enabled;

  @override
  ConsumerState<TelegramSignInButton> createState() => _TelegramSignInButtonState();
}

class _TelegramSignInButtonState extends ConsumerState<TelegramSignInButton> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn(TelegramLoginService service) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await service.signIn();
    } on TelegramLoginException catch (e) {
      if (mounted && !e.cancelled) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(telegramLoginServiceProvider);
    if (service == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: (!widget.enabled || _busy) ? null : () => _signIn(service),
          icon: _busy
              ? const SizedBox(
                  width: AppDimensions.iconSm,
                  height: AppDimensions.iconSm,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                )
              : const Icon(Icons.telegram),
          label: Text(_busy ? 'Waiting for Telegram…' : 'Continue with Telegram'),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Signs you in with the phone number on your Telegram. Nothing to type.',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppDimensions.sm),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.negative),
          ),
        ],
      ],
    );
  }
}
