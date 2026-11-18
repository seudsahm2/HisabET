import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';

/// "Waiting for Telegram" state, shared by phone verification and
/// Telegram sign-in.
class TelegramWaitingCard extends StatelessWidget {
  const TelegramWaitingCard({
    super.key,
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
