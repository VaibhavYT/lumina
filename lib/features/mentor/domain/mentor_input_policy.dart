import 'package:flutter/services.dart';

class MentorInputPolicy {
  const MentorInputPolicy._();

  static const quickQuestionMaxWords = 80;
  static const untangleReplyMaxWords = 160;

  static final _unsupportedPatterns = [
    RegExp(
      r'\b(code|coding|program|programming|debug|compile|javascript|typescript|python|java|flutter|dart|sql|html|css|api|algorithm|regex)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(solve|calculate|equation|algebra|geometry|calculus|derivative|integral|factor|simplify)\b',
      caseSensitive: false,
    ),
    RegExp(r'\d+\s*[-+*/^=]\s*\d+'),
    RegExp(r'```'),
  ];

  static int wordCount(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  static String? validate(String value, {required int maxWords}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Share what is on your mind first.';
    }
    if (wordCount(trimmed) > maxWords) {
      return 'Keep this under $maxWords words so Lumina can stay focused.';
    }
    if (_unsupportedPatterns.any((pattern) => pattern.hasMatch(trimmed))) {
      return 'Lumina is for your goals, habits, mood, tasks, and personal reflection.';
    }
    return null;
  }
}

class MentorWordLimitFormatter extends TextInputFormatter {
  const MentorWordLimitFormatter(this.maxWords);

  final int maxWords;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return MentorInputPolicy.wordCount(newValue.text) <= maxWords
        ? newValue
        : oldValue;
  }
}
