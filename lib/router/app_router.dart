import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lumina/features/insights/presentation/screens/insights_screen.dart';
import 'package:lumina/features/log/presentation/screens/daily_log_screen.dart';
import 'package:lumina/features/mentor/presentation/screens/mentor_screen.dart';
import 'package:lumina/features/settings/presentation/screens/settings_screen.dart';
import 'package:lumina/router/app_shell.dart';
import 'package:lumina/shared/animations/fade_slide_transition.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      if (state.uri.path == '/') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
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
