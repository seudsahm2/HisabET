import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/auth/data/services/otp_service.dart';
import 'package:hisabet/features/auth/presentation/providers/otp_providers.dart';

/// Which part of the sign-in flow is on screen.
enum _Stage { chooser, phoneEntry, codeEntry }

/// The signed-out entry point.
///
/// Routing is handled entirely by `AuthGate` listening to `authStateChanges`,
/// so this screen never navigates on success — it just signs in and lets the
/// gate swap it out.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  _Stage _stage = _Stage.chooser;
  bool _busy = false;
  String? _error;

  String? _sessionId;
  int? _resendToken;
  String _submittedPhone = '';

  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── State helpers ─────────────────────────────────────────────────────────

  void _setBusy(bool value, {String? error}) {
    if (!mounted) return;
    setState(() {
      _busy = value;
      _error = error;
    });
  }

  void _goTo(_Stage stage) {
    setState(() {
      _stage = stage;
      _error = null;
    });
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    _setBusy(true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setBusy(false); // user dismissed the picker
        return;
      }

      final googleAuth = await googleUser.authentication;
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
      // AuthGate takes over from here.
      if (mounted) setState(() => _busy = false);
    } on FirebaseAuthException catch (e) {
      _setBusy(false, error: e.message ?? 'Google sign-in failed.');
    } catch (e) {
      _setBusy(false, error: 'Google sign-in failed. $e');
    }
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  Future<void> _sendCode({bool isResend = false}) async {
    final normalized = PhoneUtil.normalize(_phoneController.text.trim());
    final digits = normalized.replaceAll(RegExp(r'\D'), '').length;

    if (!normalized.startsWith('+') || digits < 10 || digits > 15) {
      _setBusy(false, error: 'Enter a valid number, for example 0911223344.');
      return;
    }

    _setBusy(true);
    try {
      final outcome = await ref.read(otpServiceProvider).start(
            normalized,
            resendToken: isResend ? _resendToken : null,
          );

      if (!mounted) return;

      switch (outcome) {
        case OtpAutoResolved():
          // Android auto-retrieval already signed us in.
          setState(() => _busy = false);
        case OtpCodeSent(:final sessionId, :final resendToken):
          setState(() {
            _sessionId = sessionId;
            _resendToken = resendToken;
            _submittedPhone = normalized;
            _busy = false;
            _error = null;
            _stage = _Stage.codeEntry;
          });
          _startResendCountdown();
      }
    } on OtpException catch (e) {
      _setBusy(false, error: e.message);
    } catch (e) {
      _setBusy(false, error: 'Could not send the code. $e');
    }
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _sessionId == null) {
      _setBusy(false, error: 'Enter the 6-digit code.');
      return;
    }

    _setBusy(true);
    try {
      await ref.read(otpServiceProvider).verifyAndSignIn(
            sessionId: _sessionId!,
            code: code,
          );
      if (mounted) setState(() => _busy = false);
    } on OtpException catch (e) {
      _setBusy(false, error: e.message);
    } catch (e) {
      _setBusy(false, error: 'Verification failed. $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.xxl,
                vertical: AppDimensions.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppDimensions.xxxl,
                  maxWidth: 480,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandBlock(),
                    const SizedBox(height: AppDimensions.xxxl),
                    _AuthCard(
                      stage: _stage,
                      busy: _busy,
                      error: _error,
                      phoneController: _phoneController,
                      codeController: _codeController,
                      submittedPhone: _submittedPhone,
                      secondsLeft: _secondsLeft,
                      otpService: ref.watch(otpServiceProvider),
                      onGoogle: _signInWithGoogle,
                      onUsePhone: () => _goTo(_Stage.phoneEntry),
                      onBack: () => _goTo(
                        _stage == _Stage.codeEntry
                            ? _Stage.phoneEntry
                            : _Stage.chooser,
                      ),
                      onSendCode: _sendCode,
                      onResend: () => _sendCode(isResend: true),
                      onConfirmCode: _confirmCode,
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    const _LegalFootnote(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand
// ─────────────────────────────────────────────────────────────────────────────

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const AppLogo(size: 84, showText: true),
        const SizedBox(height: AppDimensions.md),
        Text(
          'Your ledger, your stock, in agreement.',
          textAlign: TextAlign.center,
          style: AppTextStyles.cardSubtitle.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        const _TrustStrip(),
      ],
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TrustChip(
            icon: Icons.wifi_off_rounded,
            label: 'Works\noffline',
          ),
        ),
        SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _TrustChip(
            icon: Icons.sync_alt_rounded,
            label: 'Both sides\nagree',
          ),
        ),
        SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _TrustChip(
            icon: Icons.inventory_2_rounded,
            label: 'Cartons\ntracked',
          ),
        ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.md,
        horizontal: AppDimensions.sm,
      ),
      decoration: AppGlass.surface(
        context,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        withShadow: false,
      ),
      child: Column(
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: AppColors.primary),
          const SizedBox(height: AppDimensions.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth card
// ─────────────────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.stage,
    required this.busy,
    required this.error,
    required this.phoneController,
    required this.codeController,
    required this.submittedPhone,
    required this.secondsLeft,
    required this.otpService,
    required this.onGoogle,
    required this.onUsePhone,
    required this.onBack,
    required this.onSendCode,
    required this.onResend,
    required this.onConfirmCode,
  });

  final _Stage stage;
  final bool busy;
  final String? error;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final String submittedPhone;
  final int secondsLeft;
  final OtpService otpService;
  final VoidCallback onGoogle;
  final VoidCallback onUsePhone;
  final VoidCallback onBack;
  final VoidCallback onSendCode;
  final VoidCallback onResend;
  final VoidCallback onConfirmCode;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            switch (stage) {
              _Stage.chooser => _ChooserBody(
                  busy: busy,
                  otpService: otpService,
                  onGoogle: onGoogle,
                  onUsePhone: onUsePhone,
                ),
              _Stage.phoneEntry => _PhoneBody(
                  busy: busy,
                  controller: phoneController,
                  otpService: otpService,
                  onBack: onBack,
                  onSubmit: onSendCode,
                ),
              _Stage.codeEntry => _CodeBody(
                  busy: busy,
                  controller: codeController,
                  phone: submittedPhone,
                  secondsLeft: secondsLeft,
                  onBack: onBack,
                  onResend: onResend,
                  onSubmit: onConfirmCode,
                ),
            },
            if (error != null) ...[
              const SizedBox(height: AppDimensions.lg),
              _ErrorNote(message: error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChooserBody extends StatelessWidget {
  const _ChooserBody({
    required this.busy,
    required this.otpService,
    required this.onGoogle,
    required this.onUsePhone,
  });

  final bool busy;
  final OtpService otpService;
  final VoidCallback onGoogle;
  final VoidCallback onUsePhone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phoneUsable = otpService.isUsable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in',
          style: AppTextStyles.titleLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Use the account your contacts can find you by.',
          style: AppTextStyles.cardSubtitle.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.xl),

        ElevatedButton.icon(
          onPressed: busy ? null : onGoogle,
          icon: busy
              ? const SizedBox(
                  width: AppDimensions.iconSm,
                  height: AppDimensions.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : const Icon(Icons.account_circle_rounded),
          label: Text(busy ? 'Signing in…' : 'Continue with Google'),
        ),

        const SizedBox(height: AppDimensions.lg),
        const _OrDivider(),
        const SizedBox(height: AppDimensions.lg),

        OutlinedButton.icon(
          onPressed: (busy || !phoneUsable) ? null : onUsePhone,
          icon: const Icon(Icons.smartphone_rounded),
          label: const Text('Continue with phone number'),
        ),

        if (!phoneUsable) ...[
          const SizedBox(height: AppDimensions.md),
          _InfoNote(
            icon: Icons.info_outline_rounded,
            message:
                'Phone sign-in switches on as soon as an SMS provider is connected. '
                'Google works now, and you can add your phone number to your profile either way.',
          ),
        ] else if (otpService.availability == OtpAvailability.testNumbers) ...[
          const SizedBox(height: AppDimensions.md),
          _InfoNote(
            icon: Icons.construction_rounded,
            message:
                'Test mode: only numbers registered in the Firebase console will '
                'work, and no real SMS is sent.',
            tone: AppColors.warning,
          ),
        ],
      ],
    );
  }
}

class _PhoneBody extends StatelessWidget {
  const _PhoneBody({
    required this.busy,
    required this.controller,
    required this.otpService,
    required this.onBack,
    required this.onSubmit,
  });

  final bool busy;
  final TextEditingController controller;
  final OtpService otpService;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          title: 'Your phone number',
          subtitle: 'We send a 6-digit code to confirm it is you.',
          onBack: busy ? null : onBack,
        ),
        const SizedBox(height: AppDimensions.xl),
        TextField(
          controller: controller,
          enabled: !busy,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => busy ? null : onSubmit(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '0911223344',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Ethiopian numbers are converted to +251 automatically.',
          style: AppTextStyles.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        ElevatedButton(
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const SizedBox(
                  width: AppDimensions.iconSm,
                  height: AppDimensions.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : const Text('Send code'),
        ),
      ],
    );
  }
}

class _CodeBody extends StatelessWidget {
  const _CodeBody({
    required this.busy,
    required this.controller,
    required this.phone,
    required this.secondsLeft,
    required this.onBack,
    required this.onResend,
    required this.onSubmit,
  });

  final bool busy;
  final TextEditingController controller;
  final String phone;
  final int secondsLeft;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          title: 'Enter the code',
          subtitle: 'Sent to $phone',
          onBack: busy ? null : onBack,
        ),
        const SizedBox(height: AppDimensions.xl),
        TextField(
          controller: controller,
          enabled: !busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          onSubmitted: (_) => busy ? null : onSubmit(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.headlineSmall.copyWith(
            letterSpacing: 10,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        ElevatedButton(
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const SizedBox(
                  width: AppDimensions.iconSm,
                  height: AppDimensions.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : const Text('Verify and continue'),
        ),
        const SizedBox(height: AppDimensions.sm),
        TextButton(
          onPressed: (busy || secondsLeft > 0) ? null : onResend,
          child: Text(
            secondsLeft > 0 ? 'Resend code in ${secondsLeft}s' : 'Resend code',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared pieces
// ─────────────────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: 'Back',
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.cardSubtitle.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final line = Expanded(
      child: Divider(color: colorScheme.outlineVariant, height: 1),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(
            'or',
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.message,
    this.tone,
  });

  final IconData icon;
  final String message;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = tone ?? AppColors.info;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: accent),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.negative.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.negative.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: AppDimensions.iconSm,
            color: AppColors.negative,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.negative,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalFootnote extends StatelessWidget {
  const _LegalFootnote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      'By continuing you agree to the Terms of Service and Privacy Policy.',
      textAlign: TextAlign.center,
      style: AppTextStyles.labelSmall.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
