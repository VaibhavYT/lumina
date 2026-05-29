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

  Future<DailyLog?> getTodayLog() async {
    final data = await _today();
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

  Future<List<HabitProgress>> getHabits() {
    return _dashboardRepository.getTodaysHabitProgress();
  }

  Future<void> saveDailyLog(DailyLog log) async {
    await _syncService.syncDailyLog(log);
  }

  Future<void> saveHabits(List<HabitProgress> habits) async {
    await _syncService.syncHabits(habits);
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
      payload: {'action': 'today_log', 'device_id': deviceId},
      headers: {'x-device-id': deviceId},
    );
    return result.isSuccess ? result.data ?? const {} : const {};
  }
}
