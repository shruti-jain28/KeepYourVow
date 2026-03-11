// lib/features/habits/models/habit.dart

/// Frequency options for a habit.
enum HabitFrequency {
  daily,
  weekly,
  monthly,
  weekdays,
  weekends;

  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.weekdays:
        return 'Weekdays';
      case HabitFrequency.weekends:
        return 'Weekends';
    }
  }
}

class Habit {
  final int? id; // null until saved to DB
  final String title; // e.g. 'Morning run — 20 mins'
  final bool isDaily; // if false, check scheduledDays
  final List<int> scheduledDays; // 1=Mon...7=Sun; empty = every day
  final DateTime createdAt;
  final int? goalId; // null = standalone habit
  final HabitFrequency frequency;
  final String? startTime; // e.g. "07:30" — nullable for legacy habits

  // Streak — recomputed and cached after each completion
  final int currentStreak;
  final int longestStreak;

  const Habit({
    this.id,
    required this.title,
    this.isDaily = true,
    this.scheduledDays = const [],
    required this.createdAt,
    this.goalId,
    this.frequency = HabitFrequency.daily,
    this.startTime,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  Habit copyWith({
    int? id,
    String? title,
    bool? isDaily,
    List<int>? scheduledDays,
    DateTime? createdAt,
    int? goalId,
    HabitFrequency? frequency,
    String? startTime,
    int? currentStreak,
    int? longestStreak,
  }) =>
      Habit(
        id: id ?? this.id,
        title: title ?? this.title,
        isDaily: isDaily ?? this.isDaily,
        scheduledDays: scheduledDays ?? this.scheduledDays,
        createdAt: createdAt ?? this.createdAt,
        goalId: goalId ?? this.goalId,
        frequency: frequency ?? this.frequency,
        startTime: startTime ?? this.startTime,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'isDaily': isDaily ? 1 : 0,
        'scheduledDays': scheduledDays.join(','),
        'createdAt': createdAt.toIso8601String(),
        'goalId': goalId,
        'frequency': frequency.name,
        'startTime': startTime,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  factory Habit.fromMap(Map<String, dynamic> map) {
    final daysStr = map['scheduledDays'] as String? ?? '';
    final days = daysStr.isEmpty
        ? <int>[]
        : daysStr.split(',').map(int.parse).toList();
    final freqStr = map['frequency'] as String? ?? 'daily';
    final freq = HabitFrequency.values.firstWhere(
      (f) => f.name == freqStr,
      orElse: () => HabitFrequency.daily,
    );
    return Habit(
      id: map['id'] as int?,
      title: map['title'] as String,
      isDaily: (map['isDaily'] as int) == 1,
      scheduledDays: days,
      createdAt: DateTime.parse(map['createdAt'] as String),
      goalId: map['goalId'] as int?,
      frequency: freq,
      startTime: map['startTime'] as String?,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
    );
  }
}
