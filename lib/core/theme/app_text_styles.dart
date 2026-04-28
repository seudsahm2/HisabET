import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale for HisabET using Inter from Google Fonts.
/// Use named styles everywhere — never define ad-hoc TextStyle in widgets.
abstract final class AppTextStyles {
  // ── Base font getter ─────────────────────────────────────────────────────
  /// Returns Inter TextTheme to be applied in ThemeData.
  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          // Material 3 roles mapped to our scale:
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      );

  // ── App-specific named styles ─────────────────────────────────────────────

  static final TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static final TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Screen title in AppBar
  static final TextStyle screenTitle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  /// Hero number / balance (big amount shown on cards)
  static final TextStyle heroAmount = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -1.0,
  );

  /// Card title
  static final TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Card subtitle / meta
  static final TextStyle cardSubtitle = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Section label (ALL CAPS small text above sections)
  static final TextStyle sectionLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  /// Stat value (large number in stat tiles)
  static final TextStyle statValue = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// Stat label (small label under stat value)
  static final TextStyle statLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Amount in transaction / sale tiles
  static final TextStyle amountPositive = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.positive,
  );

  static final TextStyle amountNegative = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.negative,
  );

  static final TextStyle amountNeutral = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Badge / chip label
  static final TextStyle badgeLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  /// Button label
  static final TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  /// Form label (above input)
  static final TextStyle formLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Empty state title
  static final TextStyle emptyTitle = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// Empty state subtitle
  static final TextStyle emptySubtitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// On dark (white text for gradient cards)
  static final TextStyle onDarkLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
    letterSpacing: 1.0,
  );

  static final TextStyle onDarkValue = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// Module card title
  static final TextStyle moduleTitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Module card subtitle
  static final TextStyle moduleStat = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// MonoSpace for codes (promo codes, invoices)
  static final TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 1.0,
  );
}
