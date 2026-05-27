import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/features/agents/data/repositories/agents_repository.dart';

final agentsRepositoryProvider = Provider<AgentsRepository>((ref) {
  return AgentsRepository();
});

final agentsNotifierProvider =
    AsyncNotifierProvider<AgentsNotifier, AgentsState>(AgentsNotifier.new);

class AgentsNotifier extends AsyncNotifier<AgentsState> {
  AgentsRepository get _repository => ref.read(agentsRepositoryProvider);

  @override
  Future<AgentsState> build() {
    return _repository.fetchAgents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<AgentsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repository.fetchAgents);
  }
}
