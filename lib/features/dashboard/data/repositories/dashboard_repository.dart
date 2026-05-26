import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';

class DashboardRepository {
  DashboardRepository();

  final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  String _todayKey() => _keyFormat.format(DateTime.now());

  Future<List<Task>> getTodaysTasks() async {
    final box = await _openBox(AppConstants.tasksBox);
    final stored = box?.get(_todayKey());
    if (stored is List && stored.isNotEmpty) {
      return stored
          .whereType<Map<dynamic, dynamic>>()
          .map(Task.fromJson)
          .toList();
    }

    final seeded = _seedTasks();
    await box?.put(_todayKey(), seeded.map((task) => task.toJson()).toList());
    return seeded;
  }

  Future<MoodEntry?> getTodaysMoodEntry() async {
    final box = await _openBox(AppConstants.logsBox);
    final stored = box?.get('mood_${_todayKey()}');
    if (stored is Map) {
      return MoodEntry.fromJson(stored);
    }
    return null;
  }

  Future<int> getCurrentStreak() async {
    final box = await _openBox(AppConstants.logsBox);
    return box?.get('streak', defaultValue: 12) as int? ?? 12;
  }

  Future<List<HabitProgress>> getTodaysHabitProgress() async {
    final box = await _openBox(AppConstants.habitsBox);
    final stored = box?.get(_todayKey());
    if (stored is List && stored.isNotEmpty) {
      return stored
          .whereType<Map<dynamic, dynamic>>()
          .map(HabitProgress.fromJson)
          .toList();
    }

    final seeded = _seedHabits();
    await box?.put(_todayKey(), seeded.map((habit) => habit.toJson()).toList());
    return seeded;
  }

  Future<MentorInsight?> getLatestMentorInsight() async {
    final box = await _openBox(AppConstants.insightsBox);
    final stored = box?.get('latest_dashboard');
    if (stored is Map) {
      return MentorInsight.fromJson(stored);
    }

    final seeded = MentorInsight(
      headline: 'Your focus is strongest before noon',
      body:
          'Your recent pattern shows better task completion when the first focus block starts early. Protect one quiet hour before messages take over.',
    );
    await box?.put('latest_dashboard', seeded.toJson());
    return seeded;
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final box = await _openBox(AppConstants.tasksBox);
    await box?.put(_todayKey(), tasks.map((task) => task.toJson()).toList());
  }

  Future<void> updateTaskCompletion(String id, bool isCompleted) async {
    final tasks = await getTodaysTasks();
    final updated = [
      for (final task in tasks)
        if (task.id == id) task.copyWith(isCompleted: isCompleted) else task,
    ];
    await saveTasks(updated);
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

  List<Task> _seedTasks() {
    final now = DateTime.now();
    return [
      Task(
        title: 'Write one honest reflection',
        priority: TaskPriority.high,
        dueDate: now,
      ),
      Task(
        title: 'Move for twenty minutes',
        priority: TaskPriority.normal,
        dueDate: now,
      ),
      Task(
        title: 'Choose tomorrow morning focus',
        priority: TaskPriority.normal,
        dueDate: now,
      ),
      Task(
        title: 'Clear one lingering message',
        priority: TaskPriority.low,
        dueDate: now,
      ),
      Task(
        title: 'Read for ten calm minutes',
        priority: TaskPriority.low,
        dueDate: now,
      ),
    ];
  }

  List<HabitProgress> _seedHabits() {
    return const [
      HabitProgress(
        habitId: 'morning-pages',
        name: 'Journal',
        emoji: '✍',
        color: Color(0xFFF0A500),
        completedToday: 1,
        targetPerDay: 1,
      ),
      HabitProgress(
        habitId: 'hydration',
        name: 'Water',
        emoji: '💧',
        color: Color(0xFF34C97B),
        completedToday: 2,
        targetPerDay: 3,
      ),
      HabitProgress(
        habitId: 'deep-work',
        name: 'Focus',
        emoji: '⚡',
        color: Color(0xFF7B61FF),
        completedToday: 1,
        targetPerDay: 2,
      ),
      HabitProgress(
        habitId: 'sleep',
        name: 'Sleep',
        emoji: '🌙',
        color: Color(0xFFFF8C42),
        completedToday: 0,
        targetPerDay: 1,
      ),
    ];
  }
}
