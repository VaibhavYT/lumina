import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/onboarding/data/onboarding_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 1850), _continue);
  }

  void _continue() {
    if (!mounted) {
      return;
    }
    final completed = const OnboardingRepository().hasCompleted;
    context.go(completed ? '/' : '/onboarding');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 196,
                    height: 196,
                    child: CustomPaint(
                      painter: _SplashOrbitPainter(
                        progress: _controller.value,
                        amber: colors.primaryAccent,
                        indigo: colors.secondaryAccent,
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale:
                              0.96 +
                              math.sin(_controller.value * math.pi * 2) * 0.02,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(42),
                            child: Image.asset(
                              'assets/images/lumina_app_icon.png',
                              width: 118,
                              height: 118,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Lumina', style: context.textTheme.displayLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your inner light, noticed.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashOrbitPainter extends CustomPainter {
  const _SplashOrbitPainter({
    required this.progress,
    required this.amber,
    required this.indigo,
  });

  final double progress;
  final Color amber;
  final Color indigo;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.43;
    final orbit = Paint()
      ..color = amber.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, orbit);

    for (var index = 0; index < 3; index++) {
      final angle = (progress + index / 3) * math.pi * 2;
      final sparkCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final spark = Paint()
        ..color = index == 1 ? indigo : amber
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sparkCenter, index == 1 ? 3.4 : 4.2, spark);
      canvas.drawCircle(
        sparkCenter,
        index == 1 ? 7.2 : 8.4,
        Paint()..color = spark.color.withValues(alpha: 0.14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashOrbitPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        amber != oldDelegate.amber ||
        indigo != oldDelegate.indigo;
  }
}
