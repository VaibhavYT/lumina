import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/features/mentor/domain/mentor_input_policy.dart';

void main() {
  group('MentorInputPolicy', () {
    test('counts whitespace-separated words', () {
      expect(MentorInputPolicy.wordCount('  one\n two   three '), 3);
    });

    test('rejects coding and math prompts', () {
      expect(
        MentorInputPolicy.validate(
          'Can you debug my Flutter code?',
          maxWords: MentorInputPolicy.quickQuestionMaxWords,
        ),
        isNotNull,
      );
      expect(
        MentorInputPolicy.validate(
          'Calculate 12 + 18 for me',
          maxWords: MentorInputPolicy.quickQuestionMaxWords,
        ),
        isNotNull,
      );
    });

    test('accepts personal growth prompts', () {
      expect(
        MentorInputPolicy.validate(
          'Why do I keep avoiding my morning habit?',
          maxWords: MentorInputPolicy.quickQuestionMaxWords,
        ),
        isNull,
      );
    });
  });
}
