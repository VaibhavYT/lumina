import 'package:intl/intl.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';

enum AgentStatus { recent, scheduled, listening, waiting }

class AgentsState {
  const AgentsState({
    required this.agents,
    required this.lastSyncedAt,
    required this.signalCount,
    this.latestLogAt,
    this.activeGoalTitle,
  });

  final List<LuminaAgent> agents;
  final DateTime lastSyncedAt;
  final int signalCount;
  final DateTime? latestLogAt;
  final String? activeGoalTitle;

  int get recentlyActiveCount =>
      agents.where((agent) => agent.status == AgentStatus.recent).length;

  LuminaAgent? get nextScheduledAgent {
    final scheduled = agents.where((agent) => agent.nextRunAt != null).toList()
      ..sort((a, b) => a.nextRunAt!.compareTo(b.nextRunAt!));
    return scheduled.isEmpty ? null : scheduled.first;
  }
}

class LuminaAgent {
  const LuminaAgent({
    required this.id,
    required this.name,
    required this.functionName,
    required this.role,
    required this.description,
    required this.trigger,
    required this.dataUsed,
    required this.status,
    required this.nextRunLabel,
    this.lastRunAt,
    this.nextRunAt,
  });

  final String id;
  final String name;
  final String functionName;
  final String role;
  final String description;
  final String trigger;
  final String dataUsed;
  final AgentStatus status;
  final String nextRunLabel;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
}

class AgentsRepository {
  AgentsRepository({
    EdgeFunctionClient? edgeClient,
    DeviceIdentityService? identityService,
  }) : _edgeClient = edgeClient ?? EdgeFunctionClient(),
       _identityService = identityService ?? DeviceIdentityService();

  final EdgeFunctionClient _edgeClient;
  final DeviceIdentityService _identityService;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<AgentsState> fetchAgents() async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'app-data',
      payload: {
        'action': 'agents',
        'device_id': deviceId,
        'todayDate': _dateFormat.format(DateTime.now()),
      },
      headers: {'x-device-id': deviceId},
    );
    if (!result.isSuccess) {
      throw StateError(result.error ?? 'Agents could not load.');
    }

    final data = result.data ?? const {};
    final insights = _mapList(data['insights']);
    final chats = _mapList(data['chatMessages']);
    final latestLog = _mapValue(data['latestLog']);
    final activeGoal = _mapValue(data['activeGoal']);
    final now =
        _parseDate(data['serverTime'])?.toLocal() ?? DateTime.now().toLocal();
    final latestLogAt = _parseDate(
      latestLog?['updated_at'] ?? latestLog?['log_date'],
    )?.toLocal();
    final activeGoalTitle = activeGoal?['title'] as String?;

    return AgentsState(
      agents: _agents(
        now: now,
        insights: insights,
        chats: chats,
        latestLogAt: latestLogAt,
        activeGoal: activeGoal,
      ),
      lastSyncedAt: now,
      signalCount: insights.length + chats.length + (latestLog == null ? 0 : 1),
      latestLogAt: latestLogAt,
      activeGoalTitle: activeGoalTitle,
    );
  }

  List<LuminaAgent> _agents({
    required DateTime now,
    required List<Map<String, dynamic>> insights,
    required List<Map<String, dynamic>> chats,
    required DateTime? latestLogAt,
    required Map<String, dynamic>? activeGoal,
  }) {
    final morningBrief = _lastInsight(insights, types: {'morning_brief'});
    final burnout = _lastInsight(insights, types: {'burnout_warning'});
    final patterns = _lastInsight(
      insights,
      types: {
        'pattern',
        'strength',
        'behavioral_observation',
        'gentle_challenge',
        'momentum',
      },
      sources: {'pattern_mining_agent'},
    );
    final weeklyDebrief = _lastInsight(insights, types: {'weekly_debrief'});
    final dailyReflection = _lastInsight(
      insights,
      types: {'daily_reflection'},
      sources: {'generate-daily-reflection'},
    );
    final goalPlan = _latestOf(
      _lastInsight(
        insights,
        types: {'goal_created'},
        sources: {'goal_decomposition_agent'},
      ),
      _parseDate(activeGoal?['updated_at'] ?? activeGoal?['created_at']),
    );
    final chat = chats.isEmpty ? null : _parseDate(chats.first['created_at']);

    return [
      LuminaAgent(
        id: 'morning',
        name: 'Sunny Signal',
        functionName: 'morning-brief-agent',
        role: 'Morning brief maker',
        description:
            'Builds a concise morning brief from your open tasks, active goal, recent mood, and habit rhythm.',
        trigger: 'Daily scheduled brief or manual Supabase invocation.',
        dataUsed: 'Today tasks, active goal, mood logs, habits.',
        status: _status(now: now, lastRunAt: morningBrief),
        lastRunAt: morningBrief,
        nextRunAt: _nextDaily(now, hour: 7),
        nextRunLabel: 'Next planned brief',
      ),
      LuminaAgent(
        id: 'burnout',
        name: 'Ember Guard',
        functionName: 'burnout-interception-agent',
        role: 'Burnout risk watcher',
        description:
            'Checks new daily logs for low mood or energy patterns, then creates a warning insight and recovery task when needed.',
        trigger: 'Immediately after a daily log sync.',
        dataUsed: 'Recent mood, energy, notes, tasks, and habit completions.',
        status: _status(
          now: now,
          lastRunAt: burnout,
          needsData: latestLogAt == null,
          eventDriven: true,
        ),
        lastRunAt: burnout,
        nextRunLabel: latestLogAt == null
            ? 'Waiting for your first saved log'
            : 'After your next saved log',
      ),
      LuminaAgent(
        id: 'patterns',
        name: 'Poppy Pattern',
        functionName: 'pattern-mining-agent',
        role: 'Pattern finder',
        description:
            'Looks across your real logs and completions to discover repeating emotional and productivity patterns.',
        trigger: 'Scheduled pattern scan.',
        dataUsed: 'Mood history, energy history, tasks, habits, notes.',
        status: _status(now: now, lastRunAt: patterns),
        lastRunAt: patterns,
        nextRunAt: _nextDaily(now, hour: 21),
        nextRunLabel: 'Next planned scan',
      ),
      LuminaAgent(
        id: 'goal',
        name: 'Milo Mapmaker',
        functionName: 'goal-decomposition-agent',
        role: 'Goal planner',
        description:
            'Turns a goal into milestones and dated task rows, then keeps the active goal snapshot readable in the app.',
        trigger: 'When you create or refresh an active goal.',
        dataUsed: 'Goal title, target date, context, recent mood, habits.',
        status: _status(
          now: now,
          lastRunAt: goalPlan,
          needsData: activeGoal == null,
          eventDriven: true,
        ),
        lastRunAt: goalPlan,
        nextRunLabel: activeGoal == null
            ? 'Waiting for a goal'
            : 'When you change goal',
      ),
      LuminaAgent(
        id: 'mentor',
        name: 'Luna Listener',
        functionName: 'ask-mentor',
        role: 'Chat mentor',
        description:
            'Answers mentor chat with your actual recent logs, tasks, habits, goals, and insight feed as context.',
        trigger: 'When you send a mentor chat message.',
        dataUsed: 'Selected day feed, recent logs, active goal, insights.',
        status: _status(now: now, lastRunAt: chat, eventDriven: true),
        lastRunAt: chat,
        nextRunLabel: 'When you ask a question',
      ),
      LuminaAgent(
        id: 'reflection',
        name: 'Nova Note',
        functionName: 'generate-daily-reflection',
        role: 'Reflection writer',
        description:
            'Creates a grounded daily reflection from your latest real activity instead of a canned response.',
        trigger: 'When the Mentor page requests the daily reflection.',
        dataUsed: 'Today log, task completion, habits, active goal.',
        status: _status(
          now: now,
          lastRunAt: dailyReflection,
          needsData: latestLogAt == null,
          eventDriven: true,
        ),
        lastRunAt: dailyReflection,
        nextRunLabel: latestLogAt == null
            ? 'Waiting for a daily log'
            : 'On next reflection request',
      ),
      LuminaAgent(
        id: 'weekly',
        name: 'Sage Sunday',
        functionName: 'weekly-debrief-agent',
        role: 'Weekly reviewer',
        description:
            'Summarizes the week, highlights progress, and creates a debrief insight from logged behavior.',
        trigger: 'Weekly scheduled debrief.',
        dataUsed: 'Seven-day mood, energy, task, habit, and note history.',
        status: _status(now: now, lastRunAt: weeklyDebrief),
        lastRunAt: weeklyDebrief,
        nextRunAt: _nextWeekday(now, DateTime.sunday, hour: 18),
        nextRunLabel: 'Next weekly debrief',
      ),
      LuminaAgent(
        id: 'weekly-plan',
        name: 'Tilly Tempo',
        functionName: 'generate-weekly-plan',
        role: 'Weekly plan composer',
        description:
            'Drafts a seven-day growth plan from your current pattern data when the Mentor page needs one.',
        trigger: 'When weekly plan data is requested.',
        dataUsed: 'Pattern summary from real logs and completion history.',
        status: _status(
          now: now,
          lastRunAt: null,
          needsData: insights.isEmpty,
          eventDriven: true,
        ),
        nextRunAt: _nextWeekday(now, DateTime.monday, hour: 8),
        nextRunLabel: insights.isEmpty
            ? 'Waiting for pattern data'
            : 'Next plan window',
      ),
    ];
  }

  AgentStatus _status({
    required DateTime now,
    required DateTime? lastRunAt,
    bool needsData = false,
    bool eventDriven = false,
  }) {
    if (needsData) {
      return AgentStatus.waiting;
    }
    if (lastRunAt != null && now.difference(lastRunAt.toLocal()).inHours < 12) {
      return AgentStatus.recent;
    }
    return eventDriven ? AgentStatus.listening : AgentStatus.scheduled;
  }

  DateTime? _lastInsight(
    List<Map<String, dynamic>> insights, {
    Set<String> types = const {},
    Set<String> sources = const {},
  }) {
    for (final insight in insights) {
      final type = insight['insight_type'] as String?;
      final metadata = _mapValue(insight['metadata']) ?? const {};
      final source = metadata['source'] as String?;
      final matchesType = types.isEmpty || types.contains(type);
      final matchesSource = sources.isEmpty || sources.contains(source);
      if (matchesType || matchesSource) {
        return _parseDate(insight['generated_at']);
      }
    }
    return null;
  }

  DateTime? _latestOf(DateTime? first, DateTime? second) {
    if (first == null) {
      return second;
    }
    if (second == null) {
      return first;
    }
    return first.isAfter(second) ? first : second;
  }

  DateTime _nextDaily(DateTime now, {required int hour, int minute = 0}) {
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _nextWeekday(
    DateTime now,
    int weekday, {
    required int hour,
    int minute = 0,
  }) {
    var days = (weekday - now.weekday) % 7;
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: days));
    if (!next.isAfter(now)) {
      days = days == 0 ? 7 : days;
      next = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).add(Duration(days: days));
    }
    return next;
  }

  List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
