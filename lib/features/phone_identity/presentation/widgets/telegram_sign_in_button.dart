import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/phone_identity/data/telegram_sign_in_service.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';
import 'package:hisabet/features/phone_identity/presentation/providers/phone_identity_providers.dart';
import 'package:hisabet/features/phone_identity/presentation/widgets/telegram_waiting_card.dart';

/// "Continue with Telegram" on the sign-in screen.
///
/// Renders nothing when Telegram sign-in isn't configured for this build, so
/// the screen degrades to Google / phone. When sign-in succeeds the Firebase
/// auth state changes and `AuthGate` routes on — this widget never navigates.
class TelegramSignInButton extends ConsumerStatefulWidget {
  const TelegramSignInButton({super.key, this.enabled = true});

  /// False while another sign-in method is in progress.
  final bool enabled;

  @override
  ConsumerState<TelegramSignInButton> createState() => _TelegramSignInButtonState();
}

class _TelegramSignInButtonState extends ConsumerState<TelegramSignInButton> {
  String? _sessionId;
  bool _starting = false;
  bool _finishing = false;
  String? _error;

  Future<void> _start(TelegramSignInService service) async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final session = await service.begin();
      if (!mounted) return;
      setState(() => _sessionId = session.id);
      await _openTelegram(service, session.id);
    } on TelegramSignInException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _openTelegram(TelegramSignInService service, String sessionId) async {
    final opened = await ref.read(telegramLauncherProvider).open(
          appLink: service.verifier.appLink(sessionId),
          webLink: service.verifier.webLink(sessionId),
        );
    if (!opened && mounted) {
      setState(() => _error = 'Could not open Telegram. Is it installed?');
    }
  }

  Future<void> _finish(TelegramSignInService service, String sessionId) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await service.finish(sessionId);
      // AuthGate takes over from here.
    } on TelegramSignInException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _sessionId = null;
        });
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _cancel(TelegramSignInService service) async {
    setState(() => _sessionId = null);
    await service.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(telegramSignInServiceProvider);
    if (service == null) return const SizedBox.shrink();

    final sessionId = _sessionId;
    if (sessionId != null) {
      ref.listen<AsyncValue<TelegramVerificationSession>>(
        telegramSessionProvider(sessionId),
        (_, next) {
          final session = next.valueOrNull;
          if (session == null) return;
          if (session.status == TelegramVerificationStatus.verified) {
            _finish(service, sessionId);
          } else if (session.status == TelegramVerificationStatus.failed) {
            setState(() {
              _error = (session.failure ?? TelegramVerificationFailure.unknown).message;
              _sessionId = null;
            });
          }
        },
      );

      if (_finishing) {
        return const _Status(text: 'Opening your account…');
      }
      final status = ref.watch(telegramSessionProvider(sessionId)).valueOrNull?.status ??
          TelegramVerificationStatus.pending;
      return TelegramWaitingCard(
        status: status,
        onReopen: () => _openTelegram(service, sessionId),
        onCancel: () => _cancel(service),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: (!widget.enabled || _starting) ? null : () => _start(service),
          icon: _starting
              ? const SizedBox(
                  width: AppDimensions.iconSm,
                  height: AppDimensions.iconSm,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                )
              : const Icon(Icons.telegram),
          label: const Text('Continue with Telegram'),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Uses the phone number on your Telegram. Nothing to type.',
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

class _Status extends StatelessWidget {
  const _Status({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: AppDimensions.iconSm,
            height: AppDimensions.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppDimensions.md),
          Text(text, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}
