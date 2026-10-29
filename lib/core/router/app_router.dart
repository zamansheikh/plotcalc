import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/features/about/view/about_screen.dart';
import '../../presentation/features/adjust/view/adjust_screen.dart';
import '../../presentation/features/calculator/view/calculator_screen.dart';
import '../../presentation/features/compare/view/compare_screen.dart';
import '../../presentation/features/converter/view/converter_screen.dart';
import '../../presentation/features/draw/view/draw_screen.dart';
import '../../presentation/features/history/view/history_screen.dart';
import '../../presentation/features/home/view/home_screen.dart';
import '../../presentation/features/info/data/articles.dart';
import '../../presentation/features/info/view/article_screen.dart';
import '../../presentation/features/info/view/info_screen.dart';
import '../../presentation/features/khotiyan/view/khotiyan_screen.dart';
import '../../presentation/features/mouza/view/mouza_screen.dart';
import '../../presentation/features/overlay/view/overlay_screen.dart';
import '../../presentation/features/picker/view/picker_screen.dart';
import '../../presentation/features/result/view/result_screen.dart';
import '../../presentation/features/settings/view/breakdown_units_screen.dart';
import '../../presentation/features/settings/view/settings_screen.dart';
import '../../presentation/features/sheet/view/arrange_screen.dart';
import '../../presentation/features/sheet/view/sheet_screen.dart';
import '../../presentation/features/subdivide/view/subdivide_screen.dart';
import '../../presentation/shared/widgets/main_shell.dart';
import '../../l10n/l10n.dart';
import '../geometry/presets.dart';
import '../input_method.dart';

class AppRoutes {
  // Tabs (inside the shell)
  static const home = '/';
  static const history = '/history';
  static const subdivide = '/subdivide';
  static const info = '/info';

  // Pushed on top of the shell (no bottom nav)
  static const picker = '/picker';
  static const draw = '/draw';
  static const result = '/result';
  static const adjust = '/adjust';
  static const compare = '/compare';
  static const sheet = '/sheet';
  static const sheetArrange = '/sheet/arrange';
  static const mouza = '/mouza';
  static const mapOverlay = '/map-overlay';
  static const converter = '/converter';
  static const calculator = '/calculator';
  static const khotiyan = '/khotiyan';
  static const article = '/article';
  static const settings = '/settings';
  static const breakdownUnits = '/settings/breakdown-units';
  static const about = '/about';
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // Persistent shell with the four bottom-nav tabs. Each branch keeps
      // its own navigation stack, so deep navigation in one tab doesn't
      // disturb the others.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.subdivide,
                builder: (_, _) => const SubdivideScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.info,
                builder: (_, _) => const InfoScreen(),
              ),
            ],
          ),
        ],
      ),

      // Top-level routes pushed over the shell (bottom nav hidden while
      // they're active).
      GoRoute(path: AppRoutes.picker, builder: (_, _) => const PickerScreen()),
      GoRoute(
        path: AppRoutes.draw,
        builder: (_, state) {
          final extra = state.extra;
          if (extra is DrawArgs) return DrawScreen(args: extra);
          if (extra is ShapePreset) {
            return DrawScreen(
              args: DrawArgs(method: InputMethod.draw, preset: extra),
            );
          }
          return const DrawScreen(
            args: DrawArgs(
              method: InputMethod.draw,
              preset: ShapePreset.freeform,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.result,
        builder: (_, state) {
          final args = state.extra as ResultArgs?;
          return ResultScreen(args: args ?? const ResultArgs.demo());
        },
      ),
      GoRoute(
        path: AppRoutes.adjust,
        builder: (context, state) {
          final args = state.extra as AdjustArgs?;
          return AdjustScreen(
            args:
                args ??
                AdjustArgs(name: context.l10n.defaultPlotLabel, vertices: []),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.compare,
        builder: (_, state) =>
            CompareScreen(plotIds: (state.extra as List?)?.cast<String>()),
      ),
      GoRoute(
        path: AppRoutes.sheet,
        builder: (_, state) => SheetScreen(sheetId: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.sheetArrange,
        builder: (_, state) => ArrangeScreen(sheetId: state.extra as String),
      ),
      GoRoute(path: AppRoutes.mouza, builder: (_, _) => const MouzaScreen()),
      GoRoute(
        path: AppRoutes.mapOverlay,
        builder: (_, _) => const OverlayScreen(),
      ),
      GoRoute(
        path: AppRoutes.converter,
        builder: (_, _) => const ConverterScreen(),
      ),
      GoRoute(
        path: AppRoutes.calculator,
        builder: (_, _) => const CalculatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.khotiyan,
        builder: (_, _) => const KhotiyanScreen(),
      ),
      GoRoute(
        path: AppRoutes.article,
        builder: (_, state) {
          final article = state.extra as Article?;
          if (article == null) return const InfoScreen();
          return ArticleScreen(article: article);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.breakdownUnits,
        builder: (_, _) => const BreakdownUnitsScreen(),
      ),
      GoRoute(path: AppRoutes.about, builder: (_, _) => const AboutScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(context.l10n.routeNotFound('${state.uri}'))),
    ),
  );
}
