import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/insights/data/repositories/insights_repository.dart';
import 'package:lumina/shared/widgets/animated_counter.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:lumina/shared/widgets/lumina_tag.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TimeRangeFilter extends StatelessWidget {
  const TimeRangeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final InsightRange selected;
  final ValueChanged<InsightRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = InsightRange.values.indexOf(selected);

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        border: Border.all(color: colors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth =
              constraints.maxWidth / InsightRange.values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.fast,
                curve: AppMotion.standardCurve,
                left: segmentWidth * index,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryAccent,
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final range in InsightRange.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(range),
                        child: Center(
                          child: Text(
                            range.label,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: range == selected
                                  ? (context.isDark
                                        ? colors.backgroundPrimary
                                        : Colors.white)
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class MoodJourneyCard extends StatefulWidget {
  const MoodJourneyCard({super.key, required this.days});

  final List<InsightDay> days;

  @override
  State<MoodJourneyCard> createState() => _MoodJourneyCardState();
}

class _MoodJourneyCardState extends State<MoodJourneyCard> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final average = widget.days.isEmpty
        ? 0.0
        : widget.days.map((day) => day.mood).reduce((a, b) => a + b) /
              widget.days.length;
    final lineColor = average >= 4
        ? context.colors.successColor
        : average >= 3
        ? context.colors.primaryAccent
        : context.colors.warningColor;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood Journey', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTapDown: (details) => _selectPoint(details.localPosition),
            onHorizontalDragUpdate: (details) =>
                _selectPoint(details.localPosition),
            child: SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final selected = _selectedIndex == null
                      ? null
                      : widget.days[_selectedIndex!.clamp(
                          0,
                          widget.days.length - 1,
                        )];

                  return Stack(
                    children: [
                      RepaintBoundary(
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(widget.days.length),
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: AppMotion.xSlow,
                          curve: AppMotion.enter,
                          builder: (context, progress, child) {
                            return CustomPaint(
                              size: constraints.biggest,
                              painter: _MoodLinePainter(
                                days: widget.days,
                                color: lineColor,
                                progress: progress,
                                gridColor: context.colors.divider,
                                labelColor: context.colors.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                      if (selected != null)
                        AnimatedPositioned(
                          duration: AppMotion.fast,
                          curve: AppMotion.enter,
                          left: _pointX(
                            _selectedIndex!,
                            constraints.maxWidth,
                          ).clamp(0, constraints.maxWidth - 116),
                          top: 8,
                          child: Container(
                            width: 116,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.backgroundElevated,
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusMd,
                              ),
                              border: Border.all(color: context.colors.divider),
                            ),
                            child: Text(
                              '${DateFormat('E, d MMM').format(selected.date)} • ${_moodEmoji(selected.mood)} ${selected.mood}/5',
                              style: context.textTheme.labelSmall,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPoint(Offset position) {
    if (widget.days.isEmpty) {
      return;
    }
    final width = context.size?.width ?? 1;
    final index = ((position.dx / width) * (widget.days.length - 1)).round();
    setState(() => _selectedIndex = index.clamp(0, widget.days.length - 1));
  }

  double _pointX(int index, double width) {
    if (widget.days.length <= 1) {
      return 0;
    }
    return index / (widget.days.length - 1) * width;
  }
}

class _MoodLinePainter extends CustomPainter {
  const _MoodLinePainter({
    required this.days,
    required this.color,
    required this.progress,
    required this.gridColor,
    required this.labelColor,
  });

  final List<InsightDay> days;
  final Color color;
  final double progress;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(0, 0, size.width, size.height - 28);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (var i = 1; i <= 5; i++) {
      final y = chartRect.bottom - (i - 1) / 4 * chartRect.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (days.length < 2) {
      return;
    }

    final path = Path();
    for (var i = 0; i < days.length; i++) {
      final x = i / (days.length - 1) * size.width;
      final y = chartRect.bottom - (days[i].mood - 1) / 4 * chartRect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final areaPath = Path.from(path)
      ..lineTo(size.width, chartRect.bottom)
      ..lineTo(0, chartRect.bottom)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.38), color.withValues(alpha: 0)],
        ).createShader(chartRect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < days.length; i++) {
      final pointProgress = i / (days.length - 1);
      if (pointProgress <= progress) {
        final x = i / (days.length - 1) * size.width;
        final y = chartRect.bottom - (days[i].mood - 1) / 4 * chartRect.height;
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      }
    }
    canvas.restore();

    final labelStep = days.length <= 7
        ? 1
        : days.length <= 30
        ? 5
        : 14;
    for (var i = 0; i < days.length; i += labelStep) {
      textPainter.text = TextSpan(
        text: days[i].weekday,
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      textPainter.layout();
      final x = i / (days.length - 1) * size.width;
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartRect.bottom + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodLinePainter oldDelegate) {
    return days != oldDelegate.days ||
        color != oldDelegate.color ||
        progress != oldDelegate.progress ||
        gridColor != oldDelegate.gridColor ||
        labelColor != oldDelegate.labelColor;
  }
}

class EnergyPatternsCard extends StatelessWidget {
  const EnergyPatternsCard({super.key, required this.days});

  final List<InsightDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return LuminaCard(
        borderRadius: AppRadius.radiusXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Energy Patterns', style: context.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Log energy for a few days to reveal your real weekly rhythm.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = List.generate(7, (index) => <int>[]);
    for (final day in days) {
      grouped[day.date.weekday - 1].add(day.energy);
    }
    final averages = [
      for (final values in grouped)
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length,
    ];
    final bestIndex = averages.indexOf(averages.reduce(math.max));

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Energy Patterns', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 176,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppMotion.slow,
              curve: AppMotion.enter,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _EnergyBarPainter(
                    values: averages,
                    progress: value,
                    peakIndex: bestIndex,
                    color: context.colors.secondaryAccent,
                    labelColor: context.colors.textTertiary,
                    accent: context.colors.primaryAccent,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                color: context.colors.primaryAccent,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Your energy has been strongest on ${DateFormat('EEEE').format(DateTime(2024, 1, bestIndex + 1))} in this range.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyBarPainter extends CustomPainter {
  const _EnergyBarPainter({
    required this.values,
    required this.progress,
    required this.peakIndex,
    required this.color,
    required this.labelColor,
    required this.accent,
  });

  final List<double> values;
  final double progress;
  final int peakIndex;
  final Color color;
  final Color labelColor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 26;
    final barWidth = (size.width / 7) - 8;
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (var i = 0; i < 7; i++) {
      final centerX = size.width / 7 * i + size.width / 14;
      final value = values[i] == 0 ? 0.2 : values[i] / 5;
      final barHeight = chartHeight * value * progress;
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        chartHeight - barHeight,
        barWidth,
        math.max(8, barHeight),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            values[i] == 0 ? labelColor.withValues(alpha: 0.25) : color,
            values[i] == 0
                ? labelColor.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.65),
          ],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        paint,
      );
      if (i == peakIndex) {
        textPainter.text = TextSpan(
          text: '✦',
          style: TextStyle(color: accent, fontSize: 15),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(centerX - textPainter.width / 2, rect.top - 20),
        );
      }
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: labelColor, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyBarPainter oldDelegate) {
    return values != oldDelegate.values ||
        progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        labelColor != oldDelegate.labelColor ||
        accent != oldDelegate.accent;
  }
}

class BurnoutRiskCard extends StatelessWidget {
  const BurnoutRiskCard({super.key, required this.analysis});

  final BurnoutAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final riskColor = analysis.score <= 30
        ? context.colors.successColor
        : analysis.score <= 60
        ? context.colors.primaryAccent
        : context.colors.errorColor;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LuminaTag(
            label: 'Burnout Radar',
            icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
            color: context.colors.primaryAccentSoft,
            textColor: context.colors.primaryAccent,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SizedBox(
              width: 180,
              height: 134,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: analysis.score / 100),
                duration: AppMotion.xSlow,
                curve: AppMotion.enter,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _BurnoutGaugePainter(
                      progress: value,
                      track: context.colors.divider,
                      success: context.colors.successColor,
                      warning: context.colors.primaryAccent,
                      error: context.colors.errorColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 34),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedCounter(
                              value: analysis.score,
                              textStyle: context.textTheme.displayMedium
                                  ?.copyWith(color: riskColor),
                            ),
                            Text(
                              analysis.label,
                              style: context.textTheme.labelLarge?.copyWith(
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final signal in analysis.signals)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: signal.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      signal.label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BurnoutGaugePainter extends CustomPainter {
  const _BurnoutGaugePainter({
    required this.progress,
    required this.track,
    required this.success,
    required this.warning,
    required this.error,
  });

  final double progress;
  final Color track;
  final Color success;
  final Color warning;
  final Color error;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: [success, warning, error],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, basePaint);
    canvas.drawArc(rect, math.pi, math.pi * progress, false, progressPaint);

    final angle = math.pi + math.pi * progress;
    final needleEnd =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 18);
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = error.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = warning);
  }

  @override
  bool shouldRepaint(covariant _BurnoutGaugePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        track != oldDelegate.track ||
        success != oldDelegate.success ||
        warning != oldDelegate.warning ||
        error != oldDelegate.error;
  }
}

class HabitHeatmapCard extends StatelessWidget {
  const HabitHeatmapCard({super.key, required this.days});

  final List<InsightDay> days;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Habit Consistency', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          RepaintBoundary(
            child: SizedBox(
              height: 132,
              child: CustomPaint(
                painter: _HeatmapPainter(
                  days: days,
                  color: context.colors.secondaryAccent,
                  empty: context.colors.backgroundElevated,
                  label: context.colors.textTertiary,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({
    required this.days,
    required this.color,
    required this.empty,
    required this.label,
  });

  final List<InsightDay> days;
  final Color color;
  final Color empty;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 12.0;
    const gap = 4.0;
    final startX = 22.0;
    final startY = 22.0;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (final entry in days.indexed) {
      final index = entry.$1;
      final day = entry.$2;
      final column = index ~/ 7;
      final row = day.date.weekday - 1;
      final intensity = day.habitRate;
      final paint = Paint()
        ..color = intensity == 0
            ? empty
            : color.withValues(alpha: intensity.clamp(0.22, 1));
      final rect = Rect.fromLTWH(
        startX + column * (cell + gap),
        startY + row * (cell + gap),
        cell,
        cell,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      if (row == 0 && day.date.day <= 7) {
        textPainter.text = TextSpan(
          text: DateFormat('MMM').format(day.date),
          style: TextStyle(color: label, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(rect.left, 0));
      }
    }

    for (final item in const [('M', 0), ('W', 2), ('F', 4)]) {
      textPainter.text = TextSpan(
        text: item.$1,
        style: TextStyle(color: label, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, startY + item.$2 * (cell + gap) - 1));
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return days != oldDelegate.days ||
        color != oldDelegate.color ||
        empty != oldDelegate.empty ||
        label != oldDelegate.label;
  }
}

class ProductivityPatternsCard extends StatelessWidget {
  const ProductivityPatternsCard({super.key, required this.summary});

  final ProductivitySummary summary;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productivity Patterns',
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _RatioBar(
            label: 'Tasks added',
            value: 1,
            color: context.colors.backgroundElevated,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RatioBar(
            label: 'Completed',
            value: summary.completionRate,
            color: context.colors.successColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You complete ${(summary.completionRate * 100).round()}% of your daily tasks on average.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SmallMetricCard(
                  title: 'Best Day',
                  value: summary.bestDay,
                  color: context.colors.successColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SmallMetricCard(
                  title: 'Challenging Day',
                  value: summary.challengingDay,
                  color: context.colors.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.labelSmall),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 10, color: context.colors.divider),
                  AnimatedContainer(
                    duration: AppMotion.standard,
                    height: 10,
                    width: constraints.maxWidth * value.clamp(0, 1),
                    color: color,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(value, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class EmotionalTriggersCard extends StatelessWidget {
  const EmotionalTriggersCard({super.key, required this.triggers});

  final List<EmotionalTrigger> triggers;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emotional Triggers', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          if (triggers.isEmpty)
            Text(
              'Log your notes daily for 7 days to unlock emotional trigger analysis.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trigger in triggers)
                  GestureDetector(
                    onTap: () => _showTriggerSheet(context, trigger),
                    child: LuminaTag(
                      label:
                          '${trigger.tag} ${trigger.moodCorrelation >= 0 ? '↑' : '↓'}',
                      color: _triggerColor(
                        context,
                        trigger,
                      ).withValues(alpha: 0.15),
                      textColor: _triggerColor(context, trigger),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _triggerColor(BuildContext context, EmotionalTrigger trigger) {
    if (trigger.moodCorrelation > 0.3) {
      return context.colors.successColor;
    }
    if (trigger.moodCorrelation < -0.3) {
      return context.colors.errorColor;
    }
    return context.colors.textSecondary;
  }

  void _showTriggerSheet(BuildContext context, EmotionalTrigger trigger) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.backgroundElevated,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trigger.tag, style: context.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'On days you mention ${trigger.tag}, mood correlation is ${trigger.moodCorrelation.toStringAsFixed(2)} across ${trigger.frequency} entries.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class NotableStreaksRow extends StatelessWidget {
  const NotableStreaksRow({super.key, required this.days});

  final List<InsightDay> days;

  @override
  Widget build(BuildContext context) {
    final completedTasks = days
        .map((day) => day.tasksCompleted)
        .fold<int>(0, (a, b) => a + b);
    final goodMoodDays = days.where((day) => day.mood >= 4).length;
    final loggingStreak = _currentLoggingStreak(days);

    final cards = [
      (
        '🔥',
        '$loggingStreak',
        'Day Logging Streak',
        context.colors.primaryAccent,
      ),
      ('✓', '$completedTasks', 'Tasks Completed', context.colors.successColor),
      ('🙂', '$goodMoodDays', 'Good Mood Days', context.colors.secondaryAccent),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        itemCount: cards.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final card = cards[index];
          return Container(
            width: 148,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card.$4.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: card.$4.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.$1, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Text(card.$2, style: context.textTheme.headlineMedium),
                Text(
                  card.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

int _currentLoggingStreak(List<InsightDay> days) {
  final dates = days
      .map(
        (day) =>
            DateUtils.dateOnly(day.date).toIso8601String().substring(0, 10),
      )
      .toSet();
  var cursor = DateUtils.dateOnly(DateTime.now());
  var streak = 0;
  while (dates.contains(cursor.toIso8601String().substring(0, 10))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

String _moodEmoji(int mood) {
  return switch (mood) {
    1 => '😔',
    2 => '😕',
    3 => '😐',
    4 => '🙂',
    _ => '😄',
  };
}
