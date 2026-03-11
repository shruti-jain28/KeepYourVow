// lib/features/today/screens/today_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/today_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../goals/models/goal.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/habit_card.dart';
import '../../../shared/copy.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayProvider);
    final showDashboard = ref.watch(showDashboardOverrideProvider);

    return todayAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text("Error: $e"))),
      data: (state) {
        // Reset the override when not all done so the celebration
        // re-triggers next time all habits are completed.
        if (!state.allDone && showDashboard) {
          Future.microtask(() =>
              ref.read(showDashboardOverrideProvider.notifier).state = false);
        }
        if (state.allDone && !showDashboard) {
          return _AllDoneState(goal: state.activeGoal?.identityPhrase);
        }
        return _DashboardScaffold(state: state);
      },
    );
  }
}

// ─── SCAFFOLD WITH DRAWER ───────────────────────────────────────────────────
class _DashboardScaffold extends ConsumerWidget {
  const _DashboardScaffold({required this.state});
  final TodayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissedIds = ref.watch(dismissedHabitIdsProvider);
    final visibleHabits =
        state.habits.where((h) => !dismissedIds.contains(h.id)).toList();

    return Scaffold(
      drawer: _AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            floating: true,
            backgroundColor: KYVColors.pale,
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: KYVColors.deep),
                tooltip: "Menu",
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text("KeepYourVow", style: KYVText.heading(context)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: KYVColors.sky),
                tooltip: "Create new",
                onPressed: () => context.push('/create'),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Today's Completion Status ──
                _CompletionStatusCard(state: state),

                const SizedBox(height: 24),

                // ── Goals Section ──
                _SectionHeader(
                  title: "Goals",
                  onSeeAll: state.allGoals.isNotEmpty
                      ? () => context.push('/goals')
                      : null,
                ),
                const SizedBox(height: 8),
                if (state.allGoals.isEmpty)
                  _EmptyTileHint(
                    text: KYVCopy.noGoalHint,
                    onTap: () => context.push('/goals/new'),
                  )
                else
                  _GoalTilesRow(
                    goals: state.allGoals.take(3).toList(),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Sticky "Today's Plan" header ──
          if (visibleHabits.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  color: KYVColors.pale,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text("Today\u2019s Plan",
                      style: KYVText.heading(context)),
                ),
              ),
            ),

          // ── Habit checklist (visible habits, scrollable) ──
          if (visibleHabits.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => HabitCard(
                  habit: visibleHabits[i],
                  isCompleted:
                      state.completions[visibleHabits[i].id] ?? false,
                  isSkipped:
                      state.skips[visibleHabits[i].id] ?? false,
                  onDismissed: () {
                    final current =
                        ref.read(dismissedHabitIdsProvider);
                    ref.read(dismissedHabitIdsProvider.notifier).state =
                        {...current, visibleHabits[i].id!};
                  },
                ),
                childCount: visibleHabits.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: _EmptyTileHint(
                text: KYVCopy.noHabitsHint,
                onTap: () => context.push('/habits/new'),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── SIDE DRAWER ────────────────────────────────────────────────────────────
class _AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = AuthService.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? '';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child:
                  Text("KeepYourVow", style: KYVText.display(context)),
            ),
            if (displayName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(displayName,
                    style: KYVText.caption(context)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("Stay committed.",
                    style: KYVText.caption(context)),
              ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: KYVColors.sky),
              title: Text("Dashboard", style: KYVText.body(context)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.repeat_rounded, color: KYVColors.sky),
              title: Text("Habits", style: KYVText.body(context)),
              onTap: () {
                Navigator.pop(context);
                context.push('/habits');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.flag_rounded, color: KYVColors.sky),
              title: Text("Goals", style: KYVText.body(context)),
              onTap: () {
                Navigator.pop(context);
                context.push('/goals');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.insights_rounded, color: KYVColors.sky),
              title: Text("Analytics", style: KYVText.body(context)),
              onTap: () {
                Navigator.pop(context);
                context.push('/analytics');
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: KYVColors.darkGray),
              title: Text("Sign Out",
                  style: KYVText.body(context)
                      .copyWith(color: KYVColors.darkGray)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('skipped_auth');
                if (context.mounted) context.go('/auth');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── STICKY HEADER DELEGATE ─────────────────────────────────────────────────
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => false;
}

// ─── COMPLETION STATUS CARD ─────────────────────────────────────────────────
class _CompletionStatusCard extends StatelessWidget {
  const _CompletionStatusCard({required this.state});
  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final completed = state.completedCount;
    final total = state.totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: progress >= 1.0
              ? [KYVColors.teal, const Color(0xFF16A085)]
              : [KYVColors.sky, KYVColors.deep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0
                          ? "No habits yet"
                          : progress >= 1.0
                              ? "All done!"
                              : "$completed of $total done",
                      style: KYVText.heading(context)
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? "Tap + to create your first habit"
                          : progress >= 1.0
                              ? "You\u2019ve kept your promises today"
                              : "Keep going, you\u2019re doing great",
                      style: KYVText.caption(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (ctx, val, _) => CircularProgressIndicator(
                        value: val,
                        strokeWidth: 5,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                    Text(
                      total == 0 ? "0%" : "${(progress * 100).round()}%",
                      style: KYVText.subheading(context)
                          .copyWith(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (ctx, val, _) => LinearProgressIndicator(
                    value: val,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SECTION HEADER ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(title, style: KYVText.heading(context)),
            const Spacer(),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text("See all",
                    style: KYVText.caption(context).copyWith(
                        color: KYVColors.sky,
                        decoration: TextDecoration.underline)),
              ),
          ],
        ),
      );
}

// ─── GOAL TILES ROW (clickable) ─────────────────────────────────────────────
class _GoalTilesRow extends StatelessWidget {
  const _GoalTilesRow({required this.goals});
  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: goals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => context.push('/goals/${goals[i].id}'),
          child: _GoalTile(goal: goals[i]),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.endDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KYVColors.deep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KYVText.subheading(context)
                .copyWith(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOverdue
                  ? const Color(0xFFE74C3C).withValues(alpha: 0.2)
                  : KYVColors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOverdue ? "Overdue" : "$daysLeft days left",
              style: KYVText.caption(context).copyWith(
                color: isOverdue ? const Color(0xFFE74C3C) : KYVColors.teal,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EMPTY TILE HINT ────────────────────────────────────────────────────────
class _EmptyTileHint extends StatelessWidget {
  const _EmptyTileHint({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KYVColors.light,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KYVColors.sky, width: 1.5),
            ),
            child: Row(children: [
              const Icon(Icons.add_circle_outline, color: KYVColors.sky),
              const SizedBox(width: 12),
              Text(text,
                  style: KYVText.subheading(context)
                      .copyWith(color: KYVColors.sky)),
            ]),
          ),
        ),
      );
}

// ─── ALL DONE STATE ─────────────────────────────────────────────────────────
class _AllDoneState extends ConsumerStatefulWidget {
  const _AllDoneState({this.goal});
  final String? goal;

  @override
  ConsumerState<_AllDoneState> createState() => _AllDoneStateState();
}

class _AllDoneStateState extends ConsumerState<_AllDoneState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _playCelebration();
  }

  Future<void> _playCelebration() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/celebration.wav'));
    } catch (_) {
      // Sound file may not exist yet — fall back silently.
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: KYVColors.pale,
        drawer: _AppDrawer(),
        appBar: AppBar(
          backgroundColor: KYVColors.pale,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: KYVColors.deep),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Text("KeepYourVow", style: KYVText.heading(context)),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Confetti overlay
              AnimatedBuilder(
                animation: _confettiController,
                builder: (ctx, _) => CustomPaint(
                  size: MediaQuery.of(ctx).size,
                  painter: _ConfettiPainter(_confettiController.value),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KYVColors.teal.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: KYVColors.teal, size: 56),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      KYVCopy.allDoneTitle,
                      textAlign: TextAlign.center,
                      style: KYVText.display(context),
                    ),
                    const SizedBox(height: 16),
                    Text(KYVCopy.allDoneSubtitle,
                        style: KYVText.body(context)),
                    if (widget.goal != null) ...[
                      const SizedBox(height: 32),
                      Text(widget.goal!,
                          textAlign: TextAlign.center,
                          style: KYVText.identity(context)),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(showDashboardOverrideProvider.notifier)
                              .state = true;
                        },
                        icon: const Icon(Icons.dashboard_outlined, size: 20),
                        label: const Text("Back to Dashboard"),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── CONFETTI PAINTER ────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);
  final double progress;

  static final _rng = Random(42);
  static final _particles = List.generate(60, (_) => _Particle.random(_rng));

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in _particles) {
      final x = p.x * size.width;
      final y = p.startY + p.speed * progress * size.height;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.rotationSpeed);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, startY, speed, size, rotation, rotationSpeed;
  final Color color;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
  });

  static const _colors = [
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE91E63),
  ];

  static _Particle random(Random rng) => _Particle(
        x: rng.nextDouble(),
        startY: -rng.nextDouble() * 100 - 20,
        speed: 0.5 + rng.nextDouble() * 0.8,
        size: 6 + rng.nextDouble() * 8,
        rotation: rng.nextDouble() * pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * pi * 4,
        color: _colors[rng.nextInt(_colors.length)],
      );
}
