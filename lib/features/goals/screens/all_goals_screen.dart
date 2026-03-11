// lib/features/goals/screens/all_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/goal_provider.dart';
import '../../../shared/theme/app_theme.dart';

class AllGoalsScreen extends ConsumerWidget {
  const AllGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("All Goals"),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\ud83c\udff3\ufe0f',
                      style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No goals yet.', style: KYVText.subheading(context)),
                  const SizedBox(height: 4),
                  Text('Tap + to make your first vow.',
                      style: KYVText.caption(context)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (ctx, i) {
              final goal = goals[i];
              final daysLeft = goal.endDate.difference(DateTime.now()).inDays;
              final isOverdue = daysLeft < 0;

              return GestureDetector(
                onTap: () => context.push('/goals/${goal.id}'),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: KYVText.subheading(context)),
                        const SizedBox(height: 4),
                        Text(goal.identityPhrase,
                            style: KYVText.caption(context)
                                .copyWith(fontStyle: FontStyle.italic)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: isOverdue
                                  ? const Color(0xFFE74C3C)
                                  : KYVColors.darkGray,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOverdue ? "Overdue" : "$daysLeft days left",
                              style: KYVText.caption(context).copyWith(
                                color: isOverdue
                                    ? const Color(0xFFE74C3C)
                                    : KYVColors.darkGray,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Goal?"),
                                    content: const Text(
                                        "This will permanently delete the goal and all its linked habits."),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text("Delete",
                                            style: TextStyle(
                                                color: Color(0xFFE74C3C))),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(goalNotifierProvider.notifier)
                                      .deleteGoal(goal.id!);
                                }
                              },
                              child: const Icon(Icons.delete_outline,
                                  size: 20, color: KYVColors.darkGray),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goals/new'),
        backgroundColor: KYVColors.sky,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
