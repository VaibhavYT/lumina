import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/utils/haptic_utils.dart';
import 'package:lumina/features/log/presentation/providers/today_log_notifier.dart';
import 'package:lumina/features/log/presentation/widgets/daily_log_widgets.dart';
import 'package:lumina/shared/widgets/shimmer_loader.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  final _moodNoteController = TextEditingController();
  final _notesController = TextEditingController();
  var _didHydrateControllers = false;
  var _showSuccess = false;

  @override
  void dispose() {
    _moodNoteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrateControllers(TodayLogState state) {
    if (_didHydrateControllers) {
      return;
    }
    _moodNoteController.text = state.log.moodNote ?? '';
    _notesController.text = state.log.notes ?? '';
    _didHydrateControllers = true;
  }

  Future<void> _save(TodayLogState state) async {
    FocusScope.of(context).unfocus();
    final saved = await ref.read(todayLogNotifierProvider.notifier).save();
    if (!mounted) {
      return;
    }

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one thing to log.')),
      );
      return;
    }

    HapticUtils.success();
    setState(() => _showSuccess = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _showSuccess = false);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(todayLogNotifierProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: asyncState.when(
        loading: () => const _LogLoadingState(),
        error: (error, stackTrace) => Center(
          child: Text(
            'Daily log could not load.',
            style: context.textTheme.bodyLarge,
          ),
        ),
        data: (state) {
          _hydrateControllers(state);
          final notifier = ref.read(todayLogNotifierProvider.notifier);

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverSafeArea(
                      bottom: false,
                      sliver: SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.pagePadding,
                          AppSpacing.lg,
                          AppSpacing.pagePadding,
                          148 + MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        sliver: SliverList.list(
                          children: [
                            LogHeader(log: state.log),
                            const SizedBox(height: AppSpacing.sectionGap),
                            MoodSelectorSection(
                              selectedMood: state.log.mood,
                              noteController: _moodNoteController,
                              onMoodChanged: notifier.setMood,
                              onNoteChanged: notifier.setMoodNote,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            EnergySelectorSection(
                              energy: state.log.energy,
                              onChanged: notifier.setEnergy,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            TasksEditorSection(
                              tasks: state.log.tasks,
                              onAddTask: notifier.addTask,
                              onToggleTask: notifier.toggleTask,
                              onDeleteTask: notifier.deleteTask,
                              onReorder: notifier.reorderTasks,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            HabitsTrackerSection(
                              habits: state.habits,
                              onToggleHabit: notifier.toggleHabit,
                              onAddHabit: (name, emoji, color) =>
                                  notifier.addHabit(
                                    name: name,
                                    emoji: emoji,
                                    color: color,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            NotesSection(
                              controller: _notesController,
                              onChanged: notifier.setNotes,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SaveLogDock(
                  log: state.log,
                  savedToday: state.savedToday,
                  onPressed: () => _save(state),
                ),
                if (_showSuccess) const SuccessOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogLoadingState extends StatelessWidget {
  const _LogLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoader(width: 160, height: 28),
              SizedBox(height: AppSpacing.sectionGap),
              ShimmerLoader(height: 150),
              SizedBox(height: AppSpacing.md),
              ShimmerLoader(height: 120),
              SizedBox(height: AppSpacing.md),
              ShimmerLoader(height: 180),
            ],
          ),
        ),
      ),
    );
  }
}
