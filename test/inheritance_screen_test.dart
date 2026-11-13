import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/inheritance/view/inheritance_screen.dart';
import 'package:plotcalc/presentation/features/subdivide/view/subdivide_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _plot = Plot(
  id: 'home',
  name: 'Homestead',
  vertices: const [Vertex(0, 0), Vertex(40, 0), Vertex(40, 30), Vertex(0, 30)],
  tag: PlotTag.residential,
  createdAt: DateTime(2026, 11, 13),
  colorValue: 0xFFC8FF5A,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
    await sl<SavePlot>()(_plot);
  });
  tearDown(() => Intl.defaultLocale = null);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InheritanceScreen()),
        GoRoute(
          path: AppRoutes.divide,
          builder: (_, s) => Scaffold(
            body: SubdivideScreen(prefill: s.extra as DivisionPrefill),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      final f = find.byKey(ValueKey(key));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('wife, son, daughter: shares, land, then divide the plot', (
    tester,
  ) async {
    await pump(tester);
    // Nothing chosen yet: can't go on.
    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('inherit-next')),
    );
    expect(next.onPressed, isNull);

    await tapKey(tester, 'inherit-male');
    await tester.enterText(
      find.byKey(const ValueKey('inherit-name')),
      'Abdul Karim',
    );
    await tester.enterText(find.byKey(const ValueKey('inherit-land')), '100');
    await tester.pumpAndSettle();
    await tapKey(tester, 'inherit-next');

    // A man: wives, not a husband.
    expect(find.byKey(const ValueKey('inherit-husband-switch')), findsNothing);
    await tapKey(tester, 'inherit-wives-plus');
    await tapKey(tester, 'inherit-sons-plus');
    await tapKey(tester, 'inherit-daughters-plus');

    // With a son, brothers and uncles are not asked about.
    expect(
      find.byKey(const ValueKey('inherit-fullBrothers-plus')),
      findsNothing,
    );
    expect(find.textContaining('brothers, sisters, uncles'), findsOneWidget);

    await tapKey(tester, 'inherit-see');
    expect(find.text("Abdul Karim's estate"), findsOneWidget);
    expect(find.text('Base 24'), findsOneWidget);
    expect(find.text('Wife'), findsOneWidget);
    expect(find.text('Son'), findsOneWidget);
    expect(find.text('Daughter'), findsOneWidget);
    expect(find.textContaining('1/8 · 12.5%'), findsOneWidget);
    expect(find.textContaining('7/12 · 58.3%'), findsOneWidget);
    expect(find.textContaining('7/24 · 29.2%'), findsOneWidget);
    expect(find.text('3 of 24 parts'), findsOneWidget);
    expect(
      find.text('With children: wives take 1/8, shared equally.'),
      findsOneWidget,
    );

    // On to dividing the land: pick the plot, owners are already there.
    await tapKey(tester, 'inherit-divide');
    expect(find.text('Which plot is being divided?'), findsOneWidget);
    await tester.tap(find.text('Homestead'));
    await tester.pumpAndSettle();
    String field(String key) =>
        tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;
    expect(field('owner-name-0'), 'Wife');
    expect(field('owner-amount-0'), '1/8');
    expect(field('owner-name-1'), 'Son');
    expect(field('owner-amount-1'), '7/12');
    expect(field('owner-name-2'), 'Daughter');
    expect(field('owner-amount-2'), '7/24');
  });

  testWidgets('a saved plot goes straight to its division', (tester) async {
    await pump(tester);
    await tapKey(tester, 'inherit-female');
    await tester.tap(find.text('Homestead'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'inherit-next');
    await tapKey(tester, 'inherit-husband-switch');
    await tapKey(tester, 'inherit-daughters-plus', times: 2);
    await tapKey(tester, 'inherit-see');
    // Husband 1/4, two daughters 2/3: 11/12, the rest back to the daughters.
    expect(find.textContaining('radd'), findsOneWidget);
    await tapKey(tester, 'inherit-divide');
    expect(find.text('Which plot is being divided?'), findsNothing);
    expect(find.text('Daughter 2'), findsWidgets);
  });

  testWidgets('relatives are asked about only when they can matter', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'inherit-male');
    await tapKey(tester, 'inherit-next');

    // No children, no father: brothers and sisters can inherit.
    expect(
      find.byKey(const ValueKey('inherit-fullBrothers-plus')),
      findsOneWidget,
    );
    // The father shuts them out…
    await tapKey(tester, 'inherit-father-switch');
    expect(
      find.byKey(const ValueKey('inherit-fullBrothers-plus')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('inherit-grandfather-switch')),
      findsNothing,
    );
    // …but with the mother alive they still cut her share, so they're asked.
    await tapKey(tester, 'inherit-mother-switch');
    expect(
      find.byKey(const ValueKey('inherit-fullBrothers-plus')),
      findsOneWidget,
    );
    expect(find.textContaining('cut the mother to 1/6'), findsOneWidget);
    await tapKey(tester, 'inherit-fullBrothers-plus', times: 2);
    await tapKey(tester, 'inherit-see');
    expect(find.textContaining('1/6 ·'), findsNothing); // no land: no "·"
    expect(find.text('1/6'), findsOneWidget); // the mother
    expect(find.text('5/6'), findsOneWidget); // the father
    expect(
      find.text('Brother: nothing, because the father is alive'),
      findsOneWidget,
    );
  });

  testWidgets('a child who died earlier passes their share on', (tester) async {
    await pump(tester);
    await tapKey(tester, 'inherit-male');
    await tapKey(tester, 'inherit-next');
    await tapKey(tester, 'inherit-wives-plus');
    await tapKey(tester, 'inherit-sons-plus');
    await tapKey(tester, 'inherit-add-dead');
    await tapKey(tester, 'inherit-dead-0-daughters-plus');
    await tapKey(tester, 'inherit-see');
    // Wife 1/8; the son and the late son 7/16 each; the late son's son and
    // daughter split his 7/16 as 2:1.
    expect(find.text("Late son 1's son"), findsOneWidget);
    expect(find.text("Late son 1's daughter"), findsOneWidget);
    expect(find.text('7/24'), findsOneWidget);
    expect(find.text('7/48'), findsOneWidget);
  });

  testWidgets('Hindu: the widow takes a son\'s share, for life', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'inherit-male');
    await tapKey(tester, 'inherit-law-hindu');
    await tapKey(tester, 'inherit-next');
    await tapKey(tester, 'inherit-widows-plus');
    await tapKey(tester, 'inherit-sons-plus', times: 2);
    // With sons, daughters and the rest are not asked about.
    expect(
      find.byKey(const ValueKey('inherit-unmarriedDaughters-plus')),
      findsNothing,
    );
    await tapKey(tester, 'inherit-see');
    expect(find.text('1/3'), findsNWidgets(3));
    expect(find.text('For life'), findsOneWidget);
    expect(find.textContaining('A life interest'), findsOneWidget);
    expect(find.textContaining('Dayabhaga'), findsOneWidget);
  });

  testWidgets("Hindu: a woman's estate is explained, not worked out", (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'inherit-female');
    await tapKey(tester, 'inherit-law-hindu');
    expect(find.byKey(const ValueKey('inherit-hindu-woman')), findsOneWidget);
    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('inherit-next')),
    );
    expect(next.onPressed, isNull);
    // Another religion: on again.
    await tapKey(tester, 'inherit-law-christian');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('inherit-next')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Christian: widow, mother and two brothers', (tester) async {
    await pump(tester);
    await tapKey(tester, 'inherit-male');
    await tapKey(tester, 'inherit-law-christian');
    await tapKey(tester, 'inherit-next');
    await tapKey(tester, 'inherit-spouse-switch');
    await tapKey(tester, 'inherit-mother-switch');
    await tapKey(tester, 'inherit-brothers-plus', times: 2);
    await tapKey(tester, 'inherit-see');
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('1/6'), findsNWidgets(3));
    expect(find.textContaining('Succession Act 1925'), findsOneWidget);
  });

  testWidgets('Muslim: distant relatives only when nobody else inherits', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'inherit-male');
    await tapKey(tester, 'inherit-next');
    // Nobody yet: the distant relatives are asked about.
    expect(
      find.byKey(const ValueKey('inherit-maternalGrandfather-switch')),
      findsOneWidget,
    );
    // A daughter inherits: no more distant relatives.
    await tapKey(tester, 'inherit-daughters-plus');
    expect(
      find.byKey(const ValueKey('inherit-maternalGrandfather-switch')),
      findsNothing,
    );
    await tapKey(tester, 'inherit-daughters-minus');
    await tapKey(tester, 'inherit-wives-plus');
    await tapKey(tester, 'inherit-fullPaternalAunts-plus');
    await tapKey(tester, 'inherit-fullMaternalUncles-plus');
    await tapKey(tester, 'inherit-see');
    // Wife 1/4; the rest: father's side 2/3, mother's side 1/3.
    expect(find.text('1/4'), findsWidgets);
    expect(find.text("Father's sister"), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.textContaining('distant relatives inherit'), findsOneWidget);
  });
}
