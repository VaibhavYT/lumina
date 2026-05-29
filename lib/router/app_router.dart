import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/features/agents/presentation/screens/agents_screen.dart';
import 'package:lumina/features/auth/data/auth_repository.dart';
import 'package:lumina/features/auth/presentation/screens/auth_screen.dart';
import 'package:lumina/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lumina/features/insights/presentation/screens/insights_screen.dart';
import 'package:lumina/features/log/presentation/screens/daily_log_screen.dart';
import 'package:lumina/features/mentor/presentation/screens/mentor_screen.dart';
import 'package:lumina/features/mentor/presentation/screens/untangle_screen.dart';
import 'package:lumina/features/settings/presentation/screens/settings_screen.dart';
import 'package:lumina/router/app_shell.dart';
import 'package:lumina/shared/animations/fade_slide_transition.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authRefresh = authRepository.isAvailable
      ? GoRouterRefreshStream(authRepository.authStateChanges)
      : null;
  ref.onDispose(() => authRefresh?.dispose());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/auth';

      if (!authRepository.isAvailable) {
        if (path == '/' || isAuthRoute) {
          return '/dashboard';
        }
        return null;
      }

      final isSignedIn = authRepository.currentSession != null;

      if (path == '/') {
        return isSignedIn ? '/dashboard' : '/auth';
      }
      if (!isSignedIn && !isAuthRoute) {
        return '/auth';
      }
      if (isSignedIn && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            fadeSlidePage(key: state.pageKey, child: const AuthScreen()),
      ),
      GoRoute(
        path: '/mentor/untangle',
        pageBuilder: (context, state) =>
            fadeSlidePage(key: state.pageKey, child: const UntangleScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/log',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const DailyLogScreen(),
            ),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const InsightsScreen(),
            ),
          ),
          GoRoute(
            path: '/mentor',
            pageBuilder: (context, state) =>
                fadeSlidePage(key: state.pageKey, child: const MentorScreen()),
          ),
          GoRoute(
            path: '/agents',
            pageBuilder: (context, state) =>
                fadeSlidePage(key: state.pageKey, child: const AgentsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
