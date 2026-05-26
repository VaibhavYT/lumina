import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';

enum InsightRange {
  seven(7, '7D'),
  thirty(30, '30D'),
  ninety(90, '90D');

  const InsightRange(this.days, this.label);

  final int days;
  final String label;
}

class InsightDay {
  const InsightDay({
    required this.date,
    required this.mood,
    required this.energy,
    required this.tasksAdded,
    required this.tasksCompleted,
    required this.habitRate,
    this.notes = '',
  });

  final DateTime date;
  final int mood;
  final int energy;
  final int tasksAdded;
  final int tasksCompleted;
  final double habitRate;
  final String notes;

  String get weekday => DateFormat('E').format(date);
}

class EmotionalTrigger {
  const EmotionalTrigger({
    required this.tag,
    required this.sentiment,
    required this.frequency,
    required this.moodCorrelation,
  });

  final String tag;
  final String sentiment;
  final int frequency;
  final double moodCorrelation;

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'sentiment': sentiment,
      'frequency': frequency,
      'moodCorrelation': moodCorrelation,
    };
  }

  factory EmotionalTrigger.fromJson(Map<dynamic, dynamic> json) {
    return EmotionalTrigger(
      tag: json['tag'] as String? ?? 'pattern',
      sentiment: json['sentiment'] as String? ?? 'neutral',
      frequency: json['frequency'] as int? ?? 1,
      moodCorrelation: (json['moodCorrelation'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BurnoutSignal {
  const BurnoutSignal({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;
}

class BurnoutAnalysis {
  const BurnoutAnalysis({
    required this.score,
    required this.label,
    required this.signals,
  });

  final int score;
  final String label;
  final List<BurnoutSignal> signals;
}

class ProductivitySummary {
  const ProductivitySummary({
    required this.averageAdded,
    required this.averageCompleted,
    required this.completionRate,
    required this.bestDay,
    required this.challengingDay,
  });

  final double averageAdded;
  final double averageCompleted;
  final double completionRate;
  final String bestDay;
  final String challengingDay;
}

class InsightsRepository {
  InsightsRepository();

  final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  Future<List<InsightDay>> getInsightDays(InsightRange range) async {
    final logsBox = await _openBox(AppConstants.logsBox);
    final tasksBox = await _openBox(AppConstants.tasksBox);
    final habitsBox = await _openBox(AppConstants.habitsBox);
    final days = <InsightDay>[];
    final now = DateTime.now();

    for (var i = range.days - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final key = _keyFormat.format(date);
      final logMap = logsBox?.get('log_$key');
      final moodMap = logsBox?.get('mood_$key');
      final tasksRaw = tasksBox?.get(key);
      final habitsRaw = habitsBox?.get(key);

      final log = logMap is Map ? DailyLog.fromJson(logMap) : null;
      final moodEntry = moodMap is Map ? MoodEntry.fromJson(moodMap) : null;
      final tasks = tasksRaw is List
          ? tasksRaw
                .whereType<Map<dynamic, dynamic>>()
                .map(Task.fromJson)
                .toList()
          : <Task>[];
      final habits = habitsRaw is List
          ? habitsRaw
                .whereType<Map<dynamic, dynamic>>()
                .map(HabitProgress.fromJson)
                .toList()
          : <HabitProgress>[];

      days.add(
        InsightDay(
          date: date,
          mood: log?.mood ?? moodEntry?.mood ?? _seedMood(i),
          energy: log?.energy ?? moodEntry?.energy ?? _seedEnergy(i),
          tasksAdded: log?.tasks.length ?? tasks.length,
          tasksCompleted: (log?.tasks ?? tasks)
              .where((task) => task.isCompleted)
              .length,
          habitRate: habits.isEmpty
              ? _seedHabitRate(i)
              : habits.map((habit) => habit.progress).reduce((a, b) => a + b) /
                    habits.length,
          notes: log?.notes ?? '',
        ),
      );
    }

    return days;
  }

  BurnoutAnalysis analyzeBurnout(List<InsightDay> days, AppColorsShim colors) {
    var score = 0;
    final signals = <BurnoutSignal>[];
    final recent = days.takeLast(math.min(days.length, 7)).toList();
    final lowMoodStreak = _longestStreak(recent.map((day) => day.mood < 3));
    final lowEnergyStreak = _longestStreak(recent.map((day) => day.energy < 3));
    final habitRate = recent.isEmpty
        ? 1.0
        : recent.map((day) => day.habitRate).reduce((a, b) => a + b) /
              recent.length;
    final taskRate = recent.isEmpty
        ? 1.0
        : recent
                  .map((day) {
                    if (day.tasksAdded == 0) {
                      return 1.0;
                    }
                    return day.tasksCompleted / day.tasksAdded;
                  })
                  .reduce((a, b) => a + b) /
              recent.length;

    if (lowMoodStreak >= 3) {
      score += 30;
      signals.add(
        BurnoutSignal(
          label: 'Low mood for $lowMoodStreak days',
          score: 30,
          color: colors.error,
        ),
      );
    }
    if (lowEnergyStreak >= 3) {
      score += 25;
      signals.add(
        BurnoutSignal(
          label: 'Energy has been running low',
          score: 25,
          color: colors.warning,
        ),
      );
    }
    if (habitRate < 0.4) {
      score += 20;
      signals.add(
        BurnoutSignal(
          label: 'Habit consistency below 40%',
          score: 20,
          color: colors.warning,
        ),
      );
    }
    if (taskRate < 0.3) {
      score += 15;
      signals.add(
        BurnoutSignal(
          label: 'Task completion is under 30%',
          score: 15,
          color: colors.error,
        ),
      );
    }
    if (signals.isEmpty) {
      signals.add(
        BurnoutSignal(
          label: 'Recovery rhythm looks stable',
          score: 0,
          color: colors.success,
        ),
      );
    }

    final clamped = score.clamp(0, 100);
    final label = clamped <= 30
        ? 'Balanced'
        : clamped <= 60
        ? 'Watch Out'
        : 'High Risk';

    return BurnoutAnalysis(score: clamped, label: label, signals: signals);
  }

  ProductivitySummary summarizeProductivity(List<InsightDay> days) {
    if (days.isEmpty) {
      return const ProductivitySummary(
        averageAdded: 0,
        averageCompleted: 0,
        completionRate: 0,
        bestDay: 'Mon',
        challengingDay: 'Fri',
      );
    }

    final added = days.map((day) => day.tasksAdded).reduce((a, b) => a + b);
    final completed = days
        .map((day) => day.tasksCompleted)
        .reduce((a, b) => a + b);
    final grouped = <int, List<InsightDay>>{};
    for (final day in days) {
      grouped.putIfAbsent(day.date.weekday, () => []).add(day);
    }

    String labelFor(int weekday) =>
        DateFormat('EEEE').format(DateTime(2024, 1, weekday));
    final sorted = grouped.entries.toList()
      ..sort((a, b) {
        double rate(List<InsightDay> source) {
          final total = source
              .map((day) => day.tasksAdded)
              .fold<int>(0, (a, b) => a + b);
          if (total == 0) {
            return 1;
          }
          return source
                  .map((day) => day.tasksCompleted)
                  .fold<int>(0, (a, b) => a + b) /
              total;
        }

        return rate(b.value).compareTo(rate(a.value));
      });

    return ProductivitySummary(
      averageAdded: added / days.length,
      averageCompleted: completed / days.length,
      completionRate: added == 0 ? 1 : completed / added,
      bestDay: labelFor(sorted.first.key),
      challengingDay: labelFor(sorted.last.key),
    );
  }

  Future<List<EmotionalTrigger>> getEmotionalTriggers(
    List<InsightDay> days,
  ) async {
    final box = await _openBox(AppConstants.insightsBox);
    final cached = box?.get('emotional_triggers_cache');
    if (cached is Map) {
      final generatedAt = DateTime.tryParse(
        cached['generatedAt'] as String? ?? '',
      );
      final raw = cached['triggers'];
      if (generatedAt != null &&
          DateTime.now().difference(generatedAt).inHours < 24 &&
          raw is List) {
        return raw
            .whereType<Map<dynamic, dynamic>>()
            .map(EmotionalTrigger.fromJson)
            .toList();
      }
    }

    final triggers = _seedTriggers(days);
    await box?.put('emotional_triggers_cache', {
      'generatedAt': DateTime.now().toIso8601String(),
      'triggers': triggers.map((trigger) => trigger.toJson()).toList(),
    });
    return triggers;
  }

  Future<Box<dynamic>?> _openBox(String name) async {
    try {
      if (Hive.isBoxOpen(name)) {
        return Hive.box<dynamic>(name);
      }
      return await Hive.openBox<dynamic>(name);
    } on Object {
      return null;
    }
  }

  int _seedMood(int offset) =>
      3 + (math.sin(offset / 2) * 1.4).round().clamp(-2, 2);

  int _seedEnergy(int offset) =>
      3 + (math.cos(offset / 3) * 1.5).round().clamp(-2, 2);

  double _seedHabitRate(int offset) =>
      (0.48 + math.sin(offset / 3) * 0.32).clamp(0.05, 1);

  int _longestStreak(Iterable<bool> values) {
    var current = 0;
    var longest = 0;
    for (final value in values) {
      current = value ? current + 1 : 0;
      longest = math.max(longest, current);
    }
    return longest;
  }

  List<EmotionalTrigger> _seedTriggers(List<InsightDay> days) {
    return const [
      EmotionalTrigger(
        tag: 'early focus',
        sentiment: 'positive',
        frequency: 8,
        moodCorrelation: 0.72,
      ),
      EmotionalTrigger(
        tag: 'late messages',
        sentiment: 'negative',
        frequency: 6,
        moodCorrelation: -0.58,
      ),
      EmotionalTrigger(
        tag: 'movement',
        sentiment: 'positive',
        frequency: 5,
        moodCorrelation: 0.49,
      ),
      EmotionalTrigger(
        tag: 'sleep debt',
        sentiment: 'negative',
        frequency: 4,
        moodCorrelation: -0.64,
      ),
      EmotionalTrigger(
        tag: 'quiet planning',
        sentiment: 'neutral',
        frequency: 3,
        moodCorrelation: 0.18,
      ),
    ];
  }
}

extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final items = toList();
    return items.skip(math.max(0, items.length - count));
  }
}

class AppColorsShim {
  const AppColorsShim({
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color success;
  final Color warning;
  final Color error;
}
