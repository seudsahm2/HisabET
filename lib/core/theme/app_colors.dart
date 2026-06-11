import 'package:flutter/material.dart';

/// Central color system for HisabET.
/// All colors are defined here — never use hardcoded Color values elsewhere.
/// This makes global rebranding a one-file change.
abstract final class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────
  /// Primary brand: Rich deep teal — communicates trust, money, reliability.
  static const Color primary = Color(0xFF004D40);
  static const Color primaryDark = Color(0xFF00251A);
  static const Color primaryLight = Color(0xFF39796B);
  static const Color primaryBright = Color(0xFF4DB6AC); // Vibrant teal for dark mode text
  static const Color primaryContainer = Color(0xFFB2DFDB); // for chip bg etc.

  /// Accent: Gold — premium, highlights, loyalty, badges.
  static const Color accent = Color(0xFFFFB300);
  static const Color accentLight = Color(0xFFFFF8E1);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// Positive / income / receivable / "give"
  static const Color positive = Color(0xFF2E7D32);
  static const Color positiveLight = Color(0xFFE8F5E9);
  static const Color positiveMid = Color(0xFF81C784);

  /// Negative / expense / payable / "take"
  static const Color negative = Color(0xFFC62828);
  static const Color negativeLight = Color(0xFFFFEBEE);
  static const Color negativeMid = Color(0xFFFF5252); // Vibrant Bright Red

  /// Warning / caution (low stock, overdue)
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningMid = Color(0xFFFFB74D);

  /// Info / neutral action
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoMid = Color(0xFF64B5F6);

  // ── Alias for legacy compat ──────────────────────────────────────────────
  static const Color give = positive;
  static const Color giveLight = positiveLight;
  static const Color take = negative;
  static const Color takeLight = negativeLight;

  // ── Neutral / Surface ────────────────────────────────────────────────────
  /// Main screen background
  static const Color background = Color(0xFFF1F7F4);

  /// Card / sheet surface
  static const Color surface = Color(0xFFF9FCFA);

  /// Elevated surface (modals, bottom sheets)
  static const Color surfaceElevated = Color(0xFFF7FBF9);

  /// Subtle container — for chips, input fills, section bg
  static const Color surfaceVariant = Color(0xFFE7F1EC);

  // ── Neutral Scale ────────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textHint = neutral400;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Divider / Border ─────────────────────────────────────────────────────
  static const Color divider = neutral200;
  static const Color border = neutral200;
  static const Color borderFocused = primary;

  // ── Shadow ───────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0A000000); // 4% black
  static const Color shadowMedium = Color(0x14000000); // 8% black
  static const Color shadowStrong = Color(0x1F000000); // 12% black

  // ── Module accent colors (used in Business Hub cards) ────────────────────
  static const Color moduleSales = Color(0xFF1B5E20);       // deep green
  static const Color moduleInventory = Color(0xFF1A237E);   // deep indigo
  static const Color modulePurchases = Color(0xFFE65100);   // deep orange
  static const Color moduleOrders = Color(0xFFB71C1C);      // deep red
  static const Color moduleExpenses = Color(0xFF880E4F);    // deep pink
  static const Color moduleCashbook = Color(0xFF3E2723);    // deep brown
  static const Color moduleReports = Color(0xFF4A148C);     // deep purple
  static const Color moduleCustomers = Color(0xFF0D47A1);   // deep blue
  static const Color moduleSuppliers = Color(0xFF004D40);   // primary teal
  static const Color modulePromotions = Color(0xFFAD1457);  // pink
  static const Color moduleTeam = Color(0xFF006064);        // cyan-teal
  static const Color moduleSettings = Color(0xFF37474F);    // blue grey
}
