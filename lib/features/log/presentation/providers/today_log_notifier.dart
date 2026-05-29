import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/features/log/data/repositories/log_repository.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

final todayLogNotifierProvider =
    AsyncNotifierProvider<TodayLogNotifier, TodayLogState>(
      TodayLogNotifier.new,
    );

@immutable
class TodayLogState {
  const TodayLogState({
    required this.log,
    required this.habits,
    this.savedToday = false,
  });

  final DailyLog log;
  final List<HabitProgress> habits;
  final bool savedToday;

  int get completedSections => log.completedSections;

  bool get canSave =>
      log.mood != null ||
      log.energy != null ||
      log.tasks.isNotEmpty ||
      log.completedHabitIds.isNotEmpty ||
      (log.moodNote ?? '').trim().isNotEmpty ||
      (log.notes ?? '').trim().isNotEmpty;

  TodayLogState copyWith({
    DailyLog? log,
    List<HabitProgress>? habits,
    bool? savedToday,
  }) {
    return TodayLogState(
      log: log ?? this.log,
      habits: habits ?? this.habits,
      savedToday: savedToday ?? this.savedToday,
    );
  }
}

class TodayLogNotifier extends AsyncNotifier<TodayLogState> {
  LogRepository get _repository => ref.read(logRepositoryProvider);

  @override
  Future<TodayLogState> build() async {
    final log =
        await _repository.getTodayLog() ?? DailyLog(date: DateTime.now());
    final habits = await _repository.getHabits();
    return TodayLogState(
      log: log,
      habits: _mergeHabitCompletion(log, habits),
      savedToday: log.updatedAt.difference(log.createdAt).inMilliseconds > 0,
    );
  }

  void setMood(int mood) {
    _mutate(
      (current) => current.copyWith(log: current.log.copyWith(mood: mood)),
    );
  }

  void setMoodNote(String value) {
    _mutate(
      (current) => current.copyWith(
        log: current.log.copyWith(
          moodNote: value,
          clearMoodNote: value.isEmpty,
        ),
      ),
    );
  }

  void setEnergy(int energy) {
    _mutate(
      (current) => current.copyWith(log: current.log.copyWith(energy: energy)),
    );
  }

  void setNotes(String value) {
    _mutate(
      (current) => current.copyWith(
        log: current.log.copyWith(notes: value, clearNotes: value.isEmpty),
      ),
    );
  }

  void addTask(String title, TaskPriority priority) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _mutate((current) {
      final task = Task(title: trimmed, priority: priority);
      return current.copyWith(
        log: current.log.copyWith(tasks: [...current.log.tasks, task]),
      );
    });
  }

  void toggleTask(String id) {
    _mutate((current) {
      final tasks = [
        for (final task in current.log.tasks)
          if (task.id == id)
            task.copyWith(isCompleted: !task.isCompleted)
          else
            task,
      ];
      return current.copyWith(log: current.log.copyWith(tasks: tasks));
    });
  }

  void deleteTask(String id) {
    _mutate((current) {
      return current.copyWith(
        log: current.log.copyWith(
          tasks: current.log.tasks.where((task) => task.id != id).toList(),
        ),
      );
    });
  }

  void reorderTasks(int oldIndex, int newIndex) {
    _mutate((current) {
      final tasks = [...current.log.tasks];
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final task = tasks.removeAt(oldIndex);
      tasks.insert(targetIndex, task);
      return current.copyWith(log: current.log.copyWith(tasks: tasks));
    });
  }

  Future<void> toggleHabit(String habitId) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final isCompleted = current.log.completedHabitIds.contains(habitId);
    final completedIds = isCompleted
        ? current.log.completedHabitIds.where((id) => id != habitId).toList()
        : [...current.log.completedHabitIds, habitId];
    final habits = [
      for (final habit in current.habits)
        if (habit.habitId == habitId)
          habit.copyWith(completedToday: isCompleted ? 0 : habit.targetPerDay)
        else
          habit,
    ];
    final updated = current.copyWith(
      habits: habits,
      log: current.log.copyWith(completedHabitIds: completedIds),
      savedToday: true,
    );
    state = AsyncData(updated);
    await _repository.saveDailyLog(updated.log);
  }

  Future<void> addHabit({
    required String name,
    required String emoji,
    required Color color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final habit = HabitProgress(
      habitId: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      emoji: emoji,
      color: color,
      completedToday: 0,
      targetPerDay: 1,
    );
    final updated = current.copyWith(
      habits: [...current.habits, habit],
      savedToday: current.savedToday,
    );
    state = AsyncData(updated);
    await _repository.saveHabits(updated.habits);
  }

  Future<bool> save() async {
    final current = state.valueOrNull;
    if (current == null || !current.canSave) {
      return false;
    }
    await _repository.saveDailyLog(current.log);
    await _repository.saveHabits(current.habits);
    state = AsyncData(current.copyWith(savedToday: true));
    return true;
  }

  void _mutate(TodayLogState Function(TodayLogState current) transform) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(transform(current).copyWith(savedToday: false));
  }

  List<HabitProgress> _mergeHabitCompletion(
    DailyLog log,
    List<HabitProgress> habits,
  ) {
    return [
      for (final habit in habits)
        habit.copyWith(
          completedToday: log.completedHabitIds.contains(habit.habitId)
              ? habit.targetPerDay
              : habit.completedToday,
        ),
    ];
  }
}
