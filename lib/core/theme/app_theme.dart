import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Complete Material 3 theme for HisabET.
/// Import only this class — it assembles colors, typography and component themes.
abstract final class AppTheme {
  static ThemeData get light => _build(brightness: Brightness.light);

  // Dark mode — for future use.
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0E1113) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF151A1C) : AppColors.surface;
    final elevatedSurfaceColor = isDark ? const Color(0xFF1B2124) : AppColors.surfaceElevated;
    final surfaceVariantColor = isDark ? const Color(0xFF21282B) : AppColors.surfaceVariant;
    final onSurfaceColor = isDark ? Colors.white : AppColors.textPrimary;
    final onSurfaceVariantColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final outlineColor = isDark ? Colors.white24 : AppColors.border;
    final outlineVariantColor = isDark ? Colors.white12 : AppColors.neutral200;
    final dividerColor = isDark ? Colors.white12 : AppColors.divider;
    final appBarColor = isDark ? const Color(0xFF151A1C) : AppColors.background;
    final navigationBarColor = isDark ? const Color(0xFF151A1C) : AppColors.surface;
    final inputFillColor = isDark ? const Color(0xFF1F2629) : AppColors.surfaceVariant;

    final positiveColor = isDark ? AppColors.positiveMid : AppColors.positive;
    final negativeColor = isDark ? AppColors.negativeMid : AppColors.negative;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: positiveColor,
      onSecondary: isDark ? Colors.black : Colors.white,
      secondaryContainer: isDark ? AppColors.positive.withValues(alpha: 0.2) : AppColors.positiveLight,
      onSecondaryContainer: positiveColor,
      tertiary: AppColors.accent,
      onTertiary: AppColors.primaryDark,
      tertiaryContainer: AppColors.accentLight,
      onTertiaryContainer: AppColors.primaryDark,
      error: negativeColor,
      onError: isDark ? Colors.black : Colors.white,
      errorContainer: isDark ? AppColors.negative.withValues(alpha: 0.2) : AppColors.negativeLight,
      onErrorContainer: negativeColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        surfaceContainerHighest: surfaceVariantColor,
        onSurfaceVariant: onSurfaceVariantColor,
        outline: outlineColor,
        outlineVariant: outlineVariantColor,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark ? Colors.white : AppColors.neutral900,
      onInverseSurface: isDark ? AppColors.neutral900 : Colors.white,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
      textTheme: AppTextStyles.textTheme,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: appBarColor,
        foregroundColor: onSurfaceColor,
        titleTextStyle: AppTextStyles.screenTitle.copyWith(
          color: onSurfaceColor,
        ),
        iconTheme: IconThemeData(
          color: onSurfaceColor,
          size: AppDimensions.iconMd,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: AppDimensions.bottomNavHeight,
        backgroundColor: navigationBarColor,
        indicatorColor: AppColors.primaryContainer.withValues(alpha: isDark ? 0.28 : 0.5),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.badgeLabel.copyWith(
            fontSize: 11,
            color: selected ? AppColors.primary : onSurfaceVariantColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.primary : onSurfaceVariantColor,
          );
        }),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: BorderSide(color: outlineVariantColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: BorderSide(color: outlineVariantColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide:
              const BorderSide(color: AppColors.borderFocused, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.negative),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide:
              const BorderSide(color: AppColors.negative, width: 2),
        ),
        labelStyle: AppTextStyles.formLabel,
        hintStyle: AppTextStyles.formLabel.copyWith(
          color: onSurfaceVariantColor,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: onSurfaceVariantColor,
        suffixIconColor: onSurfaceVariantColor,
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.neutral300,
          disabledForegroundColor: AppColors.neutral500,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize:
              const Size(0, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize:
              const Size(0, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonLabel,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.xs,
          ),
        ),
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedTextStyle: AppTextStyles.buttonLabel.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantColor,
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppTextStyles.badgeLabel.copyWith(
          color: onSurfaceColor,
        ),
        secondaryLabelStyle: AppTextStyles.badgeLabel.copyWith(
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: BorderSide.none,
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ── TabBar ────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.divider,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.badgeLabel.copyWith(fontSize: 13),
        unselectedLabelStyle:
            AppTextStyles.badgeLabel.copyWith(fontSize: 13),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.sm,
        ),
        titleTextStyle: AppTextStyles.cardTitle,
        subtitleTextStyle: AppTextStyles.cardSubtitle,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral900,
        contentTextStyle: AppTextStyles.cardSubtitle.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevatedSurfaceColor,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: outlineVariantColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXxl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: elevatedSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: AppTextStyles.cardTitle,
        contentTextStyle: AppTextStyles.cardSubtitle,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return outlineVariantColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryContainer;
          }
          return surfaceVariantColor;
        }),
      ),

      // ── Segmented Button ──────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          selectedBackgroundColor: AppColors.primaryContainer,
          foregroundColor: onSurfaceVariantColor,
          selectedForegroundColor: AppColors.primary,
          textStyle: AppTextStyles.badgeLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryContainer,
      ),

      // ── PopupMenu ─────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: AppTextStyles.cardSubtitle.copyWith(
          color: onSurfaceColor,
        ),
      ),
    );
  }
}
