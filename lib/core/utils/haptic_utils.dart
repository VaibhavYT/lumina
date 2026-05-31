import 'package:flutter/services.dart';

enum HapticTexture { soft, focused, celebratory }

class HapticUtils {
  const HapticUtils._();

  static Future<void> light() => HapticFeedback.lightImpact();

  static Future<void> medium() => HapticFeedback.mediumImpact();

  static Future<void> success() => HapticFeedback.heavyImpact();

  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> typewriterPurr({
    required int index,
    required String character,
    HapticTexture texture = HapticTexture.soft,
  }) async {
    if (character.trim().isEmpty) {
      return;
    }
    final cadence = switch (texture) {
      HapticTexture.soft => 4,
      HapticTexture.focused => 3,
      HapticTexture.celebratory => 5,
    };
    if (index % cadence != 0) {
      return;
    }
    await HapticFeedback.selectionClick();
  }
}
