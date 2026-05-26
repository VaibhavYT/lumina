import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  SyncService({DeviceIdentityService? identityService})
    : _identityService = identityService ?? DeviceIdentityService();

  final DeviceIdentityService _identityService;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> syncDailyLog(DailyLog log) async {
    try {
      final deviceId = await _identityService.getDeviceId();
      final client = Supabase.instance.client;
      await client.from('profiles').upsert({
        'device_id': deviceId,
      }, onConflict: 'device_id');
      await client.from('daily_logs').upsert({
        'device_id': deviceId,
        'log_date': _dateFormat.format(log.date),
        'mood': log.mood,
        'mood_note': log.moodNote,
        'energy': log.energy,
        'notes': log.notes,
      }, onConflict: 'device_id,log_date');
      await syncTasks(log.tasks, date: log.date);
    } on Object catch (error) {
      debugPrint('Lumina syncDailyLog queued: $error');
      await _queue('daily_log', log.toJson());
    }
  }

  Future<void> syncHabitCompletion(String habitId, DateTime date) async {
    try {
      final deviceId = await _identityService.getDeviceId();
      final client = Supabase.instance.client;
      await client.from('habit_completions').upsert({
        'habit_id': habitId,
        'device_id': deviceId,
        'completion_date': _dateFormat.format(date),
      }, onConflict: 'habit_id,completion_date');
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
      final client = Supabase.instance.client;
      final logDate = _dateFormat.format(date ?? DateTime.now());
      final payload = [
        for (final (index, task) in tasks.indexed)
          {
            'id': task.id,
            'device_id': deviceId,
            'log_date': logDate,
            'title': task.title,
            'is_completed': task.isCompleted,
            'priority': task.priority.name,
            'sort_order': index,
          },
      ];
      if (payload.isNotEmpty) {
        await client.from('tasks').upsert(payload);
      }
    } on Object catch (error) {
      debugPrint('Lumina syncTasks queued: $error');
      await _queue('tasks', tasks.map((task) => task.toJson()).toList());
    }
  }

  Future<List<MentorInsight>> fetchRecentInsights(String deviceId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('mentor_insights')
          .select()
          .eq('device_id', deviceId)
          .eq('is_dismissed', false)
          .order('generated_at', ascending: false)
          .limit(30);
      return [
        for (final item in response)
          MentorInsight(
            id: item['id'] as String?,
            headline: item['headline'] as String? ?? 'Mentor Insight',
            body: item['body'] as String? ?? '',
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
