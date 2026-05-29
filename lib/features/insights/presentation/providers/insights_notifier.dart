import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/features/insights/data/repositories/insights_repository.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository();
});

final insightsNotifierProvider =
    AsyncNotifierProvider<InsightsNotifier, InsightsState>(
      InsightsNotifier.new,
    );

class InsightsState {
  const InsightsState({
    required this.range,
    required this.days,
    required this.triggers,
    required this.productivity,
    required this.retrospective,
  });

  final InsightRange range;
  final List<InsightDay> days;
  final List<EmotionalTrigger> triggers;
  final ProductivitySummary productivity;
  final MonthlyRetrospective retrospective;

  double get averageMood {
    if (days.isEmpty) {
      return 0;
    }
    return days.map((day) => day.mood).reduce((a, b) => a + b) / days.length;
  }

  double get averageEnergy {
    if (days.isEmpty) {
      return 0;
    }
    return days.map((day) => day.energy).reduce((a, b) => a + b) / days.length;
  }
}

class InsightsNotifier extends AsyncNotifier<InsightsState> {
  InsightsRepository get _repository => ref.read(insightsRepositoryProvider);
  InsightRange _range = InsightRange.thirty;

  @override
  Future<InsightsState> build() async {
    return _load();
  }

  Future<void> setRange(InsightRange range) async {
    if (_range == range) {
      return;
    }
    _range = range;
    state = const AsyncLoading<InsightsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<InsightsState> _load() async {
    final days = await _repository.getInsightDays(_range);
    final triggers = await _repository.getEmotionalTriggers(days);
    final productivity = _repository.summarizeProductivity(days);
    final retrospective = _repository.buildMonthlyRetrospective(
      _range,
      days,
      triggers,
    );
    return InsightsState(
      range: _range,
      days: days,
      triggers: triggers,
      productivity: productivity,
      retrospective: retrospective,
    );
  }
}
