import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:lumina/features/goals/data/repositories/goal_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
    );

class DashboardState {
  const DashboardState({
    required this.tasks,
    required this.moodEntry,
    required this.streak,
    required this.habits,
    required this.mentorInsight,
    required this.goalSnapshot,
    required this.burnoutWarning,
  });

  final List<Task> tasks;
  final MoodEntry? moodEntry;
  final int streak;
  final List<HabitProgress> habits;
  final MentorInsight? mentorInsight;
  final GoalSnapshot goalSnapshot;
  final MentorInsight? burnoutWarning;

  int get completedTasks => tasks.where((task) => task.isCompleted).length;

  bool get hasLoggedMood => moodEntry != null;

  DashboardState copyWith({
    List<Task>? tasks,
    MoodEntry? moodEntry,
    int? streak,
    List<HabitProgress>? habits,
    MentorInsight? mentorInsight,
    GoalSnapshot? goalSnapshot,
    MentorInsight? burnoutWarning,
  }) {
    return DashboardState(
      tasks: tasks ?? this.tasks,
      moodEntry: moodEntry ?? this.moodEntry,
      streak: streak ?? this.streak,
      habits: habits ?? this.habits,
      mentorInsight: mentorInsight ?? this.mentorInsight,
      goalSnapshot: goalSnapshot ?? this.goalSnapshot,
      burnoutWarning: burnoutWarning ?? this.burnoutWarning,
    );
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  @override
  Future<DashboardState> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<DashboardState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleTask(String taskId) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final updatedTasks = [
      for (final task in current.tasks)
        if (task.id == taskId)
          task.copyWith(isCompleted: !task.isCompleted)
        else
          task,
    ];

    state = AsyncData(current.copyWith(tasks: updatedTasks));
    final task = updatedTasks.firstWhere((item) => item.id == taskId);
    await _repository.updateTaskCompletion(taskId, task.isCompleted);
  }

  Future<DashboardState> _load() async {
    final results = await Future.wait<Object?>([
      _repository.getTodaysTasks(),
      _repository.getTodaysMoodEntry(),
      _repository.getCurrentStreak(),
      _repository.getTodaysHabitProgress(),
      _repository.getLatestMentorInsight(),
      _repository.getActiveGoal(),
      _repository.getActiveBurnoutWarning(),
    ]);

    return DashboardState(
      tasks: results[0]! as List<Task>,
      moodEntry: results[1] as MoodEntry?,
      streak: results[2]! as int,
      habits: results[3]! as List<HabitProgress>,
      mentorInsight: results[4] as MentorInsight?,
      goalSnapshot: results[5]! as GoalSnapshot,
      burnoutWarning: results[6] as MentorInsight?,
    );
  }
}
