import 'package:flutter/material.dart';

/// Central color system for HisabET.
///
/// ## Design intent — read before changing anything
///
/// This is a **ledger**. People settle real debts with it, in a market stall,
/// in daylight, on a cheap Android phone. The visual language is borrowed from
/// professional banking software, which means three rules:
///
/// 1. **The substrate is neutral, not branded.** Backgrounds and cards are
///    slate/white. The teal appears on *actions and identity only*. When a
///    brand colour is smeared across every surface, nothing reads as important
///    and the result looks like a template.
/// 2. **Depth is carried by hairlines, not shadows.** There is effectively one
///    elevation level. Shadows here are 3–6% black and exist only to lift
///    genuinely floating things (sheets, the nav bar). No gradients on
///    surfaces — they turn to mud in sunlight and read as decoration.
/// 3. **Colour is semantic, never decorative.** Green means money coming in,
///    red means money going out, amber means attention. If a colour is not
///    saying one of those things, it should be a neutral.
///
/// The neutral ramp is Tailwind's slate — cool, institutional, and already
/// contrast-verified. Text pairs are checked against WCAG AA (4.5:1 body).
abstract final class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────
  /// Primary brand: deep teal. Anchors the logo and the native splash screen
  /// (`flutter_native_splash.color` in pubspec.yaml) — keep those in sync.
  ///
  /// Reserved for: primary buttons, active nav, focus rings, selection.
  /// Never for: page backgrounds, card tints, decorative fills.
  static const Color primary = Color(0xFF004D40);
  static const Color primaryDark = Color(0xFF00332B);
  static const Color primaryLight = Color(0xFF0F5F52);

  /// Legible teal for dark surfaces — the deep primary fails contrast there.
  static const Color primaryBright = Color(0xFF5EEAD4);

  /// Low-chroma teal wash for selected rows and quiet emphasis.
  static const Color primaryContainer = Color(0xFFCCEDE8);

  /// Accent: gold. Deliberately darkened from the old #FFB300, which could not
  /// hold 3:1 against white. Use sparingly — badges, a rare highlight.
  static const Color accent = Color(0xFFA16207);
  static const Color accentLight = Color(0xFFFEF3C7);

  // ── Semantic: money direction ────────────────────────────────────────────
  /// Receivable / cash in / "they owe me".
  static const Color positive = Color(0xFF15803D);
  static const Color positiveLight = Color(0xFFF0FDF4);
  static const Color positiveMid = Color(0xFF4ADE80);

  /// Payable / cash out / "I owe them".
  static const Color negative = Color(0xFFB91C1C);
  static const Color negativeLight = Color(0xFFFEF2F2);
  static const Color negativeMid = Color(0xFFF87171);

  /// Attention: low stock, overdue, unconfirmed.
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningMid = Color(0xFFFBBF24);

  /// Neutral informational.
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoMid = Color(0xFF60A5FA);

  // ── Semantic on deep brand surfaces ──────────────────────────────────────
  // [positive] and [negative] are tuned for white backgrounds and go muddy on
  // the deep teal anchor panel. These lightened pairs clear WCAG AA (>4.5:1)
  // against [primary], so direction stays legible on the hero surface.
  static const Color positiveOnDark = Color(0xFF6EE7B7);
  static const Color negativeOnDark = Color(0xFFFCA5A5);

  // ── Ledger aliases ───────────────────────────────────────────────────────
  static const Color give = positive;
  static const Color giveLight = positiveLight;
  static const Color take = negative;
  static const Color takeLight = negativeLight;

  // ── Neutral ramp (slate) ─────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // ── Surfaces (light) ─────────────────────────────────────────────────────
  /// Page background. Neutral, *not* teal-tinted — a tinted ground was what
  /// forced every card to fight it with a gradient.
  static const Color background = neutral50;

  /// Card / sheet. Plain white: the banking default, maximum contrast for
  /// numbers, and readable in direct sun.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Quiet fill for inputs, chips, table headers.
  static const Color surfaceVariant = neutral100;

  /// Recessed wells (segmented controls, empty slots).
  static const Color surfaceSunken = neutral100;

  // ── Surfaces (dark) ──────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF141C2B);
  static const Color surfaceVariantDark = Color(0xFF1C2637);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral500;
  static const Color textTertiary = neutral400;
  static const Color textHint = neutral400;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = neutral50;

  // ── Lines ────────────────────────────────────────────────────────────────
  /// The workhorse of this system. Rows, sections and cards are separated by
  /// hairlines rather than by shadow or by being individually boxed.
  static const Color hairline = Color(0xFFEEF2F6);
  static const Color divider = hairline;
  static const Color border = neutral200;
  static const Color borderStrong = neutral300;
  static const Color borderFocused = primary;

  static const Color hairlineDark = Color(0xFF243044);
  static const Color borderDark = Color(0xFF2C394F);

  // ── Shadow ───────────────────────────────────────────────────────────────
  // Intentionally faint. If a shadow is visible as a shadow, it is too strong.
  static const Color shadowLight = Color(0x080F172A); // 3%
  static const Color shadowMedium = Color(0x0F0F172A); // 6%
  static const Color shadowStrong = Color(0x1A0F172A); // 10%

  /// Modal scrim — strong enough to isolate foreground content.
  static const Color overlayScrim = Color(0x800F172A); // 50%

  // ── Module accents (Business Hub) ────────────────────────────────────────
  // Muted one step from the previous near-black saturated set so twelve tiles
  // read as one family instead of twelve competing brands. These are
  // identifiers, not decoration: they appear as a small icon wash only.
  static const Color moduleSales = Color(0xFF0F766E);
  static const Color moduleInventory = Color(0xFF3730A3);
  static const Color modulePurchases = Color(0xFFC2410C);
  static const Color moduleOrders = Color(0xFFBE123C);
  static const Color moduleExpenses = Color(0xFF9D174D);
  static const Color moduleCashbook = Color(0xFF57534E);
  static const Color moduleReports = Color(0xFF6D28D9);
  static const Color moduleCustomers = Color(0xFF1D4ED8);
  static const Color moduleSuppliers = Color(0xFF115E59);
  static const Color modulePromotions = Color(0xFFA21CAF);
  static const Color moduleTeam = Color(0xFF0E7490);
  static const Color moduleSettings = Color(0xFF475569);
}
