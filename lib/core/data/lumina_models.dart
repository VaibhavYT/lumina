import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TaskPriority {
  high,
  normal,
  low;

  static TaskPriority fromName(String? value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => TaskPriority.normal,
    );
  }
}

@immutable
class Task {
  Task({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.priority = TaskPriority.normal,
    DateTime? dueDate,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       dueDate = dueDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime dueDate;
  final DateTime createdAt;

  Task copyWith({
    String? title,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    return Task(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: TaskPriority.fromName(json['priority'] as String?),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

@immutable
class MoodEntry {
  MoodEntry({
    String? id,
    required this.mood,
    required this.energy,
    this.note,
    DateTime? timestamp,
  }) : id = id ?? _uuid.v4(),
       timestamp = timestamp ?? DateTime.now();

  final String id;
  final int mood;
  final int energy;
  final String? note;
  final DateTime timestamp;

  String get emoji => switch (mood) {
    1 => ':(',
    2 => ':/',
    3 => ':|',
    4 => ':)',
    _ => ':D',
  };

  String get label => switch (mood) {
    1 => 'struggling',
    2 => 'low',
    3 => 'okay',
    4 => 'good',
    _ => 'great',
  };

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood,
      'energy': energy,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoodEntry.fromJson(Map<dynamic, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String?,
      mood: json['mood'] as int? ?? 3,
      energy: json['energy'] as int? ?? 3,
      note: json['note'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
    );
  }
}

@immutable
class HabitProgress {
  const HabitProgress({
    required this.habitId,
    required this.name,
    required this.emoji,
    required this.color,
    required this.completedToday,
    required this.targetPerDay,
  });

  final String habitId;
  final String name;
  final String emoji;
  final Color color;
  final int completedToday;
  final int targetPerDay;

  double get progress {
    if (targetPerDay == 0) {
      return 0;
    }
    return (completedToday / targetPerDay).clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'name': name,
      'emoji': emoji,
      'color': color.toARGB32(),
      'completedToday': completedToday,
      'targetPerDay': targetPerDay,
    };
  }

  factory HabitProgress.fromJson(Map<dynamic, dynamic> json) {
    return HabitProgress(
      habitId: json['habitId'] as String? ?? _uuid.v4(),
      name: json['name'] as String? ?? 'Habit',
      emoji: json['emoji'] as String? ?? '*',
      color: Color(json['color'] as int? ?? 0xFFF0A500),
      completedToday: json['completedToday'] as int? ?? 0,
      targetPerDay: json['targetPerDay'] as int? ?? 1,
    );
  }
}

@immutable
class MentorInsight {
  MentorInsight({
    String? id,
    required this.headline,
    required this.body,
    DateTime? generatedAt,
  }) : id = id ?? _uuid.v4(),
       generatedAt = generatedAt ?? DateTime.now();

  final String id;
  final String headline;
  final String body;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      'body': body,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory MentorInsight.fromJson(Map<dynamic, dynamic> json) {
    return MentorInsight(
      id: json['id'] as String?,
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? ''),
    );
  }
}
