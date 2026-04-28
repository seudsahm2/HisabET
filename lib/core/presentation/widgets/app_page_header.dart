import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.lg,
            AppDimensions.pagePaddingH,
            0,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}