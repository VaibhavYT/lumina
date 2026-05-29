import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/living_canvas.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(AppColors colors, {LivingCanvas? canvas}) {
    final rhythm = canvas?.typeRhythm ?? 1;

    return TextTheme(
      displayLarge: GoogleFonts.bricolageGrotesque(
        color: colors.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 42 / 36 * rhythm,
        letterSpacing: 0,
      ),
      displayMedium: GoogleFonts.bricolageGrotesque(
        color: colors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 34 / 28 * rhythm,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.bricolageGrotesque(
        color: colors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22 * rhythm,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        color: colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 24 / 18 * rhythm,
        letterSpacing: 0,
      ),
      bodyLarge: GoogleFonts.dmSans(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16 * rhythm,
        letterSpacing: 0,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: colors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14 * rhythm,
        letterSpacing: 0,
      ),
      bodySmall: GoogleFonts.dmSans(
        color: colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12 * rhythm,
        letterSpacing: 0,
      ),
      labelLarge: GoogleFonts.dmSans(
        color: colors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 18 / 14 * rhythm,
        letterSpacing: 0,
      ),
      labelSmall: GoogleFonts.dmSans(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11 * rhythm,
        letterSpacing: 0,
      ),
    );
  }

  static TextStyle monoSmall(BuildContext context) {
    final colors = AppColors.of(context);
    return GoogleFonts.jetBrainsMono(
      color: colors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
      letterSpacing: 0,
    );
  }
}
