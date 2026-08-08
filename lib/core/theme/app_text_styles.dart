import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography for HisabET.
///
/// ## Why IBM Plex Sans
///
/// It was drawn for IBM's enterprise and financial software: open apertures,
/// unambiguous `1/l/I` and `0/O`, and a slightly technical tone that reads as
/// institutional rather than consumer. It is also the difference between an
/// interface that looks considered and one that looks like every default.
///
/// ## The rule that matters most: tabular figures
///
/// Every number that represents money, quantity or a date **must** use
/// [tabularFeatures]. With proportional figures a `1` is narrower than a `8`,
/// so a balance visibly jitters as it updates and columns of amounts fail to
/// align. Real ledgers never do this. Use [moneyHero], [moneyLarge],
/// [moneyMedium], [moneySmall] or [tabular] — never a bare `GoogleFonts` call
/// for a numeric value.
///
/// ## Hierarchy
///
/// Contrast comes from size and weight, not colour. A screen should have one
/// dominant number, a few 14–16px labels, and 11px uppercase section markers.
/// If everything is 14px semibold, the screen reads as noise.
abstract final class AppTextStyles {
  /// Monospaced-width digits. Required for all numeric display.
  static const List<FontFeature> tabularFeatures = [
    FontFeature.tabularFigures(),
  ];

  // ── Base theme ───────────────────────────────────────────────────────────
  static TextTheme get textTheme => GoogleFonts.ibmPlexSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1.2),
          displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0),
          displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.8),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      );

  // ── Money & numerics ─────────────────────────────────────────────────────

  /// The one dominant number on a screen — a total balance.
  static TextStyle get moneyHero => GoogleFonts.ibmPlexSans(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.2,
        height: 1.05,
        fontFeatures: tabularFeatures,
      );

  /// Section totals, card headline figures.
  static TextStyle get moneyLarge => GoogleFonts.ibmPlexSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        fontFeatures: tabularFeatures,
      );

  /// Amount in a ledger row.
  static TextStyle get moneyMedium => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        fontFeatures: tabularFeatures,
      );

  /// Secondary figures, running balances.
  static TextStyle get moneySmall => GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFeatures: tabularFeatures,
      );

  /// Any non-money numeric that still needs to align (quantities, dates).
  static TextStyle get tabular => GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFeatures: tabularFeatures,
      );

  /// Currency code shown beside an amount — deliberately small and quiet so
  /// the digits stay dominant.
  static TextStyle get currencyMark => GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  // ── Headings ─────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.ibmPlexSans(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6);

  static TextStyle get headlineSmall => GoogleFonts.ibmPlexSans(
        fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3);

  static TextStyle get titleLarge => GoogleFonts.ibmPlexSans(
        fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2);

  /// AppBar title.
  static TextStyle get screenTitle => GoogleFonts.ibmPlexSans(
        fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2);

  /// Small uppercase marker above a group. The main structural device in this
  /// system — it replaces wrapping every group in its own floating card.
  static TextStyle get sectionLabel => GoogleFonts.ibmPlexSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: AppColors.textSecondary,
      );

  // ── Body & UI ────────────────────────────────────────────────────────────
  static TextStyle get bodyMedium => GoogleFonts.ibmPlexSans(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get cardTitle => GoogleFonts.ibmPlexSans(
        fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1);

  static TextStyle get cardSubtitle => GoogleFonts.ibmPlexSans(
        fontSize: 13, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle get formLabel => GoogleFonts.ibmPlexSans(
        fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get buttonLabel => GoogleFonts.ibmPlexSans(
        fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0);

  static TextStyle get badgeLabel => GoogleFonts.ibmPlexSans(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3);

  static TextStyle get labelSmall => GoogleFonts.ibmPlexSans(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  // ── Stats ────────────────────────────────────────────────────────────────
  static TextStyle get statValue => GoogleFonts.ibmPlexSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        fontFeatures: tabularFeatures,
      );

  static TextStyle get statLabel => GoogleFonts.ibmPlexSans(
        fontSize: 12, fontWeight: FontWeight.w400);

  // ── Amounts (semantic colour baked in) ───────────────────────────────────
  static TextStyle get amountPositive =>
      moneyMedium.copyWith(color: AppColors.positive);

  static TextStyle get amountNegative =>
      moneyMedium.copyWith(color: AppColors.negative);

  static TextStyle get amountNeutral => moneyMedium;

  /// Legacy alias — a hero balance rendered on a dark/branded surface.
  static TextStyle get heroAmount =>
      moneyHero.copyWith(color: AppColors.textOnPrimary);

  // ── On dark surfaces ─────────────────────────────────────────────────────
  static TextStyle get onDarkLabel => GoogleFonts.ibmPlexSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: Colors.white70,
      );

  static TextStyle get onDarkValue => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFeatures: tabularFeatures,
      );

  // ── Empty states ─────────────────────────────────────────────────────────
  static TextStyle get emptyTitle => GoogleFonts.ibmPlexSans(
        fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get emptySubtitle => GoogleFonts.ibmPlexSans(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);

  // ── Module cards ─────────────────────────────────────────────────────────
  static TextStyle get moduleTitle => GoogleFonts.ibmPlexSans(
        fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1);

  static TextStyle get moduleStat => GoogleFonts.ibmPlexSans(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.35);

  // ── Codes ────────────────────────────────────────────────────────────────
  /// Invoice numbers, promo codes, SKUs.
  static TextStyle get mono => GoogleFonts.ibmPlexMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
      );
}
