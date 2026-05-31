import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/data/lumina_models.dart';

void main() {
  test('goal task metadata survives a JSON round trip', () {
    final task = Task.fromJson({
      'id': '18f910ce-fef6-41ae-9827-aac42b160e6e',
      'title': 'Take one goal step',
      'goal_id': 'e18bcde0-5139-4ed2-849b-466e4997392b',
      'metadata': {
        'source': 'goal_decomposition_agent',
        'tags': ['goal'],
      },
    });

    expect(task.isGoalTask, isTrue);
    expect(task.toJson()['goalId'], 'e18bcde0-5139-4ed2-849b-466e4997392b');
    expect(task.toJson()['metadata'], {
      'source': 'goal_decomposition_agent',
      'tags': ['goal'],
    });
  });
}
