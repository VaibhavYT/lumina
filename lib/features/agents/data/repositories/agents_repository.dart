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
    this.latestResult,
    this.resultCount = 0,
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
  final AgentResult? latestResult;
  final int resultCount;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
}

class AgentResult {
  const AgentResult({
    required this.label,
    required this.headline,
    required this.body,
    this.createdAt,
  });

  final String label;
  final String headline;
  final String body;
  final DateTime? createdAt;
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
    final morningBrief = _latestInsight(insights, types: {'morning_brief'});
    final burnout = _latestInsight(insights, types: {'burnout_warning'});
    final patterns = _latestInsight(
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
    final weeklyDebrief = _latestInsight(insights, types: {'weekly_debrief'});
    final dailyReflection = _latestInsight(
      insights,
      types: {'daily_reflection'},
      sources: {'generate-daily-reflection'},
    );
    final goalInsight = _latestInsight(
      insights,
      types: {'goal_created'},
      sources: {'goal_decomposition_agent'},
    );
    final goalPlanAt = _latestOf(
      _insightDate(goalInsight),
      _parseDate(activeGoal?['updated_at'] ?? activeGoal?['created_at']),
    );
    final chat = chats.isEmpty ? null : chats.first;
    final chatAt = _parseDate(chat?['created_at']);

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
        status: _status(now: now, lastRunAt: _insightDate(morningBrief)),
        lastRunAt: _insightDate(morningBrief),
        latestResult: _insightResult(morningBrief, label: 'Morning note'),
        resultCount: _insightCount(insights, types: {'morning_brief'}),
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
          lastRunAt: _insightDate(burnout),
          needsData: latestLogAt == null,
          eventDriven: true,
        ),
        lastRunAt: _insightDate(burnout),
        latestResult: _insightResult(burnout, label: 'Care note'),
        resultCount: _insightCount(insights, types: {'burnout_warning'}),
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
        status: _status(now: now, lastRunAt: _insightDate(patterns)),
        lastRunAt: _insightDate(patterns),
        latestResult: _insightResult(patterns, label: 'Pattern spotted'),
        resultCount: _insightCount(
          insights,
          types: {
            'pattern',
            'strength',
            'behavioral_observation',
            'gentle_challenge',
            'momentum',
          },
          sources: {'pattern_mining_agent'},
        ),
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
          lastRunAt: goalPlanAt,
          needsData: activeGoal == null,
          eventDriven: true,
        ),
        lastRunAt: goalPlanAt,
        latestResult:
            _insightResult(goalInsight, label: 'Goal map') ??
            _goalResult(activeGoal),
        resultCount: activeGoal == null ? 0 : 1,
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
        status: _status(now: now, lastRunAt: chatAt, eventDriven: true),
        lastRunAt: chatAt,
        latestResult: _chatResult(chat),
        resultCount: chats.length,
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
          lastRunAt: _insightDate(dailyReflection),
          needsData: latestLogAt == null,
          eventDriven: true,
        ),
        lastRunAt: _insightDate(dailyReflection),
        latestResult: _insightResult(dailyReflection, label: 'Reflection'),
        resultCount: _insightCount(
          insights,
          types: {'daily_reflection'},
          sources: {'generate-daily-reflection'},
        ),
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
        status: _status(now: now, lastRunAt: _insightDate(weeklyDebrief)),
        lastRunAt: _insightDate(weeklyDebrief),
        latestResult: _insightResult(weeklyDebrief, label: 'Weekly debrief'),
        resultCount: _insightCount(insights, types: {'weekly_debrief'}),
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

  AgentResult? _insightResult(
    Map<String, dynamic>? insight, {
    required String label,
  }) {
    if (insight == null) {
      return null;
    }
    final body = _text(insight['body']);
    if (body == null) {
      return null;
    }
    return AgentResult(
      label: label,
      headline: _text(insight['headline']) ?? label,
      body: body,
      createdAt: _parseDate(insight['generated_at']),
    );
  }

  AgentResult? _goalResult(Map<String, dynamic>? goal) {
    if (goal == null) {
      return null;
    }
    final title = _text(goal['title']);
    if (title == null) {
      return null;
    }
    return AgentResult(
      label: 'Active goal',
      headline: title,
      body:
          _text(goal['description']) ??
          'Your active goal map is ready. Milo will refresh the daily steps when the goal changes.',
      createdAt: _parseDate(goal['updated_at'] ?? goal['created_at']),
    );
  }

  AgentResult? _chatResult(Map<String, dynamic>? chat) {
    if (chat == null) {
      return null;
    }
    final body = _text(chat['content']);
    if (body == null) {
      return null;
    }
    return AgentResult(
      label: 'Latest reply',
      headline: 'A note from your mentor',
      body: body,
      createdAt: _parseDate(chat['created_at']),
    );
  }

  DateTime? _insightDate(Map<String, dynamic>? insight) {
    return _parseDate(insight?['generated_at']);
  }

  Map<String, dynamic>? _latestInsight(
    List<Map<String, dynamic>> insights, {
    Set<String> types = const {},
    Set<String> sources = const {},
  }) {
    for (final insight in insights) {
      if (_matchesInsight(insight, types: types, sources: sources)) {
        return insight;
      }
    }
    return null;
  }

  int _insightCount(
    List<Map<String, dynamic>> insights, {
    Set<String> types = const {},
    Set<String> sources = const {},
  }) {
    return insights
        .where(
          (insight) =>
              _matchesInsight(insight, types: types, sources: sources),
        )
        .length;
  }

  bool _matchesInsight(
    Map<String, dynamic> insight, {
    required Set<String> types,
    required Set<String> sources,
  }) {
    final type = insight['insight_type'] as String?;
    final metadata = _mapValue(insight['metadata']) ?? const {};
    final source = metadata['source'] as String?;
    return (types.isEmpty || types.contains(type)) &&
        (sources.isEmpty || sources.contains(source));
  }

  String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
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
