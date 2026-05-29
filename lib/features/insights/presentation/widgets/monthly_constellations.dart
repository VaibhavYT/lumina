import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/insights/data/repositories/insights_repository.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:lumina/shared/widgets/lumina_tag.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MonthlyConstellationsCard extends StatelessWidget {
  const MonthlyConstellationsCard({super.key, required this.retrospective});

  final MonthlyRetrospective retrospective;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      backgroundColor: colors.backgroundElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LuminaTag(
                label: '60s story',
                color: colors.primaryAccentSoft,
                textColor: colors.primaryAccent,
                icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              ),
              const Spacer(),
              Text(
                retrospective.monthLabel,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(retrospective.title, style: context.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            retrospective.hasEnoughData
                ? 'Your mood points become stars, then tell the story of how far you came.'
                : 'Log a few more days to unlock your first constellation story.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: _MoodConstellationChart(
              days: retrospective.days,
              progress: 1,
              showLabels: false,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ConstellationMetric(
                  label: 'Logged days',
                  value: '${retrospective.loggedDays}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ConstellationMetric(
                  label: 'Habit streak',
                  value: '${retrospective.longestHabitStreak}d',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LuminaButton(
            label: retrospective.hasEnoughData
                ? 'Play Monthly Story'
                : 'Keep Logging',
            icon: PhosphorIcons.play(),
            onPressed: retrospective.hasEnoughData
                ? () => _openStory(context, retrospective)
                : null,
          ),
        ],
      ),
    );
  }

  void _openStory(BuildContext context, MonthlyRetrospective retrospective) {
    final canvas = context.livingCanvas;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: canvas.slow,
        reverseTransitionDuration: canvas.fast,
        pageBuilder: (context, animation, secondaryAnimation) {
          return MonthlyConstellationsStory(retrospective: retrospective);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: canvas.curve),
            child: child,
          );
        },
      ),
    );
  }
}

class MonthlyConstellationsStory extends StatefulWidget {
  const MonthlyConstellationsStory({super.key, required this.retrospective});

  final MonthlyRetrospective retrospective;

  @override
  State<MonthlyConstellationsStory> createState() =>
      _MonthlyConstellationsStoryState();
}

class _MonthlyConstellationsStoryState extends State<MonthlyConstellationsStory>
    with SingleTickerProviderStateMixin {
  static const _chapterCount = 4;
  static const _chapterDuration = Duration(seconds: 15);

  late final AnimationController _progressController;
  var _chapter = 0;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(vsync: this, duration: _chapterDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _next(automatic: true);
            }
          });
    unawaited(_progressController.forward());
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _restartChapter() {
    _progressController
      ..reset()
      ..forward();
  }

  void _next({bool automatic = false}) {
    if (_chapter >= _chapterCount - 1) {
      if (automatic) {
        _progressController.stop();
      }
      return;
    }
    setState(() => _chapter += 1);
    _restartChapter();
  }

  void _previous() {
    if (_chapter == 0) {
      return;
    }
    setState(() => _chapter -= 1);
    _restartChapter();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canvas = context.livingCanvas;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundSecondary,
              colors.backgroundPrimary,
              colors.backgroundPrimary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _StorySkyPainter(
                      progress: _progressController.value,
                      color: colors.primaryAccent,
                      secondary: colors.secondaryAccent,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return _StoryProgress(
                                chapter: _chapter,
                                chapterCount: _chapterCount,
                                progress: _progressController.value,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: colors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: canvas.standard,
                        switchInCurve: canvas.curve,
                        switchOutCurve: AppMotion.exit,
                        child: KeyedSubtree(
                          key: ValueKey(_chapter),
                          child: _chapterWidget(_chapter),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _chapter == 0 ? null : _previous,
                          icon: const Icon(Icons.chevron_left),
                          color: colors.textPrimary,
                        ),
                        const Spacer(),
                        Text(
                          '${_chapter + 1}/$_chapterCount',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _chapter == _chapterCount - 1
                              ? null
                              : () => _next(),
                          icon: const Icon(Icons.chevron_right),
                          color: colors.textPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chapterWidget(int chapter) {
    return switch (chapter) {
      0 => _StarsChapter(retrospective: widget.retrospective),
      1 => _HabitChapter(retrospective: widget.retrospective),
      2 => _EnergyChapter(retrospective: widget.retrospective),
      _ => _TriggerChapter(retrospective: widget.retrospective),
    };
  }
}

class _StarsChapter extends StatelessWidget {
  const _StarsChapter({required this.retrospective});

  final MonthlyRetrospective retrospective;

  @override
  Widget build(BuildContext context) {
    return _StoryChapterFrame(
      eyebrow: retrospective.monthLabel,
      title: 'Your month became a constellation',
      body:
          '${retrospective.loggedDays} logged days. Average mood: ${retrospective.averageMood.toStringAsFixed(1)}/5.',
      visual: _MoodConstellationChart(
        days: retrospective.days,
        progress: 1,
        showLabels: true,
      ),
    );
  }
}

class _HabitChapter extends StatelessWidget {
  const _HabitChapter({required this.retrospective});

  final MonthlyRetrospective retrospective;

  @override
  Widget build(BuildContext context) {
    return _StoryChapterFrame(
      eyebrow: 'Consistency',
      title: 'You kept returning',
      body:
          'Your longest habit streak was ${retrospective.longestHabitStreak} days. That is proof of return, not perfection.',
      visual: _HabitOrbit(streak: retrospective.longestHabitStreak),
    );
  }
}

class _EnergyChapter extends StatelessWidget {
  const _EnergyChapter({required this.retrospective});

  final MonthlyRetrospective retrospective;

  @override
  Widget build(BuildContext context) {
    return _StoryChapterFrame(
      eyebrow: 'Energy',
      title: 'Your rhythm had a shape',
      body: retrospective.energyStory,
      visual: _EnergyStoryChart(days: retrospective.days),
    );
  }
}

class _TriggerChapter extends StatelessWidget {
  const _TriggerChapter({required this.retrospective});

  final MonthlyRetrospective retrospective;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StoryChapterFrame(
            eyebrow: 'Brightest trigger',
            title: retrospective.positiveTrigger == null
                ? 'Your language is still becoming data'
                : '"${retrospective.positiveTriggerLabel}" kept glowing',
            body: retrospective.positiveTrigger == null
                ? 'Keep adding notes. Lumina will learn which moments bring you back to yourself.'
                : 'This was the most positive trigger in your notes across ${retrospective.positiveTrigger!.frequency} entries.',
            visual: _TriggerStar(trigger: retrospective.positiveTriggerLabel),
          ),
        ),
        LuminaButton(
          label: 'Copy Share Card',
          icon: PhosphorIcons.shareNetwork(),
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: retrospective.shareText),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Monthly recap copied'),
                    backgroundColor: colors.backgroundElevated,
                  ),
                );
            }
          },
        ),
      ],
    );
  }
}

class _StoryChapterFrame extends StatelessWidget {
  const _StoryChapterFrame({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.visual,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.primaryAccent,
          ),
        ).animate().fadeIn(duration: context.livingCanvas.fast),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: context.textTheme.displayLarge)
            .animate(delay: 120.ms)
            .fadeIn(duration: context.livingCanvas.standard)
            .slideY(begin: 0.08, end: 0),
        const SizedBox(height: AppSpacing.md),
        Text(
          body,
          style: context.textTheme.bodyLarge?.copyWith(
            color: colors.textSecondary,
          ),
        ).animate(delay: 220.ms).fadeIn(duration: context.livingCanvas.slow),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: Center(
            child: visual
                .animate(delay: 320.ms)
                .fadeIn(duration: context.livingCanvas.slow)
                .scale(
                  begin: const Offset(0.96, 0.96),
                  end: const Offset(1, 1),
                  curve: context.livingCanvas.curve,
                ),
          ),
        ),
      ],
    );
  }
}

class _MoodConstellationChart extends StatelessWidget {
  const _MoodConstellationChart({
    required this.days,
    required this.progress,
    required this.showLabels,
  });

  final List<InsightDay> days;
  final double progress;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moodDays = days.where((day) => day.mood > 0).toList();
    if (moodDays.length < 2) {
      return Center(
        child: Text(
          'Log at least 3 mood entries to form a constellation.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final visibleCount = (moodDays.length * progress).ceil().clamp(
      2,
      moodDays.length,
    );
    final visibleDays = moodDays.take(visibleCount).toList();
    final spots = [
      for (final entry in visibleDays.indexed)
        FlSpot(entry.$1.toDouble(), entry.$2.mood.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, moodDays.length - 1).toDouble(),
        minY: 1,
        maxY: 5,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: showLabels,
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showLabels,
              reservedSize: 30,
              interval: math.max(1.0, moodDays.length / 4),
              getTitlesWidget: (value, meta) {
                final index = value.round().clamp(0, moodDays.length - 1);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d MMM').format(moodDays[index].date),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.24,
            barWidth: 2.4,
            color: colors.primaryAccent,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.primaryAccent.withValues(alpha: 0.22),
                  colors.secondaryAccent.withValues(alpha: 0.02),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: index == spots.length - 1 ? 5.5 : 4.2,
                  color: Colors.white,
                  strokeWidth: 2.2,
                  strokeColor: colors.primaryAccent,
                );
              },
            ),
          ),
        ],
      ),
      duration: context.livingCanvas.xSlow,
      curve: context.livingCanvas.curve,
    );
  }
}

class _EnergyStoryChart extends StatelessWidget {
  const _EnergyStoryChart({required this.days});

  final List<InsightDay> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final energyDays = days.where((day) => day.energy > 0).toList();
    if (energyDays.length < 2) {
      return Text(
        'Energy data will appear here after a few logs.',
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      );
    }

    final spots = [
      for (final entry in energyDays.indexed)
        FlSpot(entry.$1.toDouble(), entry.$2.energy.toDouble()),
    ];

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, energyDays.length - 1).toDouble(),
          minY: 1,
          maxY: 5,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: colors.divider, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.28,
              barWidth: 4,
              gradient: LinearGradient(
                colors: [colors.secondaryAccent, colors.primaryAccent],
              ),
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.secondaryAccent.withValues(alpha: 0.24),
                    colors.primaryAccent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: context.livingCanvas.xSlow,
        curve: context.livingCanvas.curve,
      ),
    );
  }
}

class _HabitOrbit extends StatelessWidget {
  const _HabitOrbit({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 260,
      height: 260,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: streak.clamp(0, 30) / 30),
        duration: context.livingCanvas.xSlow,
        curve: context.livingCanvas.curve,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _HabitOrbitPainter(
              progress: value,
              color: colors.primaryAccent,
              secondary: colors.secondaryAccent,
              track: colors.divider,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$streak', style: context.textTheme.displayLarge),
                  Text(
                    'day streak',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TriggerStar extends StatelessWidget {
  const _TriggerStar({required this.trigger});

  final String trigger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.primaryAccent.withValues(alpha: 0.30),
                      colors.secondaryAccent.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: const Duration(milliseconds: 2200),
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.06, 1.06),
              ),
          Icon(
            PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
            color: colors.primaryAccent,
            size: 68,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 142),
            child: Text(
              trigger,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstellationMetric extends StatelessWidget {
  const _ConstellationMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.textTheme.headlineMedium?.copyWith(
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({
    required this.chapter,
    required this.chapterCount,
    required this.progress,
  });

  final int chapter;
  final int chapterCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        for (var index = 0; index < chapterCount; index++) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: index < chapter
                    ? 1.0
                    : index == chapter
                    ? progress
                    : 0.0,
                backgroundColor: colors.divider,
                color: colors.primaryAccent,
              ),
            ),
          ),
          if (index != chapterCount - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _HabitOrbitPainter extends CustomPainter {
  const _HabitOrbitPainter({
    required this.progress,
    required this.color,
    required this.secondary,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color secondary;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 18;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = track,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12
        ..shader = SweepGradient(
          colors: [color, secondary, color],
        ).createShader(rect),
    );
    final angle = -math.pi / 2 + math.pi * 2 * progress;
    final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(dot, 8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HabitOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.secondary != secondary ||
        oldDelegate.track != track;
  }
}

class _StorySkyPainter extends CustomPainter {
  const _StorySkyPainter({
    required this.progress,
    required this.color,
    required this.secondary,
  });

  final double progress;
  final Color color;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 36; index++) {
      final seed = index * 97.31;
      final x = (math.sin(seed) * 0.5 + 0.5) * size.width;
      final y = (math.cos(seed * 1.7 + progress) * 0.5 + 0.5) * size.height;
      final pulse = (math.sin(progress * math.pi * 2 + index) + 1) / 2;
      paint.color = Color.lerp(
        color,
        secondary,
        pulse,
      )!.withValues(alpha: 0.06 + pulse * 0.12);
      canvas.drawCircle(Offset(x, y), 1.4 + pulse * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StorySkyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.secondary != secondary;
  }
}
