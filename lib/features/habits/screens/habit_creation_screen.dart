// lib/features/habits/screens/habit_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../../goals/providers/goal_provider.dart';
import '../../../shared/theme/app_theme.dart';

class HabitCreationScreen extends ConsumerStatefulWidget {
  const HabitCreationScreen({super.key, this.goalId});
  final int? goalId;

  @override
  ConsumerState<HabitCreationScreen> createState() =>
      _HabitCreationScreenState();
}

class _HabitCreationScreenState extends ConsumerState<HabitCreationScreen> {
  final _titleController = TextEditingController();
  HabitFrequency _frequency = HabitFrequency.daily;
  TimeOfDay? _startTime;
  int? _selectedGoalId;
  Set<int> _selectedDays = {}; // weekday 1-7 for weekly, day-of-month 1-31 for monthly

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.goalId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await ref.read(habitNotifierProvider.notifier).createHabit(
          title: title,
          frequency: _frequency,
          startTime: _startTime != null ? _formatTime(_startTime!) : null,
          goalId: _selectedGoalId,
          scheduledDays: _selectedDays.toList()..sort(),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(allGoalsProvider);
    final allGoals = goalsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("New Habit"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What habit do you want to build?",
                style: KYVText.body(context)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. Morning run \u2014 20 mins',
                filled: true,
                fillColor: KYVColors.pale,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Frequency ──
            Text("Frequency", style: KYVText.subheading(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitFrequency.values.map((f) {
                final selected = _frequency == f;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: selected,
                  selectedColor: KYVColors.sky,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : KYVColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() {
                    _frequency = f;
                    _selectedDays = {};
                  }),
                );
              }).toList(),
            ),

            // ── Day/Date selection based on frequency ──
            if (_frequency == HabitFrequency.weekly) ...[
              const SizedBox(height: 16),
              Text("Which days?", style: KYVText.subheading(context)),
              const SizedBox(height: 8),
              _WeekdaySelector(
                selected: _selectedDays,
                onChanged: (days) => setState(() => _selectedDays = days),
              ),
            ],

            if (_frequency == HabitFrequency.monthly) ...[
              const SizedBox(height: 16),
              Text("Which dates?", style: KYVText.subheading(context)),
              const SizedBox(height: 8),
              _MonthDateSelector(
                selected: _selectedDays,
                onChanged: (days) => setState(() => _selectedDays = days),
              ),
            ],

            const SizedBox(height: 24),

            // ── Start Time ──
            Text("Expected Start Time", style: KYVText.subheading(context)),
            const SizedBox(height: 4),
            Text("When do you usually do this?",
                style: KYVText.caption(context)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: KYVColors.pale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.access_time, color: KYVColors.sky),
                  const SizedBox(width: 12),
                  Text(
                    _startTime != null
                        ? _startTime!.format(context)
                        : "Tap to set time (optional)",
                    style: KYVText.body(context).copyWith(
                        color: _startTime != null
                            ? KYVColors.slate
                            : KYVColors.darkGray),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 24),

            // ── Link to goal (optional) ──
            Text("Link to Goal", style: KYVText.subheading(context)),
            const SizedBox(height: 4),
            Text("Attach this habit to a goal (optional).",
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
                  onChanged: (val) => setState(() => _selectedGoalId = val),
                ),
              ),
            ),
            if (allGoals.isEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push('/goals/new'),
                child: Text(
                  "Or create a new goal first",
                  style: KYVText.caption(context).copyWith(
                    color: KYVColors.sky,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _titleController.text.trim().isNotEmpty ? _submit : null,
                child: const Text("Add Habit"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── WEEKDAY SELECTOR (Mon-Sun, multi-select) ───────────────────────────────
class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({required this.selected, required this.onChanged});
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(7, (i) {
        final day = i + 1; // 1=Mon..7=Sun
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = Set<int>.from(selected);
            isSelected ? updated.remove(day) : updated.add(day);
            onChanged(updated);
          },
          child: Container(
            width: 44,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? KYVColors.sky : KYVColors.pale,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? KYVColors.sky : KYVColors.light,
                width: 1.5,
              ),
            ),
            child: Text(
              _labels[i],
              style: KYVText.caption(context).copyWith(
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

// ─── MONTH DATE SELECTOR (1-31, multi-select) ───────────────────────────────
class _MonthDateSelector extends StatelessWidget {
  const _MonthDateSelector({required this.selected, required this.onChanged});
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
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
            width: 38,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? KYVColors.sky : KYVColors.pale,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? KYVColors.sky : KYVColors.light,
                width: 1.5,
              ),
            ),
            child: Text(
              '$date',
              style: KYVText.caption(context).copyWith(
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
