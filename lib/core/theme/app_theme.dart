import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_shadows.dart';
import 'package:lumina/core/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark =>
      _buildTheme(colors: AppColors.dark, brightness: Brightness.dark);

  static ThemeData get light =>
      _buildTheme(colors: AppColors.light, brightness: Brightness.light);

  static ThemeData _buildTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.backgroundPrimary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primaryAccent,
        onPrimary: isDark ? colors.backgroundPrimary : Colors.white,
        secondary: colors.secondaryAccent,
        onSecondary: Colors.white,
        error: colors.errorColor,
        onError: Colors.white,
        surface: colors.backgroundCard,
        onSurface: colors.textPrimary,
      ),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        titleTextStyle: textTheme.headlineMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: colors.primaryAccent,
        unselectedItemColor: colors.textTertiary,
      ),
      cardTheme: CardThemeData(
        color: colors.backgroundCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: isDark ? Colors.transparent : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          side: BorderSide(color: colors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.backgroundSecondary,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
        border: _inputBorder(colors.divider),
        enabledBorder: _inputBorder(colors.divider),
        focusedBorder: _inputBorder(colors.primaryAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          foregroundColor: isDark ? colors.backgroundPrimary : Colors.white,
          backgroundColor: colors.primaryAccent,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryAccent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.backgroundElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: isDark ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          side: BorderSide(color: colors.divider),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.backgroundElevated,
        elevation: isDark ? 0 : 18,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.divider),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      borderSide: BorderSide(color: color),
    );
  }

  static List<BoxShadow> cardShadowFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const []
        : AppShadows.cardShadow;
  }
}
