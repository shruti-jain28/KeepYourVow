// lib/features/analytics/providers/analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/isar/isar_service.dart';
import '../../goals/models/goal.dart';
import '../../habits/models/habit.dart';
import '../../habits/models/habit_log.dart';
import '../../habits/providers/habit_provider.dart';
import '../../goals/providers/goal_provider.dart';

// ─── Period selection ────────────────────────────────────────────────────────

enum AnalyticsPeriodType { thisWeek, previousWeek, thisMonth, previousMonth, custom }

class AnalyticsPeriod {
  final AnalyticsPeriodType type;
  final DateTime? customMonth; // year+month for custom selection

  const AnalyticsPeriod({this.type = AnalyticsPeriodType.thisWeek, this.customMonth});

  String get label {
    switch (type) {
      case AnalyticsPeriodType.thisWeek:
        return 'This Week';
      case AnalyticsPeriodType.previousWeek:
        return 'Previous Week';
      case AnalyticsPeriodType.thisMonth:
        return 'This Month';
      case AnalyticsPeriodType.previousMonth:
        return 'Previous Month';
      case AnalyticsPeriodType.custom:
        if (customMonth != null) {
          const months = [
            '', 'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December',
          ];
          return '${months[customMonth!.month]} ${customMonth!.year}';
        }
        return 'Custom';
    }
  }

  /// Returns (start, end) date range for this period.
  (DateTime, DateTime) get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case AnalyticsPeriodType.thisWeek:
        final weekStart = today.subtract(Duration(days: 6));
        return (weekStart, today);
      case AnalyticsPeriodType.previousWeek:
        final weekEnd = today.subtract(Duration(days: 7));
        final weekStart = weekEnd.subtract(Duration(days: 6));
        return (weekStart, weekEnd);
      case AnalyticsPeriodType.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, today);
      case AnalyticsPeriodType.previousMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final prevMonthEnd = DateTime(now.year, now.month, 0);
        return (prevMonth, prevMonthEnd);
      case AnalyticsPeriodType.custom:
        if (customMonth != null) {
          final monthStart = DateTime(customMonth!.year, customMonth!.month, 1);
          final monthEnd = DateTime(customMonth!.year, customMonth!.month + 1, 0);
          // Don't go past today
          final end = monthEnd.isAfter(today) ? today : monthEnd;
          return (monthStart, end);
        }
        // Fallback to this week
        return (today.subtract(Duration(days: 6)), today);
    }
  }

  int get dayCount {
    final (start, end) = dateRange;
    return end.difference(start).inDays + 1;
  }
}

final selectedPeriodProvider = StateProvider<AnalyticsPeriod>(
  (_) => const AnalyticsPeriod(),
);

// ─── Analytics State ─────────────────────────────────────────────────────────

class AnalyticsState {
  final List<Goal> goals;
  final List<Habit> habits;
  final Map<int, List<HabitLog>> habitLogs; // habitId -> logs
  final int totalCompletions;
  final int totalSkips;
  final Map<int, double> periodRate; // habitId -> completion rate 0..1
  final List<DayActivity> periodActivity; // day-by-day activity
  final AnalyticsPeriod period;

  const AnalyticsState({
    required this.goals,
    required this.habits,
    required this.habitLogs,
    required this.totalCompletions,
    required this.totalSkips,
    required this.periodRate,
    required this.periodActivity,
    required this.period,
  });

  // Keep old getters for compatibility
  Map<int, double> get last7DaysRate => periodRate;
  List<DayActivity> get weekActivity => periodActivity;

  int get activeGoalCount => goals.length;
  int get habitCount => habits.length;

  double get overallCompletionRate {
    if (periodRate.isEmpty) return 0;
    final sum = periodRate.values.fold<double>(0, (a, b) => a + b);
    return sum / periodRate.length;
  }

  Habit? get bestStreakHabit {
    if (habits.isEmpty) return null;
    return habits.reduce(
        (a, b) => a.currentStreak >= b.currentStreak ? a : b);
  }

  Map<int, int> get habitsPerGoal {
    final map = <int, int>{};
    for (final h in habits) {
      if (h.goalId != null) {
        map[h.goalId!] = (map[h.goalId!] ?? 0) + 1;
      }
    }
    return map;
  }
}

class DayActivity {
  final DateTime date;
  final int completed;
  final int total;

  const DayActivity({
    required this.date,
    required this.completed,
    required this.total,
  });

  double get rate => total == 0 ? 0 : completed / total;
}

final analyticsProvider = FutureProvider<AnalyticsState>((ref) async {
  final goals = (ref.watch(allGoalsProvider).valueOrNull) ?? [];
  final habits = (ref.watch(habitsProvider).valueOrNull) ?? [];
  final period = ref.watch(selectedPeriodProvider);
  final db = IsarService.instance.db;

  // Fetch all logs
  final allLogRows = await db.query('habit_logs', orderBy: 'date DESC');
  final allLogs = allLogRows.map(HabitLog.fromMap).toList();

  // Group by habitId
  final habitLogs = <int, List<HabitLog>>{};
  for (final log in allLogs) {
    habitLogs.putIfAbsent(log.habitId, () => []).add(log);
  }

  final (rangeStart, rangeEnd) = period.dateRange;
  final dayCount = period.dayCount;

  // Count completions/skips within period
  final periodLogs = allLogs.where((l) {
    return !l.date.isBefore(rangeStart) && !l.date.isAfter(rangeEnd);
  }).toList();
  final totalCompletions = periodLogs.where((l) => l.completed).length;
  final totalSkips = periodLogs.where((l) => !l.completed).length;

  // Rate per habit within period
  final periodRate = <int, double>{};
  for (final habit in habits) {
    final logs = habitLogs[habit.id] ?? [];
    int daysWithCompletion = 0;
    for (int i = 0; i < dayCount; i++) {
      final day = rangeStart.add(Duration(days: i));
      final hasCompletion = logs.any((l) => l.completed && l.date == day);
      if (hasCompletion) daysWithCompletion++;
    }
    periodRate[habit.id!] = dayCount > 0 ? daysWithCompletion / dayCount : 0;
  }

  // Day-by-day activity
  final periodActivity = <DayActivity>[];
  for (int i = 0; i < dayCount; i++) {
    final day = rangeStart.add(Duration(days: i));
    int completed = 0;
    for (final habit in habits) {
      final logs = habitLogs[habit.id] ?? [];
      if (logs.any((l) => l.completed && l.date == day)) {
        completed++;
      }
    }
    periodActivity.add(DayActivity(
      date: day,
      completed: completed,
      total: habits.length,
    ));
  }

  return AnalyticsState(
    goals: goals,
    habits: habits,
    habitLogs: habitLogs,
    totalCompletions: totalCompletions,
    totalSkips: totalSkips,
    periodRate: periodRate,
    periodActivity: periodActivity,
    period: period,
  );
});
