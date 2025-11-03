import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/measurement/presentation/pages/home_page.dart';
import '../../features/measurement/presentation/pages/drawing_page.dart';
import '../../features/measurement/presentation/pages/history_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static const String home = '/';
  static const String drawing = '/drawing';
  static const String measurement = '/measurement';
  static const String results = '/results';
  static const String history = '/history';
  static const String settings = '/settings';

  static GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: drawing,
        name: 'drawing',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const DrawingPage()),
      ),
      GoRoute(
        path: measurement,
        name: 'measurement',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Measurement Page - Coming Soon')),
          ),
        ),
      ),
      GoRoute(
        path: results,
        name: 'results',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Results Page - Coming Soon')),
          ),
        ),
      ),
      GoRoute(
        path: history,
        name: 'history',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HistoryPage()),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SettingsPage()),
      ),
    ],
  );
}
