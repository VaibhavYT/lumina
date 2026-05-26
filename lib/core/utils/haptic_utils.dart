import 'package:flutter/services.dart';

class HapticUtils {
  const HapticUtils._();

  static Future<void> light() => HapticFeedback.lightImpact();

  static Future<void> medium() => HapticFeedback.mediumImpact();

  static Future<void> success() => HapticFeedback.heavyImpact();

  static Future<void> selection() => HapticFeedback.selectionClick();
}
