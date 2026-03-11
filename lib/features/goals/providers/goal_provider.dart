// lib/features/goals/providers/goal_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../../../shared/isar/isar_service.dart';
import '../../habits/providers/habit_provider.dart';

// ─── PROVIDER: single active goal ────────────────────────────────────────────
final activeGoalProvider = FutureProvider<Goal?>((ref) async {
  return IsarService.instance.getActiveGoal();
});

// ─── PROVIDER: all goals sorted by endDate ASC ──────────────────────────────
final allGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  return IsarService.instance.getAllGoals();
});

// ─── NOTIFIER ────────────────────────────────────────────────────────────────
final goalNotifierProvider =
    NotifierProvider<GoalNotifier, void>(GoalNotifier.new);

class GoalNotifier extends Notifier<void> {
  @override
  void build() {}

  IsarService get _db => IsarService.instance;

  Future<int> createGoal({
    required String title,
    required String identityPhrase,
    required DateTime endDate,
    bool strengthenFocus = false,
  }) async {
    final goal = Goal(
      title: title,
      identityPhrase: identityPhrase,
      endDate: endDate,
      strengthenFocus: strengthenFocus,
      createdAt: DateTime.now(),
    );
    final id = await _db.insertGoal(goal);
    ref.invalidate(activeGoalProvider);
    ref.invalidate(allGoalsProvider);
    return id;
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.updateGoal(goal);
    ref.invalidate(activeGoalProvider);
    ref.invalidate(allGoalsProvider);
  }

  Future<void> deleteGoal(int goalId) async {
    await ref.read(habitNotifierProvider.notifier).deleteHabitsByGoalId(goalId);
    await _db.deleteGoal(goalId);
    ref.invalidate(activeGoalProvider);
    ref.invalidate(allGoalsProvider);
  }
}
