import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/features/mentor/data/repositories/mentor_repository.dart';

final mentorRepositoryProvider = Provider<MentorRepository>((ref) {
  return MentorRepository();
});

final mentorNotifierProvider =
    AsyncNotifierProvider<MentorNotifier, MentorState>(MentorNotifier.new);

class MentorState {
  const MentorState({
    required this.dailyReflection,
    required this.weeklyPlan,
    required this.insightFeed,
    this.coachingMission,
    this.isAsking = false,
  });

  final MentorInsight dailyReflection;
  final CoachingMission? coachingMission;
  final List<WeeklyPlanDay> weeklyPlan;
  final List<MentorInsight> insightFeed;
  final bool isAsking;

  MentorState copyWith({
    MentorInsight? dailyReflection,
    Object? coachingMission = _unchanged,
    List<WeeklyPlanDay>? weeklyPlan,
    List<MentorInsight>? insightFeed,
    bool? isAsking,
  }) {
    return MentorState(
      dailyReflection: dailyReflection ?? this.dailyReflection,
      coachingMission: coachingMission == _unchanged
          ? this.coachingMission
          : coachingMission as CoachingMission?,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      insightFeed: insightFeed ?? this.insightFeed,
      isAsking: isAsking ?? this.isAsking,
    );
  }
}

class MentorNotifier extends AsyncNotifier<MentorState> {
  MentorRepository get _repository => ref.read(mentorRepositoryProvider);

  @override
  Future<MentorState> build() async {
    final results = await Future.wait<Object?>([
      _repository.getDailyReflection(),
      _repository.getCoachingMission(),
      _repository.getWeeklyPlan(),
      _repository.getInsightFeed(),
    ]);
    return MentorState(
      dailyReflection: results[0] as MentorInsight,
      coachingMission: results[1] as CoachingMission?,
      weeklyPlan: results[2] as List<WeeklyPlanDay>,
      insightFeed: results[3] as List<MentorInsight>,
    );
  }

  Future<void> ask(String question) async {
    final current = state.valueOrNull;
    if (current == null || question.trim().isEmpty) {
      return;
    }
    state = AsyncData(current.copyWith(isAsking: true));
    final insight = await _repository.askMentor(question.trim());
    state = AsyncData(
      current.copyWith(
        isAsking: false,
        insightFeed: [insight, ...current.insightFeed],
      ),
    );
  }

  Future<void> dismiss(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _repository.dismissInsight(id);
    state = AsyncData(
      current.copyWith(
        insightFeed: current.insightFeed
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  Future<void> toggleCoachingDone() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final mission = current.coachingMission;
    if (mission == null) {
      return;
    }
    final next = mission.copyWith(doneToday: !mission.doneToday);
    await _repository.setCoachingDone(next.doneToday);
    state = AsyncData(current.copyWith(coachingMission: next));
  }
}

const _unchanged = Object();
