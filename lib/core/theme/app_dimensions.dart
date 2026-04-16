/// Layout constants for HisabET.
/// Always use these — never hardcode padding/radius numbers in widget files.
abstract final class AppDimensions {
  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // ── Screen padding ────────────────────────────────────────────────────────
  /// Standard horizontal page padding
  static const double pagePaddingH = 16.0;
  /// Standard vertical page padding (top/bottom)
  static const double pagePaddingV = 16.0;
  /// Bottom padding to avoid FAB overlap
  static const double bottomListPadding = 100.0;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 28.0;
  static const double radiusFull = 999.0; // fully rounded pill

  // ── Icon / Avatar sizes ───────────────────────────────────────────────────
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  static const double avatarSm = 32.0;
  static const double avatarMd = 44.0;
  static const double avatarLg = 56.0;

  // ── Card ──────────────────────────────────────────────────────────────────
  static const double cardRadius = radiusLg;   // 20
  static const double cardPadding = lg;        // 16
  static const double cardGap = md;            // 12

  // ── Button ────────────────────────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonRadius = radiusMd;  // 14
  static const double buttonPaddingH = xxl;     // 24

  // ── AppBar ────────────────────────────────────────────────────────────────
  static const double appBarHeight = 56.0;

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  static const double bottomNavHeight = 80.0;

  // ── Input ─────────────────────────────────────────────────────────────────
  static const double inputRadius = radiusMd;  // 14
  static const double inputPadding = lg;       // 16

  // ── Grid ──────────────────────────────────────────────────────────────────
  static const double gridSpacing = md;        // 12
  static const int gridCols = 2;
}
