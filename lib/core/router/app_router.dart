import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/measurement/presentation/pages/home_page.dart';
import '../../features/measurement/presentation/pages/drawing_page.dart';
import '../../features/measurement/presentation/pages/history_page.dart';
import '../../features/measurement/presentation/pages/calculator_page.dart';
import '../../features/measurement/presentation/pages/unit_converter_page.dart';
import '../../features/measurement/presentation/pages/land_calculator_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/measurement/domain/entities/measurement.dart';

class AppRouter {
  static const String home = '/';
  static const String drawing = '/drawing';
  static const String calculator = '/calculator';
  static const String converter = '/converter';
  static const String measurement = '/measurement';
  static const String results = '/results';
  static const String history = '/history';
  static const String landCalculator = '/land-calculator';
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
        pageBuilder: (context, state) {
          final measurement = state.extra as Measurement?;
          return MaterialPage(
            key: state.pageKey,
            child: DrawingPage(measurement: measurement),
          );
        },
      ),
      GoRoute(
        path: calculator,
        name: 'calculator',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const CalculatorPage()),
      ),
      GoRoute(
        path: converter,
        name: 'converter',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const UnitConverterPage()),
      ),
      GoRoute(
        path: landCalculator,
        name: 'landCalculator',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LandCalculatorPage()),
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
