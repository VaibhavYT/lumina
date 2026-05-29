import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';
import 'package:lumina/core/services/sync_service.dart';
import 'package:lumina/features/log/data/repositories/log_repository.dart';

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

  factory WeeklyPlanDay.fromJson(Map<dynamic, dynamic> json) {
    return WeeklyPlanDay(
      day: json['day'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      action: json['action'] as String? ?? '',
      microHabit: json['microHabit'] as String? ?? '',
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

  String get todayAction {
    if (actions.isEmpty) {
      return 'Add a few daily logs to unlock a coaching action.';
    }
    return actions[dayIndex.clamp(0, actions.length - 1)];
  }

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

enum MentorChatRole { user, assistant }

class MentorChatMessage {
  MentorChatMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final MentorChatRole role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toPayload() {
    return {
      'role': role == MentorChatRole.assistant ? 'assistant' : 'user',
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MentorRepository {
  MentorRepository({
    EdgeFunctionClient? edgeClient,
    DeviceIdentityService? identityService,
    SyncService? syncService,
    LogRepository? logRepository,
  }) : _edgeClient = edgeClient ?? EdgeFunctionClient(),
       _identityService = identityService ?? DeviceIdentityService(),
       _syncService = syncService ?? SyncService(),
       _logRepository = logRepository ?? LogRepository();

  final EdgeFunctionClient _edgeClient;
  final DeviceIdentityService _identityService;
  final SyncService _syncService;
  final LogRepository _logRepository;

  Future<String> get deviceId => _identityService.getDeviceId();

  Future<MentorInsight> getDailyReflection() async {
    final id = await deviceId;
    final result = await _edgeClient.invoke(
      'generate-daily-reflection',
      payload: {'deviceId': id},
      headers: {'x-device-id': id},
    );
    final body = result.data?['reflection'] as String?;
    return MentorInsight(
      headline: "Today's Reflection",
      body: body?.trim().isNotEmpty == true
          ? body!.trim()
          : 'Log today to generate a reflection from your real mood, energy, tasks, and notes.',
      insightType: 'daily_reflection',
    );
  }

  Future<List<MentorInsight>> getInsightFeed({DateTime? date}) async {
    final id = await deviceId;
    return _syncService.fetchRecentInsights(id, date: date);
  }

  Future<List<WeeklyPlanDay>> getWeeklyPlan() async {
    final patterns = await _mentorPatterns(rangeDays: 30);
    if ((patterns['days'] as List<dynamic>? ?? const []).length < 3) {
      return const [];
    }

    final result = await _edgeClient.invoke(
      'generate-weekly-plan',
      payload: {'patterns': patterns},
    );
    final plan = result.data?['plan'];
    if (plan is! List) {
      return const [];
    }
    return plan
        .whereType<Map<dynamic, dynamic>>()
        .map(WeeklyPlanDay.fromJson)
        .where(
          (item) =>
              item.day.isNotEmpty &&
              item.theme.isNotEmpty &&
              item.action.isNotEmpty,
        )
        .take(7)
        .toList();
  }

  Future<CoachingMission?> getCoachingMission() async {
    final patterns = await _mentorPatterns(rangeDays: 30);
    if ((patterns['days'] as List<dynamic>? ?? const []).length < 3) {
      return null;
    }

    final result = await _edgeClient.invoke(
      'detect-burnout-coaching',
      payload: {'patterns': patterns},
    );
    final coaching = result.data?['coaching'];
    if (coaching is! Map) {
      return null;
    }
    final actions = (coaching['dailyActions'] as List? ?? const [])
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .take(7)
        .toList();
    if (actions.isEmpty) {
      return null;
    }

    return CoachingMission(
      title: coaching['coachingTitle'] as String? ?? 'Current Focus',
      reason:
          coaching['coachingReason'] as String? ??
          'This focus was generated from your recent logs.',
      dayIndex: DateTime.now().weekday - 1,
      doneToday: await _coachingDoneToday(),
      actions: actions,
    );
  }

  Future<MentorChatMessage> sendChatMessage({
    required String question,
    required String sessionId,
    required List<MentorChatMessage> history,
    Map<String, dynamic> context = const <String, dynamic>{
      'source': 'lumina_chat',
    },
    String fallbackAnswer =
        'I could not reach the mentor service. Try again after your latest log syncs.',
  }) async {
    final id = await deviceId;
    final result = await _edgeClient.invoke(
      'ask-mentor',
      payload: {
        'deviceId': id,
        'sessionId': sessionId,
        'question': question,
        'history': history.map((message) => message.toPayload()).toList(),
        'context': context,
      },
      headers: {'x-device-id': id},
    );
    final answer = result.data?['answer'] as String?;
    final content = answer?.trim().isNotEmpty == true
        ? answer!.trim()
        : fallbackAnswer;
    return MentorChatMessage(role: MentorChatRole.assistant, content: content);
  }

  Future<MentorChatMessage> sendUntangleReply({
    required String reply,
    required String sessionId,
    required List<MentorChatMessage> history,
  }) {
    return sendChatMessage(
      question: reply,
      sessionId: sessionId,
      history: history,
      context: {
        'source': 'untangle',
        'stage': 'socratic',
        'turnCount': history.length,
      },
      fallbackAnswer:
          'What feels most true about that, even if it is uncomfortable to say plainly?',
    );
  }

  Future<String> synthesizeBreakthrough({
    required String sessionId,
    required List<MentorChatMessage> history,
  }) async {
    final answer = await sendChatMessage(
      question: 'Create the final Breakthrough card for this Untangle session.',
      sessionId: sessionId,
      history: history,
      context: {
        'source': 'untangle',
        'stage': 'breakthrough',
        'turnCount': history.length,
      },
      fallbackAnswer: _localBreakthrough(history),
    );
    return answer.content;
  }

  Future<void> saveBreakthroughToJournal(String breakthrough) {
    return _logRepository.appendJournalEntry(
      'Breakthrough - ${DateTime.now().toIso8601String().substring(0, 10)}\n\n'
      '${breakthrough.trim()}',
    );
  }

  Future<void> dismissInsight(String id) async {
    final deviceId = await this.deviceId;
    await _edgeClient.invoke(
      'fetch-mentor-insights',
      payload: {'action': 'dismiss', 'deviceId': deviceId, 'insightId': id},
      headers: {'x-device-id': deviceId},
    );
  }

  Future<void> setCoachingDone(bool done) async {
    final box = await _box();
    await box?.put(
      'coaching_done_${DateTime.now().toIso8601String().substring(0, 10)}',
      done,
    );
  }

  Future<Map<String, dynamic>> _mentorPatterns({required int rangeDays}) async {
    final id = await deviceId;
    final result = await _edgeClient.invoke(
      'app-data',
      payload: {'action': 'insights', 'device_id': id, 'rangeDays': rangeDays},
      headers: {'x-device-id': id},
    );
    return result.data ?? const {};
  }

  Future<bool> _coachingDoneToday() async {
    final box = await _box();
    return box?.get(
              'coaching_done_${DateTime.now().toIso8601String().substring(0, 10)}',
              defaultValue: false,
            )
            as bool? ??
        false;
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

String _localBreakthrough(List<MentorChatMessage> history) {
  final userReplies = history
      .where((message) => message.role == MentorChatRole.user)
      .map((message) => message.content.trim())
      .where((content) => content.isNotEmpty)
      .toList();
  final first = userReplies.isEmpty
      ? 'This matters to you.'
      : userReplies.first;
  final last = userReplies.isEmpty ? first : userReplies.last;
  return 'Pattern: $first\n\n'
      'Truth: $last\n\n'
      'Next brave move: Choose one small action that respects this truth today.';
}
