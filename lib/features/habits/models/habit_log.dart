// lib/features/habits/models/habit_log.dart

class HabitLog {
  final int? id;
  final int habitId; // which habit this log belongs to
  final DateTime date; // ALWAYS normalized to midnight: DateTime(y, m, d)
  final bool completed; // true = honored, false = skipped
  final DateTime loggedAt; // exact moment the user tapped

  const HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'completed': completed ? 1 : 0,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
        id: map['id'] as int?,
        habitId: map['habitId'] as int,
        date: DateTime.parse(map['date'] as String),
        completed: (map['completed'] as int) == 1,
        loggedAt: DateTime.parse(map['loggedAt'] as String),
      );
}

// Helper — call this before saving any log date.
// Ensures streak calculations are never broken by time-of-day.
DateTime normalizeToMidnight(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day);
