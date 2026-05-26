import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';

class SyncService {
  SyncService({
    DeviceIdentityService? identityService,
    EdgeFunctionClient? edgeClient,
  }) : _identityService = identityService ?? DeviceIdentityService(),
       _edgeClient = edgeClient ?? EdgeFunctionClient();

  final DeviceIdentityService _identityService;
  final EdgeFunctionClient _edgeClient;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> syncDailyLog(DailyLog log) async {
    try {
      final deviceId = await _identityService.getDeviceId();
      final result = await _edgeClient.invoke(
        'sync-daily-log',
        payload: {
          'deviceId': deviceId,
          'profile': {'device_id': deviceId},
          'dailyLog': {
            'log_date': _dateFormat.format(log.date),
            'mood': log.mood,
            'mood_note': log.moodNote,
            'energy': log.energy,
            'notes': log.notes,
          },
          'tasks': [
            for (final (index, task) in log.tasks.indexed)
              {
                'id': task.id,
                'title': task.title,
                'is_completed': task.isCompleted,
                'priority': task.priority.name,
                'sort_order': index,
              },
          ],
          'completedHabitIds': log.completedHabitIds,
        },
        headers: {'x-device-id': deviceId},
      );
      if (!result.isSuccess) {
        throw StateError(result.error ?? 'Daily log sync failed.');
      }
    } on Object catch (error) {
      debugPrint('Lumina syncDailyLog queued: $error');
      await _queue('daily_log', log.toJson());
    }
  }

  Future<void> syncHabitCompletion(String habitId, DateTime date) async {
    try {
      final deviceId = await _identityService.getDeviceId();
      final result = await _edgeClient.invoke(
        'sync-daily-log',
        payload: {
          'deviceId': deviceId,
          'habitCompletions': [
            {'habit_id': habitId, 'completion_date': _dateFormat.format(date)},
          ],
        },
        headers: {'x-device-id': deviceId},
      );
      if (!result.isSuccess) {
        throw StateError(result.error ?? 'Habit completion sync failed.');
      }
    } on Object catch (error) {
      debugPrint('Lumina syncHabitCompletion queued: $error');
      await _queue('habit_completion', {
        'habitId': habitId,
        'date': date.toIso8601String(),
      });
    }
  }

  Future<void> syncTasks(List<Task> tasks, {DateTime? date}) async {
    try {
      final deviceId = await _identityService.getDeviceId();
      final result = await _edgeClient.invoke(
        'sync-daily-log',
        payload: {
          'deviceId': deviceId,
          'tasks': [
            for (final (index, task) in tasks.indexed)
              {
                'id': task.id,
                'log_date': _dateFormat.format(date ?? DateTime.now()),
                'title': task.title,
                'is_completed': task.isCompleted,
                'priority': task.priority.name,
                'sort_order': index,
              },
          ],
        },
        headers: {'x-device-id': deviceId},
      );
      if (!result.isSuccess) {
        throw StateError(result.error ?? 'Task sync failed.');
      }
    } on Object catch (error) {
      debugPrint('Lumina syncTasks queued: $error');
      await _queue('tasks', tasks.map((task) => task.toJson()).toList());
    }
  }

  Future<void> syncHabits(List<HabitProgress> habits) async {
    try {
      final deviceId = await _identityService.getDeviceId();
      final result = await _edgeClient.invoke(
        'sync-daily-log',
        payload: {
          'deviceId': deviceId,
          'habits': [
            for (final habit in habits)
              {
                'habitId': habit.habitId,
                'name': habit.name,
                'emoji': habit.emoji,
                'color_hex':
                    '#${habit.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                'frequency': 'daily',
                'is_active': true,
              },
          ],
        },
        headers: {'x-device-id': deviceId},
      );
      if (!result.isSuccess) {
        throw StateError(result.error ?? 'Habit sync failed.');
      }
    } on Object catch (error) {
      debugPrint('Lumina syncHabits queued: $error');
      await _queue('habits', habits.map((habit) => habit.toJson()).toList());
    }
  }

  Future<List<MentorInsight>> fetchRecentInsights(String deviceId) async {
    try {
      final result = await _edgeClient.invoke(
        'fetch-mentor-insights',
        payload: {'deviceId': deviceId},
        headers: {'x-device-id': deviceId},
      );
      if (!result.isSuccess) {
        throw StateError(result.error ?? 'Insight fetch failed.');
      }
      final insights = result.data?['insights'];
      if (insights is! List) {
        return const [];
      }
      return [
        for (final item in insights.whereType<Map>())
          MentorInsight(
            id: item['id'] as String?,
            insightType: item['insight_type'] as String? ?? 'general',
            headline: item['headline'] as String? ?? 'Mentor Insight',
            body: item['body'] as String? ?? '',
            metadata: item['metadata'] is Map
                ? Map<String, dynamic>.from(item['metadata'] as Map)
                : const {},
            generatedAt: DateTime.tryParse(
              item['generated_at'] as String? ?? '',
            ),
          ),
      ];
    } on Object catch (error) {
      debugPrint('Lumina fetchRecentInsights skipped: $error');
      return const [];
    }
  }

  Future<void> _queue(String type, Object payload) async {
    try {
      final box = Hive.isBoxOpen(AppConstants.pendingSyncBox)
          ? Hive.box<dynamic>(AppConstants.pendingSyncBox)
          : await Hive.openBox<dynamic>(AppConstants.pendingSyncBox);
      await box.add({
        'type': type,
        'payload': payload,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on Object {
      return;
    }
  }
}
