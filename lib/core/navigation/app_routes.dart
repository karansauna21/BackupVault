import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main_navigation_shell.dart';
import '../../features/splash/presentation/views/splash_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/backup/presentation/views/backup_screen.dart';
import '../../features/restore/presentation/views/restore_screen.dart';
import '../../features/folder_manager/folder_manager_screen.dart';
import '../../features/statistics/presentation/views/statistics_screen.dart';
import '../../features/logs/presentation/views/logs_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/about/presentation/views/about_screen.dart';
import '../../features/search/presentation/views/search_screen.dart';
import '../../features/version_history/version_history_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/scheduler/scheduler_screen.dart';
import '../../features/configuration/configuration_screen.dart';
import '../../features/devices/devices_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigationShell(state: state, child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/backup',
          builder: (context, state) => const BackupScreen(),
        ),
        GoRoute(
          path: '/restore',
          builder: (context, state) => const RestoreScreen(),
        ),
        GoRoute(
          path: '/folders',
          builder: (context, state) => const FolderManagerScreen(),
        ),
        GoRoute(
          path: '/statistics',
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: '/logs',
          builder: (context, state) => const LogsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/configuration',
          builder: (context, state) => const ConfigurationScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/versions',
          builder: (context, state) => const VersionHistoryScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationCenterScreen(),
        ),
        GoRoute(
          path: '/scheduler',
          builder: (context, state) => const SchedulerScreen(),
        ),
        GoRoute(
          path: '/devices',
          builder: (context, state) => const DevicesScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
