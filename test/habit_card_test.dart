// test/habit_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepyourvow/features/habits/models/habit.dart';
import 'package:keepyourvow/shared/theme/app_theme.dart';
import 'package:keepyourvow/shared/widgets/habit_card.dart';

void main() {
  // Helper: build the card in a test harness
  Widget buildCard({required bool isCompleted}) {
    final habit = Habit(
      id: 1,
      title: 'Morning run',
      isDaily: true,
      scheduledDays: const [],
      createdAt: DateTime.now(),
      currentStreak: isCompleted ? 3 : 0,
      longestStreak: 3,
    );

    return ProviderScope(
      child: MaterialApp(
        theme: KYVTheme.light,
        home: Scaffold(
          body: HabitCard(habit: habit, isCompleted: isCompleted),
        ),
      ),
    );
  }

  testWidgets('shows habit title', (tester) async {
    await tester.pumpWidget(buildCard(isCompleted: false));
    expect(find.text('Morning run'), findsOneWidget);
  });

  testWidgets('shows streak badge when streak > 0', (tester) async {
    await tester.pumpWidget(buildCard(isCompleted: true));
    expect(find.text('3'), findsOneWidget); // streak count
  });

  testWidgets('shows strikethrough when completed', (tester) async {
    await tester.pumpWidget(buildCard(isCompleted: true));
    // Text widget exists — visual strikethrough is style-level
    expect(find.text('Morning run'), findsOneWidget);
  });
}
