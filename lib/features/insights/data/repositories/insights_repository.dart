import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/services/device_identity_service.dart';
import 'package:lumina/core/services/edge_function_client.dart';

enum InsightRange {
  seven(7, '7D'),
  thirty(30, '30D');

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

  factory InsightDay.fromJson(Map<dynamic, dynamic> json) {
    return InsightDay(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      mood: json['mood'] as int? ?? 0,
      energy: json['energy'] as int? ?? 0,
      tasksAdded: json['tasksAdded'] as int? ?? 0,
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      habitRate: (json['habitRate'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
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

class MonthlyRetrospective {
  const MonthlyRetrospective({
    required this.range,
    required this.days,
    required this.monthLabel,
    required this.loggedDays,
    required this.longestHabitStreak,
    required this.energyDelta,
    required this.startEnergy,
    required this.endEnergy,
    required this.averageMood,
    this.positiveTrigger,
  });

  final InsightRange range;
  final List<InsightDay> days;
  final String monthLabel;
  final int loggedDays;
  final int longestHabitStreak;
  final double energyDelta;
  final double startEnergy;
  final double endEnergy;
  final double averageMood;
  final EmotionalTrigger? positiveTrigger;

  bool get hasEnoughData => days.length >= 3;

  String get title =>
      range == InsightRange.thirty ? 'Monthly Retrospective' : 'Recent Stars';

  String get energyStory {
    if (startEnergy == 0 || endEnergy == 0) {
      return 'Energy will reveal itself as you keep logging.';
    }
    if (energyDelta >= 0.2) {
      return 'Your energy lifted by ${energyDelta.toStringAsFixed(1)} points.';
    }
    if (energyDelta <= -0.2) {
      return 'Your energy asked for more recovery this month.';
    }
    return 'Your energy held steady with quiet consistency.';
  }

  String get positiveTriggerLabel {
    final trigger = positiveTrigger;
    if (trigger == null) {
      return 'No positive trigger yet';
    }
    return trigger.tag;
  }

  String get shareText {
    return [
      'Lumina $title - $monthLabel',
      '$loggedDays logged days',
      'Longest habit streak: $longestHabitStreak days',
      energyStory,
      'Brightest trigger: $positiveTriggerLabel',
    ].join('\n');
  }
}

class InsightsRepository {
  InsightsRepository({
    EdgeFunctionClient? edgeClient,
    DeviceIdentityService? identityService,
  }) : _edgeClient = edgeClient ?? EdgeFunctionClient(),
       _identityService = identityService ?? DeviceIdentityService();

  final EdgeFunctionClient _edgeClient;
  final DeviceIdentityService _identityService;
  List<EmotionalTrigger> _lastTriggers = const [];

  Future<List<InsightDay>> getInsightDays(InsightRange range) async {
    final deviceId = await _identityService.getDeviceId();
    final result = await _edgeClient.invoke(
      'app-data',
      payload: {
        'action': 'insights',
        'device_id': deviceId,
        'rangeDays': range.days,
      },
      headers: {'x-device-id': deviceId},
    );
    if (!result.isSuccess) {
      _lastTriggers = const [];
      return const [];
    }
    final data = result.data ?? const {};
    final triggers = data['triggers'];
    _lastTriggers = triggers is List
        ? triggers
              .whereType<Map<dynamic, dynamic>>()
              .map(EmotionalTrigger.fromJson)
              .toList()
        : const [];
    final days = data['days'];
    return days is List
        ? days
              .whereType<Map<dynamic, dynamic>>()
              .map(InsightDay.fromJson)
              .toList()
        : const [];
  }

  BurnoutAnalysis analyzeBurnout(List<InsightDay> days, AppColorsShim colors) {
    var score = 0;
    final signals = <BurnoutSignal>[];
    final recent = days.takeLast(math.min(days.length, 7)).toList();
    final lowMoodStreak = _longestStreak(
      recent.map((day) => day.mood > 0 && day.mood < 3),
    );
    final lowEnergyStreak = _longestStreak(
      recent.map((day) => day.energy > 0 && day.energy < 3),
    );
    final habitRate = recent.isEmpty
        ? 1.0
        : recent.map((day) => day.habitRate).reduce((a, b) => a + b) /
              recent.length;
    final taskRate = recent.isEmpty
        ? 1.0
        : recent
                  .map(
                    (day) => day.tasksAdded == 0
                        ? 1.0
                        : day.tasksCompleted / day.tasksAdded,
                  )
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
          label: days.isEmpty
              ? 'Log data to unlock burnout radar'
              : 'Recovery rhythm looks stable',
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
        bestDay: '-',
        challengingDay: '-',
      );
    }

    final added = days
        .map((day) => day.tasksAdded)
        .fold<int>(0, (a, b) => a + b);
    final completed = days
        .map((day) => day.tasksCompleted)
        .fold<int>(0, (a, b) => a + b);
    final grouped = <int, List<InsightDay>>{};
    for (final day in days) {
      grouped.putIfAbsent(day.date.weekday, () => []).add(day);
    }

    String labelFor(int weekday) =>
        DateFormat('EEEE').format(DateTime(2024, 1, weekday));
    final sorted = grouped.entries.toList()
      ..sort((a, b) => _taskRate(b.value).compareTo(_taskRate(a.value)));

    return ProductivitySummary(
      averageAdded: added / days.length,
      averageCompleted: completed / days.length,
      completionRate: added == 0 ? 0 : completed / added,
      bestDay: labelFor(sorted.first.key),
      challengingDay: labelFor(sorted.last.key),
    );
  }

  MonthlyRetrospective buildMonthlyRetrospective(
    InsightRange range,
    List<InsightDay> days,
    List<EmotionalTrigger> triggers,
  ) {
    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final energy = _energyShift(sorted);
    final positiveTriggers =
        triggers.where((trigger) => trigger.moodCorrelation > 0).toList()
          ..sort((a, b) => b.moodCorrelation.compareTo(a.moodCorrelation));
    final monthLabel = sorted.isEmpty
        ? DateFormat('MMMM yyyy').format(DateTime.now())
        : DateFormat('MMMM yyyy').format(sorted.last.date);

    return MonthlyRetrospective(
      range: range,
      days: sorted,
      monthLabel: monthLabel,
      loggedDays: sorted.length,
      longestHabitStreak: _longestHabitStreak(sorted),
      energyDelta: energy.delta,
      startEnergy: energy.start,
      endEnergy: energy.end,
      averageMood: sorted.isEmpty
          ? 0
          : sorted
                    .where((day) => day.mood > 0)
                    .map((day) => day.mood)
                    .fold<int>(0, (a, b) => a + b) /
                math.max(1, sorted.where((day) => day.mood > 0).length),
      positiveTrigger: positiveTriggers.isEmpty ? null : positiveTriggers.first,
    );
  }

  Future<List<EmotionalTrigger>> getEmotionalTriggers(
    List<InsightDay> days,
  ) async {
    return _lastTriggers;
  }

  double _taskRate(List<InsightDay> source) {
    final total = source
        .map((day) => day.tasksAdded)
        .fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return 0;
    }
    return source
            .map((day) => day.tasksCompleted)
            .fold<int>(0, (a, b) => a + b) /
        total;
  }

  int _longestStreak(Iterable<bool> values) {
    var current = 0;
    var longest = 0;
    for (final value in values) {
      current = value ? current + 1 : 0;
      longest = math.max(longest, current);
    }
    return longest;
  }

  int _longestHabitStreak(List<InsightDay> days) {
    DateTime? previous;
    var current = 0;
    var longest = 0;
    for (final day in days) {
      final currentDate = DateUtils.dateOnly(day.date);
      if (previous != null && currentDate.difference(previous).inDays > 1) {
        current = 0;
      }
      current = day.habitRate > 0 ? current + 1 : 0;
      longest = math.max(longest, current);
      previous = currentDate;
    }
    return longest;
  }

  ({double start, double end, double delta}) _energyShift(
    List<InsightDay> days,
  ) {
    final usable = days.where((day) => day.energy > 0).toList();
    if (usable.length < 2) {
      return (start: 0, end: 0, delta: 0);
    }
    final segmentLength = math.max(1, (usable.length / 3).ceil());
    final start = _averageEnergy(usable.take(segmentLength));
    final end = _averageEnergy(
      usable.skip(math.max(0, usable.length - segmentLength)),
    );
    return (start: start, end: end, delta: end - start);
  }

  double _averageEnergy(Iterable<InsightDay> days) {
    final values = days.map((day) => day.energy).where((value) => value > 0);
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((a, b) => a + b) / values.length;
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
