import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/utils/haptic_utils.dart';
import 'package:lumina/features/dashboard/presentation/providers/dashboard_notifier.dart';
import 'package:lumina/shared/widgets/animated_counter.dart';
import 'package:lumina/shared/widgets/gradient_icon.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:lumina/shared/widgets/lumina_tag.dart';
import 'package:lumina/shared/widgets/shimmer_loader.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SnapshotRow extends StatelessWidget {
  const SnapshotRow({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allDone =
        state.tasks.isNotEmpty && state.completedTasks == state.tasks.length;

    return Row(
      children: [
        Expanded(
          child: SnapshotChip(
            icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            value: '${state.completedTasks}/${state.tasks.length}',
            label: 'Tasks',
            color: allDone ? colors.successColor : colors.textSecondary,
          ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child:
              SnapshotChip(
                    icon: PhosphorIcons.smiley(PhosphorIconsStyle.fill),
                    value: state.moodEntry?.emoji ?? '-',
                    label: 'Mood',
                    color: colors.secondaryAccent,
                  )
                  .animate(delay: 80.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.92, 0.92)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child:
              SnapshotChip(
                    icon: PhosphorIcons.fire(PhosphorIconsStyle.fill),
                    valueWidget: AnimatedCounter(
                      value: state.streak,
                      suffix: ' days',
                      textStyle: context.textTheme.headlineMedium?.copyWith(
                        color: colors.primaryAccent,
                      ),
                    ),
                    label: 'Streak',
                    color: colors.primaryAccent,
                  )
                  .animate(delay: 160.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.92, 0.92)),
        ),
      ],
    );
  }
}

class SnapshotChip extends StatelessWidget {
  const SnapshotChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          valueWidget ??
              Text(
                value ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.headlineMedium?.copyWith(color: color),
              ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMentorCard extends StatelessWidget {
  const DashboardMentorCard({super.key, required this.insight});

  final MentorInsight? insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryAccent.withValues(alpha: 0.45),
                colors.secondaryAccent.withValues(alpha: 0.22),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusXl - 1),
              color: colors.backgroundCard,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryAccent.withValues(alpha: 0.05),
                  colors.backgroundCard,
                ],
              ),
            ),
            child: insight == null
                ? _EmptyMentorState(colors: colors)
                : _InsightMentorState(insight: insight!, colors: colors),
          ),
        )
        .animate(delay: 220.ms)
        .fadeIn(duration: AppMotion.standard)
        .scale(begin: const Offset(0.95, 0.95), curve: AppMotion.enter);
  }
}

class _EmptyMentorState extends StatelessWidget {
  const _EmptyMentorState({required this.colors});

  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SparkleBadge(colors: colors),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your mentor is getting to know you',
          style: context.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Log your first day to unlock personalized insights.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LuminaButton(
          label: "Start Today's Log",
          icon: PhosphorIcons.arrowRight(),
          onPressed: () => context.go('/log'),
        ),
      ],
    );
  }
}

class _InsightMentorState extends StatelessWidget {
  const _InsightMentorState({required this.insight, required this.colors});

  final MentorInsight insight;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SparkleBadge(colors: colors, compact: true),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Mentor Insight',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.primaryAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(insight.headline, style: context.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          insight.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/mentor'),
            child: const Text('See full analysis ->'),
          ),
        ),
      ],
    );
  }
}

class _SparkleBadge extends StatelessWidget {
  const _SparkleBadge({required this.colors, this.compact = false});

  final dynamic colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 42.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryAccentSoft,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.36),
            blurRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: GradientIcon(
          icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
          size: compact ? 17 : 24,
          gradient: LinearGradient(
            colors: [colors.primaryAccent, colors.secondaryAccent],
          ),
        ),
      ),
    );
  }
}

class MentorCardSkeleton extends StatelessWidget {
  const MentorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(width: 120, height: 14),
          SizedBox(height: AppSpacing.md),
          ShimmerLoader(height: 24),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 14),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(width: 220, height: 14),
        ],
      ),
    );
  }
}

class TodaysFocusSection extends StatelessWidget {
  const TodaysFocusSection({
    super.key,
    required this.tasks,
    required this.onToggleTask,
  });

  final List<Task> tasks;
  final ValueChanged<String> onToggleTask;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = tasks.take(3).toList();
    final remaining = math.max(0, tasks.length - visibleTasks.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: "Today's Focus",
          actionLabel: 'Add +',
          onAction: () => context.go('/log'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visibleTasks.isEmpty)
          LuminaCard(
            child: Center(
              child: Text(
                'No tasks yet. A focused day starts here.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          )
        else
          for (final (index, task) in visibleTasks.indexed) ...[
            DashboardTaskTile(task: task, onTap: () => onToggleTask(task.id))
                .animate(delay: (80 * index).ms)
                .fadeIn()
                .slideY(begin: 0.08, end: 0),
            if (index != visibleTasks.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        if (remaining > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/log'),
              child: Text('$remaining more tasks ->'),
            ),
          ),
        ],
      ],
    );
  }
}

class DashboardTaskTile extends StatefulWidget {
  const DashboardTaskTile({super.key, required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  State<DashboardTaskTile> createState() => _DashboardTaskTileState();
}

class _DashboardTaskTileState extends State<DashboardTaskTile> {
  bool _flash = false;

  Future<void> _toggle() async {
    HapticUtils.success();
    setState(() => _flash = true);
    widget.onTap();
    await Future<void>.delayed(AppMotion.fast);
    if (mounted) {
      setState(() => _flash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final task = widget.task;

    return LuminaCard(
      onTap: _toggle,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: _flash ? colors.successSoft : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? colors.primaryAccent : null,
              border: Border.all(
                color: task.isCompleted ? colors.primaryAccent : colors.divider,
              ),
            ),
            child: AnimatedScale(
              duration: AppMotion.fast,
              scale: task.isCompleted ? 1 : 0,
              child: Icon(
                PhosphorIcons.check(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: context.textTheme.bodyLarge!.copyWith(
                color: task.isCompleted
                    ? colors.textSecondary
                    : colors.textPrimary,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: colors.primaryAccent,
                decorationThickness: 2,
              ),
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PriorityDot(priority: task.priority),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (priority) {
      TaskPriority.high => colors.primaryAccent,
      TaskPriority.normal => colors.textTertiary,
      TaskPriority.low => colors.divider,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class MoodCheckInBanner extends StatelessWidget {
  const MoodCheckInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
          onTap: () {
            HapticUtils.selection();
            context.go('/log');
          },
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.primaryAccentSoft,
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
              border: Border.all(
                color: colors.primaryAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.smiley(PhosphorIconsStyle.fill),
                  color: colors.secondaryAccent,
                ),
                const SizedBox(width: 6),
                Icon(
                  PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                  color: colors.secondaryAccent,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'How are you feeling right now?',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    color: context.isDark
                        ? colors.backgroundPrimary
                        : Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(
          begin: 1,
          end: 1.015,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        );
  }
}

class HabitRingsRow extends StatelessWidget {
  const HabitRingsRow({super.key, required this.habits});

  final List<HabitProgress> habits;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          itemCount: habits.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final habit = habits[index];
            return HabitRingWidget(habit: habit)
                .animate(delay: (60 * index).ms)
                .fadeIn()
                .slideY(begin: 0.12, end: 0);
          },
        ),
      ),
    );
  }
}

class HabitRingWidget extends StatelessWidget {
  const HabitRingWidget({super.key, required this.habit});

  final HabitProgress habit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: habit.progress),
            duration: AppMotion.xSlow,
            curve: AppMotion.enter,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _HabitRingPainter(
                  progress: value,
                  color: habit.color,
                  trackColor: context.colors.textTertiary.withValues(
                    alpha: 0.28,
                  ),
                ),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: Text(
                      habit.emoji,
                      style: const TextStyle(fontSize: 23),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            habit.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRingPainter extends CustomPainter {
  const _HabitRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = trackColor;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = color;

    canvas
      ..drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint)
      ..drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _HabitRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor;
  }
}

class EmptyHabitRhythmCard extends StatelessWidget {
  const EmptyHabitRhythmCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      onTap: () => context.go('/log'),
      child: Text(
        'Add habits in your daily log to track real completion rhythm here.',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class RealPatternsLinkCard extends StatelessWidget {
  const RealPatternsLinkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LuminaCard(
      onTap: () => context.go('/insights'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuminaTag(
                  label: 'Insights',
                  color: colors.primaryAccentSoft,
                  textColor: colors.primaryAccent,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Review patterns from your synced logs',
                  style: context.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Mood, energy, habits, and task trends are calculated from backend data.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            color: colors.textTertiary,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }
}

class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: LuminaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                color: context.colors.warningColor,
                size: 34,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Dashboard needs a refresh',
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Local data could not be read this time.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LuminaButton(label: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardLoadingSliver extends StatelessWidget {
  const DashboardLoadingSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        180,
        AppSpacing.pagePadding,
        120,
      ),
      sliver: SliverList.list(
        children: const [
          ShimmerLoader(height: 40, width: 220),
          SizedBox(height: AppSpacing.sectionGap),
          MentorCardSkeleton(),
          SizedBox(height: AppSpacing.md),
          ShimmerLoader(height: 72),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 72),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.textTheme.headlineMedium)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.textTheme.headlineMedium);
  }
}
