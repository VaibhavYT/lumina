import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/goals/data/repositories/goal_repository.dart';
import 'package:lumina/features/goals/presentation/providers/goal_notifier.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:lumina/shared/widgets/lumina_tag.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum _GoalAction { edit, replace, delete }

enum _GoalSheetMode { create, edit, replace }

class GoalDashboardCard extends ConsumerWidget {
  const GoalDashboardCard({
    super.key,
    required this.snapshot,
    required this.onGoalChanged,
  });

  final GoalSnapshot snapshot;
  final VoidCallback onGoalChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final goal = snapshot.goal;

    if (goal == null) {
      return LuminaCard(
        borderRadius: AppRadius.radiusXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryAccentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                  ),
                  child: Icon(
                    PhosphorIcons.target(PhosphorIconsStyle.fill),
                    color: colors.primaryAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Set a big goal - your AI mentor will break it down',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LuminaButton(
              label: 'Set a Goal ->',
              icon: PhosphorIcons.arrowRight(),
              onPressed: () =>
                  _showGoalSheet(context, mode: _GoalSheetMode.create),
            ),
          ],
        ),
      );
    }

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      backgroundColor: colors.primaryAccentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LuminaTag(
                label: 'Goal set',
                color: colors.backgroundCard,
                textColor: colors.primaryAccent,
                icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              ),
              const Spacer(),
              PopupMenuButton<_GoalAction>(
                tooltip: 'Goal options',
                color: colors.backgroundElevated,
                icon: Icon(
                  PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold),
                  color: colors.textSecondary,
                ),
                onSelected: (action) =>
                    _handleAction(context, ref, goal, action),
                itemBuilder: (context) => [
                  _goalMenuItem(
                    _GoalAction.edit,
                    'Edit goal',
                    PhosphorIcons.pencilSimple(),
                  ),
                  _goalMenuItem(
                    _GoalAction.replace,
                    'Replace goal',
                    PhosphorIcons.arrowsClockwise(),
                  ),
                  _goalMenuItem(
                    _GoalAction.delete,
                    'Delete goal',
                    PhosphorIcons.trash(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Goal set! Your first tasks are ready.',
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(goal.title, style: context.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            snapshot.justCreatedSummary ?? goal.summary,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (snapshot.todaysTasks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Today\'s goal tasks', style: context.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final task in snapshot.todaysTasks.take(3)) ...[
              _GoalTaskPreview(
                title: task.title,
                isCompleted: task.isCompleted,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }

  PopupMenuItem<_GoalAction> _goalMenuItem(
    _GoalAction value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ActiveGoal goal,
    _GoalAction action,
  ) async {
    switch (action) {
      case _GoalAction.edit:
        await _showGoalSheet(
          context,
          mode: _GoalSheetMode.edit,
          existingGoal: goal,
        );
        return;
      case _GoalAction.replace:
        await _showGoalSheet(
          context,
          mode: _GoalSheetMode.replace,
          existingGoal: goal,
        );
        return;
      case _GoalAction.delete:
        await _deleteGoal(context, ref, goal);
        return;
    }
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    ActiveGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this goal?'),
        content: const Text(
          'Lumina will remove its generated tasks from your daily plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id);
      if (!context.mounted) {
        return;
      }
      onGoalChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal and generated tasks deleted.')),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the goal.')),
        );
      }
    }
  }

  Future<void> _showGoalSheet(
    BuildContext context, {
    required _GoalSheetMode mode,
    ActiveGoal? existingGoal,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXl),
        ),
      ),
      builder: (context) => _GoalSheet(
        mode: mode,
        existingGoal: existingGoal,
        onGoalChanged: onGoalChanged,
      ),
    );
  }
}

class _GoalTaskPreview extends StatelessWidget {
  const _GoalTaskPreview({required this.title, required this.isCompleted});

  final String title;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.backgroundCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                : PhosphorIcons.circle(),
            color: isCompleted ? colors.successColor : colors.primaryAccent,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.snapshot});

  final GoalSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final goal = snapshot.goal;
    final stats = snapshot.stats;
    if (goal == null || stats == null) {
      return const SizedBox.shrink();
    }

    final statusColor = switch (stats.status) {
      'Ahead' => colors.successColor,
      'Behind' => colors.errorColor,
      _ => colors.primaryAccent,
    };

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Goal Progress',
                  style: context.textTheme.headlineMedium,
                ),
              ),
              LuminaTag(
                label: stats.status,
                color: statusColor.withValues(alpha: 0.14),
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(goal.title, style: context.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 10, color: colors.divider),
                    AnimatedContainer(
                      duration: AppMotion.standard,
                      height: 10,
                      width:
                          constraints.maxWidth * stats.weekProgress.clamp(0, 1),
                      color: colors.primaryAccent,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Week ${stats.weeksElapsed} of ${stats.totalWeeks}',
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
          if (stats.currentMilestone != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              stats.currentMilestone!.title,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              stats.currentMilestone!.description,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({
    required this.mode,
    required this.onGoalChanged,
    this.existingGoal,
  });

  final _GoalSheetMode mode;
  final VoidCallback onGoalChanged;
  final ActiveGoal? existingGoal;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  static const _loadingMessages = [
    'Analyzing your goal...',
    'Building your phase plan...',
    "Creating your first week's tasks...",
  ];

  final _goalController = TextEditingController();
  final _contextController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 60));
  var _isLoading = false;
  var _messageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.mode == _GoalSheetMode.edit && widget.existingGoal != null) {
      _goalController.text = widget.existingGoal!.title;
      _targetDate = widget.existingGoal!.targetDate;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _goalController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.isBefore(firstDate) ? firstDate : _targetDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = _goalController.text.trim();
    if (title.length < 4) {
      _showSnack('Tell Lumina the goal first.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _messageIndex = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1).clamp(
          0,
          _loadingMessages.length - 1,
        );
      });
    });

    try {
      final notifier = ref.read(goalNotifierProvider.notifier);
      switch (widget.mode) {
        case _GoalSheetMode.create:
          await notifier.setGoal(
            title: title,
            targetDate: _targetDate,
            context: _contextController.text,
          );
          break;
        case _GoalSheetMode.edit:
          await notifier.updateGoal(
            goalId: widget.existingGoal!.id,
            title: title,
            targetDate: _targetDate,
            context: _contextController.text,
          );
          break;
        case _GoalSheetMode.replace:
          await notifier.replaceGoal(
            goalId: widget.existingGoal!.id,
            title: title,
            targetDate: _targetDate,
            context: _contextController.text,
          );
          break;
      }
      if (!mounted) {
        return;
      }
      widget.onGoalChanged();
      Navigator.of(context).pop();
      _showSnack(
        widget.mode == _GoalSheetMode.create
            ? 'Goal set. Your first tasks are ready.'
            : 'Goal updated. Your daily tasks were refreshed.',
      );
    } on Object {
      if (mounted) {
        _showSnack(
          'Goal planning failed. Try again in a moment.',
          isError: true,
        );
      }
    } finally {
      _timer?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final rootContext = Navigator.of(context).context;
    final colors = rootContext.colors;
    ScaffoldMessenger.of(rootContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? colors.errorSoft : colors.successSoft,
          content: Text(
            message,
            style: rootContext.textTheme.bodyMedium?.copyWith(
              color: isError ? colors.errorColor : colors.successColor,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary,
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(switch (widget.mode) {
                  _GoalSheetMode.create => 'What do you want to achieve?',
                  _GoalSheetMode.edit => 'Refine your goal',
                  _GoalSheetMode.replace => 'Set a new goal',
                }, style: context.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _goalController,
                  minLines: 3,
                  maxLines: 5,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g., Run a 5K in 60 days, Ship my app in 30 days...',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text('Target Date:', style: context.textTheme.labelLarge),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isLoading ? null : _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryAccentSoft,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Text(
                          DateFormat('d MMM yyyy').format(_targetDate),
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colors.primaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _contextController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Any context? (optional)',
                    hintText: "e.g., I'm a complete beginner",
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                LuminaButton(
                  label: switch (widget.mode) {
                    _GoalSheetMode.create => 'Let Lumina Plan This ->',
                    _GoalSheetMode.edit => 'Update Goal ->',
                    _GoalSheetMode.replace => 'Replace Goal ->',
                  },
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                  icon: PhosphorIcons.magicWand(),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.backgroundElevated.withValues(alpha: 0.86),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      _loadingMessages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: colors.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
