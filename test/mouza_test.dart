import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/map_scale.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/mouza/view/mouza_screen.dart';
import 'package:plotcalc/presentation/features/result/view/result_screen.dart'
    show ResultArgs;
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('map scale', () {
    test('a square one chain each side is ten shotok', () {
      // 100 px on the photo is one chain (66 ft); a 100 px square is then
      // one square chain, which is a tenth of an acre: exactly 10 shotok.
      const scale = MapScale(
        a: Offset(0, 0),
        b: Offset(100, 0),
        meters: 20.1168,
      );
      const square = [
        Offset(10, 10),
        Offset(110, 10),
        Offset(110, 110),
        Offset(10, 110),
      ];
      expect(AreaUnit.shotok.fromSqm(scale.areaOf(square)), closeTo(10, 1e-9));
      expect(scale.lengthOf(square[0], square[1]), closeTo(20.1168, 1e-9));
    });

    test('units', () {
      expect(MapDistanceUnit.chain.toMeters(1), closeTo(66 * 0.3048, 1e-9));
      expect(MapDistanceUnit.link.toMeters(100), closeTo(20.1168, 1e-9));
      expect(MapDistanceUnit.foot.toMeters(1), 0.3048);
      expect(MapDistanceUnit.meter.toMeters(7), 7);
    });

    test('the outline is centred and keeps its shape', () {
      const scale = MapScale(a: Offset(0, 0), b: Offset(0, 50), meters: 10);
      final v = scale.toVertices(const [
        Offset(500, 500),
        Offset(600, 500),
        Offset(600, 550),
      ]);
      final cx = v.fold<double>(0, (s, p) => s + p.x) / 3;
      final cy = v.fold<double>(0, (s, p) => s + p.y) / 3;
      expect(cx, closeTo(0, 1e-9));
      expect(cy, closeTo(0, 1e-9));
      // 100 × 50 px right triangle at 0.2 m/px: legs 20 m and 10 m.
      expect(Geometry.polygonArea(v), closeTo(100, 1e-9));
    });

    test('a zero-length scale is not usable', () {
      expect(
        const MapScale(a: Offset(5, 5), b: Offset(5, 5), meters: 10).isValid,
        isFalse,
      );
      expect(
        const MapScale(a: Offset(0, 0), b: Offset(1, 0), meters: 0).isValid,
        isFalse,
      );
    });
  });

  group('screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GetIt.I.reset();
      await configureDependencies();
    });

    /// A plain 1000 × 1000 test "map".
    Future<Uint8List> photo() async {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 1000),
        Paint()..color = const Color(0xFFF2EBD9),
      );
      final img = await rec.endRecording().toImage(1000, 1000);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    }

    ResultArgs? opened;

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      opened = null;
      final bytes = (await tester.runAsync(photo))!;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('ROOT')),
          ),
          GoRoute(
            path: '/m',
            builder: (_, _) => MouzaScreen(initialPhoto: bytes),
          ),
          GoRoute(
            path: AppRoutes.result,
            builder: (_, s) {
              opened = s.extra as ResultArgs;
              return const Scaffold(body: Text('RESULT'));
            },
          ),
        ],
      );
      await tester.runAsync(() async {
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
        // Open the map screen on top of a root page, as the app does, so
        // leaving it can be tested.
        router.push('/m');
        await tester.pump();
        // Let the photo decode.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
    }

    /// Where the 1000 px image is drawn: fitted and centred in the canvas.
    Rect imageRect(WidgetTester tester) {
      final c = tester.getRect(find.byKey(const ValueKey('mouza-canvas')));
      final side = c.width < c.height ? c.width : c.height;
      return Rect.fromCenter(center: c.center, width: side, height: side);
    }

    Offset at(Rect r, double fx, double fy) =>
        Offset(r.left + r.width * fx, r.top + r.height * fy);

    testWidgets('scale, corners, result', (tester) async {
      await pump(tester);
      var r = imageRect(tester);

      expect(find.textContaining('Tap two points'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Scale: a line a fifth of the image wide is one chain.
      await tester.tapAt(at(r, 0.1, 0.9));
      await tester.pump();
      expect(find.text('Now tap the second point.'), findsOneWidget);
      await tester.tapAt(at(r, 0.3, 0.9));
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('mouza-distance')), '1');
      await tester.tap(find.text('chain'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      // The view moved to keep the scale line in sight; reset it.
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pump();
      r = imageRect(tester);

      // Corners: a square a fifth of the image on each side → 1 chain².
      expect(
        find.text('Tap each corner of the plot, one after another.'),
        findsOneWidget,
      );
      for (final (fx, fy) in [(0.4, 0.2), (0.6, 0.2), (0.6, 0.4), (0.4, 0.4)]) {
        await tester.tapAt(at(r, fx, fy));
        await tester.pump();
      }
      expect(find.textContaining('4 corners'), findsOneWidget);

      final area = tester.widget<Text>(
        find.byKey(const ValueKey('mouza-area')),
      );
      // Default display unit is square feet: one square chain is 4,356 sq ft.
      expect(area.data, AreaUnit.sqft.format(AreaUnit.shotok.toSqm(10)));

      await tester.tap(find.text('See result'));
      await tester.pumpAndSettle();
      expect(find.text('RESULT'), findsOneWidget);
      expect(opened!.vertices.length, 4);
      expect(
        AreaUnit.shotok.fromSqm(Geometry.polygonArea(opened!.vertices)),
        closeTo(10, 0.05),
      );
      expect(opened!.name, 'Mouza map plot');
    });

    testWidgets('undo, drag a corner, start a new plot', (tester) async {
      await pump(tester);
      var r = imageRect(tester);
      await tester.tapAt(at(r, 0.1, 0.9));
      await tester.tapAt(at(r, 0.3, 0.9));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('mouza-distance')),
        '66',
      );
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      // The view moved to keep the scale line in sight; reset it.
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pump();
      r = imageRect(tester);

      for (final (fx, fy) in [(0.4, 0.2), (0.6, 0.2), (0.6, 0.4), (0.5, 0.5)]) {
        await tester.tapAt(at(r, fx, fy));
        await tester.pump();
      }
      await tester.tap(find.byTooltip('UNDO'));
      await tester.pump();
      expect(find.textContaining('3 corners'), findsOneWidget);
      final before = tester
          .widget<Text>(find.byKey(const ValueKey('mouza-area')))
          .data;

      // Pull the third corner further out: the area must grow.
      await tester.dragFrom(at(r, 0.6, 0.4), Offset(0, r.height * 0.2));
      await tester.pumpAndSettle();
      final after = tester
          .widget<Text>(find.byKey(const ValueKey('mouza-area')))
          .data;
      expect(after, isNot(before));

      await tester.tap(find.text('New plot'));
      await tester.pump();
      expect(find.byKey(const ValueKey('mouza-area')), findsNothing);
      expect(
        find.text('Tap each corner of the plot, one after another.'),
        findsOneWidget,
      );
    });

    testWidgets('the map does not move when the area appears', (tester) async {
      // Found tracing a real sheet: the area box used to appear at the third
      // corner, the panel grew, and the map slid under the finger mid-tap.
      await pump(tester);
      var r = imageRect(tester);
      await tester.tapAt(at(r, 0.1, 0.9));
      await tester.tapAt(at(r, 0.3, 0.9));
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('mouza-distance')), '1');
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      // The view moved to keep the scale line in sight; reset it.
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pump();
      r = imageRect(tester);
      final canvas = find.byKey(const ValueKey('mouza-canvas'));
      final before = tester.getRect(canvas);
      for (final (fx, fy) in [(0.4, 0.2), (0.6, 0.2), (0.6, 0.4)]) {
        await tester.tapAt(at(r, fx, fy));
        await tester.pump();
      }
      expect(find.byKey(const ValueKey('mouza-area')), findsOneWidget);
      expect(tester.getRect(canvas), before);
    });

    testWidgets('zoom buttons zoom about the middle', (tester) async {
      await pump(tester);
      var r = imageRect(tester);
      // Zoom in twice, then tap the middle: it is still the image's middle.
      await tester.tap(find.byKey(const ValueKey('mouza-zoom-in')));
      await tester.tap(find.byKey(const ValueKey('mouza-zoom-in')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('mouza-zoom-out')));
      await tester.pump();
      final c = tester.getRect(find.byKey(const ValueKey('mouza-canvas')));
      await tester.tapAt(c.center);
      await tester.pump();
      // A second point a known distance right of it, at 1.6x zoom.
      await tester.tapAt(c.center + Offset(r.width * 0.1 * 1.6, 0));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('mouza-distance')),
        '10',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('the map does not move between the two scale taps', (
      tester,
    ) async {
      await pump(tester);
      final canvas = find.byKey(const ValueKey('mouza-canvas'));
      final before = tester.getRect(canvas);
      await tester.tapAt(at(imageRect(tester), 0.1, 0.9));
      await tester.pump();
      expect(find.text('Now tap the second point.'), findsOneWidget);
      expect(tester.getRect(canvas), before);
    });

    testWidgets('Next waits for two points and a distance', (tester) async {
      await pump(tester);
      var r = imageRect(tester);
      FilledButton next() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(next().onPressed, isNull);
      await tester.tapAt(at(r, 0.2, 0.5));
      await tester.tapAt(at(r, 0.8, 0.5));
      await tester.pump();
      expect(next().onPressed, isNull, reason: 'no distance yet');
      // Bengali digits are fine.
      await tester.enterText(
        find.byKey(const ValueKey('mouza-distance')),
        '৫০',
      );
      await tester.pump();
      expect(next().onPressed, isNotNull);
      await tester.tap(find.text('Start over'));
      await tester.pump();
      expect(find.textContaining('Tap two points'), findsOneWidget);
    });

    testWidgets('leaving with corners asks first', (tester) async {
      await pump(tester);
      var r = imageRect(tester);
      await tester.tapAt(at(r, 0.1, 0.9));
      await tester.tapAt(at(r, 0.3, 0.9));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('mouza-distance')),
        '10',
      );
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      // The view moved to keep the scale line in sight; reset it.
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pump();
      r = imageRect(tester);
      await tester.tapAt(at(r, 0.5, 0.5));
      await tester.pump();

      // Back from corners goes to the scale step, keeping the corner.
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      // Back again would lose the corner, so it asks.
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Leave the map?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Leave the map?'), findsNothing);
      expect(find.byType(MouzaScreen), findsOneWidget);
    });

    testWidgets('Back leaves from the scale step', (tester) async {
      // Back used to do nothing here: the screen's own guard refused it.
      await pump(tester);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.byType(MouzaScreen), findsNothing);
      expect(find.text('ROOT'), findsOneWidget);
    });

    testWidgets('discarding traced corners leaves', (tester) async {
      await pump(tester);
      var r = imageRect(tester);
      await tester.tapAt(at(r, 0.1, 0.9));
      await tester.tapAt(at(r, 0.3, 0.9));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('mouza-distance')),
        '10',
      );
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pump();
      r = imageRect(tester);
      await tester.tapAt(at(r, 0.5, 0.5));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.chevron_left)); // to scale
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left)); // asks
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(MouzaScreen), findsNothing);
      expect(find.text('ROOT'), findsOneWidget);
    });

    testWidgets('a tap beside the photo adds nothing', (tester) async {
      await pump(tester);
      final c = tester.getRect(find.byKey(const ValueKey('mouza-canvas')));
      final r = imageRect(tester);
      // The photo is square and the canvas tall: there is margin above it.
      expect(r.top - c.top, greaterThan(20));
      await tester.tapAt(Offset(c.center.dx, c.top + 8));
      await tester.pump();
      expect(
        find.textContaining('Tap two points'),
        findsOneWidget,
        reason: 'still waiting for the first point',
      );
    });

    testWidgets('picking from the gallery opens the photo', (tester) async {
      tester.view.physicalSize = const Size(800, 1300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final bytes = (await tester.runAsync(photo))!;
      await tester.pumpWidget(
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MouzaScreen(pickPhoto: (_) async => bytes),
          ),
        ),
      );
      expect(find.text('Take a photo of the map'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Choose from gallery'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mouza-canvas')), findsOneWidget);
      expect(find.textContaining('Tap two points'), findsOneWidget);
    });
  });
}
