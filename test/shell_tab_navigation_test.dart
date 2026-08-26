import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/presentation/shared/widgets/bottom_tab_bar.dart';
import 'package:plotcalc/presentation/shared/widgets/main_shell.dart';

/// Minimal stand-in for the real shell: same StatefulShellRoute wiring, but
/// with trivial tab bodies so the test exercises navigation only.
GoRouter _router() {
  Widget page(String label, {VoidCallback? onTap}) => Scaffold(
    body: Center(
      child: GestureDetector(
        onTap: onTap,
        child: Text(label),
      ),
    ),
  );

  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _TestShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, _) => page(
                  'PLOTS',
                  onTap: () => context.goTab(TabKind.history),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/history', builder: (_, _) => page('HISTORY')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/subdivide', builder: (_, _) => page('SUBDIVIDE')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/info', builder: (_, _) => page('INFO')),
            ],
          ),
        ],
      ),
    ],
  );
}

class _TestShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _TestShell({required this.shell});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: Row(
      children: [
        for (final t in TabKind.values)
          Expanded(
            child: GestureDetector(
              key: ValueKey('tab-${t.name}'),
              behavior: HitTestBehavior.opaque,
              // Mirrors BottomTabBar: taps on the active tab are ignored.
              onTap: t.index == shell.currentIndex
                  ? null
                  : () => shell.goBranch(t.index),
              child: SizedBox(
                height: 40,
                child: Center(child: Text('nav-${t.name}')),
              ),
            ),
          ),
      ],
    ),
  );

  static int indexOf(WidgetTester tester) =>
      (tester.widget<_TestShell>(find.byType(_TestShell))).shell.currentIndex;
}

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();
  }

  testWidgets('"See all" selects the History tab, not a pushed page', (
    tester,
  ) async {
    await pump(tester);
    expect(_TestShell.indexOf(tester), 0);

    await tester.tap(find.text('PLOTS'));
    await tester.pumpAndSettle();

    expect(find.text('HISTORY'), findsOneWidget);
    // The bug: History was visible while the shell still reported branch 0,
    // so the bar highlighted Plots.
    expect(_TestShell.indexOf(tester), 1);
  });

  testWidgets('you can leave History again after arriving via "See all"', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('PLOTS'));
    await tester.pumpAndSettle();
    expect(find.text('HISTORY'), findsOneWidget);

    // Previously this was the dead end: the Plots tab was rendered active,
    // its tap handler was null, and goBranch(0) re-revealed the pushed
    // History page.
    await tester.tap(find.byKey(const ValueKey('tab-plots')));
    await tester.pumpAndSettle();

    expect(find.text('PLOTS'), findsOneWidget);
    expect(find.text('HISTORY'), findsNothing);
    expect(_TestShell.indexOf(tester), 0);
  });

  testWidgets('every other tab remains reachable from History', (tester) async {
    await pump(tester);
    await tester.tap(find.text('PLOTS'));
    await tester.pumpAndSettle();

    for (final t in [TabKind.subdivide, TabKind.info, TabKind.plots]) {
      await tester.tap(find.byKey(ValueKey('tab-${t.name}')));
      await tester.pumpAndSettle();
      expect(_TestShell.indexOf(tester), t.index, reason: t.name);
    }
  });
}
