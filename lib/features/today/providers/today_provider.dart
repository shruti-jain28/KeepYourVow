// lib/features/today/providers/today_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../goals/providers/goal_provider.dart';
import '../../habits/providers/habit_provider.dart';
import '../../goals/models/goal.dart';
import '../../habits/models/habit.dart';

class TodayState {
  final Goal? activeGoal;
  final List<Goal> allGoals;
  final List<Habit> habits;
  final Map<int, bool> completions; // habitId -> completed today?
  final Map<int, bool> skips; // habitId -> skipped today?
  final int completedCount;
  final int totalCount;
  final bool allDone;

  const TodayState({
    required this.activeGoal,
    required this.allGoals,
    required this.habits,
    required this.completions,
    required this.skips,
    required this.completedCount,
    required this.totalCount,
    required this.allDone,
  });

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  /// Habits that are NOT linked to any goal, sorted by startTime ASC.
  List<Habit> get standaloneHabits {
    final list = habits.where((h) => h.goalId == null).toList();
    list.sort((a, b) {
      final aTime = a.startTime ?? '';
      final bTime = b.startTime ?? '';
      return aTime.compareTo(bTime);
    });
    return list;
  }
}

/// Tracks habit IDs dismissed (right-swiped) from the Today's Plan list.
/// Survives provider rebuilds unlike local widget state.
final dismissedHabitIdsProvider = StateProvider<Set<int>>((ref) => {});

/// When true, show the dashboard even if all habits are done.
final showDashboardOverrideProvider = StateProvider<bool>((ref) => false);

final todayProvider = FutureProvider<TodayState>((ref) async {
  final goalAsync = ref.watch(activeGoalProvider);
  final allGoalsAsync = ref.watch(allGoalsProvider);
  final habitsAsync = ref.watch(habitsProvider);

  final goal = goalAsync.valueOrNull;
  final allGoals = allGoalsAsync.valueOrNull ?? [];
  final allHabits = habitsAsync.valueOrNull ?? [];

  // Filter to only habits scheduled for today
  final habits = allHabits.where(_isScheduledForToday).toList();

  final notifier = ref.read(habitNotifierProvider.notifier);
  final completions = await notifier.completionMapForToday(habits);
  final skips = await notifier.skipMapForToday(habits);
  final completedCount = completions.values.where((v) => v).length;

  return TodayState(
    activeGoal: goal,
    allGoals: allGoals,
    habits: habits,
    completions: completions,
    skips: skips,
    completedCount: completedCount,
    totalCount: habits.length,
    allDone: habits.isNotEmpty && completedCount == habits.length,
  );
});

bool _isScheduledForToday(Habit h) {
  final now = DateTime.now();
  final weekday = now.weekday; // 1=Mon..7=Sun
  final dayOfMonth = now.day;

  switch (h.frequency) {
    case HabitFrequency.daily:
      return true;
    case HabitFrequency.weekdays:
      return weekday >= 1 && weekday <= 5;
    case HabitFrequency.weekends:
      return weekday == 6 || weekday == 7;
    case HabitFrequency.weekly:
      // If no days selected, show every day (backwards compat)
      return h.scheduledDays.isEmpty || h.scheduledDays.contains(weekday);
    case HabitFrequency.monthly:
      // If no dates selected, show every day (backwards compat)
      return h.scheduledDays.isEmpty || h.scheduledDays.contains(dayOfMonth);
  }
}
