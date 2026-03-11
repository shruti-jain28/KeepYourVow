// lib/features/goals/screens/goal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../../habits/models/habit.dart';
import '../../habits/providers/habit_provider.dart';
import '../../../shared/theme/app_theme.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Goal Details"),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          final goal = goals.where((g) => g.id == goalId).firstOrNull;
          if (goal == null) {
            return const Center(child: Text("Goal not found"));
          }

          final allHabits = habitsAsync.valueOrNull ?? [];
          final goalHabits =
              allHabits.where((h) => h.goalId == goalId).toList();
          goalHabits.sort((a, b) {
            final aTime = a.startTime ?? '';
            final bTime = b.startTime ?? '';
            return aTime.compareTo(bTime);
          });

          final daysLeft = goal.endDate.difference(DateTime.now()).inDays;
          final isOverdue = daysLeft < 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Goal info card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: KYVColors.deep,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: KYVText.heading(context)
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(goal.identityPhrase,
                        style: KYVText.body(context).copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFE74C3C).withValues(alpha: 0.2)
                            : KYVColors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverdue ? "Overdue" : "$daysLeft days left",
                        style: KYVText.caption(context).copyWith(
                          color: isOverdue
                              ? const Color(0xFFE74C3C)
                              : KYVColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Habits section ──
              Row(
                children: [
                  Text("Habits (${goalHabits.length})",
                      style: KYVText.heading(context)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      final standaloneHabits = allHabits
                          .where((h) => h.goalId == null)
                          .toList();
                      if (standaloneHabits.isEmpty) {
                        context.push('/habits/new?goalId=$goalId');
                      } else {
                        _showAddHabitOptions(
                            context, ref, goalId, standaloneHabits);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (goalHabits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: KYVColors.light,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "No habits linked to this goal yet.\nCreate a habit and attach it to this goal.",
                    style: KYVText.body(context),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...goalHabits.map((habit) => _HabitListItem(habit: habit)),

              const SizedBox(height: 24),

              // ── Edit / Delete goal ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDialog(context, ref, goal),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Goal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref, goal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Delete Goal"),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddHabitOptions(BuildContext context, WidgetRef ref, int goalId,
      List<Habit> standaloneHabits) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: KYVColors.sky),
              title: const Text("Create new habit"),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/habits/new?goalId=$goalId');
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Link existing habit",
                    style: KYVText.caption(context)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            ...standaloneHabits.map((habit) => ListTile(
                  leading: const Icon(Icons.repeat_rounded,
                      color: KYVColors.sky, size: 20),
                  title: Text(habit.title),
                  subtitle: Text(habit.frequency.label,
                      style: KYVText.caption(context)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(habitNotifierProvider.notifier)
                        .updateHabitGoal(habit.id!, goalId);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final titleController = TextEditingController(text: goal.title);
    final phraseController = TextEditingController(text: goal.identityPhrase);
    var endDate = goal.endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Edit Goal"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: "Title",
                    filled: true,
                    fillColor: KYVColors.pale,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phraseController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: "Identity phrase",
                    filled: true,
                    fillColor: KYVColors.pale,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: endDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setDialogState(() => endDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KYVColors.pale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: KYVColors.sky, size: 20),
                      const SizedBox(width: 12),
                      Text(
                          '${endDate.day}/${endDate.month}/${endDate.year}'),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final phrase = phraseController.text.trim();
                if (title.isEmpty || phrase.isEmpty) return;
                final updated = goal.copyWith(
                  title: title,
                  identityPhrase: phrase,
                  endDate: endDate,
                );
                await ref
                    .read(goalNotifierProvider.notifier)
                    .updateGoal(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Goal?"),
        content: const Text(
            "This will permanently delete the goal and all its linked habits."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id!);
      if (context.mounted) context.pop();
    }
  }
}

class _HabitListItem extends StatelessWidget {
  const _HabitListItem({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/habits/${habit.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KYVColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KYVColors.light, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.repeat_rounded,
                color: KYVColors.sky, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title, style: KYVText.subheading(context)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      habit.frequency.label,
                      if (habit.startTime != null) habit.startTime!,
                    ].join(' \u2022 '),
                    style: KYVText.caption(context),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KYVColors.darkGray),
          ],
        ),
      ),
    );
  }
}
