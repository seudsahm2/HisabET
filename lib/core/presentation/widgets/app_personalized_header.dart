import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/core/theme/theme.dart';

class AppPersonalizedHeader extends ConsumerWidget {
  const AppPersonalizedHeader({
    super.key,
    this.subtitle,
    this.onAvatarTap,
    this.avatarSize = 52,
  });

  final String? subtitle;
  final VoidCallback? onAvatarTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final userName = userProfileAsync.when(
      data: (profile) => profile?.displayName ?? 'Merchant',
      loading: () => 'Merchant',
      error: (_, __) => 'Merchant',
    );
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase();
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hello, $userName',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.05,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
                    image: photoUrl != null
                        ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                        : null,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: photoUrl == null
                      ? Icon(Icons.person_rounded, color: colorScheme.primary, size: avatarSize * 0.45)
                      : null,
                ),
                if (onAvatarTap != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}