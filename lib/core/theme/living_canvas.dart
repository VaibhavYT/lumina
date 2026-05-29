import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/theme/app_colors.dart';

enum LivingCanvasPhase { morning, day, evening, windDown }

final livingCanvasProvider = StreamProvider<LivingCanvas>((ref) {
  final controller = StreamController<LivingCanvas>();

  void emit() {
    if (!controller.isClosed) {
      controller.add(LivingCanvas.resolve(DateTime.now()));
    }
  }

  emit();
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => emit());
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

@immutable
class LivingCanvas extends ThemeExtension<LivingCanvas> {
  const LivingCanvas({
    required this.phase,
    required this.instant,
    required this.fast,
    required this.standard,
    required this.slow,
    required this.xSlow,
    required this.curve,
    required this.springCurve,
    required this.typeRhythm,
    required this.contrast,
  });

  final LivingCanvasPhase phase;
  final Duration instant;
  final Duration fast;
  final Duration standard;
  final Duration slow;
  final Duration xSlow;
  final Curve curve;
  final Curve springCurve;
  final double typeRhythm;
  final double contrast;

  static LivingCanvas resolve(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 11) {
      return morning;
    }
    if (hour >= 11 && hour < 18) {
      return day;
    }
    if (hour >= 18 && hour < 23) {
      return evening;
    }
    return windDown;
  }

  static const morning = LivingCanvas(
    phase: LivingCanvasPhase.morning,
    instant: Duration(milliseconds: 70),
    fast: Duration(milliseconds: 150),
    standard: Duration(milliseconds: 260),
    slow: Duration(milliseconds: 420),
    xSlow: Duration(milliseconds: 680),
    curve: Curves.easeOutCubic,
    springCurve: Cubic(0.24, 1.22, 0.32, 1),
    typeRhythm: 0.98,
    contrast: 1.08,
  );

  static const day = LivingCanvas(
    phase: LivingCanvasPhase.day,
    instant: Duration(milliseconds: 80),
    fast: Duration(milliseconds: 180),
    standard: Duration(milliseconds: 300),
    slow: Duration(milliseconds: 500),
    xSlow: Duration(milliseconds: 800),
    curve: Curves.easeInOutCubic,
    springCurve: Curves.elasticOut,
    typeRhythm: 1,
    contrast: 1,
  );

  static const evening = LivingCanvas(
    phase: LivingCanvasPhase.evening,
    instant: Duration(milliseconds: 95),
    fast: Duration(milliseconds: 220),
    standard: Duration(milliseconds: 380),
    slow: Duration(milliseconds: 620),
    xSlow: Duration(milliseconds: 920),
    curve: Curves.easeInOutCubic,
    springCurve: Cubic(0.32, 0.9, 0.24, 1),
    typeRhythm: 1.04,
    contrast: 0.94,
  );

  static const windDown = LivingCanvas(
    phase: LivingCanvasPhase.windDown,
    instant: Duration(milliseconds: 180),
    fast: Duration(milliseconds: 360),
    standard: Duration(milliseconds: 800),
    slow: Duration(milliseconds: 920),
    xSlow: Duration(milliseconds: 1200),
    curve: Curves.easeInOut,
    springCurve: Curves.easeInOut,
    typeRhythm: 1.09,
    contrast: 0.82,
  );

  bool get isWindDown => phase == LivingCanvasPhase.windDown;

  String get label {
    return switch (phase) {
      LivingCanvasPhase.morning => 'Morning clarity',
      LivingCanvasPhase.day => 'Daylight focus',
      LivingCanvasPhase.evening => 'Evening warmth',
      LivingCanvasPhase.windDown => 'Wind down',
    };
  }

  AppColors colorsFor(AppColors base, Brightness brightness) {
    return switch (phase) {
      LivingCanvasPhase.morning => _morningColors(base, brightness),
      LivingCanvasPhase.day => base,
      LivingCanvasPhase.evening => _eveningColors(base, brightness),
      LivingCanvasPhase.windDown => _windDownColors(base, brightness),
    };
  }

  LinearGradient heroGradient(AppColors colors) {
    return switch (phase) {
      LivingCanvasPhase.morning => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primaryAccent.withValues(alpha: 0.24),
          colors.warningSoft.withValues(alpha: 0.58),
          Colors.transparent,
        ],
      ),
      LivingCanvasPhase.windDown => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.secondaryAccent.withValues(alpha: 0.10),
          colors.backgroundPrimary,
        ],
      ),
      _ => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          colors.primaryAccent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ),
    };
  }

  AppColors _morningColors(AppColors base, Brightness brightness) {
    final surfaceLift = brightness == Brightness.dark
        ? const Color(0xFF11111B)
        : const Color(0xFFFFFBF1);
    return base.copyWith(
      backgroundSecondary: Color.lerp(
        base.backgroundSecondary,
        surfaceLift,
        0.32,
      ),
      primaryAccent: Color.lerp(
        base.primaryAccent,
        const Color(0xFFFFB434),
        0.28,
      ),
      textPrimary: Color.lerp(base.textPrimary, Colors.white, 0.08),
      textSecondary: Color.lerp(base.textSecondary, base.textPrimary, 0.10),
    );
  }

  AppColors _eveningColors(AppColors base, Brightness brightness) {
    return base.copyWith(
      backgroundPrimary: Color.lerp(
        base.backgroundPrimary,
        brightness == Brightness.dark
            ? const Color(0xFF080811)
            : const Color(0xFFF4F0EC),
        0.32,
      ),
      primaryAccent: Color.lerp(
        base.primaryAccent,
        const Color(0xFFE19B51),
        0.22,
      ),
      textSecondary: Color.lerp(base.textSecondary, base.textTertiary, 0.12),
    );
  }

  AppColors _windDownColors(AppColors base, Brightness brightness) {
    const obsidian100 = Color(0xFF050509);
    const obsidian200 = Color(0xFF0B0B12);
    const obsidian300 = Color(0xFF11111A);

    if (brightness == Brightness.dark) {
      return base.copyWith(
        backgroundPrimary: obsidian100,
        backgroundSecondary: obsidian200,
        backgroundCard: obsidian300,
        backgroundElevated: const Color(0xFF171720),
        primaryAccent: Color.lerp(
          base.primaryAccent,
          const Color(0xFFB78A4C),
          0.45,
        ),
        secondaryAccent: Color.lerp(
          base.secondaryAccent,
          const Color(0xFF8B7AD6),
          0.32,
        ),
        textPrimary: Color.lerp(
          base.textPrimary,
          const Color(0xFFD9D5E4),
          0.24,
        ),
        textSecondary: Color.lerp(
          base.textSecondary,
          const Color(0xFF777284),
          0.34,
        ),
        textTertiary: Color.lerp(
          base.textTertiary,
          const Color(0xFF4E4A58),
          0.40,
        ),
        divider: const Color(0x10FFFFFF),
      );
    }

    return base.copyWith(
      backgroundPrimary: const Color(0xFFEDE9E2),
      backgroundSecondary: const Color(0xFFE4DFD7),
      backgroundCard: const Color(0xFFF7F4EE),
      backgroundElevated: const Color(0xFFFCF9F2),
      textPrimary: Color.lerp(base.textPrimary, const Color(0xFF25222B), 0.22),
      textSecondary: Color.lerp(
        base.textSecondary,
        const Color(0xFF77706B),
        0.28,
      ),
    );
  }

  @override
  LivingCanvas copyWith({
    LivingCanvasPhase? phase,
    Duration? instant,
    Duration? fast,
    Duration? standard,
    Duration? slow,
    Duration? xSlow,
    Curve? curve,
    Curve? springCurve,
    double? typeRhythm,
    double? contrast,
  }) {
    return LivingCanvas(
      phase: phase ?? this.phase,
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      standard: standard ?? this.standard,
      slow: slow ?? this.slow,
      xSlow: xSlow ?? this.xSlow,
      curve: curve ?? this.curve,
      springCurve: springCurve ?? this.springCurve,
      typeRhythm: typeRhythm ?? this.typeRhythm,
      contrast: contrast ?? this.contrast,
    );
  }

  @override
  LivingCanvas lerp(ThemeExtension<LivingCanvas>? other, double t) {
    if (other is! LivingCanvas) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}
