import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/export/sheet_pdf.dart';
import 'package:plotcalc/core/export/sheet_summary.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/sheet_layout.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/entities/plot_sheet.dart';
import 'package:plotcalc/domain/usecases/delete_sheet.dart';
import 'package:plotcalc/domain/usecases/get_sheets.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:plotcalc/domain/usecases/save_sheet.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/sheet/view/arrange_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'export_test.dart' show l10nFor;

List<Vertex> square(double side) => [
  const Vertex(0, 0),
  Vertex(side, 0),
  Vertex(side, side),
  Vertex(0, side),
];

Plot plot(String id, String name, double side) => Plot(
  id: id,
  name: name,
  vertices: square(side),
  tag: PlotTag.agricultural,
  createdAt: DateTime(2026, 10, 29),
  colorValue: 0xFFC8FF5A,
);

PlotSheet sheetOf(List<String> ids, {double? price}) => PlotSheet(
  id: 's1',
  name: 'Father’s land',
  plotIds: ids,
  createdAt: DateTime(2026, 10, 29),
  pricePerUnit: price,
);

SheetSummary summaryOf(PlotSheet s, List<Plot> plots) => SheetSummary.of(
  s,
  plots,
  fallbackUnit: AreaUnit.sqm,
  breakdown: BreakdownConfig.defaults,
);

void main() {
  tearDown(() => Intl.defaultLocale = null);

  final a = plot('a', 'Dag 102', 20); // 400 m²
  final b = plot('b', 'Dag 105', 10); // 100 m²
  final c = plot('c', 'Pond side', 30); // 900 m²

  group('totals', () {
    test('adds the plots, in the sheet’s order', () {
      final s = summaryOf(sheetOf(['c', 'a', 'b']), [a, b, c]);
      expect(s.rows.map((r) => r.plotId), ['c', 'a', 'b']);
      expect(s.totalSqm, closeTo(1400, 1e-9));
      expect(s.shareOf(s.rows[0]), closeTo(900 / 1400, 1e-12));
    });

    test('skips plots deleted since, and counts them', () {
      final s = summaryOf(sheetOf(['a', 'gone', 'b']), [a, b]);
      expect(s.rows.length, 2);
      expect(s.missing, 1);
      expect(s.totalSqm, closeTo(500, 1e-9));
    });

    test('no price means no value', () {
      final s = summaryOf(sheetOf(['a']), [a]);
      expect(s.hasPrice, isFalse);
      expect(s.totalValue, isNull);
    });

    test('value is area in the price unit times the rate', () {
      final s = summaryOf(sheetOf(['a', 'b'], price: 50000), [a, b]);
      final shotok = AreaUnit.shotok.fromSqm(500);
      expect(s.totalValue, closeTo(shotok * 50000, 1e-6));
      // Row values add up to the total.
      final sum = s.rows.fold<double>(0, (t, r) => t + s.valueOf(r.areaSqm)!);
      expect(sum, closeTo(s.totalValue!, 1e-6));
    });

    test('an empty sheet is zero, not a division by zero', () {
      final s = summaryOf(sheetOf([]), [a]);
      expect(s.totalSqm, 0);
      expect(s.breakdown.isEmpty, isTrue);
    });

    test('the sheet unit overrides the app setting', () {
      final s = SheetSummary.of(
        sheetOf(['a']).copyWith(unit: AreaUnit.katha),
        [a],
        fallbackUnit: AreaUnit.sqm,
        breakdown: BreakdownConfig.defaults,
      );
      expect(s.unit, AreaUnit.katha);
    });
  });

  group('typed amounts', () {
    test('reads ASCII and Bengali digits, ignoring commas', () {
      expect(SheetSummary.parseAmount('50,000'), 50000);
      expect(SheetSummary.parseAmount('৫০০০০'), 50000);
      expect(SheetSummary.parseAmount('১২.৫'), 12.5);
      expect(SheetSummary.parseAmount(''), isNull);
      expect(SheetSummary.parseAmount('.'), isNull);
    });
  });

  group('stored sheet', () {
    test('survives a JSON round trip', () {
      final s = sheetOf(
        ['a', 'b'],
        price: 1250.5,
      ).copyWith(unit: AreaUnit.bigha, priceUnit: AreaUnit.katha);
      expect(PlotSheet.fromJson(s.toJson()), s);
    });

    test('defaults: follows the app unit, priced per shotok', () {
      final s = PlotSheet.fromJson({
        'id': 'x',
        'name': 'Old',
        'plotIds': <String>[],
        'createdAt': '2026-10-29T00:00:00.000',
      });
      expect(s.unit, isNull);
      expect(s.pricePerUnit, isNull);
      expect(s.priceUnit, AreaUnit.shotok);
    });

    test('clearing the price and unit', () {
      final s = sheetOf(['a'], price: 10).copyWith(unit: AreaUnit.acre);
      expect(s.copyWith(clearPrice: true).pricePerUnit, isNull);
      expect(s.copyWith(clearUnit: true).unit, isNull);
    });

    group('repository', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await GetIt.I.reset();
        await configureDependencies();
      });

      test('saves, updates, lists newest first and deletes', () async {
        await sl<SaveSheet>()(sheetOf(['a']));
        await sl<SaveSheet>()(
          PlotSheet(
            id: 's2',
            name: 'Second',
            plotIds: const ['b'],
            createdAt: DateTime(2026, 10, 30),
          ),
        );
        await sl<SaveSheet>()(sheetOf(['a', 'b'], price: 7));

        final all = await sl<GetSheets>()();
        expect(all.map((s) => s.id), ['s2', 's1']);
        expect(all.last.plotIds, ['a', 'b']);
        expect(all.last.pricePerUnit, 7);

        await sl<DeleteSheet>()('s1');
        expect((await sl<GetSheets>()()).map((s) => s.id), ['s2']);
      });
    });
  });

  group('text', () {
    testWidgets('lists every plot, the total and the value', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final text = summaryOf(sheetOf(['a', 'b'], price: 1000), [
        a,
        b,
      ]).asText(t);
      expect(text, startsWith('Father’s land'));
      expect(text, contains('1. Dag 102'));
      expect(text, contains('2. Dag 105'));
      expect(text, contains('Total · 2 plots: 500.0'));
      expect(text, contains('Total value: ৳ 12,355'));
      expect(text, contains('Rate: ৳ 1,000 / shotok'));
    });

    testWidgets('leaves out the price lines with no price', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final text = summaryOf(sheetOf(['a']), [a]).asText(t);
      expect(text, isNot(contains('৳')));
    });

    testWidgets('follows the locale', (tester) async {
      final t = await l10nFor(tester, const Locale('bn'));
      final text = summaryOf(sheetOf(['a', 'b'], price: 1000), [
        a,
        b,
      ]).asText(t);
      expect(text, contains('মোট মূল্য'));
      expect(text, contains('১২,৩৫৫'));
    });
  });

  group('pdf', () {
    Future<void> expectPdf(List<int> bytes) async {
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(
        String.fromCharCodes(bytes.skip(bytes.length - 8)),
        contains('EOF'),
      );
    }

    testWidgets('builds with and without a price', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final plain = await SheetPdf.build(summaryOf(sheetOf(['a']), [a]), t);
      final priced = await SheetPdf.build(
        summaryOf(sheetOf(['a', 'b'], price: 500), [a, b]),
        t,
      );
      await expectPdf(plain);
      await expectPdf(priced);
      expect(priced.length, greaterThan(plain.length));
    });

    testWidgets('builds in Bengali', (tester) async {
      final t = await l10nFor(tester, const Locale('bn'));
      final bytes = await SheetPdf.build(
        summaryOf(sheetOf(['a', 'b', 'c'], price: 500), [a, b, c]),
        t,
      );
      await expectPdf(bytes);
    });

    testWidgets('draws the saved layout with side lengths', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final s = summaryOf(sheetOf(['a', 'b', 'c'], price: 500), [a, b, c]);
      final plain = await SheetPdf.build(s, t);
      final laid = await SheetPdf.build(
        s,
        t,
        layout: {'a': const PlotPlacement(0, 0, 0.4)},
      );
      await expectPdf(laid);
      // Placement changes the drawing, not whether it is drawn.
      expect(laid, isNot(equals(plain)));
    });

    testWidgets('an empty sheet still builds', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      await expectPdf(await SheetPdf.build(summaryOf(sheetOf([]), []), t));
    });

    testWidgets('runs onto more pages for a long sheet', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final many = [for (var i = 0; i < 60; i++) plot('p$i', 'Plot $i', 10)];
      final bytes = await SheetPdf.build(
        summaryOf(sheetOf([for (final p in many) p.id]), many),
        t,
      );
      await expectPdf(bytes);
      final pages = RegExp(
        r'/Type\s*/Page[^s]',
      ).allMatches(String.fromCharCodes(bytes)).length;
      expect(pages, greaterThan(1));
    });
  });

  group('layout', () {
    const sq = [Vertex(0, 0), Vertex(10, 0), Vertex(10, 10), Vertex(0, 10)];

    test('centroid of a square is its middle', () {
      final c = SheetLayout.centroid(sq);
      expect(c.x, closeTo(5, 1e-9));
      expect(c.y, closeTo(5, 1e-9));
    });

    test('placing moves and turns the shape but keeps its area', () {
      final placed = SheetLayout.place(
        sq,
        const PlotPlacement(100, 50, math.pi / 4),
      );
      final c = SheetLayout.centroid(placed);
      expect(c.x, closeTo(100, 1e-9));
      expect(c.y, closeTo(50, 1e-9));
      expect(Geometry.polygonArea(placed), closeTo(100, 1e-9));
      // A 45° square stands on a corner: its width is the diagonal.
      final (x0, _, x1, _) = Geometry.bbox(placed);
      expect(x1 - x0, closeTo(10 * math.sqrt2, 1e-9));
    });

    test('turning wraps instead of growing', () {
      var p = const PlotPlacement(0, 0);
      for (var i = 0; i < 30; i++) {
        p = p.turned(math.pi / 12);
      }
      expect(p.angle.abs(), lessThanOrEqualTo(math.pi));
      expect(p.angle, closeTo(math.pi / 2, 1e-9)); // 30 × 15° = 450° ≡ 90°
    });

    test('point in polygon', () {
      expect(SheetLayout.contains(sq, const Vertex(5, 5)), isTrue);
      expect(SheetLayout.contains(sq, const Vertex(11, 5)), isFalse);
    });

    test('auto layout keeps placed plots and keeps new ones apart', () {
      final shapes = [('a', sq), ('b', square(20)), ('c', square(5))];
      final out = SheetLayout.fill(shapes, {'a': const PlotPlacement(7, 7)});
      expect(out['a'], const PlotPlacement(7, 7));
      expect(out.keys, containsAll(['a', 'b', 'c']));
      // No two boxes overlap.
      final boxes = [
        for (final (id, v) in shapes)
          Geometry.bbox(SheetLayout.place(v, out[id]!)),
      ];
      for (var i = 0; i < boxes.length; i++) {
        for (var j = i + 1; j < boxes.length; j++) {
          final (a0, b0, a1, b1) = boxes[i];
          final (c0, d0, c1, d1) = boxes[j];
          final overlap = a0 < c1 && c0 < a1 && b0 < d1 && d0 < b1;
          expect(overlap, isFalse, reason: 'plots $i and $j overlap');
        }
      }
    });

    test('a corner let go near another corner meets it exactly', () {
      final shapes = [('a', sq), ('b', sq)];
      // b's top-left corner lands 0.4 m right of and 0.3 m below a's
      // bottom-right corner.
      final layout = {
        'a': const PlotPlacement(5, 5),
        'b': const PlotPlacement(15.4, 15.3),
      };
      final snapped = SheetLayout.snap('b', shapes, layout, 1);
      expect(snapped.x, closeTo(15, 1e-9));
      expect(snapped.y, closeTo(15, 1e-9));
    });

    test('a corner near another plot’s side lands on it', () {
      final shapes = [('a', square(20)), ('b', sq)];
      // b sits 0.5 m right of a's right side, halfway down it.
      final layout = {
        'a': const PlotPlacement(10, 10),
        'b': const PlotPlacement(25.5, 7),
      };
      final snapped = SheetLayout.snap('b', shapes, layout, 1);
      expect(snapped.x, closeTo(25, 1e-9));
      expect(snapped.y, closeTo(7, 1e-9), reason: 'slides only sideways');
    });

    test('nothing nearby, nothing moves', () {
      final shapes = [('a', sq), ('b', sq)];
      final layout = {
        'a': const PlotPlacement(5, 5),
        'b': const PlotPlacement(40, 40),
      };
      expect(SheetLayout.snap('b', shapes, layout, 1), layout['b']);
    });

    test('the layout is stored with the sheet', () {
      final s = sheetOf(['a', 'b']).copyWith(
        layout: {
          'a': const PlotPlacement(1, 2, 0.5),
          'b': const PlotPlacement(-3, 4),
        },
      );
      expect(PlotSheet.fromJson(s.toJson()), s);
      expect(sheetOf(['a']).toJson().containsKey('layout'), isFalse);
    });
  });

  group('arrange screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GetIt.I.reset();
      await configureDependencies();
    });

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await sl<SavePlot>()(a);
      await sl<SavePlot>()(b);
      await sl<SaveSheet>()(sheetOf(['a', 'b']));
      await tester.pumpWidget(
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ArrangeScreen(sheetId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    FilledButton saveButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

    testWidgets('drag a plot, turn it, save', (tester) async {
      await pump(tester);
      expect(
        saveButton(tester).onPressed,
        isNull,
        reason: 'nothing to save yet',
      );

      final canvas = tester.getRect(
        find.byKey(const ValueKey('arrange-canvas')),
      );
      final before = (await sl<GetSheets>()()).single.layout;
      expect(before, isEmpty);

      // Find where plot 'a' is drawn by tapping candidates until it selects.
      Offset? onA;
      for (var y = canvas.top + 20; y < canvas.bottom && onA == null; y += 20) {
        for (var x = canvas.left + 20; x < canvas.right; x += 20) {
          await tester.tapAt(Offset(x, y));
          await tester.pump();
          if (find.textContaining('Dag 102 ·').evaluate().isNotEmpty) {
            onA = Offset(x, y);
            break;
          }
        }
      }
      expect(onA, isNotNull, reason: 'plot a is on the canvas');

      await tester.dragFrom(onA!, const Offset(-60, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Turn right'));
      await tester.pump();
      expect(find.textContaining('15°'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Layout saved'), findsOneWidget);

      final layout = (await sl<GetSheets>()()).single.layout;
      expect(layout.keys, containsAll(['a', 'b']));
      expect(layout['a']!.angle, closeTo(math.pi / 12, 1e-9));
    });

    testWidgets('leaving with unsaved changes asks first', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Arrange automatically'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(ArrangeScreen), findsOneWidget);
    });
  });

  group('from History to a sheet', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GetIt.I.reset();
      await configureDependencies();
    });

    testWidgets('pick two plots, sum them, price them', (tester) async {
      // Wide, because the test font draws every glyph a full em across and
      // the existing Home and History rows overflow a phone width with it.
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await sl<SavePlot>()(a);
      await sl<SavePlot>()(b);

      final router = buildRouter();
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
      router.go(AppRoutes.history);
      await tester.pumpAndSettle();

      expect(find.text('LONG-PRESS PLOTS TO SELECT'), findsOneWidget);

      // Long-press starts picking; after that a tap picks too.
      await tester.longPress(find.text('Dag 102'));
      await tester.pump();
      await tester.tap(find.text('Dag 105'));
      await tester.pump();
      expect(find.text('2 SELECTED'), findsOneWidget);

      await tester.tap(find.text('Sum 2 plots'));
      await tester.pumpAndSettle();
      expect(find.text('Name this sheet'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Father’s land');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // On the sheet: both plots and their 500 m² total (in sq ft here).
      expect(find.text('Father’s land'), findsOneWidget);
      expect(find.text('Dag 102'), findsOneWidget);
      expect(find.text('Dag 105'), findsOneWidget);
      expect(find.text('5,382'), findsOneWidget);
      expect(find.text('2 plots'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1000');
      await tester.pumpAndSettle();
      expect(find.text('Total value: ৳ 12,355'), findsOneWidget);

      final saved = (await sl<GetSheets>()()).single;
      expect(saved.plotIds, ['a', 'b']);
      expect(saved.pricePerUnit, 1000);

      // Back in History, the sheet is listed.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Sheets · 1'), findsOneWidget);
      expect(find.text('Father’s land'), findsOneWidget);
    });
  });
}
