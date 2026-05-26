import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/features/dashboard/data/repositories/dashboard_repository.dart';

class LogRepository {
  LogRepository({DashboardRepository? dashboardRepository})
    : _dashboardRepository = dashboardRepository ?? DashboardRepository();

  final DashboardRepository _dashboardRepository;
  final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  String get todayKey => _keyFormat.format(DateTime.now());

  String get todayLogKey => 'log_$todayKey';

  Future<DailyLog?> getTodayLog() async {
    final box = await _openBox(AppConstants.logsBox);
    final stored = box?.get(todayLogKey);
    if (stored is Map) {
      return DailyLog.fromJson(stored);
    }

    final tasks = await _dashboardRepository.getTodaysTasks();
    return DailyLog(date: DateTime.now(), tasks: tasks);
  }

  Future<List<HabitProgress>> getHabits() {
    return _dashboardRepository.getTodaysHabitProgress();
  }

  Future<void> saveDailyLog(DailyLog log) async {
    final logsBox = await _openBox(AppConstants.logsBox);
    final tasksBox = await _openBox(AppConstants.tasksBox);

    await logsBox?.put(todayLogKey, log.toJson());
    await tasksBox?.put(
      todayKey,
      log.tasks.map((task) => task.toJson()).toList(),
    );

    if (log.mood != null) {
      final moodEntry = MoodEntry(
        mood: log.mood!,
        energy: log.energy ?? 3,
        note: log.moodNote,
        timestamp: DateTime.now(),
      );
      await logsBox?.put('mood_$todayKey', moodEntry.toJson());
    }

    await logsBox?.put('streak', _calculateNextStreak(logsBox));
  }

  Future<void> saveHabits(List<HabitProgress> habits) async {
    final box = await _openBox(AppConstants.habitsBox);
    await box?.put(todayKey, habits.map((habit) => habit.toJson()).toList());
  }

  Future<void> updateTask(String id, bool isCompleted) async {
    final log = await getTodayLog();
    if (log == null) {
      return;
    }
    final tasks = [
      for (final task in log.tasks)
        if (task.id == id) task.copyWith(isCompleted: isCompleted) else task,
    ];
    await saveDailyLog(log.copyWith(tasks: tasks));
  }

  Future<void> addTask(Task task) async {
    final log = await getTodayLog();
    if (log == null) {
      return;
    }
    await saveDailyLog(log.copyWith(tasks: [...log.tasks, task]));
  }

  Future<void> deleteTask(String id) async {
    final log = await getTodayLog();
    if (log == null) {
      return;
    }
    await saveDailyLog(
      log.copyWith(tasks: log.tasks.where((task) => task.id != id).toList()),
    );
  }

  Future<void> checkHabit(String habitId) async {
    final log = await getTodayLog();
    if (log == null || log.completedHabitIds.contains(habitId)) {
      return;
    }
    await saveDailyLog(
      log.copyWith(completedHabitIds: [...log.completedHabitIds, habitId]),
    );
  }

  Future<void> uncheckHabit(String habitId) async {
    final log = await getTodayLog();
    if (log == null) {
      return;
    }
    await saveDailyLog(
      log.copyWith(
        completedHabitIds: log.completedHabitIds
            .where((id) => id != habitId)
            .toList(),
      ),
    );
  }

  int _calculateNextStreak(Box<dynamic>? logsBox) {
    final current = logsBox?.get('streak', defaultValue: 0) as int? ?? 0;
    return current == 0 ? 1 : current;
  }

  Future<Box<dynamic>?> _openBox(String name) async {
    try {
      if (Hive.isBoxOpen(name)) {
        return Hive.box<dynamic>(name);
      }
      return await Hive.openBox<dynamic>(name);
    } on Object {
      return null;
    }
  }
}
