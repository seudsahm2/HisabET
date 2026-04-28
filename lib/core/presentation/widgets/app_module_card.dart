import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisabet/core/presentation/widgets/app_glass.dart';
import 'package:hisabet/core/theme/theme.dart';

/// ─── App Module Tile ─────────────────────────────────────────────────────────
///
/// A premium, icon-free "mini-app" launcher tile for the Business Hub.
/// Each tile has a dark-surface card with a subtle left-edge gradient accent,
/// a large category icon rendered as a monochrome watermark, live stat badge,
/// and a clean title/description layout.
///
/// Two variants:
///   [AppModuleTile.hero]    – full-width tall cards for top-level modules
///   [AppModuleTile.compact] – standard list tile with icon on left
///
class AppModuleTile extends StatefulWidget {
  const AppModuleTile._({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    required this.variant,
    this.badge,
    this.stat,
  });

  /// Full-width hero variant (for primary modules grid).
  factory AppModuleTile.hero({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    AppStatusBadgeData? badge,
    String? stat,
  }) =>
      AppModuleTile._(
        title: title,
        description: description,
        icon: icon,
        accentColor: accentColor,
        onTap: onTap,
        variant: _TileVariant.hero,
        badge: badge,
        stat: stat,
      );

  /// Standard compact list-row variant.
  factory AppModuleTile.compact({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    AppStatusBadgeData? badge,
    String? stat,
  }) =>
      AppModuleTile._(
        title: title,
        description: description,
        icon: icon,
        accentColor: accentColor,
        onTap: onTap,
        variant: _TileVariant.compact,
        badge: badge,
        stat: stat,
      );

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  // ignore: library_private_types_in_public_api
  final _TileVariant variant;
  final AppStatusBadgeData? badge;
  final String? stat;

  @override
  State<AppModuleTile> createState() => _AppModuleTileState();
}

class _AppModuleTileState extends State<AppModuleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _ctrl.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.variant == _TileVariant.hero
            ? _buildHero(context)
            : _buildCompact(context),
      ),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor;

    return Container(
      height: 130,
      decoration: AppGlass.surface(
        context,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        tintColor: accent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Stack(
          children: [
            // ── Gradient accent strip on left ─────────────────────────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accent.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),
            // ── Watermark icon (decorative, large, faint) ─────────────────
            Positioned(
              right: -12,
              bottom: -14,
              child: Icon(
                widget.icon,
                size: 96,
                color: accent.withValues(alpha: isDark ? 0.07 : 0.06),
              ),
            ),
            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Small tinted icon circle
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, size: 18, color: accent),
                      ),
                      const Spacer(),
                      if (widget.badge != null) _buildBadge(widget.badge!),
                      if (widget.badge == null)
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 13,
                          color: colorScheme.outlineVariant),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.stat ?? widget.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact Row ───────────────────────────────────────────────────────────
  Widget _buildCompact(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor;

    return Container(
      height: 68,
      decoration: AppGlass.surface(
        context,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        tintColor: accent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Row(
          children: [
            // Accent strip
            Container(
              width: 3,
              color: accent,
            ),
            // Icon block
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 19, color: accent),
              ),
            ),
            // Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Trailing
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: widget.badge != null
                  ? _buildBadge(widget.badge!)
                  : Icon(Icons.chevron_right_rounded,
                      size: 18,
                      color: colorScheme.outlineVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(AppStatusBadgeData badge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: isDark ? 0.16 : 0.13),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: badge.color.withValues(alpha: isDark ? 0.30 : 0.25),
          width: 1,
        ),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: badge.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

enum _TileVariant { hero, compact }

/// Simple data class for module tile badge.
class AppStatusBadgeData {
  const AppStatusBadgeData({required this.label, required this.color});
  final String label;
  final Color color;
}

// Keep the old name as an alias so nothing else breaks
typedef AppModuleCard = AppModuleTile;
