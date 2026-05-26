import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/utils/haptic_utils.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LogHeader extends StatelessWidget {
  const LogHeader({super.key, required this.log});

  final DailyLog log;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final complete = log.isComplete;
    final label = complete
        ? 'Complete ✓'
        : '${log.completedSections}/5 sections';
    final badgeColor = complete
        ? colors.successColor
        : log.completedSections == 0
        ? colors.textTertiary
        : colors.primaryAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Log", style: context.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM').format(log.date),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppMotion.standard,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
              ),
              child: Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 3, color: colors.divider),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: log.completedSections / 5),
                    duration: AppMotion.standard,
                    curve: AppMotion.enter,
                    builder: (context, value, child) {
                      return Container(
                        width: constraints.maxWidth * value,
                        height: 3,
                        decoration: BoxDecoration(
                          color: complete
                              ? colors.successColor
                              : colors.primaryAccent,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                        ),
                      );
                    },
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

class MoodSelectorSection extends StatelessWidget {
  const MoodSelectorSection({
    super.key,
    required this.selectedMood,
    required this.noteController,
    required this.onMoodChanged,
    required this.onNoteChanged,
  });

  final int? selectedMood;
  final TextEditingController noteController;
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<String> onNoteChanged;

  static const _moods = [
    _MoodOption(1, 'Struggling', '😔', Color(0xFFFF4D6D)),
    _MoodOption(2, 'Low', '😕', Color(0xFFFF8C42)),
    _MoodOption(3, 'Okay', '😐', Color(0xFFF0A500)),
    _MoodOption(4, 'Good', '🙂', Color(0xFF5BC67A)),
    _MoodOption(5, 'Great', '😄', Color(0xFF34C97B)),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _moods.firstWhere(
      (mood) => mood.level == selectedMood,
      orElse: () => _moods[2],
    );

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selectedMood == null
            ? context.colors.backgroundCard
            : selected.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: math.max(constraints.maxWidth, 340.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final mood in _moods)
                        _MoodBubble(
                          option: mood,
                          isSelected: selectedMood == mood.level,
                          onTap: () {
                            HapticUtils.selection();
                            onMoodChanged(mood.level);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: selectedMood == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: TextField(
                      controller: noteController,
                      onChanged: onNoteChanged,
                      minLines: 1,
                      maxLines: 3,
                      style: context.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: "What's driving this feeling?",
                        fillColor: selected.color.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoodOption {
  const _MoodOption(this.level, this.label, this.emoji, this.color);

  final int level;
  final String label;
  final String emoji;
  final Color color;
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _MoodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.enter,
              width: isSelected ? 68 : 52,
              height: isSelected ? 68 : 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: isSelected ? 0.25 : 0.12),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: option.color.withValues(alpha: 0.30),
                          blurRadius: 16,
                        ),
                      ]
                    : const [],
              ),
              child: AnimatedOpacity(
                duration: AppMotion.fast,
                opacity: isSelected ? 1 : 0.6,
                child: Text(option.emoji, style: const TextStyle(fontSize: 27)),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        option.label,
                        key: ValueKey(option.label),
                        maxLines: 1,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: option.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox(height: 21),
            ),
          ],
        ),
      ),
    );
  }
}

class EnergySelectorSection extends StatefulWidget {
  const EnergySelectorSection({
    super.key,
    required this.energy,
    required this.onChanged,
  });

  final int? energy;
  final ValueChanged<int> onChanged;

  @override
  State<EnergySelectorSection> createState() => _EnergySelectorSectionState();
}

class _EnergySelectorSectionState extends State<EnergySelectorSection> {
  int? _lastHapticLevel;

  static const _labels = ['Drained', 'Low', 'Moderate', 'High', 'Peak'];
  static const _colors = [
    Color(0xFFFF4D6D),
    Color(0xFFFF8C42),
    Color(0xFFF0A500),
    Color(0xFF5BC67A),
    Color(0xFF34C97B),
  ];

  void _updateFromLocalPosition(Offset position, double width) {
    final normalized = (position.dx / width).clamp(0.0, 1.0);
    final level = (normalized * 4).round() + 1;
    if (level != _lastHapticLevel) {
      _lastHapticLevel = level;
      HapticUtils.selection();
    }
    widget.onChanged(level);
  }

  @override
  Widget build(BuildContext context) {
    final energy = widget.energy ?? 3;
    final color = _colors[energy - 1];

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Energy', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final thumbX = ((energy - 1) / 4) * width;

              return GestureDetector(
                onTapDown: (details) =>
                    _updateFromLocalPosition(details.localPosition, width),
                onHorizontalDragUpdate: (details) =>
                    _updateFromLocalPosition(details.localPosition, width),
                child: SizedBox(
                  height: 86,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        duration: AppMotion.fast,
                        curve: AppMotion.enter,
                        left: (thumbX - 42).clamp(0, width - 84),
                        top: -30,
                        child: SizedBox(
                          width: 84,
                          child: Text(
                            '${_labels[energy - 1]} Energy',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: CustomPaint(
                          painter: _EnergyTrackPainter(
                            progress: (energy - 1) / 4,
                            colors: _colors,
                          ),
                          child: const SizedBox(height: 14),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: AppMotion.fast,
                        curve: AppMotion.enter,
                        left: (thumbX - 14).clamp(0, width - 28),
                        top: 13,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < _labels.length; i++)
                              Text(
                                _labels[i],
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: i == energy - 1
                                      ? _colors[i]
                                      : context.colors.textTertiary,
                                  fontWeight: i == energy - 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EnergyTrackPainter extends CustomPainter {
  const _EnergyTrackPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    final fullTrack = RRect.fromRectAndRadius(rect, radius);
    final gradient = LinearGradient(colors: colors);
    final backgroundPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..colorFilter = const ColorFilter.mode(
        Color(0x66FFFFFF),
        BlendMode.modulate,
      );
    final activePaint = Paint()..shader = gradient.createShader(rect);

    canvas.drawRRect(fullTrack, backgroundPaint);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawRRect(fullTrack, activePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EnergyTrackPainter oldDelegate) {
    return progress != oldDelegate.progress || colors != oldDelegate.colors;
  }
}

class TasksEditorSection extends StatefulWidget {
  const TasksEditorSection({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onReorder,
  });

  final List<Task> tasks;
  final void Function(String title, TaskPriority priority) onAddTask;
  final ValueChanged<String> onToggleTask;
  final ValueChanged<String> onDeleteTask;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<TasksEditorSection> createState() => _TasksEditorSectionState();
}

class _TasksEditorSectionState extends State<TasksEditorSection> {
  final _controller = TextEditingController();
  var _adding = false;
  var _priority = TaskPriority.normal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onAddTask(_controller.text, _priority);
    _controller.clear();
    setState(() {
      _adding = false;
      _priority = TaskPriority.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Tasks",
                  style: context.textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Add task',
                onPressed: () => setState(() => _adding = true),
                icon: Icon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  color: context.colors.primaryAccent,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: _adding
                ? _TaskInputRow(
                    controller: _controller,
                    priority: _priority,
                    onPriorityChanged: (priority) =>
                        setState(() => _priority = priority),
                    onSave: _save,
                    onCancel: () => setState(() => _adding = false),
                  )
                : widget.tasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'Add your first focus for today ↑',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.tasks.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.tasks.length,
              onReorder: widget.onReorder,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return Dismissible(
                  key: ValueKey(task.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => widget.onDeleteTask(task.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.errorSoft,
                      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                    ),
                    child: Icon(
                      PhosphorIcons.trash(PhosphorIconsStyle.fill),
                      color: context.colors.errorColor,
                    ),
                  ),
                  child: _EditableTaskRow(
                    index: index,
                    task: task,
                    onToggle: () => widget.onToggleTask(task.id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TaskInputRow extends StatelessWidget {
  const _TaskInputRow({
    required this.controller,
    required this.priority,
    required this.onPriorityChanged,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final TaskPriority priority;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(PhosphorIcons.circle(), color: context.colors.divider),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onSubmitted: (_) => onSave(),
              style: context.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'New focus...',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          for (final item in TaskPriority.values)
            GestureDetector(
              onTap: () => onPriorityChanged(item),
              child: Container(
                width: 16,
                height: 32,
                alignment: Alignment.center,
                child: Container(
                  width: priority == item ? 10 : 7,
                  height: priority == item ? 10 : 7,
                  decoration: BoxDecoration(
                    color: _priorityColor(context, item),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Save task',
            onPressed: onSave,
            icon: Icon(
              PhosphorIcons.check(PhosphorIconsStyle.bold),
              color: context.colors.primaryAccent,
            ),
          ),
          IconButton(
            tooltip: 'Cancel',
            onPressed: onCancel,
            icon: Icon(
              PhosphorIcons.x(PhosphorIconsStyle.bold),
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableTaskRow extends StatelessWidget {
  const _EditableTaskRow({
    required this.index,
    required this.task,
    required this.onToggle,
  });

  final int index;
  final Task task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              PhosphorIcons.dotsSixVertical(),
              color: context.colors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              HapticUtils.success();
              onToggle();
            },
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: task.isCompleted ? context.colors.primaryAccent : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted
                      ? context.colors.primaryAccent
                      : context.colors.divider,
                ),
              ),
              child: task.isCompleted
                  ? Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              task.title,
              style: context.textTheme.bodyLarge?.copyWith(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: task.isCompleted
                    ? context.colors.textSecondary
                    : context.colors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _priorityColor(context, task.priority),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

Color _priorityColor(BuildContext context, TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => context.colors.primaryAccent,
    TaskPriority.normal => context.colors.textSecondary,
    TaskPriority.low => context.colors.errorColor,
  };
}

class HabitsTrackerSection extends StatelessWidget {
  const HabitsTrackerSection({
    super.key,
    required this.habits,
    required this.onToggleHabit,
    required this.onAddHabit,
  });

  final List<HabitProgress> habits;
  final ValueChanged<String> onToggleHabit;
  final void Function(String name, String emoji, Color color) onAddHabit;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Habits', style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final habit in habits) ...[
            _HabitCheckRow(
              habit: habit,
              onTap: () => onToggleHabit(habit.habitId),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _AddHabitSheet(onAddHabit: onAddHabit),
            ),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                border: Border.all(
                  color: context.colors.divider,
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                '+ Add a habit',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCheckRow extends StatefulWidget {
  const _HabitCheckRow({required this.habit, required this.onTap});

  final HabitProgress habit;
  final VoidCallback onTap;

  @override
  State<_HabitCheckRow> createState() => _HabitCheckRowState();
}

class _HabitCheckRowState extends State<_HabitCheckRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticUtils.success();
    _burstController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.habit.progress >= 1;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: completed
              ? widget.habit.color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _burstController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _BurstPainter(
                          progress: _burstController.value,
                          color: widget.habit.color,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: completed ? widget.habit.color : null,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: completed
                            ? widget.habit.color
                            : context.colors.divider,
                      ),
                    ),
                    child: completed
                        ? Icon(
                            PhosphorIcons.check(PhosphorIconsStyle.bold),
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.habit.emoji} ${widget.habit.name}',
                    style: context.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < 3
                                ? widget.habit.color
                                : context.colors.divider,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'Daily',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) {
      return;
    }
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color.withValues(alpha: 1 - progress);
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2;
      final distance = 8 + 14 * progress;
      final offset = Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(center + offset, 2.5 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet({required this.onAddHabit});

  final void Function(String name, String emoji, Color color) onAddHabit;

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _controller = TextEditingController();
  var _emoji = '📘';
  var _color = const Color(0xFFF0A500);
  var _frequency = 'Daily';

  static const _emojis = [
    '📘',
    '🏋',
    '💧',
    '🍎',
    '🌙',
    '✍',
    '💛',
    '🧠',
    '☀',
    '🍃',
  ];
  static const _colors = [
    Color(0xFFF0A500),
    Color(0xFF7B61FF),
    Color(0xFF34C97B),
    Color(0xFFFF8C42),
    Color(0xFFFF4D6D),
    Color(0xFF5BC67A),
    Color(0xFF4FB3FF),
    Color(0xFFE06BFF),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: context.colors.backgroundElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('New Habit', style: context.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final emoji in _emojis)
                    GestureDetector(
                      onTap: () => setState(() => _emoji = emoji),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _emoji == emoji
                                ? context.colors.primaryAccent
                                : context.colors.divider,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              style: context.textTheme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Habit name...'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final color in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: _color == color
                          ? Icon(
                              PhosphorIcons.check(PhosphorIconsStyle.bold),
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final frequency in ['Daily', 'Weekdays', 'Custom'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(frequency),
                      selected: _frequency == frequency,
                      onSelected: (_) => setState(() => _frequency = frequency),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LuminaButton(
              label: 'Add Habit',
              onPressed: () {
                widget.onAddHabit(_controller.text, _emoji, _color);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class NotesSection extends StatefulWidget {
  const NotesSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _wrapSelection(String before, String after) {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) {
      return;
    }
    final selectedText = selection.textInside(value.text);
    final replacement = '$before$selectedText$after';
    final updated = value.text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );
    widget.controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: selection.start + replacement.length,
      ),
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = widget.controller.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: context.textTheme.headlineMedium),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: _focusNode.hasFocus
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        _FormatButton(
                          label: 'B',
                          onTap: () => _wrapSelection('**', '**'),
                        ),
                        _FormatButton(
                          label: 'I',
                          onTap: () => _wrapSelection('_', '_'),
                        ),
                        _FormatButton(
                          label: '💛',
                          onTap: () => _wrapSelection('==', '=='),
                        ),
                        _FormatButton(
                          label: '#',
                          onTap: () => _wrapSelection('# ', ''),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinedPaperPainter(context.colors.divider),
                ),
              ),
              TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                },
                minLines: 6,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: context.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText:
                      "Write anything: what happened, what you're thinking, what you're grateful for...",
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (_focusNode.hasFocus)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$wordCount words',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          border: Border.all(color: context.colors.divider),
        ),
        child: Text(label, style: context.textTheme.labelLarge),
      ),
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  const _LinedPaperPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPaperPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class SaveLogDock extends StatelessWidget {
  const SaveLogDock({
    super.key,
    required this.log,
    required this.savedToday,
    required this.onPressed,
  });

  final DailyLog log;
  final bool savedToday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = savedToday
        ? 'Update Log'
        : log.isComplete
        ? 'Complete Today ✓'
        : log.completedSections == 0
        ? "Save Today's Log"
        : 'Save Progress (${log.completedSections}/5)';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 112 + MediaQuery.paddingOf(context).bottom,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          34,
          AppSpacing.pagePadding,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.backgroundPrimary.withValues(alpha: 0),
              context.colors.backgroundPrimary,
            ],
          ),
        ),
        child: LuminaButton(
          label: label,
          outlined: savedToday,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class SuccessOverlay extends StatelessWidget {
  const SuccessOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: context.colors.successColor.withValues(alpha: 0.05),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.5, end: 1),
                duration: AppMotion.standard,
                curve: AppMotion.enter,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: context.colors.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Logged ✓', style: context.textTheme.headlineLarge),
            ],
          ),
        ),
      ),
    );
  }
}
