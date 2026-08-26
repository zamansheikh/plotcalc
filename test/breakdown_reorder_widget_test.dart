import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/settings/view/breakdown_units_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives a real drag on the real screen. The unit-level reorder test can
/// only check the config maths; this is what proves the screen's callback
/// semantics and the config agree, rather than double-correcting each other.
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
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const BreakdownUnitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Drags the handle of the row at [from] by [rows] positions.
  Future<void> dragRow(WidgetTester tester, int from, int rows) async {
    final handles = find.byIcon(Icons.drag_handle);
    final handle = handles.at(from);
    final rowHeight = tester.getSize(handles.at(0)).height + 44;
    final start = tester.getCenter(handle);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    // Move in steps so the list registers the intermediate positions.
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, rows * rowHeight / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a unit down lands it exactly one slot lower', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester);
    final before = bloc.state.breakdown.order;
    final moved = before.first;

    await dragRow(tester, 0, 1);

    final after = bloc.state.breakdown.order;
    expect(after.toSet(), before.toSet(), reason: 'nothing lost or duplicated');
    expect(after.length, before.length);
    expect(
      after.indexOf(moved),
      1,
      reason: 'dragged one row down, so it must sit at index 1 — index 0 '
          'means the drag was ignored, index 2 means a double correction',
    );
    expect(after[0], before[1]);
  });

  testWidgets('a reorder is persisted', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester);
    await dragRow(tester, 0, 1);
    final after = bloc.state.breakdown.order;

    expect(SettingsBloc().state.breakdown.order, after);
  });

  testWidgets('tapping a row toggles that unit, and it sticks', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester);
    expect(bloc.state.breakdown.isOn(AreaUnit.bighaMymensingh), isFalse);

    // Rows are labelled with the localized unit name, not the enum name.
    final ctx = tester.element(find.byType(BreakdownUnitsScreen));
    await tester.tap(find.text(AreaUnit.bighaMymensingh.nameOf(ctx.l10n)));
    await tester.pumpAndSettle();

    expect(bloc.state.breakdown.isOn(AreaUnit.bighaMymensingh), isTrue);
    expect(SettingsBloc().state.breakdown.isOn(AreaUnit.bighaMymensingh),
        isTrue);
  });
}
