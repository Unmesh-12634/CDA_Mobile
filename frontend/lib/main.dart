import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/storage/local_cache_service.dart';
import 'core/config/supabase_config.dart';
import 'core/services/network_connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/realtime_notification_bridge.dart';
import 'core/services/smart_nudge_scheduler.dart';
import 'core/services/study_time_tracker_service.dart';
import 'features/auth/data/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCacheService().init();
  await SupabaseConfig.initialize();
  await NotificationService().init();
  StudyTimeTrackerService().initialize();
  runApp(const ProviderScope(child: CdaCareerCompanionApp()));
}

class CdaCareerCompanionApp extends ConsumerStatefulWidget {
  const CdaCareerCompanionApp({super.key});

  @override
  ConsumerState<CdaCareerCompanionApp> createState() => _CdaCareerCompanionAppState();
}

class _CdaCareerCompanionAppState extends ConsumerState<CdaCareerCompanionApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _notifTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Deep-linking handler for notification taps
    _notifTapSub = NotificationService().onNotificationTapped.listen((route) {
      if (route.isNotEmpty) {
        debugPrint('🚀 [AppRouter] Deep-linking to notification route: $route');
        try {
          appRouter.push(route);
        } catch (e) {
          debugPrint('Error pushing notification route $route: $e');
        }
      }
    });

    // Check cached session and start Realtime Notification Bridge
    _initNotificationBridge();
  }

  void _initNotificationBridge() {
    final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
    final cachedName = LocalCacheService().get<String>('cda_auth_name') ?? 'Learner';
    if (cachedEmail != null && cachedEmail.isNotEmpty) {
      RealtimeNotificationBridge().startListening(cachedEmail);
      // Smart non-predefined nudge evaluation
      SmartNudgeScheduler().evaluateAndTriggerNudge(
        studentName: cachedName,
        targetRole: 'Software Engineer',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
      final cachedName = LocalCacheService().get<String>('cda_auth_name') ?? 'Learner';
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        RealtimeNotificationBridge().startListening(cachedEmail);
        SmartNudgeScheduler().evaluateAndTriggerNudge(
          studentName: cachedName,
          targetRole: 'Software Engineer',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isOnline = ref.watch(networkOnlineProvider);

    // Keep bridge in sync with active auth state
    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated && authState.email.isNotEmpty) {
      RealtimeNotificationBridge().startListening(authState.email);
    }

    return MaterialApp.router(
      title: 'CDA Career Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            if (!isOnline)
              Material(
                color: const Color(0xFFDC2626),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'No Internet Connection • Running in Offline Mode',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}


