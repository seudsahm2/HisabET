import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/core/presentation/widgets/app_glass.dart';
import 'package:hisabet/core/theme/theme.dart';

class AppPersonalizedHeader extends ConsumerWidget {
  const AppPersonalizedHeader({
    super.key,
    this.onAvatarTap,
    this.avatarSize = 52,
  });

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
    final photoUrl = userProfileAsync.value?.photoUrl ?? FirebaseAuth.instance.currentUser?.photoURL;
    final localImageAsync = photoUrl != null 
        ? ref.watch(localProfileImageProvider(photoUrl)) 
        : const AsyncValue.data(null);
    final localImageFile = localImageAsync.value;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: AppGlass.surface(
        context,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.4,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    image: (localImageFile != null || photoUrl != null)
                        ? DecorationImage(
                            image: localImageFile != null 
                                ? FileImage(localImageFile) 
                                : NetworkImage(photoUrl!) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: photoUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          color: colorScheme.primary,
                          size: avatarSize * 0.45,
                        )
                      : null,
                ),
                if (onAvatarTap != null)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: Icon(
                      Icons.verified_rounded,
                      size: 20,
                      color: AppColors.info,
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