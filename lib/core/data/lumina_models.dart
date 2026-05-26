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
      isCompleted:
          json['isCompleted'] as bool? ??
          json['is_completed'] as bool? ??
          false,
      priority: TaskPriority.fromName(json['priority'] as String?),
      dueDate: DateTime.tryParse(
        json['dueDate'] as String? ?? json['log_date'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      ),
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

  HabitProgress copyWith({
    String? habitId,
    String? name,
    String? emoji,
    Color? color,
    int? completedToday,
    int? targetPerDay,
  }) {
    return HabitProgress(
      habitId: habitId ?? this.habitId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      completedToday: completedToday ?? this.completedToday,
      targetPerDay: targetPerDay ?? this.targetPerDay,
    );
  }

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
    this.insightType = 'general',
    this.metadata = const {},
    DateTime? generatedAt,
  }) : id = id ?? _uuid.v4(),
       generatedAt = generatedAt ?? DateTime.now();

  final String id;
  final String headline;
  final String body;
  final String insightType;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      'body': body,
      'insightType': insightType,
      'metadata': metadata,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory MentorInsight.fromJson(Map<dynamic, dynamic> json) {
    final rawMetadata = json['metadata'];
    return MentorInsight(
      id: json['id'] as String?,
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
      insightType:
          json['insightType'] as String? ??
          json['insight_type'] as String? ??
          'general',
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
      generatedAt: DateTime.tryParse(
        json['generatedAt'] as String? ?? json['generated_at'] as String? ?? '',
      ),
    );
  }
}

@immutable
class DailyLog {
  DailyLog({
    String? id,
    required this.date,
    this.mood,
    this.moodNote,
    this.energy,
    this.tasks = const [],
    this.completedHabitIds = const [],
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final DateTime date;
  final int? mood;
  final String? moodNote;
  final int? energy;
  final List<Task> tasks;
  final List<String> completedHabitIds;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get completedSections {
    var count = 0;
    if (mood != null) {
      count++;
    }
    if (energy != null) {
      count++;
    }
    if (tasks.isNotEmpty) {
      count++;
    }
    if (completedHabitIds.isNotEmpty) {
      count++;
    }
    if ((notes ?? '').trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  bool get isComplete => completedSections == 5;

  DailyLog copyWith({
    DateTime? date,
    int? mood,
    String? moodNote,
    int? energy,
    List<Task>? tasks,
    List<String>? completedHabitIds,
    String? notes,
    DateTime? updatedAt,
    bool clearMoodNote = false,
    bool clearNotes = false,
  }) {
    return DailyLog(
      id: id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      moodNote: clearMoodNote ? null : moodNote ?? this.moodNote,
      energy: energy ?? this.energy,
      tasks: tasks ?? this.tasks,
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'moodNote': moodNote,
      'energy': energy,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'completedHabitIds': completedHabitIds,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyLog.fromJson(Map<dynamic, dynamic> json) {
    final rawTasks = json['tasks'];
    final rawHabitIds = json['completedHabitIds'];

    return DailyLog(
      id: json['id'] as String?,
      date:
          DateTime.tryParse(
            json['date'] as String? ?? json['log_date'] as String? ?? '',
          ) ??
          DateTime.now(),
      mood: json['mood'] as int?,
      moodNote: json['moodNote'] as String? ?? json['mood_note'] as String?,
      energy: json['energy'] as int?,
      tasks: rawTasks is List
          ? rawTasks
                .whereType<Map<dynamic, dynamic>>()
                .map(Task.fromJson)
                .toList()
          : const [],
      completedHabitIds: rawHabitIds is List
          ? rawHabitIds.whereType<String>().toList()
          : const [],
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
