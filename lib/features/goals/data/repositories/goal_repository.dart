import 'package:intl/intl.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';

class ActiveGoal {
  const ActiveGoal({
    required this.id,
    required this.title,
    required this.summary,
    required this.targetDate,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String summary;
  final DateTime targetDate;
  final DateTime createdAt;

  factory ActiveGoal.fromJson(Map<dynamic, dynamic> json) {
    return ActiveGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Active goal',
      summary: json['description'] as String? ?? '',
      targetDate:
          DateTime.tryParse(json['target_date'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class GoalMilestone {
  const GoalMilestone({
    required this.id,
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.isCompleted,
  });

  final String id;
  final int weekNumber;
  final String title;
  final String description;
  final DateTime targetDate;
  final bool isCompleted;

  factory GoalMilestone.fromJson(Map<dynamic, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String? ?? '',
      weekNumber: json['week_number'] as int? ?? 1,
      title: json['title'] as String? ?? 'Milestone',
      description: json['description'] as String? ?? '',
      targetDate:
          DateTime.tryParse(json['target_date'] as String? ?? '') ??
          DateTime.now(),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}

class GoalStats {
  const GoalStats({
    required this.totalWeeks,
    required this.weeksElapsed,
    required this.completedTasks,
    required this.totalTasks,
    required this.completionRate,
    required this.expectedRate,
    required this.status,
    this.currentMilestone,
  });

  final int totalWeeks;
  final int weeksElapsed;
  final int completedTasks;
  final int totalTasks;
  final double completionRate;
  final double expectedRate;
  final String status;
  final GoalMilestone? currentMilestone;

  double get weekProgress => totalWeeks == 0 ? 0 : weeksElapsed / totalWeeks;

  factory GoalStats.fromJson(Map<dynamic, dynamic> json) {
    final milestone = json['currentMilestone'];
    return GoalStats(
      totalWeeks: json['totalWeeks'] as int? ?? 1,
      weeksElapsed: json['weeksElapsed'] as int? ?? 1,
      completedTasks: json['completedTasks'] as int? ?? 0,
      totalTasks: json['totalTasks'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      expectedRate: (json['expectedRate'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'On Track',
      currentMilestone: milestone is Map
          ? GoalMilestone.fromJson(milestone)
          : null,
    );
  }
}

class GoalSnapshot {
  const GoalSnapshot({
    required this.goal,
    required this.milestones,
    required this.stats,
    this.justCreatedSummary,
  });

  final ActiveGoal? goal;
  final List<GoalMilestone> milestones;
  final GoalStats? stats;
  final String? justCreatedSummary;

  bool get hasActiveGoal => goal != null;

  GoalSnapshot copyWith({String? justCreatedSummary}) {
    return GoalSnapshot(
      goal: goal,
      milestones: milestones,
      stats: stats,
      justCreatedSummary: justCreatedSummary ?? this.justCreatedSummary,
    );
  }
}

class GoalPlanResult {
  const GoalPlanResult({
    required this.goalId,
    required this.goalSummary,
    required this.milestonesCreated,
    required this.tasksCreated,
  });

  final String goalId;
  final String goalSummary;
  final int milestonesCreated;
  final int tasksCreated;
}

class GoalRepository {
  GoalRepository({
    EdgeFunctionClient? edgeClient,
    DeviceIdentityService? identityService,
  }) : _edgeClient = edgeClient ?? EdgeFunctionClient(),
       _identityService = identityService ?? DeviceIdentityService();

  final EdgeFunctionClient _edgeClient;
  final DeviceIdentityService _identityService;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<GoalSnapshot> getActiveGoal() async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'goal-decomposition-agent',
      payload: {'action': 'active_goal', 'device_id': deviceId},
      headers: {'x-device-id': deviceId},
    );
    if (!result.isSuccess) {
      return const GoalSnapshot(goal: null, milestones: [], stats: null);
    }

    final data = result.data ?? const {};
    final activeGoal = data['activeGoal'];
    final milestones = data['milestones'];
    final stats = data['stats'];
    return GoalSnapshot(
      goal: activeGoal is Map ? ActiveGoal.fromJson(activeGoal) : null,
      milestones: milestones is List
          ? milestones
                .whereType<Map<dynamic, dynamic>>()
                .map(GoalMilestone.fromJson)
                .toList()
          : const [],
      stats: stats is Map ? GoalStats.fromJson(stats) : null,
    );
  }

  Future<GoalPlanResult> setGoal({
    required String title,
    required DateTime targetDate,
    String? context,
  }) async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'goal-decomposition-agent',
      payload: {
        'device_id': deviceId,
        'goalTitle': title,
        'targetDate': _dateFormat.format(targetDate),
        if ((context ?? '').trim().isNotEmpty) 'context': context!.trim(),
      },
      headers: {'x-device-id': deviceId},
    );
    if (!result.isSuccess) {
      throw StateError(result.error ?? 'Goal planning failed.');
    }
    final data = result.data ?? const {};
    if (data['success'] != true) {
      throw StateError(data['error'] as String? ?? 'Goal planning failed.');
    }
    return GoalPlanResult(
      goalId: data['goalId'] as String? ?? '',
      goalSummary: data['goalSummary'] as String? ?? '',
      milestonesCreated: data['milestonesCreated'] as int? ?? 0,
      tasksCreated: data['tasksCreated'] as int? ?? 0,
    );
  }

  Future<List<GoalMilestone>> getGoalMilestones(String goalId) async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'goal-decomposition-agent',
      payload: {
        'action': 'goal_milestones',
        'device_id': deviceId,
        'goalId': goalId,
      },
      headers: {'x-device-id': deviceId},
    );
    final milestones = result.data?['milestones'];
    return milestones is List
        ? milestones
              .whereType<Map<dynamic, dynamic>>()
              .map(GoalMilestone.fromJson)
              .toList()
        : const [];
  }

  Future<List<Task>> getTodaysGoalTasks() async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'goal-decomposition-agent',
      payload: {'action': 'todays_goal_tasks', 'device_id': deviceId},
      headers: {'x-device-id': deviceId},
    );
    final tasks = result.data?['tasks'];
    if (tasks is! List) {
      return const [];
    }
    return [
      for (final task in tasks.whereType<Map>())
        Task(
          id: task['id'] as String?,
          title: task['title'] as String? ?? 'Goal task',
          isCompleted: task['is_completed'] as bool? ?? false,
          priority: TaskPriority.fromName(task['priority'] as String?),
          dueDate:
              DateTime.tryParse(task['log_date'] as String? ?? '') ??
              DateTime.now(),
        ),
    ];
  }
}
