import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/adjust/view/adjust_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:plotcalc/presentation/shared/settings/settings_event.dart';
import 'package:plotcalc/presentation/shared/widgets/grid_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The target has to be typeable: "make it 5.3" is the whole interaction.
/// Steppers alone meant tapping your way there.
void main() {
  _layout();

  late SettingsBloc settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
    settings = SettingsBloc();
  });
  tearDown(() => settings.close());

  /// A 400 m2 square, which is 5.98 katha — near enough the story.
  const base = [
    Vertex(0, 0),
    Vertex(20, 0),
    Vertex(20, 20),
    Vertex(0, 20),
  ];

  Future<void> pump(
    WidgetTester tester, {
    AreaUnit? unit,
    Size size = const Size(1200, 2600),
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    // Mimics the keyboard claiming the bottom of the screen.
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    if (unit != null) {
      settings.add(AreaUnitChanged(unit));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AdjustScreen(
            args: AdjustArgs(name: 'North field', vertices: base),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder targetField() => find.byType(TextField).first;
  String targetText(WidgetTester tester) =>
      tester.widget<TextField>(targetField()).controller!.text;

  testWidgets('the target is an editable field, not a read-only number', (
    tester,
  ) async {
    await pump(tester);
    expect(targetField(), findsOneWidget);
    final field = tester.widget<TextField>(targetField());
    expect(field.readOnly, isFalse);
    expect(field.controller, isNotNull);
  });

  testWidgets('it opens on the area the plot already has', (tester) async {
    await pump(tester, unit: AreaUnit.sqm);
    expect(double.parse(targetText(tester)), closeTo(400, 0.5));
  });

  testWidgets('typing a target is accepted', (tester) async {
    await pump(tester, unit: AreaUnit.sqm);
    await tester.enterText(targetField(), '440');
    await tester.pump(const Duration(milliseconds: 100));
    // The adjusted readout follows what was typed.
    expect(find.textContaining('440'), findsWidgets);
  });

  testWidgets('a half-typed number is not corrected away', (tester) async {
    // Regression guard: rewriting the field on every rebuild would turn
    // "5." into "5" mid-keystroke and fight the keyboard.
    await pump(tester, unit: AreaUnit.sqm);
    // Each step must change the parsed value, otherwise no rebuild happens
    // and the guard is never exercised.
    await tester.enterText(targetField(), '44');
    await tester.pump(const Duration(milliseconds: 50));
    expect(targetText(tester), '44');

    // "45." parses to 45, so the bloc state changes and the parent rebuilds.
    // Without the guard the field would be rewritten to "45" and the decimal
    // point would vanish as the user typed it.
    await tester.enterText(targetField(), '45.');
    await tester.pump(const Duration(milliseconds: 50));
    expect(targetText(tester), '45.');

    // And a trailing zero must survive long enough to type "45.05".
    await tester.enterText(targetField(), '45.0');
    await tester.pump(const Duration(milliseconds: 50));
    expect(targetText(tester), '45.0');
  });

  testWidgets('the steppers still work and update the field', (tester) async {
    await pump(tester, unit: AreaUnit.sqm);
    final before = double.parse(targetText(tester));
    await tester.tap(find.text('+'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(double.parse(targetText(tester)), greaterThan(before));

    await tester.tap(find.text('−'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(double.parse(targetText(tester)), closeTo(before, 0.01));
  });

  testWidgets('the target can be entered in any unit', (tester) async {
    // A plot is discussed in katha even when the app is set to sq ft.
    await pump(tester, unit: AreaUnit.sqft);
    final asSqft = double.parse(targetText(tester));
    expect(asSqft, closeTo(AreaUnit.sqft.fromSqm(400), 1));

    await tester.tap(find.text('katha').first);
    await tester.pump(const Duration(milliseconds: 100));

    // Same plot, restated — not reinterpreted.
    expect(
      double.parse(targetText(tester)),
      closeTo(AreaUnit.katha.fromSqm(400), 0.01),
    );
  });

  testWidgets('choosing a unit here does not change the app setting', (
    tester,
  ) async {
    await pump(tester, unit: AreaUnit.sqft);
    await tester.tap(find.text('katha').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(settings.state.areaUnit, AreaUnit.sqft);
  });

  testWidgets('typing rubbish does not crash or wipe the plot', (
    tester,
  ) async {
    await pump(tester, unit: AreaUnit.sqm);
    for (final junk in ['', '.', ',', '...']) {
      await tester.enterText(targetField(), junk);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
  });
}

/// The screen was a fixed Column with a 220px plan: the keyboard pushed it
/// 97px past the bottom, and with the keyboard closed there was a slab of
/// dead space under the buttons.
void _layout() {
  group('layout', () {
    late SettingsBloc settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GetIt.I.reset();
      await configureDependencies();
      settings = SettingsBloc();
    });
    tearDown(() => settings.close());

    const base = [
      Vertex(0, 0),
      Vertex(20, 0),
      Vertex(20, 20),
      Vertex(0, 20),
    ];

    Future<void> pumpAt(
      WidgetTester tester,
      Size size, {
      double keyboard = 0,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider<SettingsBloc>.value(
          value: settings,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const AdjustScreen(
              args: AdjustArgs(name: 'Plot', vertices: base),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('an open keyboard does not overflow the screen', (
      tester,
    ) async {
      // A Pixel 6 in logical pixels, numeric keypad up.
      await pumpAt(tester, const Size(393, 873), keyboard: 300);
      expect(tester.takeException(), isNull);
    });

    testWidgets('it survives a small screen with the keyboard up', (
      tester,
    ) async {
      await pumpAt(tester, const Size(360, 640), keyboard: 260);
      expect(tester.takeException(), isNull);
    });

    /// The target card has a grid behind it too, so take the tallest —
    /// that is the plan.
    double planHeight(WidgetTester tester) => tester
        .widgetList<GridBackground>(find.byType(GridBackground))
        .map((w) => tester.getSize(find.byWidget(w)).height)
        .reduce((a, b) => a > b ? a : b);

    testWidgets('the plan grows to fill a tall screen', (tester) async {
      // The dead space under the buttons was a plan pinned at 220px.
      await pumpAt(tester, const Size(393, 873));
      expect(planHeight(tester), greaterThan(280),
          reason: 'the plan should use the space, not leave it blank');
    });

    testWidgets('the plan gives way when the keyboard appears', (
      tester,
    ) async {
      await pumpAt(tester, const Size(393, 873));
      final open = planHeight(tester);
      await pumpAt(tester, const Size(393, 873), keyboard: 300);
      expect(planHeight(tester), lessThan(open));
    });

    testWidgets('the content scrolls once it no longer fits', (tester) async {
      await pumpAt(tester, const Size(393, 873), keyboard: 300);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      // Apply is reachable by scrolling rather than clipped away.
      await tester.dragUntilVisible(
        find.text('Apply adjustment'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -120),
      );
      expect(find.text('Apply adjustment'), findsOneWidget);
    });
  });
}
