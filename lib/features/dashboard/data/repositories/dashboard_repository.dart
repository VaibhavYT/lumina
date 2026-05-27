import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';
import 'package:lumina/core/services/sync_service.dart';
import 'package:lumina/features/goals/data/repositories/goal_repository.dart';

class DashboardRepository {
  DashboardRepository({
    GoalRepository? goalRepository,
    SyncService? syncService,
    DeviceIdentityService? identityService,
    EdgeFunctionClient? edgeClient,
  }) : _goalRepository = goalRepository ?? GoalRepository(),
       _syncService = syncService ?? SyncService(),
       _identityService = identityService ?? DeviceIdentityService(),
       _edgeClient = edgeClient ?? EdgeFunctionClient();

  final GoalRepository _goalRepository;
  final SyncService _syncService;
  final DeviceIdentityService _identityService;
  final EdgeFunctionClient _edgeClient;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Map<String, dynamic>? _dashboardCache;

  void clearCache() {
    _dashboardCache = null;
  }

  Future<List<Task>> getTodaysTasks() async {
    final tasks = (await _dashboard())['tasks'];
    return tasks is List
        ? tasks.whereType<Map<dynamic, dynamic>>().map(Task.fromJson).toList()
        : const [];
  }

  Future<MoodEntry?> getTodaysMoodEntry() async {
    final log = (await _dashboard())['log'];
    if (log is! Map || log['mood'] == null) {
      return null;
    }
    return MoodEntry(
      mood: log['mood'] as int? ?? 3,
      energy: log['energy'] as int? ?? 3,
      note: log['mood_note'] as String? ?? log['notes'] as String?,
      timestamp:
          DateTime.tryParse(log['log_date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Future<int> getCurrentStreak() async {
    return (await _dashboard())['streak'] as int? ?? 0;
  }

  Future<List<HabitProgress>> getTodaysHabitProgress() async {
    final habits = (await _dashboard())['habits'];
    return habits is List
        ? habits
              .whereType<Map<dynamic, dynamic>>()
              .map(_habitFromRemote)
              .toList()
        : const [];
  }

  Future<MentorInsight?> getLatestMentorInsight() async {
    final insight = (await _dashboard())['mentorInsight'];
    return insight is Map ? MentorInsight.fromJson(insight) : null;
  }

  Future<GoalSnapshot> getActiveGoal() {
    return _goalRepository.getActiveGoal();
  }

  Future<MentorInsight?> getActiveBurnoutWarning() async {
    try {
      final insight = (await _dashboard())['burnoutWarning'];
      return insight is Map ? MentorInsight.fromJson(insight) : null;
    } on Object {
      return null;
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    await _syncService.syncTasks(tasks);
    _dashboardCache = null;
  }

  Future<void> updateTaskCompletion(String id, bool isCompleted) async {
    final tasks = await getTodaysTasks();
    final updated = [
      for (final task in tasks)
        if (task.id == id) task.copyWith(isCompleted: isCompleted) else task,
    ];
    await saveTasks(updated);
  }

  Future<Map<String, dynamic>> _dashboard() async {
    if (_dashboardCache != null) {
      return _dashboardCache!;
    }
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'app-data',
      payload: {
        'action': 'dashboard',
        'device_id': deviceId,
        'todayDate': _dateFormat.format(DateTime.now()),
      },
      headers: {'x-device-id': deviceId},
    );
    _dashboardCache = result.isSuccess ? result.data ?? const {} : const {};
    return _dashboardCache!;
  }

  HabitProgress _habitFromRemote(Map<dynamic, dynamic> json) {
    return HabitProgress(
      habitId: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? 'Habit',
      emoji: json['emoji'] as String? ?? '*',
      color: _parseColor(json['color_hex'] as String? ?? '#F0A500'),
      completedToday: json['completed_today'] == true ? 1 : 0,
      targetPerDay: json['target_per_day'] as int? ?? 1,
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return Color(value ?? 0xFFF0A500);
  }
}
