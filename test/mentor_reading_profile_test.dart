import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/mentor/presentation/widgets/mentor_widgets.dart';

void main() {
  test('mentor reading profile gives low-energy text more room', () {
    const recovery = MentorReadingProfile(mood: 2, energy: 1);
    const neutral = MentorReadingProfile(mood: 3, energy: 3);
    const energized = MentorReadingProfile(mood: 5, energy: 4);

    expect(recovery.lineHeight, 1.70);
    expect(neutral.lineHeight, 1.55);
    expect(energized.lineHeight, 1.46);
  });
}
