import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';
import 'package:lumina/core/services/sync_service.dart';
import 'package:lumina/features/dashboard/data/repositories/dashboard_repository.dart';

class LogRepository {
  LogRepository({
    DashboardRepository? dashboardRepository,
    SyncService? syncService,
    EdgeFunctionClient? edgeClient,
    DeviceIdentityService? identityService,
  }) : _dashboardRepository = dashboardRepository ?? DashboardRepository(),
       _syncService = syncService ?? SyncService(),
       _edgeClient = edgeClient ?? EdgeFunctionClient(),
       _identityService = identityService ?? DeviceIdentityService();

  final DashboardRepository _dashboardRepository;
  final SyncService _syncService;
  final EdgeFunctionClient _edgeClient;
  final DeviceIdentityService _identityService;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<DailyLog?> getTodayLog() async {
    final data = await _today();
    if (data.isEmpty) {
      return _localTodayLog();
    }
    final log = data['log'];
    final tasks = data['tasks'];
    final completedHabitIds = data['completedHabitIds'];
    if (log is Map) {
      return DailyLog.fromJson({
        ...Map<String, dynamic>.from(log),
        'tasks': tasks is List ? tasks : const [],
        'completedHabitIds': completedHabitIds is List
            ? completedHabitIds.whereType<String>().toList()
            : const <String>[],
      });
    }
    final hasRemoteDraft =
        (tasks is List && tasks.isNotEmpty) ||
        (completedHabitIds is List && completedHabitIds.isNotEmpty);
    if (!hasRemoteDraft) {
      final local = await _localTodayLog();
      if (local != null) {
        return local;
      }
    }
    return DailyLog(
      date: DateTime.now(),
      tasks: tasks is List
          ? tasks.whereType<Map<dynamic, dynamic>>().map(Task.fromJson).toList()
          : const [],
      completedHabitIds: completedHabitIds is List
          ? completedHabitIds.whereType<String>().toList()
          : const [],
    );
  }

  Future<List<HabitProgress>> getHabits() async {
    final remote = await _dashboardRepository.getTodaysHabitProgress();
    if (remote.isNotEmpty) {
      await _cacheHabits(remote);
      return remote;
    }
    return _localHabits();
  }

  Future<void> saveDailyLog(DailyLog log) async {
    await _cacheDailyLog(log);
    await _syncService.syncDailyLog(log);
  }

  Future<void> saveHabits(List<HabitProgress> habits) async {
    await _cacheHabits(habits);
    _dashboardRepository.clearCache();
    await _syncService.syncHabits(habits);
    _dashboardRepository.clearCache();
  }

  Future<void> appendJournalEntry(String entry) async {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final log = await getTodayLog() ?? DailyLog(date: DateTime.now());
    final currentNotes = log.notes?.trim();
    final nextNotes = currentNotes == null || currentNotes.isEmpty
        ? trimmed
        : '$currentNotes\n\n$trimmed';
    await saveDailyLog(log.copyWith(notes: nextNotes));
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

  Future<Map<String, dynamic>> _today() async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'app-data',
      payload: {
        'action': 'today_log',
        'device_id': deviceId,
        'todayDate': _dateFormat.format(DateTime.now()),
      },
      headers: {'x-device-id': deviceId},
    );
    return result.isSuccess ? result.data ?? const {} : const {};
  }

  Future<List<HabitProgress>> _localHabits() async {
    final box = await _habitBox();
    final deviceId = await _identityService.getDeviceId();
    final raw = box.get(_habitCacheKey(deviceId));
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) HabitProgress.fromJson(item),
    ];
  }

  Future<void> _cacheHabits(List<HabitProgress> habits) async {
    final box = await _habitBox();
    final deviceId = await _identityService.getDeviceId();
    await box.put(
      _habitCacheKey(deviceId),
      habits.map((habit) => habit.toJson()).toList(),
    );
  }

  Future<Box<dynamic>> _habitBox() async {
    return Hive.isBoxOpen(AppConstants.habitsBox)
        ? Hive.box<dynamic>(AppConstants.habitsBox)
        : Hive.openBox<dynamic>(AppConstants.habitsBox);
  }

  String _habitCacheKey(String deviceId) => 'habits.$deviceId';

  Future<DailyLog?> _localTodayLog() async {
    final box = await _logBox();
    final deviceId = await _identityService.getDeviceId();
    final raw = box.get(_logCacheKey(deviceId, DateTime.now()));
    return raw is Map ? DailyLog.fromJson(raw) : null;
  }

  Future<void> _cacheDailyLog(DailyLog log) async {
    final box = await _logBox();
    final deviceId = await _identityService.getDeviceId();
    await box.put(_logCacheKey(deviceId, log.date), log.toJson());
  }

  Future<Box<dynamic>> _logBox() async {
    return Hive.isBoxOpen(AppConstants.logsBox)
        ? Hive.box<dynamic>(AppConstants.logsBox)
        : Hive.openBox<dynamic>(AppConstants.logsBox);
  }

  String _logCacheKey(String deviceId, DateTime date) {
    return 'log.$deviceId.${_dateFormat.format(date)}';
  }
}
