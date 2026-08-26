import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/calculator/view/calculator_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:plotcalc/presentation/shared/widgets/area_breakdown_view.dart';
import 'package:plotcalc/presentation/shared/widgets/unit_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    bloc = SettingsBloc();
  });
  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2800);
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

  // Unit labels appear in the total chips, the adjust chips AND the
  // breakdown, so every finder below is scoped to the region it means.
  Finder totalField() => find.byType(TextField).first;
  Finder amountField() => find.byType(TextField).at(1);
  Finder inBreakdown(String t) => find.descendant(
    of: find.byType(AreaBreakdownView),
    matching: find.text(t),
  );
  Finder totalChip(String t) => find.descendant(
    of: find.byType(UnitChipRow).first,
    matching: find.text(t),
  );
  String totalText(WidgetTester tester) =>
      tester.widget<TextField>(totalField()).controller!.text;

  Future<void> tapAdjust(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(WideButton, label));
    await tester.pumpAndSettle();
  }

  group('total and breakdown', () {
    testWidgets('typing a total shows its compound breakdown', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '20');   // 20 katha = 1 bigha
      await tester.pumpAndSettle();

      expect(inBreakdown('bigha'), findsOneWidget);
      expect(inBreakdown('1'), findsOneWidget);
      expect(inBreakdown('katha'), findsNothing, reason: 'carried into bigha');
    });

    testWidgets('an empty total explains itself', (tester) async {
      await pump(tester);
      expect(find.textContaining('Enter an area'), findsOneWidget);
    });

    testWidgets('changing the unit restates the same area', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '1');   // 1 katha
      await tester.pumpAndSettle();

      await tester.tap(totalChip('chatak'));
      await tester.pumpAndSettle();

      // 1 katha is exactly 16 chatak: same area, new label.
      expect(totalText(tester), '16');
    });
  });

  group('adjust', () {
    testWidgets('adding in another unit updates the total', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '10');
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '10');
      await tester.pumpAndSettle();
      await tapAdjust(tester, 'Add');

      expect(totalText(tester), '20');
      expect(inBreakdown('bigha'), findsOneWidget);
    });

    testWidgets('subtracting works', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '10');
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '4');
      await tester.pumpAndSettle();
      await tapAdjust(tester, 'Subtract');

      expect(totalText(tester), '6');
    });

    testWidgets('the total refuses to go negative', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '6');
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '99');
      await tester.pumpAndSettle();
      await tapAdjust(tester, 'Subtract');

      expect(totalText(tester), '6', reason: 'total left untouched');
      expect(find.textContaining('cannot go below zero'), findsOneWidget);
    });

    testWidgets('the adjust unit follows the total unit by default', (
      tester,
    ) async {
      await pump(tester);
      // Switch the total to chatak; adjusting should now default to chatak.
      await tester.tap(totalChip('chatak'));
      await tester.pumpAndSettle();
      await tester.enterText(totalField(), '32');   // 32 chatak = 2 katha
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '16');  // + 16 chatak = 1 katha
      await tester.pumpAndSettle();
      await tapAdjust(tester, 'Add');

      expect(totalText(tester), '48', reason: '48 chatak = 3 katha');
      expect(inBreakdown('katha'), findsOneWidget);
      expect(inBreakdown('3'), findsOneWidget);
    });

    testWidgets('an explicit adjust unit overrides the default', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(totalField(), '10');   // 10 katha
      await tester.pumpAndSettle();
      // Pick bigha in the adjust row (second chip row).
      await tester.tap(
        find.descendant(
          of: find.byType(UnitChipRow).last,
          matching: find.text('bigha'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '1');   // + 1 bigha = 20 katha
      await tester.pumpAndSettle();
      await tapAdjust(tester, 'Add');

      expect(totalText(tester), '30');
    });

    testWidgets('Add and Subtract are the only controls, each acting once', (
      tester,
    ) async {
      await pump(tester);
      // Regression: there used to be an Add/Subtract mode toggle *and* an
      // apply button, so two different controls read "Add".
      expect(find.widgetWithText(WideButton, 'Add'), findsOneWidget);
      expect(find.widgetWithText(WideButton, 'Subtract'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Subtract'), findsOneWidget);
    });

    testWidgets('both actions are disabled until an amount is entered', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(totalField(), '10');
      await tester.pumpAndSettle();
      expect(
        tester.widget<WideButton>(find.widgetWithText(WideButton, 'Add')).onTap,
        isNull,
      );

      await tester.enterText(amountField(), '2');
      await tester.pumpAndSettle();
      expect(
        tester.widget<WideButton>(find.widgetWithText(WideButton, 'Add')).onTap,
        isNotNull,
      );
    });

    testWidgets('the amount clears after applying', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '5');
      await tester.pumpAndSettle();
      await tester.enterText(amountField(), '5');
      await tester.pumpAndSettle();
      await tapAdjust(tester, 'Add');

      expect(tester.widget<TextField>(amountField()).controller!.text, '');
    });
  });

  group('by-unit entry', () {
    testWidgets('is seeded from the current total', (tester) async {
      await pump(tester);
      await tester.enterText(totalField(), '25');  // 1 bigha 5 katha
      await tester.pumpAndSettle();
      await tester.tap(find.text('By unit'));
      await tester.pumpAndSettle();

      final units = bloc.state.breakdown.orderedEnabled;
      String at(AreaUnit u) => tester
          .widget<TextField>(find.byType(TextField).at(units.indexOf(u)))
          .controller!
          .text;
      expect(at(AreaUnit.bigha), '1');
      expect(at(AreaUnit.katha), '5');
    });

    testWidgets('sums live with no apply step', (tester) async {
      await pump(tester);
      await tester.tap(find.text('By unit'));
      await tester.pumpAndSettle();

      final units = bloc.state.breakdown.orderedEnabled;
      await tester.enterText(
        find.byType(TextField).at(units.indexOf(AreaUnit.bigha)),
        '1',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).at(units.indexOf(AreaUnit.katha)),
        '5',
      );
      await tester.pumpAndSettle();

      expect(inBreakdown('bigha'), findsOneWidget);
      expect(inBreakdown('katha'), findsOneWidget);
      expect(inBreakdown('5'), findsOneWidget);
    });

    testWidgets('a round trip through by-unit preserves the area', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(totalField(), '25');
      await tester.pumpAndSettle();
      await tester.tap(find.text('By unit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Single value'));
      await tester.pumpAndSettle();

      expect(totalText(tester), '25');
    });
  });

  testWidgets('clear resets everything', (tester) async {
    await pump(tester);
    await tester.enterText(totalField(), '42');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(totalText(tester), '');
    expect(find.textContaining('Enter an area'), findsOneWidget);
  });

  group('design consistency', () {
    test('the calculator uses the shared UI vocabulary, not raw Material', () {
      final src = File(
        'lib/presentation/features/calculator/view/calculator_screen.dart',
      ).readAsStringSync();
      // These were the mismatches the first version shipped with.
      expect(src.contains('PopupMenuButton'), isFalse,
          reason: 'the app selects units with pill chips');
      expect(src.contains('OutlineInputBorder'), isFalse,
          reason: 'numeric entry is borderless mono');
      expect(src.contains('ToolHeader'), isTrue);
      expect(src.contains('UnitChipRow'), isTrue);
      expect(src.contains('BigNumberField'), isTrue);
    });

    test('converter and calculator share one input implementation', () {
      final conv = File(
        'lib/presentation/features/converter/view/converter_screen.dart',
      ).readAsStringSync();
      for (final w in ['ToolHeader', 'BigNumberField', 'UnitChipRow']) {
        expect(conv.contains(w), isTrue,
            reason: 'converter should use the shared $w');
      }
    });

    test('every pushed route has an entry point in the UI', () {
      final ui = Directory('lib/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.readAsStringSync())
          .join();
      for (final route in [
        'converter', 'calculator', 'khotiyan', 'compare',
        'settings', 'about', 'picker', 'breakdownUnits',
      ]) {
        expect(ui.contains('AppRoutes.$route'), isTrue,
            reason: '$route is unreachable — nothing navigates to it');
      }
    });
  });
}
