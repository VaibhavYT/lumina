import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/features/goals/data/repositories/goal_repository.dart';
import 'package:lumina/features/log/presentation/providers/today_log_notifier.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final goalNotifierProvider = AsyncNotifierProvider<GoalNotifier, GoalState>(
  GoalNotifier.new,
);

class GoalState {
  const GoalState({required this.snapshot, this.isPlanning = false});

  final GoalSnapshot snapshot;
  final bool isPlanning;

  GoalState copyWith({GoalSnapshot? snapshot, bool? isPlanning}) {
    return GoalState(
      snapshot: snapshot ?? this.snapshot,
      isPlanning: isPlanning ?? this.isPlanning,
    );
  }
}

class GoalNotifier extends AsyncNotifier<GoalState> {
  GoalRepository get _repository => ref.read(goalRepositoryProvider);

  @override
  Future<GoalState> build() async {
    return GoalState(snapshot: await _repository.getActiveGoal());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () async => GoalState(snapshot: await _repository.getActiveGoal()),
    );
  }

  Future<GoalPlanResult> setGoal({
    required String title,
    required DateTime targetDate,
    String? context,
  }) async {
    return _planGoal(
      () => _repository.setGoal(
        title: title,
        targetDate: targetDate,
        context: context,
      ),
    );
  }

  Future<GoalPlanResult> updateGoal({
    required String goalId,
    required String title,
    required DateTime targetDate,
    String? context,
  }) {
    return _planGoal(
      () => _repository.updateGoal(
        goalId: goalId,
        title: title,
        targetDate: targetDate,
        context: context,
      ),
    );
  }

  Future<GoalPlanResult> replaceGoal({
    required String goalId,
    required String title,
    required DateTime targetDate,
    String? context,
  }) {
    return _planGoal(
      () => _repository.replaceGoal(
        goalId: goalId,
        title: title,
        targetDate: targetDate,
        context: context,
      ),
    );
  }

  Future<void> deleteGoal(String goalId) async {
    await _repository.deleteGoal(goalId);
    ref.invalidate(todayLogNotifierProvider);
    state = const AsyncData(
      GoalState(
        snapshot: GoalSnapshot(goal: null, milestones: [], stats: null),
      ),
    );
  }

  Future<GoalPlanResult> _planGoal(
    Future<GoalPlanResult> Function() plan,
  ) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isPlanning: true));
    }
    try {
      final result = await plan();
      final snapshot = (await _repository.getActiveGoal()).copyWith(
        justCreatedSummary: result.goalSummary,
      );
      state = AsyncData(GoalState(snapshot: snapshot));
      ref.invalidate(todayLogNotifierProvider);
      return result;
    } catch (_) {
      if (current != null) {
        state = AsyncData(current.copyWith(isPlanning: false));
      }
      rethrow;
    }
  }
}
