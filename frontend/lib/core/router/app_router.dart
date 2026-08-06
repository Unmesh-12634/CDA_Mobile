import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/main_shell/presentation/screens/main_shell_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/learn/presentation/screens/learn_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/interview/presentation/screens/interview_setup_screen.dart';
import '../../features/interview/presentation/screens/ai_interview_session_screen.dart';
import '../../features/interview/presentation/screens/interview_analysis_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/quiz/presentation/screens/daily_quiz_screen.dart';
import '../../features/jobs/presentation/screens/saved_jobs_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Full-screen immersive routes (no bottom nav bar) ─────────────────────
    GoRoute(
      path: '/quiz',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DailyQuizScreen(),
    ),
    GoRoute(
      path: '/saved-jobs',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SavedJobsScreen(),
    ),
    GoRoute(
      path: '/interview/setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const InterviewSetupScreen(),
    ),
    GoRoute(
      path: '/interview/session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AiInterviewSessionScreen(),
    ),
    GoRoute(
      path: '/interview/analysis/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'rep-101';
        return InterviewAnalysisScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/jobs/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'job-101';
        return JobDetailScreen(jobId: id);
      },
    ),

    // ── Main Shell with Floating Navigation Bar ───────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) => '/home',
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/learn',
          builder: (context, state) => const LearnScreen(),
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => const JobsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

final routerProvider = Provider<GoRouter>((_) => _router);
