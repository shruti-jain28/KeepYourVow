// lib/shared/widgets/habit_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/habits/models/habit.dart';
import '../../features/habits/providers/habit_provider.dart';
import '../theme/app_theme.dart';

class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    this.isSkipped = false,
    this.onDismissed,
  });

  final Habit habit;
  final bool isCompleted;
  final bool isSkipped;
  final VoidCallback? onDismissed;

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  bool _showHint = false;
  late AnimationController _hintController;
  late Animation<Offset> _hintOffset;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _hintOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.15, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.15, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.15, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.15, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_hintController);
  }

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _maybeShowSwipeHint();
    }
  }

  Future<void> _maybeShowSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('swipe_hint_count') ?? 0;
    if (count < 3) {
      await prefs.setInt('swipe_hint_count', count + 1);
      if (mounted) {
        setState(() => _showHint = true);
        _hintController.forward(from: 0).then((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _showHint = false);
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final isCompleted = widget.isCompleted;
    final isSkipped = widget.isSkipped;

    final DismissDirection swipeDirection;
    if (isCompleted) {
      swipeDirection = DismissDirection.startToEnd;
    } else if (isSkipped) {
      swipeDirection = DismissDirection.endToStart;
    } else {
      swipeDirection = DismissDirection.none;
    }

    return Dismissible(
      key: ValueKey('habit_dismiss_${habit.id}'),
      direction: swipeDirection,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && isSkipped) {
          // Left swipe on skipped → unskip
          HapticFeedback.lightImpact();
          await _onUnskip();
          return false; // Don't dismiss, just unskip in place
        }
        return true; // Right swipe on completed → dismiss
      },
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        widget.onDismissed?.call();
      },
      // Right swipe background (startToEnd) — completed dismiss
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: KYVColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: KYVColors.teal),
            SizedBox(width: 8),
            Text("Done",
                style: TextStyle(
                    color: KYVColors.teal,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      // Left swipe background (endToStart) — unskip
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: KYVColors.sky.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Unskip",
                style: TextStyle(
                    color: KYVColors.sky,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.undo, color: KYVColors.sky),
          ],
        ),
      ),
      child: SlideTransition(
        position: _showHint
            ? _hintOffset
            : const AlwaysStoppedAnimation(Offset.zero),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSkipped
                    ? KYVColors.darkGray.withValues(alpha: 0.06)
                    : isCompleted
                        ? KYVColors.teal.withValues(alpha: 0.08)
                        : KYVColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSkipped
                      ? KYVColors.darkGray.withValues(alpha: 0.3)
                      : isCompleted
                          ? KYVColors.teal
                          : KYVColors.light,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                minVerticalPadding: 12,
                // Circle — tappable for both complete and uncomplete
                leading: Semantics(
                  label: isCompleted
                      ? "Tap to mark incomplete"
                      : "Mark habit complete",
                  button: true,
                  child: GestureDetector(
                    onTap: isSkipped
                        ? null
                        : isCompleted
                            ? () => _onUncomplete()
                            : () => _onComplete(),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? KYVColors.teal
                                : Colors.transparent,
                            border: Border.all(
                              color: isSkipped
                                  ? KYVColors.darkGray
                                  : isCompleted
                                      ? KYVColors.teal
                                      : KYVColors.sky,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  habit.title,
                  style: KYVText.subheading(context).copyWith(
                    color: isSkipped
                        ? KYVColors.darkGray
                        : isCompleted
                            ? KYVColors.darkGray
                            : KYVColors.slate,
                    decoration: isCompleted || isSkipped
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: isSkipped
                    ? Text("Skipped for today",
                        style: KYVText.caption(context)
                            .copyWith(fontSize: 11))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (habit.currentStreak > 0 && !isSkipped)
                      _StreakBadge(streak: habit.currentStreak),
                    if (!isCompleted && !isSkipped) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _onSkip(context),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            "Skip",
                            style: KYVText.caption(context).copyWith(
                              color: KYVColors.darkGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Swipe hint overlay
            if (_showHint && isCompleted)
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Swipe to dismiss",
                        style: KYVText.caption(context).copyWith(
                          color: KYVColors.darkGray.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16,
                          color: KYVColors.darkGray.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onComplete() async {
    HapticFeedback.lightImpact();
    await ref
        .read(habitNotifierProvider.notifier)
        .markComplete(widget.habit.id!);
  }

  Future<void> _onUncomplete() async {
    HapticFeedback.lightImpact();
    await ref
        .read(habitNotifierProvider.notifier)
        .markUncomplete(widget.habit.id!);
  }

  Future<void> _onUnskip() async {
    HapticFeedback.lightImpact();
    await ref
        .read(habitNotifierProvider.notifier)
        .unskipForToday(widget.habit.id!);
  }

  Future<void> _onSkip(BuildContext context) async {
    HapticFeedback.lightImpact();
    await ref
        .read(habitNotifierProvider.notifier)
        .skipForToday(widget.habit.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.habit.title} has been skipped for the day."),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Small streak pill shown on the right side of the card
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: KYVColors.sky.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F525}', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: KYVText.caption(context).copyWith(
              color: KYVColors.sky,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
