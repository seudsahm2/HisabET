import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.subLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 64,
  });

  final String label;
  final String? subLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBackground = backgroundColor ?? colorScheme.primary;
    final resolvedForeground = foregroundColor ?? colorScheme.onPrimary;
    final isDisabled = onTap == null;

    return Material(
      color: resolvedBackground.withOpacity(isDisabled ? 0.6 : 1),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: isDisabled
                ? const []
                : [
                    BoxShadow(
                      color: resolvedBackground.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isDisabled)
                Icon(icon, color: resolvedForeground, size: 24)
              else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(resolvedForeground),
                  ),
                ),
              const SizedBox(width: AppDimensions.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: resolvedForeground,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.1,
                    ),
                  ),
                  if (subLabel != null && subLabel!.isNotEmpty)
                    Text(
                      subLabel!,
                      style: TextStyle(
                        color: resolvedForeground.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}