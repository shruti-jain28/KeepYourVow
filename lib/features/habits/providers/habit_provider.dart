// lib/features/habits/providers/habit_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../../../shared/isar/isar_service.dart';

// ─── PROVIDER ────────────────────────────────────────────────────────────────
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final db = IsarService.instance.db;
  final rows = await db.query('habits', orderBy: 'createdAt ASC');
  return rows.map(Habit.fromMap).toList();
});

// ─── NOTIFIER ────────────────────────────────────────────────────────────────
final habitNotifierProvider =
    NotifierProvider<HabitNotifier, void>(HabitNotifier.new);

class HabitNotifier extends Notifier<void> {
  @override
  void build() {}

  Database get _db => IsarService.instance.db;

  Future<void> createHabit({
    required String title,
    bool isDaily = true,
    List<int> scheduledDays = const [],
    int? goalId,
    HabitFrequency frequency = HabitFrequency.daily,
    String? startTime,
  }) async {
    final habit = Habit(
      title: title,
      isDaily: isDaily,
      scheduledDays: scheduledDays,
      createdAt: DateTime.now(),
      goalId: goalId,
      frequency: frequency,
      startTime: startTime,
    );
    await _db.insert('habits', habit.toMap());
    ref.invalidate(habitsProvider);
  }

  Future<void> updateHabit({
    required int habitId,
    required String title,
    required HabitFrequency frequency,
    String? startTime,
    List<int> scheduledDays = const [],
  }) async {
    await _db.update(
      'habits',
      {
        'title': title,
        'frequency': frequency.name,
        'startTime': startTime,
        'scheduledDays': scheduledDays.join(','),
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
    ref.invalidate(habitsProvider);
  }

  Future<void> updateHabitGoal(int habitId, int? goalId) async {
    await _db.update(
      'habits',
      {'goalId': goalId},
      where: 'id = ?',
      whereArgs: [habitId],
    );
    ref.invalidate(habitsProvider);
  }

  Future<void> deleteHabit(int habitId) async {
    await _db.transaction((txn) async {
      await txn.delete('habit_logs',
          where: 'habitId = ?', whereArgs: [habitId]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    });
    ref.invalidate(habitsProvider);
  }

  Future<void> deleteHabitsByGoalId(int goalId) async {
    final rows = await _db.query('habits',
        columns: ['id'], where: 'goalId = ?', whereArgs: [goalId]);
    await _db.transaction((txn) async {
      for (final row in rows) {
        final habitId = row['id'] as int;
        await txn.delete('habit_logs',
            where: 'habitId = ?', whereArgs: [habitId]);
      }
      await txn.delete('habits', where: 'goalId = ?', whereArgs: [goalId]);
    });
    ref.invalidate(habitsProvider);
  }

  Future<void> markComplete(int habitId) async {
    final today = _normalizeToMidnight(DateTime.now());
    final todayStr = today.toIso8601String();

    final existing = await _db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ? AND completed = 1',
      whereArgs: [habitId, todayStr],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final log = HabitLog(
      habitId: habitId,
      date: today,
      completed: true,
      loggedAt: DateTime.now(),
    );
    await _db.insert('habit_logs', log.toMap());
    await _updateStreak(habitId);
    ref.invalidate(habitsProvider);
  }

  Future<void> markUncomplete(int habitId) async {
    final today = _normalizeToMidnight(DateTime.now());
    final todayStr = today.toIso8601String();

    await _db.delete(
      'habit_logs',
      where: 'habitId = ? AND date = ? AND completed = 1',
      whereArgs: [habitId, todayStr],
    );
    await _updateStreak(habitId);
    ref.invalidate(habitsProvider);
  }

  Future<void> skipForToday(int habitId) async {
    final today = _normalizeToMidnight(DateTime.now());
    final todayStr = today.toIso8601String();

    await _db.delete(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, todayStr],
    );

    final log = HabitLog(
      habitId: habitId,
      date: today,
      completed: false,
      loggedAt: DateTime.now(),
    );
    await _db.insert('habit_logs', log.toMap());
    ref.invalidate(habitsProvider);
  }

  Future<void> unskipForToday(int habitId) async {
    final today = _normalizeToMidnight(DateTime.now());
    final todayStr = today.toIso8601String();

    await _db.delete(
      'habit_logs',
      where: 'habitId = ? AND date = ? AND completed = 0',
      whereArgs: [habitId, todayStr],
    );
    ref.invalidate(habitsProvider);
  }

  Future<Map<int, bool>> skipMapForToday(List<Habit> habits) async {
    if (habits.isEmpty) return {};
    final today = _normalizeToMidnight(DateTime.now()).toIso8601String();
    final ids = habits.map((h) => h.id!).toList();
    final placeholders = ids.map((_) => '?').join(',');
    final rows = await _db.query(
      'habit_logs',
      where: 'date = ? AND completed = 0 AND habitId IN ($placeholders)',
      whereArgs: [today, ...ids],
    );
    final skippedIds = rows.map((r) => r['habitId'] as int).toSet();
    return {for (final h in habits) h.id!: skippedIds.contains(h.id)};
  }

  Future<void> _updateStreak(int habitId) async {
    final rows = await _db.query(
      'habit_logs',
      where: 'habitId = ? AND completed = 1',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );

    if (rows.isEmpty) {
      await _db.update(
        'habits',
        {'currentStreak': 0},
        where: 'id = ?',
        whereArgs: [habitId],
      );
      return;
    }

    final logs = rows.map(HabitLog.fromMap).toList();
    final today = _normalizeToMidnight(DateTime.now());

    if (logs.first.date != today) {
      await _db.update(
        'habits',
        {'currentStreak': 0},
        where: 'id = ?',
        whereArgs: [habitId],
      );
      return;
    }

    int current = 0;
    int longest = 0;
    DateTime? prev;

    for (final log in logs) {
      if (prev == null) {
        current = 1;
      } else {
        final diff = prev.difference(log.date).inDays;
        if (diff == 1) {
          current++;
        } else {
          break;
        }
      }
      if (current > longest) longest = current;
      prev = log.date;
    }

    final habitRows =
        await _db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    if (habitRows.isEmpty) return;

    final habit = Habit.fromMap(habitRows.first);
    final newLongest =
        current > habit.longestStreak ? current : habit.longestStreak;

    await _db.update(
      'habits',
      {'currentStreak': current, 'longestStreak': newLongest},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  Future<bool> isCompletedToday(int habitId) async {
    final today = _normalizeToMidnight(DateTime.now()).toIso8601String();
    final rows = await _db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ? AND completed = 1',
      whereArgs: [habitId, today],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Map<int, bool>> completionMapForToday(List<Habit> habits) async {
    if (habits.isEmpty) return {};
    final today = _normalizeToMidnight(DateTime.now()).toIso8601String();
    final ids = habits.map((h) => h.id!).toList();
    final placeholders = ids.map((_) => '?').join(',');
    final rows = await _db.query(
      'habit_logs',
      where: 'date = ? AND completed = 1 AND habitId IN ($placeholders)',
      whereArgs: [today, ...ids],
    );
    final completedIds = rows.map((r) => r['habitId'] as int).toSet();
    return {for (final h in habits) h.id!: completedIds.contains(h.id)};
  }

  DateTime _normalizeToMidnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
