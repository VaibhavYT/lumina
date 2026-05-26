import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_colors.dart';

extension LuminaContext on BuildContext {
  AppColors get colors => AppColors.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
