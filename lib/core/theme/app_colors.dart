import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundCard,
    required this.backgroundElevated,
    required this.primaryAccent,
    required this.primaryAccentSoft,
    required this.secondaryAccent,
    required this.secondaryAccentSoft,
    required this.successColor,
    required this.successSoft,
    required this.warningColor,
    required this.warningSoft,
    required this.errorColor,
    required this.errorSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundCard;
  final Color backgroundElevated;
  final Color primaryAccent;
  final Color primaryAccentSoft;
  final Color secondaryAccent;
  final Color secondaryAccentSoft;
  final Color successColor;
  final Color successSoft;
  final Color warningColor;
  final Color warningSoft;
  final Color errorColor;
  final Color errorSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const dark = AppColors(
    backgroundPrimary: Color(0xFF0A0A0F),
    backgroundSecondary: Color(0xFF111118),
    backgroundCard: Color(0xFF18181F),
    backgroundElevated: Color(0xFF1F1F28),
    primaryAccent: Color(0xFFF0A500),
    primaryAccentSoft: Color(0x1FF0A500),
    secondaryAccent: Color(0xFF7B61FF),
    secondaryAccentSoft: Color(0x1A7B61FF),
    successColor: Color(0xFF34C97B),
    successSoft: Color(0x1F34C97B),
    warningColor: Color(0xFFFF8C42),
    warningSoft: Color(0x1FFF8C42),
    errorColor: Color(0xFFFF4D6D),
    errorSoft: Color(0x1FFF4D6D),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFF8E8EA0),
    textTertiary: Color(0xFF48485A),
    divider: Color(0x14FFFFFF),
    shimmerBase: Color(0xFF1F1F28),
    shimmerHighlight: Color(0xFF2A2A35),
  );

  static const light = AppColors(
    backgroundPrimary: Color(0xFFF7F6F2),
    backgroundSecondary: Color(0xFFEFEDE8),
    backgroundCard: Color(0xFFFFFFFF),
    backgroundElevated: Color(0xFFFAFAF8),
    primaryAccent: Color(0xFFD4920A),
    primaryAccentSoft: Color(0x1FD4920A),
    secondaryAccent: Color(0xFF6B52E0),
    secondaryAccentSoft: Color(0x1A6B52E0),
    successColor: Color(0xFF2EAD68),
    successSoft: Color(0x1F2EAD68),
    warningColor: Color(0xFFE77E32),
    warningSoft: Color(0x1FE77E32),
    errorColor: Color(0xFFE74563),
    errorSoft: Color(0x1FE74563),
    textPrimary: Color(0xFF141414),
    textSecondary: Color(0xFF6B6B7A),
    textTertiary: Color(0xFFADADBB),
    divider: Color(0x14000000),
    shimmerBase: Color(0xFFEFEDE8),
    shimmerHighlight: Color(0xFFFFFFFF),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  @override
  AppColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundCard,
    Color? backgroundElevated,
    Color? primaryAccent,
    Color? primaryAccentSoft,
    Color? secondaryAccent,
    Color? secondaryAccentSoft,
    Color? successColor,
    Color? successSoft,
    Color? warningColor,
    Color? warningSoft,
    Color? errorColor,
    Color? errorSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundCard: backgroundCard ?? this.backgroundCard,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      primaryAccentSoft: primaryAccentSoft ?? this.primaryAccentSoft,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      secondaryAccentSoft: secondaryAccentSoft ?? this.secondaryAccentSoft,
      successColor: successColor ?? this.successColor,
      successSoft: successSoft ?? this.successSoft,
      warningColor: warningColor ?? this.warningColor,
      warningSoft: warningSoft ?? this.warningSoft,
      errorColor: errorColor ?? this.errorColor,
      errorSoft: errorSoft ?? this.errorSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      backgroundCard: Color.lerp(backgroundCard, other.backgroundCard, t)!,
      backgroundElevated: Color.lerp(
        backgroundElevated,
        other.backgroundElevated,
        t,
      )!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      primaryAccentSoft: Color.lerp(
        primaryAccentSoft,
        other.primaryAccentSoft,
        t,
      )!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      secondaryAccentSoft: Color.lerp(
        secondaryAccentSoft,
        other.secondaryAccentSoft,
        t,
      )!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
    );
  }
}
