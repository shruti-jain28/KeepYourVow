// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/theme/app_theme.dart';
import 'features/today/screens/today_screen.dart';
import 'features/today/screens/create_chooser_screen.dart';
import 'features/goals/screens/goal_creation_screen.dart';
import 'features/goals/screens/all_goals_screen.dart';
import 'features/goals/screens/goal_detail_screen.dart';
import 'features/habits/screens/habit_management_screen.dart';
import 'features/habits/screens/habit_creation_screen.dart';
import 'features/habits/screens/habit_detail_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/services/auth_service.dart';

// ─── ROUTER ──────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isSignedIn = AuthService.instance.isSignedIn;
    final isAuthRoute = state.matchedLocation == '/auth';
    final prefs = await SharedPreferences.getInstance();
    final skippedAuth = prefs.getBool('skipped_auth') ?? false;

    // If not signed in and hasn't skipped, redirect to auth
    if (!isSignedIn && !skippedAuth && !isAuthRoute) {
      return '/auth';
    }
    // If signed in (or skipped) but on auth page, go to root
    if ((isSignedIn || skippedAuth) && isAuthRoute) {
      return '/';
    }

    // Onboarding check
    if ((isSignedIn || skippedAuth) && state.matchedLocation == '/') {
      final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
      if (!hasOnboarded) return '/onboarding';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (ctx, state) => const AuthScreen()),
    GoRoute(path: '/', builder: (ctx, state) => const TodayScreen()),
    GoRoute(
        path: '/onboarding',
        builder: (ctx, state) => const OnboardingScreen()),
    GoRoute(
        path: '/create',
        builder: (ctx, state) => const CreateChooserScreen()),
    GoRoute(
        path: '/goals/new',
        builder: (ctx, state) => const GoalCreationScreen()),
    GoRoute(
        path: '/goals',
        builder: (ctx, state) => const AllGoalsScreen()),
    GoRoute(
        path: '/goals/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GoalDetailScreen(goalId: id);
        }),
    GoRoute(
        path: '/habits',
        builder: (ctx, state) => const HabitManagementScreen()),
    GoRoute(
        path: '/habits/new',
        builder: (ctx, state) {
          final goalIdStr = state.uri.queryParameters['goalId'];
          final goalId = goalIdStr != null ? int.tryParse(goalIdStr) : null;
          return HabitCreationScreen(goalId: goalId);
        }),
    GoRoute(
        path: '/habits/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return HabitDetailScreen(habitId: id);
        }),
    GoRoute(
        path: '/analytics',
        builder: (ctx, state) => const AnalyticsScreen()),
  ],
);

// ─── APP ─────────────────────────────────────────────────────────────────────
class KYVApp extends ConsumerWidget {
  const KYVApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'KeepYourVow',
      theme: KYVTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
