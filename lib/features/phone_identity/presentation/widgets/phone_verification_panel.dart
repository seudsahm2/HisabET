import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/auth/data/services/otp_service.dart';
import 'package:hisabet/features/auth/data/services/pnv_service.dart';
import 'package:hisabet/features/auth/presentation/providers/otp_providers.dart';
import 'package:hisabet/features/phone_identity/data/phone_claim_repository.dart';
import 'package:hisabet/features/phone_identity/data/telegram_phone_verifier.dart';
import 'package:hisabet/features/phone_identity/domain/phone_verification_method.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';
import 'package:hisabet/features/phone_identity/domain/verified_phone.dart';
import 'package:hisabet/features/phone_identity/presentation/providers/phone_identity_providers.dart';

/// Everything needed to give the signed-in account a verified phone number.
///
/// Used by onboarding, by the "verify your phone" gate for existing accounts,
/// and by profile editing. It owns the whole verification flow and writes
/// nothing on behalf of its parent: when it succeeds, `users/{uid}` changes
/// and [verifiedPhoneProvider] reports the new number. Parents watch that
/// provider rather than receiving a callback, so there is one source of truth.
///
/// Paths, in the order offered:
/// 1. **Sign-in number** — the account was created by phone sign-in, so
///    Firebase Auth already holds a proven number; one tap reserves it.
/// 2. **Telegram** — primary for everyone else. Nothing to type.
/// 3. **SMS code** — fallback (Firebase phone auth), with the Firebase PNV
///    carrier check when the device supports it.
class PhoneVerificationPanel extends ConsumerStatefulWidget {
  const PhoneVerificationPanel({super.key, this.allowChange = false});

  /// Offer "Change number" once verified. Off during onboarding.
  final bool allowChange;

  @override
  ConsumerState<PhoneVerificationPanel> createState() =>
      _PhoneVerificationPanelState();
}

class _PhoneVerificationPanelState
    extends ConsumerState<PhoneVerificationPanel> {
  bool _changing = false;

  // Telegram
  String? _sessionId;
  bool _startingTelegram = false;
  String? _telegramError;

  // Sign-in number
  bool _claimingSignInNumber = false;
  String? _claimError;

  bool _showSms = false;

  @override
  Widget build(BuildContext context) {
    // A new number arriving ends "change" mode, whichever path produced it.
    ref.listen<AsyncValue<VerifiedPhone?>>(verifiedPhoneProvider, (prev, next) {
      final before = prev?.valueOrNull;
      final after = next.valueOrNull;
      if (after != null && after != before) {
        setState(() {
          _changing = false;
          _sessionId = null;
          _telegramError = null;
          _showSms = false;
        });
      }
    });

    final verified = ref.watch(verifiedPhoneProvider).valueOrNull;
    if (verified != null && !_changing) {
      return _VerifiedRow(
        phone: verified,
        onChange: widget.allowChange
            ? () => setState(() => _changing = true)
            : null,
      );
    }

    final verifier = ref.watch(telegramPhoneVerifierProvider);
    final signInNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
    final offerSignInNumber =
        !_changing && signInNumber != null && signInNumber.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (offerSignInNumber)
          _signInNumberBlock(signInNumber)
        else ...[
          if (verifier != null) _telegramBlock(verifier),
          if (verifier != null && !_showSms)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.sm),
              child: TextButton(
                onPressed: () => setState(() => _showSms = true),
                child: const Text('Use an SMS code instead'),
              ),
            ),
          if (verifier == null || _showSms) ...[
            if (verifier != null) const _OrDivider(),
            const _SmsCodeVerifier(),
          ],
        ],
        if (_changing)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.sm),
            child: TextButton(
              onPressed: () => setState(() {
                _changing = false;
                _sessionId = null;
                _telegramError = null;
              }),
              child: const Text('Keep my current number'),
            ),
          ),
      ],
    );
  }

  // ── Sign-in number ────────────────────────────────────────────────────────

  Widget _signInNumberBlock(String number) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Notice(
          icon: Icons.verified_user_outlined,
          tone: AppColors.info,
          message:
              'You signed in with $number, so it is already proven. Confirm to make it your HisabET number.',
        ),
        const SizedBox(height: AppDimensions.md),
        FilledButton.icon(
          onPressed: _claimingSignInNumber ? null : _claimSignInNumber,
          icon: _claimingSignInNumber
              ? const _ButtonSpinner(onPrimary: true)
              : const Icon(Icons.check_rounded),
          label: Text('Use $number'),
        ),
        if (_claimError != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _Notice.error(_claimError!),
        ],
      ],
    );
  }

  Future<void> _claimSignInNumber() async {
    setState(() {
      _claimingSignInNumber = true;
      _claimError = null;
    });
    try {
      await ref
          .read(phoneClaimRepositoryProvider)
          .claimFirebaseAuthPhone(PhoneVerificationMethod.firebaseAuth);
    } on PhoneClaimException catch (e) {
      if (mounted) setState(() => _claimError = e.message);
    } finally {
      if (mounted) setState(() => _claimingSignInNumber = false);
    }
  }

  // ── Telegram ──────────────────────────────────────────────────────────────

  Widget _telegramBlock(TelegramPhoneVerifier verifier) {
    final session = _sessionId == null
        ? null
        : ref.watch(telegramSessionProvider(_sessionId!)).valueOrNull;

    final waiting = _sessionId != null &&
        (session == null || !session.status.isTerminal);
    final failure = session?.failure;

    if (waiting) {
      return _TelegramWaiting(
        status: session?.status ?? TelegramVerificationStatus.pending,
        onReopen: () => _openTelegram(verifier, _sessionId!),
        onCancel: () => setState(() => _sessionId = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed:
              _startingTelegram ? null : () => _startTelegram(verifier),
          icon: _startingTelegram
              ? const _ButtonSpinner(onPrimary: true)
              : const Icon(Icons.telegram),
          label: Text(failure == null
              ? 'Verify with Telegram'
              : 'Try Telegram again'),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Opens Telegram. Tap "Share my phone number" there and come back — nothing to type.',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (failure != null || _telegramError != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _Notice.error(_telegramError ?? failure!.message),
        ],
      ],
    );
  }

  Future<void> _startTelegram(TelegramPhoneVerifier verifier) async {
    setState(() {
      _startingTelegram = true;
      _telegramError = null;
      _sessionId = null;
    });
    try {
      final session = await verifier.start();
      if (!mounted) return;
      setState(() => _sessionId = session.id);
      await _openTelegram(verifier, session.id);
    } on TelegramVerificationException catch (e) {
      if (mounted) setState(() => _telegramError = e.message);
    } finally {
      if (mounted) setState(() => _startingTelegram = false);
    }
  }

  Future<void> _openTelegram(
    TelegramPhoneVerifier verifier,
    String sessionId,
  ) async {
    final opened = await ref.read(telegramLauncherProvider).open(
          appLink: verifier.appLink(sessionId),
          webLink: verifier.webLink(sessionId),
        );
    if (!opened && mounted) {
      setState(() {
        _sessionId = null;
        _telegramError =
            'Could not open Telegram. Install it, or use an SMS code instead.';
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMS code fallback (Firebase phone auth + optional PNV)
// ─────────────────────────────────────────────────────────────────────────────

class _SmsCodeVerifier extends ConsumerStatefulWidget {
  const _SmsCodeVerifier();

  @override
  ConsumerState<_SmsCodeVerifier> createState() => _SmsCodeVerifierState();
}

class _SmsCodeVerifierState extends ConsumerState<_SmsCodeVerifier> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _codeSessionId;
  bool _busy = false;
  bool _checkingSim = false;
  String? _error;
  String? _hint;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? get _normalizedPhone {
    final normalized = PhoneUtil.normalize(_phoneController.text.trim());
    final digits = normalized.replaceAll(RegExp(r'\D'), '').length;
    if (!normalized.startsWith('+') || digits < 10 || digits > 15) return null;
    return normalized;
  }

  Future<void> _sendCode() async {
    final phone = _normalizedPhone;
    if (phone == null) {
      setState(() => _error = 'Enter a valid number, e.g. 0911223344.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await ref.read(otpServiceProvider).start(
            phone,
            mode: OtpAutoResolveMode.link,
          );
      switch (outcome) {
        case OtpAutoResolved():
          // Play services proved the number without an SMS.
          await _claim();
        case OtpCodeSent(:final sessionId):
          if (mounted) setState(() => _codeSessionId = sessionId);
      }
    } on OtpException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send the code. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _codeSessionId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).verifyAndLinkToCurrentUser(
            sessionId: _codeSessionId!,
            code: code,
          );
      await _claim();
    } on OtpException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Firebase Auth now holds the proven number; reserve it and save it.
  Future<void> _claim() async {
    try {
      await ref
          .read(phoneClaimRepositoryProvider)
          .claimFirebaseAuthPhone(PhoneVerificationMethod.smsCode);
    } on PhoneClaimException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// PNV fills in the SIM's number. It is not proof on its own (the backend
  /// does not verify PNV tokens yet), so the code is still sent.
  Future<void> _detectFromSim() async {
    setState(() {
      _checkingSim = true;
      _error = null;
    });
    try {
      final result = await ref.read(pnvServiceProvider).verify();
      if (!mounted) return;
      _phoneController.text = result.phoneNumber;
      setState(() => _hint = 'Number read from your SIM. Send the code to confirm it.');
    } on PnvException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not read the number from your SIM.');
    } finally {
      if (mounted) setState(() => _checkingSim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otp = ref.watch(otpServiceProvider);
    final pnvAvailable = ref.watch(pnvAvailableProvider).valueOrNull ?? false;

    if (!otp.isUsable) {
      return const _Notice(
        icon: Icons.info_outline_rounded,
        tone: AppColors.info,
        message: 'SMS verification is not switched on for this build.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          enabled: _codeSessionId == null && !_busy,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '0911223344',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
        ),
        if (pnvAvailable && _codeSessionId == null) ...[
          const SizedBox(height: AppDimensions.sm),
          TextButton.icon(
            onPressed: _checkingSim || _busy ? null : _detectFromSim,
            icon: _checkingSim
                ? const _ButtonSpinner()
                : const Icon(Icons.sim_card_outlined),
            label: const Text('Fill in from my SIM'),
          ),
        ],
        const SizedBox(height: AppDimensions.md),
        if (_codeSessionId == null)
          OutlinedButton.icon(
            onPressed: _busy ? null : _sendCode,
            icon: _busy ? const _ButtonSpinner() : const Icon(Icons.sms_outlined),
            label: Text('Send code (${otp.channelLabel})'),
          )
        else ...[
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '6-digit code',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ElevatedButton(
            onPressed: _busy ? null : _confirmCode,
            child: _busy
                ? const _ButtonSpinner(onPrimary: true)
                : const Text('Confirm code'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _codeSessionId = null;
                      _codeController.clear();
                    }),
            child: const Text('Use a different number'),
          ),
        ],
        if (_hint != null && _error == null) ...[
          const SizedBox(height: AppDimensions.sm),
          _Notice(icon: Icons.sim_card_outlined, tone: AppColors.info, message: _hint!),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _Notice.error(_error!),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────────────────────

class _VerifiedRow extends StatelessWidget {
  const _VerifiedRow({required this.phone, this.onChange});

  final VerifiedPhone phone;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded,
              color: AppColors.positive, size: AppDimensions.iconMd),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone.e164,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified via ${phone.method.label}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onChange != null)
            TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _TelegramWaiting extends StatelessWidget {
  const _TelegramWaiting({
    required this.status,
    required this.onReopen,
    required this.onCancel,
  });

  final TelegramVerificationStatus status;
  final VoidCallback onReopen;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final opened = status == TelegramVerificationStatus.awaitingContact;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
        color: AppColors.info.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: AppDimensions.iconSm,
                height: AppDimensions.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  opened
                      ? 'Now tap "Share my phone number" in Telegram.'
                      : 'Waiting for Telegram…',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            opened
                ? 'This screen updates by itself as soon as you share it.'
                : 'In Telegram, press Start in the HisabET bot. The link works for 10 minutes.',
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReopen,
                  icon: const Icon(Icons.open_in_new_rounded,
                      size: AppDimensions.iconSm),
                  label: const Text('Open Telegram'),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
      child: Row(
        children: [
          Expanded(child: Divider(color: colorScheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            child: Text(
              'OR WITH AN SMS CODE',
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message, required this.tone});

  const _Notice.error(this.message)
      : icon = Icons.error_outline_rounded,
        tone = AppColors.negative;

  final IconData icon;
  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: tone.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: tone),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({this.onPrimary = false});

  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.iconSm,
      height: AppDimensions.iconSm,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: onPrimary ? AppColors.textOnPrimary : null,
      ),
    );
  }
}
