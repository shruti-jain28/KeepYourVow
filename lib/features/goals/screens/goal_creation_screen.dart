// lib/features/goals/screens/goal_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/goal_provider.dart';
import '../../habits/models/habit.dart';
import '../../habits/providers/habit_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/copy.dart';

class GoalCreationScreen extends ConsumerStatefulWidget {
  const GoalCreationScreen({super.key});

  @override
  ConsumerState<GoalCreationScreen> createState() =>
      _GoalCreationScreenState();
}

class _GoalCreationScreenState extends ConsumerState<GoalCreationScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _titleController = TextEditingController();
  final _phraseController = TextEditingController();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // Habits to create alongside the goal
  final List<_PendingHabit> _pendingHabits = [];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _submit() async {
    if (_phraseController.text.trim().isEmpty) return;

    final goalId = await ref.read(goalNotifierProvider.notifier).createGoal(
          title: _titleController.text.trim().isEmpty
              ? _phraseController.text.trim()
              : _titleController.text.trim(),
          identityPhrase: _phraseController.text.trim(),
          endDate: _endDate,
        );

    // Create any pending habits linked to this goal
    final habitNotifier = ref.read(habitNotifierProvider.notifier);
    for (final h in _pendingHabits) {
      await habitNotifier.createHabit(
        title: h.title,
        frequency: h.frequency,
        goalId: goalId,
        startTime: h.startTime,
        scheduledDays: h.scheduledDays,
      );
    }

    if (mounted) context.go('/');
  }

  void _addHabitDialog() {
    final habitTitleController = TextEditingController();
    var frequency = HabitFrequency.daily;
    TimeOfDay? startTime;
    Set<int> selectedDays = {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Add a habit"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: habitTitleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
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
                  _DialogWeekdaySelector(
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
                  _DialogMonthDateSelector(
                    selected: selectedDays,
                    onChanged: (days) =>
                        setDialogState(() => selectedDays = days),
                  ),
                ],

                const SizedBox(height: 16),
                // Time picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime:
                          startTime ?? const TimeOfDay(hour: 7, minute: 0),
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
                      Text(
                        startTime != null
                            ? startTime!.format(ctx)
                            : "Set time (optional)",
                        style: KYVText.caption(ctx),
                      ),
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
              onPressed: () {
                final title = habitTitleController.text.trim();
                if (title.isEmpty) return;
                String? timeStr;
                if (startTime != null) {
                  timeStr =
                      '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
                }
                setState(() {
                  _pendingHabits.add(_PendingHabit(
                    title: title,
                    frequency: frequency,
                    startTime: timeStr,
                    scheduledDays: selectedDays.toList()..sort(),
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle()),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: _prevPage)
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentPage >= i ? KYVColors.sky : KYVColors.light,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _page1Identity(),
                _page2EndDate(),
                _page3Habits(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle() => [
        'Who are you becoming?',
        'When does this chapter end?',
        'Your habits',
      ][_currentPage];

  Widget _page1Identity() => _PageWrapper(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Write your vow in your own words.",
              style: KYVText.body(context)),
          const SizedBox(height: 8),
          Text("Start with: I am becoming someone who...",
              style: KYVText.caption(context)),
          const SizedBox(height: 20),
          TextField(
            controller: _phraseController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(KYVCopy.goalPhrasePlaceholder),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration(
                "Short name (optional) \u2014 e.g. Marathon Training"),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed:
                _phraseController.text.trim().isNotEmpty ? _nextPage : null,
            child: const Text("Next"),
          ),
        ]),
      );

  Widget _page2EndDate() => _PageWrapper(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("When does this chapter close?",
              style: KYVText.body(context)),
          const SizedBox(height: 4),
          Text("Pick a date that feels meaningful, not just achievable.",
              style: KYVText.caption(context)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KYVColors.light,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    color: KYVColors.sky),
                const SizedBox(width: 16),
                Text(_formatDate(_endDate),
                    style: KYVText.heading(context)),
              ]),
            ),
          ),
          const Spacer(),
          ElevatedButton(onPressed: _nextPage, child: const Text("Next")),
        ]),
      );

  Widget _page3Habits() => _PageWrapper(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Habits move you forward.", style: KYVText.body(context)),
          const SizedBox(height: 8),
          Text(
              "Add habits that will help you reach this goal.",
              style: KYVText.caption(context)),
          const SizedBox(height: 20),

          // Pending habits list
          if (_pendingHabits.isNotEmpty) ...[
            ...List.generate(_pendingHabits.length, (i) {
              final h = _pendingHabits[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                          Text(h.title,
                              style: KYVText.subheading(context)),
                          Text(h.frequency.label,
                              style: KYVText.caption(context)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _pendingHabits.removeAt(i)),
                      child: const Icon(Icons.close,
                          color: KYVColors.darkGray, size: 20),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // Add habit button
          GestureDetector(
            onTap: _addHabitDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KYVColors.light,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KYVColors.sky, width: 1.5),
              ),
              child: Row(children: [
                const Icon(Icons.add_circle_outline, color: KYVColors.sky),
                const SizedBox(width: 12),
                Text("Add a habit",
                    style: KYVText.subheading(context)
                        .copyWith(color: KYVColors.sky)),
              ]),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KYVColors.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "\ud83d\udca1 Tip: Start with 1\u20133 habits. Small and consistent beats ambitious and abandoned.",
              style: KYVText.caption(context),
            ),
          ),
          const Spacer(),
          ElevatedButton(
              onPressed: _submit,
              child: const Text(KYVCopy.goalVowButtonLabel)),
        ]),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: KYVColors.pale,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

class _PendingHabit {
  final String title;
  final HabitFrequency frequency;
  final String? startTime;
  final List<int> scheduledDays;

  _PendingHabit({
    required this.title,
    required this.frequency,
    this.startTime,
    this.scheduledDays = const [],
  });
}

// ─── WEEKDAY SELECTOR (for dialog) ───────────────────────────────────────────
class _DialogWeekdaySelector extends StatelessWidget {
  const _DialogWeekdaySelector(
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

// ─── MONTH DATE SELECTOR (for dialog) ────────────────────────────────────────
class _DialogMonthDateSelector extends StatelessWidget {
  const _DialogMonthDateSelector(
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

class _PageWrapper extends StatelessWidget {
  const _PageWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), child: child);
}
