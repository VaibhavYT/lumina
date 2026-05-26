import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';
import 'package:lumina/core/services/sync_service.dart';

class WeeklyPlanDay {
  const WeeklyPlanDay({
    required this.day,
    required this.theme,
    required this.action,
    required this.microHabit,
  });

  final String day;
  final String theme;
  final String action;
  final String microHabit;

  Map<String, dynamic> toJson() => {
    'day': day,
    'theme': theme,
    'action': action,
    'microHabit': microHabit,
  };

  factory WeeklyPlanDay.fromJson(Map<dynamic, dynamic> json) {
    return WeeklyPlanDay(
      day: json['day'] as String? ?? 'Monday',
      theme: json['theme'] as String? ?? 'Focus',
      action: json['action'] as String? ?? 'Choose one small next step.',
      microHabit: json['microHabit'] as String? ?? 'Write one line.',
    );
  }
}

class CoachingMission {
  const CoachingMission({
    required this.title,
    required this.reason,
    required this.dayIndex,
    required this.actions,
    this.doneToday = false,
  });

  final String title;
  final String reason;
  final int dayIndex;
  final List<String> actions;
  final bool doneToday;

  String get todayAction => actions[dayIndex.clamp(0, actions.length - 1)];

  CoachingMission copyWith({bool? doneToday}) {
    return CoachingMission(
      title: title,
      reason: reason,
      dayIndex: dayIndex,
      actions: actions,
      doneToday: doneToday ?? this.doneToday,
    );
  }
}

class MentorRepository {
  MentorRepository({
    EdgeFunctionClient? edgeClient,
    DeviceIdentityService? identityService,
    SyncService? syncService,
  }) : _edgeClient = edgeClient ?? EdgeFunctionClient(),
       _identityService = identityService ?? DeviceIdentityService(),
       _syncService = syncService ?? SyncService();

  final EdgeFunctionClient _edgeClient;
  final DeviceIdentityService _identityService;
  final SyncService _syncService;

  Future<String> get deviceId => _identityService.getDeviceId();

  Future<MentorInsight> getDailyReflection() async {
    final box = await _box();
    final cached = box?.get('daily_reflection');
    if (cached is Map) {
      return MentorInsight.fromJson(cached);
    }

    final id = await deviceId;
    final result = await _edgeClient.invoke(
      'generate-daily-reflection',
      payload: {
        'deviceId': id,
        'todayLog': {'date': DateTime.now().toIso8601String()},
        'recentLogs': [],
      },
      headers: {'x-device-id': id},
    );
    final body =
        result.data?['reflection'] as String? ??
        'Today is giving you a clear signal: protect the first quiet block, then let the rest of the day become easier to steer.';
    final insight = MentorInsight(headline: "Today's Reflection", body: body);
    await box?.put('daily_reflection', insight.toJson());
    return insight;
  }

  Future<List<MentorInsight>> getInsightFeed() async {
    final id = await deviceId;
    final remote = await _syncService.fetchRecentInsights(id);
    if (remote.isNotEmpty) {
      return remote;
    }
    final box = await _box();
    final raw = box?.get('feed');
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map(MentorInsight.fromJson)
          .toList();
    }
    final seeded = [
      MentorInsight(
        headline: 'Morning focus is becoming your leverage point',
        body:
            'On days where your first task is chosen early, the rest of your task list becomes less reactive.',
      ),
      MentorInsight(
        headline: 'Strength Spotlight',
        body:
            'Your habit rhythm is more consistent than it feels. The quiet wins are accumulating.',
      ),
      MentorInsight(
        headline: 'Gentle Challenge',
        body:
            'Your notes have been short lately. Try one sentence tonight about what needed more space.',
      ),
    ];
    await box?.put('feed', seeded.map((item) => item.toJson()).toList());
    return seeded;
  }

  Future<List<WeeklyPlanDay>> getWeeklyPlan() async {
    final box = await _box();
    final raw = box?.get('weekly_plan');
    if (raw is List && raw.length == 7) {
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map(WeeklyPlanDay.fromJson)
          .toList();
    }
    const plan = [
      WeeklyPlanDay(
        day: 'Monday',
        theme: 'Clean Start',
        action: 'Choose one focus before messages.',
        microHabit: 'Write the first task.',
      ),
      WeeklyPlanDay(
        day: 'Tuesday',
        theme: 'Deep Work',
        action: 'Protect 45 minutes for the hardest task.',
        microHabit: 'Put the phone away.',
      ),
      WeeklyPlanDay(
        day: 'Wednesday',
        theme: 'Energy Check',
        action: 'Take a midday reset before the dip.',
        microHabit: 'Walk ten minutes.',
      ),
      WeeklyPlanDay(
        day: 'Thursday',
        theme: 'Repair',
        action: 'Close one draining open loop.',
        microHabit: 'Send one update.',
      ),
      WeeklyPlanDay(
        day: 'Friday',
        theme: 'Review',
        action: 'Name what worked this week.',
        microHabit: 'Write three bullets.',
      ),
      WeeklyPlanDay(
        day: 'Saturday',
        theme: 'Recovery',
        action: 'Leave one block unscheduled.',
        microHabit: 'Do nothing for five minutes.',
      ),
      WeeklyPlanDay(
        day: 'Sunday',
        theme: 'Preview',
        action: 'Choose Monday’s first step.',
        microHabit: 'Set the opening task.',
      ),
    ];
    await box?.put('weekly_plan', plan.map((item) => item.toJson()).toList());
    return plan;
  }

  Future<CoachingMission> getCoachingMission() async {
    final box = await _box();
    final done =
        box?.get('coaching_done_today', defaultValue: false) as bool? ?? false;
    return CoachingMission(
      title: 'Building Your Morning Routine',
      reason:
          'Your best days begin with fewer decisions. This focus was chosen because early clarity appears to lift both completion and mood.',
      dayIndex: DateTime.now().weekday - 1,
      doneToday: done,
      actions: const [
        'Spend the first 30 minutes without your phone.',
        'Write the day’s first useful action before opening messages.',
        'Do one small hard thing before noon.',
        'Take a recovery pause before switching contexts.',
        'Close one loop before starting a new one.',
        'Choose a low-noise block for recovery.',
        'Plan Monday before Sunday ends.',
      ],
    );
  }

  Future<MentorInsight> askMentor(String question) async {
    final id = await deviceId;
    final result = await _edgeClient.invoke(
      'ask-mentor',
      payload: {
        'deviceId': id,
        'question': question,
        'context': {'source': 'lumina_app'},
      },
      headers: {'x-device-id': id},
    );
    final answer =
        result.data?['answer'] as String? ??
        'Choose the smallest useful next action, then watch what changes in your energy after you do it.';
    final insight = MentorInsight(headline: question, body: answer);
    final feed = await getInsightFeed();
    final box = await _box();
    await box?.put(
      'feed',
      [insight, ...feed].map((item) => item.toJson()).toList(),
    );
    return insight;
  }

  Future<void> dismissInsight(String id) async {
    final deviceId = await this.deviceId;
    await _edgeClient.invoke(
      'fetch-mentor-insights',
      payload: {'action': 'dismiss', 'deviceId': deviceId, 'insightId': id},
      headers: {'x-device-id': deviceId},
    );
    final feed = await getInsightFeed();
    final updated = feed.where((item) => item.id != id).toList();
    final box = await _box();
    await box?.put('feed', updated.map((item) => item.toJson()).toList());
  }

  Future<void> setCoachingDone(bool done) async {
    final box = await _box();
    await box?.put('coaching_done_today', done);
  }

  Future<Box<dynamic>?> _box() async {
    try {
      if (Hive.isBoxOpen(AppConstants.insightsBox)) {
        return Hive.box<dynamic>(AppConstants.insightsBox);
      }
      return await Hive.openBox<dynamic>(AppConstants.insightsBox);
    } on Object {
      return null;
    }
  }
}
