import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/main_shell/presentation/screens/main_shell_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/learn/presentation/screens/learn_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/interview/presentation/screens/interview_setup_screen.dart';
import '../../features/interview/presentation/screens/interview_reports_history_screen.dart';
import '../../features/interview/presentation/screens/ai_interview_session_screen.dart';
import '../../features/interview/presentation/screens/interview_analysis_screen.dart';
import '../../features/interview/presentation/screens/backend_connection_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/quiz/presentation/screens/daily_quiz_screen.dart';
import '../../features/jobs/presentation/screens/saved_jobs_screen.dart';
import '../../features/roadmap/presentation/screens/career_roadmap_screen.dart';
import '../../features/jobs/presentation/screens/application_tracker_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

import '../../features/subscription/presentation/screens/subscription_details_screen.dart';
import '../../features/practice/presentation/screens/ai_daily_challenge_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        child: const SignUpScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const ForgotPasswordScreen(),
      ),
    ),

    // ── Full-screen immersive routes (no bottom nav bar) ─────────────────────
    GoRoute(
      path: '/subscription-details',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const SubscriptionDetailsScreen(),
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/quiz',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const DailyQuizScreen(),
      ),
    ),
    GoRoute(
      path: '/saved-jobs',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const SavedJobsScreen(),
      ),
    ),
    GoRoute(
      path: '/career-roadmap',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const CareerRoadmapScreen(),
      ),
    ),
    GoRoute(
      path: '/applications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const ApplicationTrackerScreen(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: '/daily-challenge',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const AiDailyChallengeScreen(),
      ),
    ),
    GoRoute(
      path: '/interview/setup',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final stepParam = state.uri.queryParameters['initialStep'];
        final initialStep = int.tryParse(stepParam ?? '0') ?? 0;
        return _buildAppleTransitionPage(
          context: context,
          state: state,
          isSlide: true,
          child: InterviewSetupScreen(initialStep: initialStep),
        );
      },
    ),
    GoRoute(
      path: '/interview/reports',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const InterviewReportsHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/interview/diagnostics',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const BackendConnectionDiagnosticsScreen(),
      ),
    ),
    GoRoute(
      path: '/interview/session',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const AiInterviewSessionScreen(),
      ),
    ),
    GoRoute(
      path: '/interview/analysis/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? 'rep-101';
        final extra = state.extra as Map<String, dynamic>?;
        return _buildAppleTransitionPage(
          context: context,
          state: state,
          isSlide: true,
          child: InterviewAnalysisScreen(reportId: id, reportData: extra),
        );
      },
    ),
    GoRoute(
      path: '/jobs/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? 'job-101';
        return _buildAppleTransitionPage(
          context: context,
          state: state,
          isSlide: true,
          child: JobDetailScreen(jobId: id),
        );
      },
    ),
    GoRoute(
      path: '/application-tracker',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildAppleTransitionPage(
        context: context,
        state: state,
        isSlide: true,
        child: const ApplicationTrackerScreen(),
      ),
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
          pageBuilder: (context, state) => _buildAppleTransitionPage(
            context: context,
            state: state,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/learn',
          pageBuilder: (context, state) => _buildAppleTransitionPage(
            context: context,
            state: state,
            child: const LearnScreen(),
          ),
        ),
        GoRoute(
          path: '/jobs',
          pageBuilder: (context, state) => _buildAppleTransitionPage(
            context: context,
            state: state,
            child: const JobsScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildAppleTransitionPage(
            context: context,
            state: state,
            child: const ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildAppleTransitionPage(
            context: context,
            state: state,
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);

/// Custom Apple Physical Spring Page Transition (220ms zero-latency response)
CustomTransitionPage<T> _buildAppleTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool isSlide = false,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }
      if (isSlide) {
        // Physical Apple horizontal slide + opacity fade for detail sub-screens
        final slide = Tween<Offset>(
          begin: const Offset(0.08, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      } else {
        // Smooth scale (0.97 -> 1.0) + opacity fade for top-level tab switches
        final scale = Tween<double>(begin: 0.97, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return ScaleTransition(
          scale: scale,
          child: FadeTransition(opacity: fade, child: child),
        );
      }
    },
  );
}

final routerProvider = Provider<GoRouter>((_) => _router);
