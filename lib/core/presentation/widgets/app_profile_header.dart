import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

class AppProfileHeader extends StatelessWidget {
  const AppProfileHeader({
    super.key,
    required this.name,
    required this.avatar,
    this.subtitle,
    this.onAvatarTap,
    this.helperText,
  });

  final String name;
  final ImageProvider? avatar;
  final String? subtitle;
  final String? helperText;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                    border: Border.all(color: AppColors.primary.withOpacity(0.30), width: 1.5),
                    image: avatar != null
                        ? DecorationImage(image: avatar!, fit: BoxFit.cover)
                        : null,
                  ),
                  child: avatar == null
                      ? Icon(Icons.person_rounded, color: colorScheme.primary, size: 36)
                      : null,
                ),
                if (onAvatarTap != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (helperText != null && helperText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    helperText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}