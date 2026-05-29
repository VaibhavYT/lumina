import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/living_canvas.dart';

extension LuminaContext on BuildContext {
  AppColors get colors => AppColors.of(this);

  LivingCanvas get livingCanvas =>
      Theme.of(this).extension<LivingCanvas>() ??
      LivingCanvas.resolve(DateTime.now());

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
