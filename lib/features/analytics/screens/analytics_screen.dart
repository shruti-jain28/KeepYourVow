// lib/features/analytics/screens/analytics_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/analytics_provider.dart';
import '../../habits/models/habit.dart';
import '../../goals/models/goal.dart';
import '../../../shared/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Analytics"),
      ),
      body: Column(
        children: [
          // ── Period Selector ──
          _PeriodSelector(
            selected: selectedPeriod,
            onChanged: (p) =>
                ref.read(selectedPeriodProvider.notifier).state = p,
          ),

          Expanded(
            child: analyticsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (state) {
                if (state.habits.isEmpty && state.goals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_rounded,
                              size: 64,
                              color:
                                  KYVColors.sky.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text("No data yet",
                              style: KYVText.heading(context)),
                          const SizedBox(height: 8),
                          Text(
                            "Create some goals and habits to see your progress here.",
                            style: KYVText.body(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final isWeekView =
                    state.period.type == AnalyticsPeriodType.thisWeek ||
                        state.period.type ==
                            AnalyticsPeriodType.previousWeek;
                final periodLabel = state.period.label;
                final dayCount = state.period.dayCount;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    // ── Overview Cards Row ──
                    _OverviewRow(state: state),
                    const SizedBox(height: 24),

                    // ── Activity Chart ──
                    Text(periodLabel, style: KYVText.heading(context)),
                    const SizedBox(height: 4),
                    Text(
                      isWeekView
                          ? "Daily habit completions over $dayCount days"
                          : "Daily habit completions for $periodLabel",
                      style: KYVText.caption(context),
                    ),
                    const SizedBox(height: 16),
                    isWeekView
                        ? _WeeklyBarChart(
                            activity: state.periodActivity)
                        : _MonthlyBarChart(
                            activity: state.periodActivity),
                    const SizedBox(height: 28),

                    // ── Completion Ring ──
                    Text("Overall Rate",
                        style: KYVText.heading(context)),
                    const SizedBox(height: 4),
                    Text(
                      "$dayCount-day average across all habits",
                      style: KYVText.caption(context),
                    ),
                    const SizedBox(height: 16),
                    _CompletionRing(rate: state.overallCompletionRate),
                    const SizedBox(height: 28),

                    // ── Habit Streaks ──
                    if (state.habits.isNotEmpty) ...[
                      Text("Habit Streaks",
                          style: KYVText.heading(context)),
                      const SizedBox(height: 4),
                      Text("Completion rate for this period",
                          style: KYVText.caption(context)),
                      const SizedBox(height: 16),
                      ...state.habits.map((h) => _HabitStreakBar(
                            habit: h,
                            rate: state.periodRate[h.id] ?? 0,
                          )),
                      const SizedBox(height: 28),
                    ],

                    // ── Goal Progress Cards ──
                    if (state.goals.isNotEmpty) ...[
                      Text("Goal Progress",
                          style: KYVText.heading(context)),
                      const SizedBox(height: 4),
                      Text("Habits linked and time remaining",
                          style: KYVText.caption(context)),
                      const SizedBox(height: 16),
                      ...state.goals.map((g) => _GoalProgressCard(
                            goal: g,
                            habitCount:
                                state.habitsPerGoal[g.id] ?? 0,
                            habits: state.habits
                                .where((h) => h.goalId == g.id)
                                .toList(),
                            periodRate: state.periodRate,
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PERIOD SELECTOR ──────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PeriodChip(
              label: "This Week",
              isSelected: selected.type == AnalyticsPeriodType.thisWeek,
              onTap: () => onChanged(
                  const AnalyticsPeriod(type: AnalyticsPeriodType.thisWeek)),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: "Prev Week",
              isSelected:
                  selected.type == AnalyticsPeriodType.previousWeek,
              onTap: () => onChanged(const AnalyticsPeriod(
                  type: AnalyticsPeriodType.previousWeek)),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: "This Month",
              isSelected:
                  selected.type == AnalyticsPeriodType.thisMonth,
              onTap: () => onChanged(const AnalyticsPeriod(
                  type: AnalyticsPeriodType.thisMonth)),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: "Prev Month",
              isSelected:
                  selected.type == AnalyticsPeriodType.previousMonth,
              onTap: () => onChanged(const AnalyticsPeriod(
                  type: AnalyticsPeriodType.previousMonth)),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: selected.type == AnalyticsPeriodType.custom
                  ? selected.label
                  : "Pick Month",
              isSelected:
                  selected.type == AnalyticsPeriodType.custom,
              onTap: () => _pickMonth(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selected.customMonth ?? now,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: "Select any date in the month",
    );
    if (picked != null) {
      onChanged(AnalyticsPeriod(
        type: AnalyticsPeriodType.custom,
        customMonth: DateTime(picked.year, picked.month),
      ));
    }
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KYVColors.sky : KYVColors.light,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? KYVColors.sky : KYVColors.light,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: KYVText.caption(context).copyWith(
            color: isSelected ? Colors.white : KYVColors.slate,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── OVERVIEW ROW ────────────────────────────────────────────────────────────
class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.state});
  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.flag_rounded,
            label: "Goals",
            value: "${state.activeGoalCount}",
            color: KYVColors.deep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.repeat_rounded,
            label: "Habits",
            value: "${state.habitCount}",
            color: KYVColors.sky,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            label: "Done",
            value: "${state.totalCompletions}",
            color: KYVColors.teal,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: KYVText.heading(context).copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: KYVText.caption(context)),
        ],
      ),
    );
  }
}

// ─── WEEKLY BAR CHART ────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.activity});
  final List<DayActivity> activity;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxCompleted = activity.fold<int>(
        1, (m, a) => a.total > m ? a.total : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KYVColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KYVColors.light, width: 1.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(activity.length, (i) {
                final day = activity[i];
                final barHeight =
                    maxCompleted > 0 ? (day.completed / maxCompleted) * 120 : 0.0;
                final isToday = i == activity.length - 1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "${day.completed}",
                          style: KYVText.caption(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? KYVColors.sky : KYVColors.darkGray,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: barHeight),
                          duration: Duration(milliseconds: 400 + i * 80),
                          curve: Curves.easeOutCubic,
                          builder: (ctx, val, _) => Container(
                            height: val,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isToday
                                    ? [KYVColors.sky, KYVColors.deep]
                                    : [
                                        KYVColors.sky.withValues(alpha: 0.4),
                                        KYVColors.sky.withValues(alpha: 0.7),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(activity.length, (i) {
              final dayOfWeek = activity[i].date.weekday; // 1=Mon
              final isToday = i == activity.length - 1;
              return Expanded(
                child: Center(
                  child: Text(
                    _dayLabels[dayOfWeek - 1],
                    style: KYVText.caption(context).copyWith(
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? KYVColors.sky : KYVColors.darkGray,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── MONTHLY BAR CHART ───────────────────────────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.activity});
  final List<DayActivity> activity;

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KYVColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KYVColors.light, width: 1.5),
        ),
        child: Center(
          child: Text("No data for this period",
              style: KYVText.caption(context)),
        ),
      );
    }

    final maxCompleted = activity.fold<int>(
        1, (m, a) => a.total > m ? a.total : m);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KYVColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KYVColors.light, width: 1.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(activity.length, (i) {
                final day = activity[i];
                final barHeight = maxCompleted > 0
                    ? (day.completed / maxCompleted) * 120
                    : 0.0;
                final isToday = day.date == today;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: barHeight),
                          duration: Duration(
                              milliseconds: 300 + (i * 20).clamp(0, 400)),
                          curve: Curves.easeOutCubic,
                          builder: (ctx, val, _) => Container(
                            height: val,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? KYVColors.sky
                                  : day.completed > 0
                                      ? KYVColors.sky
                                          .withValues(alpha: 0.5)
                                      : KYVColors.light,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Show a few date labels spread across the month
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildDateLabels(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDateLabels(BuildContext context) {
    if (activity.isEmpty) return [];
    final count = activity.length;
    // Show ~5 labels evenly spaced
    final labelCount = count < 5 ? count : 5;
    final step = (count - 1) / (labelCount - 1);

    return List.generate(labelCount, (i) {
      final idx = (i * step).round().clamp(0, count - 1);
      final day = activity[idx].date;
      return Text(
        "${day.day}",
        style: KYVText.caption(context).copyWith(
          fontSize: 10,
          color: KYVColors.darkGray,
        ),
      );
    });
  }
}

// ─── COMPLETION RING ─────────────────────────────────────────────────────────
class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.rate});
  final double rate;

  @override
  Widget build(BuildContext context) {
    final percentage = (rate * 100).round();
    final label = percentage >= 80
        ? "Excellent!"
        : percentage >= 50
            ? "Good progress"
            : percentage > 0
                ? "Keep pushing"
                : "Get started!";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KYVColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KYVColors.light, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rate),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, _) => CustomPaint(
                painter: _RingPainter(
                  progress: val,
                  bgColor: KYVColors.light,
                  fgColor: percentage >= 80
                      ? KYVColors.teal
                      : percentage >= 50
                          ? KYVColors.sky
                          : const Color(0xFFE67E22),
                ),
                child: Center(
                  child: Text(
                    "$percentage%",
                    style: KYVText.heading(context).copyWith(
                      fontSize: 24,
                      color: KYVColors.deep,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KYVText.heading(context)),
                const SizedBox(height: 4),
                Text(
                  "You completed $percentage% of your habits on average this period.",
                  style: KYVText.body(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  _RingPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = fgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fgColor != fgColor;
}

// ─── HABIT STREAK BAR ────────────────────────────────────────────────────────
class _HabitStreakBar extends StatelessWidget {
  const _HabitStreakBar({required this.habit, required this.rate});
  final Habit habit;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KYVColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KYVColors.light, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(habit.title,
                    style: KYVText.subheading(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (habit.currentStreak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: KYVColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "\u{1F525} ${habit.currentStreak} day${habit.currentStreak == 1 ? '' : 's'}",
                    style: KYVText.caption(context).copyWith(
                      color: KYVColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: rate),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (ctx, val, _) => LinearProgressIndicator(
                  value: val,
                  backgroundColor: KYVColors.light,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    rate >= 0.8
                        ? KYVColors.teal
                        : rate >= 0.5
                            ? KYVColors.sky
                            : const Color(0xFFE67E22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text("${(rate * 100).round()}% this period",
                  style: KYVText.caption(context)),
              const Spacer(),
              Text("Best: ${habit.longestStreak} days",
                  style: KYVText.caption(context)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── GOAL PROGRESS CARD ──────────────────────────────────────────────────────
class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({
    required this.goal,
    required this.habitCount,
    required this.habits,
    required this.periodRate,
  });
  final Goal goal;
  final int habitCount;
  final List<Habit> habits;
  final Map<int, double> periodRate;

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.endDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final totalDays =
        goal.endDate.difference(goal.createdAt).inDays.clamp(1, 9999);
    final elapsed =
        DateTime.now().difference(goal.createdAt).inDays.clamp(0, totalDays);
    final timeProgress = elapsed / totalDays;

    // Average habit rate for this goal
    double avgRate = 0;
    if (habits.isNotEmpty) {
      final sum = habits.fold<double>(
          0, (s, h) => s + (periodRate[h.id] ?? 0));
      avgRate = sum / habits.length;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KYVColors.deep, KYVColors.deep.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.title,
                    style: KYVText.subheading(context)
                        .copyWith(color: Colors.white)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFFE74C3C).withValues(alpha: 0.3)
                      : KYVColors.teal.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOverdue ? "Overdue" : "$daysLeft days left",
                  style: KYVText.caption(context).copyWith(
                    color: isOverdue
                        ? const Color(0xFFE74C3C)
                        : KYVColors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time progress bar
          Row(
            children: [
              Text("Time",
                  style: KYVText.caption(context)
                      .copyWith(color: Colors.white70, fontSize: 11)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: timeProgress),
                      duration: const Duration(milliseconds: 600),
                      builder: (ctx, val, _) => LinearProgressIndicator(
                        value: val,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverdue
                              ? const Color(0xFFE74C3C)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text("${(timeProgress * 100).round()}%",
                  style: KYVText.caption(context)
                      .copyWith(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          // Habit rate bar
          Row(
            children: [
              Text("Habits",
                  style: KYVText.caption(context)
                      .copyWith(color: Colors.white70, fontSize: 11)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: avgRate),
                      duration: const Duration(milliseconds: 600),
                      builder: (ctx, val, _) => LinearProgressIndicator(
                        value: val,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(KYVColors.teal),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text("${(avgRate * 100).round()}%",
                  style: KYVText.caption(context)
                      .copyWith(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$habitCount habit${habitCount == 1 ? '' : 's'} linked",
            style: KYVText.caption(context)
                .copyWith(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
