// lib/features/habits/screens/habit_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../../goals/providers/goal_provider.dart';
import '../../../shared/theme/app_theme.dart';

class HabitManagementScreen extends ConsumerWidget {
  const HabitManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('All Habits'),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\ud83c\udf31', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No habits yet.',
                      style: KYVText.subheading(context)),
                  const SizedBox(height: 4),
                  Text('Tap + to add your first habit.',
                      style: KYVText.caption(context)),
                ],
              ),
            );
          }

          // Sort by startTime ASC (nulls last)
          final sorted = List<Habit>.from(habits);
          sorted.sort((a, b) {
            final aTime = a.startTime ?? 'zz:zz';
            final bTime = b.startTime ?? 'zz:zz';
            return aTime.compareTo(bTime);
          });

          final goals = goalsAsync.valueOrNull ?? [];
          final goalMap = {for (final g in goals) g.id: g.title};

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) {
              final habit = sorted[i];
              final goalName = habit.goalId != null
                  ? goalMap[habit.goalId]
                  : null;

              return GestureDetector(
                onTap: () => context.push('/habits/${habit.id}'),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KYVColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: KYVColors.light, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      if (habit.startTime != null)
                        Container(
                          width: 52,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          decoration: BoxDecoration(
                            color: KYVColors.sky.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            habit.startTime!,
                            textAlign: TextAlign.center,
                            style: KYVText.caption(context).copyWith(
                                color: KYVColors.sky,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        )
                      else
                        const SizedBox(width: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.title,
                                style: KYVText.subheading(context)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(habit.frequency.label,
                                    style: KYVText.caption(context)),
                                if (goalName != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KYVColors.teal
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.flag,
                                            size: 10,
                                            color: KYVColors.teal),
                                        const SizedBox(width: 3),
                                        Text(
                                          goalName,
                                          style: KYVText.caption(context)
                                              .copyWith(
                                                  color: KYVColors.teal,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: KYVColors.darkGray),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/new'),
        backgroundColor: KYVColors.sky,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
