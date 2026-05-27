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
    required this.selectedDate,
    this.coachingMission,
    this.isFeedLoading = false,
  });

  final MentorInsight dailyReflection;
  final CoachingMission? coachingMission;
  final List<WeeklyPlanDay> weeklyPlan;
  final List<MentorInsight> insightFeed;
  final DateTime selectedDate;
  final bool isFeedLoading;

  MentorState copyWith({
    MentorInsight? dailyReflection,
    Object? coachingMission = _unchanged,
    List<WeeklyPlanDay>? weeklyPlan,
    List<MentorInsight>? insightFeed,
    DateTime? selectedDate,
    bool? isFeedLoading,
  }) {
    return MentorState(
      dailyReflection: dailyReflection ?? this.dailyReflection,
      coachingMission: coachingMission == _unchanged
          ? this.coachingMission
          : coachingMission as CoachingMission?,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      insightFeed: insightFeed ?? this.insightFeed,
      selectedDate: selectedDate ?? this.selectedDate,
      isFeedLoading: isFeedLoading ?? this.isFeedLoading,
    );
  }
}

class MentorNotifier extends AsyncNotifier<MentorState> {
  MentorRepository get _repository => ref.read(mentorRepositoryProvider);
  DateTime _selectedDate = _dateOnly(DateTime.now());

  @override
  Future<MentorState> build() async {
    final results = await Future.wait<Object?>([
      _repository.getDailyReflection(),
      _repository.getCoachingMission(),
      _repository.getWeeklyPlan(),
      _repository.getInsightFeed(date: _selectedDate),
    ]);
    return MentorState(
      dailyReflection: results[0] as MentorInsight,
      coachingMission: results[1] as CoachingMission?,
      weeklyPlan: results[2] as List<WeeklyPlanDay>,
      insightFeed: results[3] as List<MentorInsight>,
      selectedDate: _selectedDate,
    );
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.valueOrNull;
    final nextDate = _dateOnly(date);
    if (current == null ||
        current.selectedDate.year == nextDate.year &&
            current.selectedDate.month == nextDate.month &&
            current.selectedDate.day == nextDate.day) {
      return;
    }
    _selectedDate = nextDate;
    state = AsyncData(
      current.copyWith(selectedDate: nextDate, isFeedLoading: true),
    );
    final feed = await _repository.getInsightFeed(date: nextDate);
    final latest = state.valueOrNull ?? current;
    state = AsyncData(
      latest.copyWith(
        selectedDate: nextDate,
        insightFeed: feed,
        isFeedLoading: false,
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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
