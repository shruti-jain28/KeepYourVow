// lib/features/habits/screens/habit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../../goals/providers/goal_provider.dart';
import '../../../shared/theme/app_theme.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});
  final int habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  int? _selectedGoalId;
  bool _goalModified = false;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Habit Details"),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habits) {
          final habit =
              habits.where((h) => h.id == widget.habitId).firstOrNull;
          if (habit == null) {
            return const Center(child: Text("Habit not found"));
          }

          final allGoals = goalsAsync.valueOrNull ?? [];
          // Initialize selected goal from habit data on first build
          if (!_goalModified) {
            _selectedGoalId = habit.goalId;
          }
          // Ensure _selectedGoalId is valid (goal may have been deleted)
          final validGoalIds = allGoals.map((g) => g.id).toSet();
          if (_selectedGoalId != null &&
              !validGoalIds.contains(_selectedGoalId)) {
            _selectedGoalId = null;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Habit info card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: KYVColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KYVColors.light, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title,
                        style: KYVText.heading(context)),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.repeat_rounded,
                      label: "Frequency",
                      value: habit.frequency.label,
                    ),
                    if (habit.startTime != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.access_time,
                        label: "Start Time",
                        value: habit.startTime!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.local_fire_department,
                      label: "Current Streak",
                      value: "${habit.currentStreak} days",
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.emoji_events_outlined,
                      label: "Longest Streak",
                      value: "${habit.longestStreak} days",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Goal attachment ──
              Text("Linked Goal", style: KYVText.heading(context)),
              const SizedBox(height: 4),
              Text("Change which goal this habit belongs to.",
                  style: KYVText.caption(context)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: KYVColors.pale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedGoalId,
                    isExpanded: true,
                    hint: Text("None (standalone habit)",
                        style: KYVText.body(context)),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("None (standalone habit)"),
                      ),
                      ...allGoals.map((g) => DropdownMenuItem<int?>(
                            value: g.id,
                            child: Text(g.title),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedGoalId = val;
                        _goalModified = true;
                      });
                    },
                  ),
                ),
              ),

              if (_goalModified && _selectedGoalId != habit.goalId) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _saveGoalChange(habit),
                  child: const Text("Save Changes"),
                ),
              ],

              const SizedBox(height: 32),

              // ── Edit / Delete habit ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDialog(habit),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Habit"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(habit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Delete Habit"),
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

  void _showEditDialog(Habit habit) {
    final titleController = TextEditingController(text: habit.title);
    var frequency = habit.frequency;
    var selectedDays = Set<int>.from(habit.scheduledDays);
    TimeOfDay? startTime;
    if (habit.startTime != null) {
      final parts = habit.startTime!.split(':');
      if (parts.length == 2) {
        startTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Edit Habit"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Text("Frequency", style: KYVText.subheading(ctx)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HabitFrequency.values.map((f) {
                    final selected = frequency == f;
                    return ChoiceChip(
                      label: Text(f.label),
                      selected: selected,
                      selectedColor: KYVColors.sky,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : KYVColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setDialogState(() {
                        frequency = f;
                        selectedDays = {};
                      }),
                    );
                  }).toList(),
                ),

                // Day selection for weekly
                if (frequency == HabitFrequency.weekly) ...[
                  const SizedBox(height: 12),
                  Text("Which days?",
                      style: KYVText.caption(ctx)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _EditWeekdaySelector(
                    selected: selectedDays,
                    onChanged: (days) =>
                        setDialogState(() => selectedDays = days),
                  ),
                ],

                // Date selection for monthly
                if (frequency == HabitFrequency.monthly) ...[
                  const SizedBox(height: 12),
                  Text("Which dates?",
                      style: KYVText.caption(ctx)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _EditMonthDateSelector(
                    selected: selectedDays,
                    onChanged: (days) =>
                        setDialogState(() => selectedDays = days),
                  ),
                ],

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: startTime ??
                          const TimeOfDay(hour: 7, minute: 0),
                    );
                    if (picked != null) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KYVColors.pale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          color: KYVColors.sky, size: 20),
                      const SizedBox(width: 12),
                      Text(startTime != null
                          ? startTime!.format(ctx)
                          : "Tap to set time"),
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
                if (title.isEmpty) return;
                String? timeStr;
                if (startTime != null) {
                  timeStr =
                      '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
                }
                await ref.read(habitNotifierProvider.notifier).updateHabit(
                      habitId: habit.id!,
                      title: title,
                      frequency: frequency,
                      startTime: timeStr,
                      scheduledDays: selectedDays.toList()..sort(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGoalChange(Habit habit) async {
    await ref
        .read(habitNotifierProvider.notifier)
        .updateHabitGoal(habit.id!, _selectedGoalId);
    setState(() => _goalModified = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal updated")),
      );
    }
  }

  Future<void> _confirmDelete(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Habit?"),
        content: const Text("This will also remove all completion logs."),
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
      await ref
          .read(habitNotifierProvider.notifier)
          .deleteHabit(habit.id!);
      if (mounted) context.pop();
    }
  }
}

// ─── WEEKDAY SELECTOR (for edit dialog) ──────────────────────────────────────
class _EditWeekdaySelector extends StatelessWidget {
  const _EditWeekdaySelector(
      {required this.selected, required this.onChanged});
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = Set<int>.from(selected);
            isSelected ? updated.remove(day) : updated.add(day);
            onChanged(updated);
          },
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? KYVColors.sky : KYVColors.pale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                color: isSelected ? Colors.white : KYVColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── MONTH DATE SELECTOR (for edit dialog) ───────────────────────────────────
class _EditMonthDateSelector extends StatelessWidget {
  const _EditMonthDateSelector(
      {required this.selected, required this.onChanged});
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(31, (i) {
        final date = i + 1;
        final isSelected = selected.contains(date);
        return GestureDetector(
          onTap: () {
            final updated = Set<int>.from(selected);
            isSelected ? updated.remove(date) : updated.add(date);
            onChanged(updated);
          },
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? KYVColors.sky : KYVColors.pale,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$date',
              style: TextStyle(
                color: isSelected ? Colors.white : KYVColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: KYVColors.sky),
          const SizedBox(width: 10),
          Text(label, style: KYVText.caption(context)),
          const Spacer(),
          Text(value,
              style: KYVText.body(context)
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      );
}
