// test/today_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:keepyourvow/features/today/providers/today_provider.dart';
import 'package:keepyourvow/features/habits/models/habit.dart';

void main() {
  // Helper: build a TodayState directly (unit test — no widget needed)
  TodayState makeState({
    required int total,
    required int completed,
  }) {
    final habits = List.generate(
      total,
      (i) => Habit(
        id: i + 1,
        title: "Habit ${i + 1}",
        isDaily: true,
        scheduledDays: const [],
        createdAt: DateTime.now(),
      ),
    );
    final completions = {
      for (var i = 0; i < total; i++) (i + 1): i < completed,
    };
    return TodayState(
      activeGoal: null,
      allGoals: const [],
      habits: habits,
      completions: completions,
      skips: const {},
      completedCount: completed,
      totalCount: total,
      allDone: total > 0 && completed == total,
    );
  }

  test('progress is 0 when no habits completed', () {
    final state = makeState(total: 3, completed: 0);
    expect(state.progress, 0.0);
    expect(state.allDone, false);
  });

  test('progress is correct for partial completion', () {
    final state = makeState(total: 3, completed: 1);
    expect(state.progress, closeTo(0.333, 0.01));
    expect(state.allDone, false);
  });

  test('allDone is true when all habits completed', () {
    final state = makeState(total: 3, completed: 3);
    expect(state.progress, 1.0);
    expect(state.allDone, true);
  });

  test('progress is 0 when no habits exist', () {
    final state = makeState(total: 0, completed: 0);
    expect(state.progress, 0.0);
    expect(state.allDone, false);
  });
}
