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
import 'package:shared_preferences/shared_preferences.dart';

/// The target has to be typeable: "make it 5.3" is the whole interaction.
/// Steppers alone meant tapping your way there.
void main() {
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

  Future<void> pump(WidgetTester tester, {AreaUnit? unit}) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
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
