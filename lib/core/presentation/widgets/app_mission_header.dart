import 'package:flutter/material.dart';

import 'package:hisabet/core/presentation/widgets/app_top_bar.dart';

/// Page header used across the feature screens.
///
/// This is now a thin delegate to [AppTopBar] so every screen shares one
/// header implementation. It used to render a tinted glass card, which made the
/// header compete with the content cards below it; see [AppTopBar] for why a
/// header should sit directly on the page ground instead.
///
/// The constructor is unchanged so the twelve existing call sites keep working.
/// Prefer [AppTopBar] directly in new code.
class AppMissionHeader extends StatelessWidget {
  const AppMissionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow = 'HISABET',
    this.leading,
    this.trailing,
    this.padding,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: trailing == null ? null : [trailing!],
      padding: padding,
    );
  }
}
