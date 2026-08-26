import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/calculator/view/calculator_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot() async {
  SharedPreferences.setMockInitialValues({});
  await GetIt.I.reset();
  sl.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
}

void main() {
  late SettingsBloc bloc;
  setUp(() async {
    await _boot();
    bloc = SettingsBloc();
  });
  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const CalculatorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The big total field is the first TextField on screen.
  Finder totalField() => find.byType(TextField).first;

  Future<void> expand(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  testWidgets('typing a total shows its compound breakdown', (tester) async {
    await pump(tester);
    // 1 bigha expressed in katha.
    await tester.enterText(totalField(), '20');
    await tester.pumpAndSettle();

    expect(find.text('bigha'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('adding in a different unit updates the total', (tester) async {
    await pump(tester);
    await tester.enterText(totalField(), '10');   // 10 katha
    await tester.pumpAndSettle();

    await expand(tester, 'Adjust area');
    // second TextField is the adjust amount
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // 10 + 10 katha = 20 katha = exactly 1 bigha
    expect(tester.widget<TextField>(totalField()).controller!.text, '20');
    expect(find.text('bigha'), findsOneWidget);
  });

  testWidgets('subtracting works and cannot go below zero', (tester) async {
    await pump(tester);
    await tester.enterText(totalField(), '10');
    await tester.pumpAndSettle();

    await expand(tester, 'Adjust area');
    await tester.tap(find.text('Subtract'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '4');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(totalField()).controller!.text, '6');

    // Now overshoot: the total must refuse rather than go negative.
    await tester.enterText(find.byType(TextField).at(1), '99');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(totalField()).controller!.text, '6');
    expect(find.textContaining('cannot go below zero'), findsOneWidget);
  });

  testWidgets('changing the unit restates the same area', (tester) async {
    await pump(tester);
    await tester.enterText(totalField(), '1');    // 1 katha
    await tester.pumpAndSettle();

    // "katha" also appears in the breakdown, so target the picker itself.
    await tester.tap(
      find
          .descendant(
            of: find.byType(PopupMenuButton<AreaUnit>).first,
            matching: find.text('katha'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chatak').last);
    await tester.pumpAndSettle();

    // 1 katha is exactly 16 chatak — the area must not change, only its label.
    expect(tester.widget<TextField>(totalField()).controller!.text, '16');
  });

  testWidgets('combine sums several units into the total', (tester) async {
    await pump(tester);
    await expand(tester, 'Combine units');

    // Default enabled units are acre, bigha, katha, shotok, chatak.
    final fields = find.byType(TextField);
    final units = bloc.state.breakdown.orderedEnabled;
    final bighaAt = units.indexOf(AreaUnit.bigha);
    final kathaAt = units.indexOf(AreaUnit.katha);

    // +1 for the total field that precedes the combine inputs.
    await tester.enterText(fields.at(1 + bighaAt), '1');
    await tester.enterText(fields.at(1 + kathaAt), '5');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set as total'));
    await tester.pumpAndSettle();

    // 1 bigha + 5 katha = 25 katha.
    expect(tester.widget<TextField>(totalField()).controller!.text, '25');
  });

  testWidgets('clear resets everything', (tester) async {
    await pump(tester);
    await tester.enterText(totalField(), '42');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(totalField()).controller!.text, '');
    expect(find.textContaining('Enter an area'), findsOneWidget);
  });

  test('every pushed route has an entry point in the UI', () {
    // Regression: wiring the calculator onto the home screen's second tile
    // silently orphaned the converter, leaving it unreachable.
    final ui = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join();
    for (final route in ['converter', 'calculator', 'khotiyan', 'compare',
                         'settings', 'about', 'picker', 'breakdownUnits']) {
      expect(ui.contains('AppRoutes.$route'), isTrue,
          reason: '$route is unreachable — nothing navigates to it');
    }
  });
}
