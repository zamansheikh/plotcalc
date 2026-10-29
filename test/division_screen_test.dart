import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/export/division_pdf.dart';
import 'package:plotcalc/core/geometry/division_plan.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/core/units/length_unit.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/usecases/get_plots.dart';
import 'package:plotcalc/domain/usecases/get_sheets.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/subdivide/division_store.dart';
import 'package:plotcalc/presentation/features/subdivide/view/subdivide_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'export_test.dart' show l10nFor;

/// 60 × 40 m.
final parent = Plot(
  id: 'parent',
  name: 'North field',
  vertices: const [Vertex(0, 0), Vertex(60, 0), Vertex(60, 40), Vertex(0, 40)],
  tag: PlotTag.agricultural,
  createdAt: DateTime(2026, 10, 29),
  colorValue: 0xFFC8FF5A,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
    await sl<SavePlot>()(parent);
  });
  tearDown(() => Intl.defaultLocale = null);

  Future<void> pump(WidgetTester tester, {String? editSheetId}) async {
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SubdivideScreen(editSheetId: editSheetId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('owners, shares, front side and road, saved as a sheet', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('North field'));
    await tester.pumpAndSettle();

    // Two owners to start, equal.
    expect(find.text('Lot 1'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('owner-name-0')), 'Rahim');
    await tester.enterText(find.byKey(const ValueKey('owner-name-1')), 'Karim');
    await tester.tap(find.byKey(const ValueKey('add-owner')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('owner-name-2')),
      'Fatema',
    );

    // Half to Rahim, the other two split the rest.
    await tester.tap(find.byKey(const ValueKey('mode-shares')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('owner-amount-0')), '1/2');
    await tester.pumpAndSettle();
    expect(find.textContaining('50.0%'), findsOneWidget);
    expect(find.textContaining('25.0%'), findsNWidgets(2));

    // Front: the south side; an 8 ft road along it.
    await tester.tap(find.text('Side & road'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('side-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('road-8.0')));
    await tester.pumpAndSettle();

    // Boundaries: every lot opens onto the road.
    await tester.tap(find.text('Boundaries'));
    await tester.pumpAndSettle();
    expect(find.text('Road'), findsNWidgets(3));

    await tester.tap(find.text('Save subdivision'));
    await tester.pumpAndSettle();
    expect(find.text('Saved as a sheet'), findsOneWidget);

    final sheets = await sl<GetSheets>()();
    expect(sheets.length, 1);
    final sheet = sheets.single;
    expect(sheet.name, 'North field — division');
    expect(sheet.plotIds.length, 4, reason: 'three owners and the road');
    expect(sheet.division!.owners.map((o) => o.name), [
      'Rahim',
      'Karim',
      'Fatema',
    ]);
    expect(sheet.division!.frontSide, 2);
    expect(sheet.division!.roadWidthM, closeTo(8 * 0.3048, 1e-6));

    final plots = {for (final p in await sl<GetPlots>()()) p.id: p};
    final rahim = plots[sheet.division!.ownerPlotIds[0]]!;
    expect(rahim.name, 'North field · Rahim');
    final road = plots[sheet.division!.roadPlotId]!;
    final land = 2400 - Geometry.polygonArea(road.vertices);
    expect(Geometry.polygonArea(rahim.vertices), closeTo(land / 2, 0.01));
    // The sheet lays each lot where it lies on the ground.
    for (final id in sheet.plotIds) {
      expect(sheet.layout.containsKey(id), isTrue);
    }
  });

  testWidgets('a saved division opens again and saves in place', (
    tester,
  ) async {
    // Save one first.
    final t = await l10nFor(tester, const Locale('en'));
    const spec = DivisionSpec(
      parentPlotId: 'parent',
      owners: [
        DivisionOwner(name: 'A'),
        DivisionOwner(name: 'B'),
      ],
    );
    final first = await DivisionStore.save(
      parent: parent,
      spec: spec,
      result: DivisionPlan.compute(spec, parent.vertices),
      t: t,
    );
    final ids = List.of(first.division!.ownerPlotIds);

    await pump(tester, editSheetId: first.id);
    expect(find.text('Change'), findsNothing, reason: 'tied to its plot');
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('owner-name-1')),
    );
    expect(name.controller!.text, 'B');
    await tester.enterText(find.byKey(const ValueKey('owner-name-1')), 'Beta');
    await tester.tap(find.text('Save subdivision'));
    await tester.pumpAndSettle();

    final sheets = await sl<GetSheets>()();
    expect(sheets.length, 1, reason: 'the same sheet, not a second');
    expect(
      sheets.single.division!.ownerPlotIds,
      ids,
      reason: 'the same plots, updated',
    );
    final plots = await sl<GetPlots>()();
    expect(plots.length, 3, reason: 'parent and two lots, no duplicates');
    expect(plots.any((p) => p.name == 'North field · Beta'), isTrue);
  });

  testWidgets('dropping an owner deletes their old plot', (tester) async {
    final t = await l10nFor(tester, const Locale('en'));
    const three = DivisionSpec(
      parentPlotId: 'parent',
      owners: [DivisionOwner(), DivisionOwner(), DivisionOwner()],
    );
    final first = await DivisionStore.save(
      parent: parent,
      spec: three,
      result: DivisionPlan.compute(three, parent.vertices),
      t: t,
    );
    final two = first.division!.copyWith(
      owners: first.division!.owners.sublist(0, 2),
    );
    await DivisionStore.save(
      parent: parent,
      spec: two,
      result: DivisionPlan.compute(two, parent.vertices),
      t: t,
      existing: first,
    );
    final plots = await sl<GetPlots>()();
    expect(plots.length, 3);
    expect(plots.any((p) => p.id == first.division!.ownerPlotIds[2]), isFalse);
  });

  testWidgets('বণ্টননামা builds in Bengali', (tester) async {
    final t = await l10nFor(tester, const Locale('bn'));
    const spec = DivisionSpec(
      parentPlotId: 'parent',
      owners: [
        DivisionOwner(name: 'রহিম', amount: '১০ আনা'),
        DivisionOwner(name: 'করিম', amount: '৬ আনা'),
      ],
      mode: DivisionMode.shares,
      frontSide: 2,
      roadWidthM: 2.4,
    );
    final r = DivisionPlan.compute(spec, parent.vertices);
    expect(r.ok, isTrue);
    final bytes = await tester.runAsync(
      () => DivisionPdf.build(
        t: t,
        plotName: 'উত্তরের জমি',
        parent: parent.vertices,
        spec: spec,
        result: r,
        nameOf: DivisionNames(spec, t).of,
        areaUnit: AreaUnit.shotok,
        lengthUnit: LengthUnit.ft,
        breakdown: BreakdownConfig.defaults,
      ),
    );
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });
}
