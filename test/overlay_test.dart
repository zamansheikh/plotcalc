import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/map_align.dart';
import 'package:plotcalc/core/geometry/map_scale.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/core/units/length_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/overlay/view/overlay_canvas.dart';
import 'package:plotcalc/presentation/features/overlay/view/overlay_report.dart';
import 'package:plotcalc/presentation/features/overlay/view/overlay_screen.dart';
import 'package:plotcalc/presentation/features/result/view/result_screen.dart'
    show ResultArgs;
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'export_test.dart' show l10nFor;

const w = 800.0, h = 600.0;

/// The new survey is the old one turned 4°, 8% smaller, and shifted: a
/// similarity, so two matched places pin it exactly.
final _ang = 4 * math.pi / 180;
final truth = PlaneTransform([
  0.92 * math.cos(_ang),
  -0.92 * math.sin(_ang),
  60,
  0.92 * math.sin(_ang),
  0.92 * math.cos(_ang),
  10,
  0,
  0,
  1,
]);

Future<(Uint8List, Uint8List)> maps() async {
  // Old sheet: a grid of "plots" on paper.
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
  final ink = Paint()
    ..color = Colors.black
    ..strokeWidth = 3;
  for (var x = 50.0; x < w; x += 100) {
    c.drawLine(Offset(x, 40), Offset(x, h - 40), ink);
  }
  for (var y = 50.0; y < h; y += 100) {
    c.drawLine(Offset(40, y), Offset(w - 40, y), ink);
  }
  final a = await rec.endRecording().toImage(w.toInt(), h.toInt());
  // New sheet: the old one through [truth].
  final rec2 = ui.PictureRecorder();
  final c2 = Canvas(rec2);
  c2.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
  c2.transform(truth.toMatrix4());
  c2.drawImage(a, Offset.zero, Paint());
  final b = await rec2.endRecording().toImage(w.toInt(), h.toInt());
  Future<Uint8List> png(ui.Image i) async => (await i.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  return (await png(a), await png(b));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
  });
  tearDown(() => Intl.defaultLocale = null);

  ResultArgs? opened;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    opened = null;
    final (a, b) = (await tester.runAsync(maps))!;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('ROOT')),
        ),
        GoRoute(
          path: '/o',
          builder: (_, _) => OverlayScreen(initialOld: a, initialNew: b),
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
      router.push('/o');
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
  }

  Rect canvas(WidgetTester tester) =>
      tester.getRect(find.byKey(const ValueKey('overlay-canvas')));

  testWidgets('match, check, scale, trace, and read the shared area', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Add both maps of the mouza'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // The old map fills the canvas; its scale never changes below.
    final c0 = canvas(tester);
    final s = math.min(c0.width / w, c0.height / h);
    const centre = Offset(w / 2, h / 2);
    // Each view keeps what was in its middle in the middle, so image points
    // are found from the canvas's current centre.
    Offset onA(Offset p) => canvas(tester).center + (p - centre) * s;

    expect(
      find.textContaining('Tap a place you can find on both'),
      findsOneWidget,
    );

    // Places 1 and 2: by hand. After each mark on the old map the new one
    // is shown, centred where the twin is guessed to be (the same spot, as
    // nothing is matched yet), at the same scale.
    for (final p in const [Offset(150, 150), Offset(650, 450)]) {
      await tester.tapAt(onA(p));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Now tap the very same place on the RS'),
        findsOneWidget,
      );
      final twin = truth.apply(p);
      await tester.tapAt(canvas(tester).center + (twin - p) * s);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next place'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Add 2 more to check the match'), findsOneWidget);

    // Places 3 and 4: one tap each — the twin is put where it should be.
    for (final p in const [Offset(650, 150), Offset(150, 450)]) {
      await tester.tapAt(onA(p));
      await tester.pumpAndSettle();
      expect(find.textContaining('Placed where it should be'), findsOneWidget);
      await tester.tap(find.text('Next place'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Match: good'), findsOneWidget);

    // Scale: 100 px of the old map is 10 m.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overlay-mix')), findsOneWidget);
    await tester.tapAt(onA(const Offset(100, 550)));
    await tester.pump();
    await tester.tapAt(onA(const Offset(200, 550)));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('mouza-distance')), '10');
    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // A 10 × 10 m plot on the old survey…
    Future<void> trace(List<Offset> pts) async {
      for (final p in pts) {
        await tester.tapAt(onA(p));
        await tester.pump();
      }
      await tester.tap(find.text('Plot done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save')); // keep the suggested name
      await tester.pumpAndSettle();
    }

    await trace(const [
      Offset(300, 200),
      Offset(400, 200),
      Offset(400, 300),
      Offset(300, 300),
    ]);
    // …and one on the new survey, half of it over the old one.
    await tester.tap(find.text('RS plot'));
    await tester.pump();
    await trace(const [
      Offset(350, 200),
      Offset(450, 200),
      Offset(450, 300),
      Offset(350, 300),
    ]);

    expect(find.text('CS plot 1'), findsOneWidget);
    expect(find.text('RS plot 1'), findsOneWidget);
    final shared = tester.widget<Text>(
      find.byKey(const ValueKey('overlap-CS plot 1-RS plot 1')),
    );
    // 50 m², shown in the default unit (square feet).
    expect(shared.data, '${AreaUnit.sqft.format(50)} sq ft');
    expect(find.textContaining('50.0% of CS plot 1'), findsOneWidget);

    // A plot opens as a normal measurement.
    await tester.tap(find.text('CS plot 1'));
    await tester.pumpAndSettle();
    expect(find.text('RESULT'), findsOneWidget);
    expect(opened!.vertices.length, 4);
  });

  testWidgets('a wrong mark is named once there are enough', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final c0 = canvas(tester);
    final s = math.min(c0.width / w, c0.height / h);
    const centre = Offset(w / 2, h / 2);
    Offset onA(Offset p) => canvas(tester).center + (p - centre) * s;

    Future<void> byHand(Offset p) async {
      await tester.tapAt(onA(p));
      await tester.pumpAndSettle();
      await tester.tapAt(canvas(tester).center + (truth.apply(p) - p) * s);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next place'));
      await tester.pumpAndSettle();
    }

    Future<void> predicted(Offset p) async {
      await tester.tapAt(onA(p));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next place'));
      await tester.pumpAndSettle();
    }

    await byHand(const Offset(150, 150));
    await byHand(const Offset(650, 450));
    await predicted(const Offset(650, 150));
    await predicted(const Offset(150, 450));
    expect(find.text('Match: good'), findsOneWidget);

    // Fifth place: the app puts its twin where it should be, and the user
    // taps a neighbouring crossing 50 px away instead — a tap moves the
    // selected mark, it does not start another place.
    await tester.tapAt(onA(const Offset(400, 300)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Placed where it should be'), findsOneWidget);
    await tester.tapAt(canvas(tester).center + Offset(40 * s, 30 * s));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsWidgets, reason: 'still five places');
    expect(find.text('6'), findsNothing);
    expect(find.textContaining('Place 5 looks wrong'), findsOneWidget);
  });

  testWidgets('after a place is done by hand, a tap starts the next one', (
    tester,
  ) async {
    // Found on a real sheet: a finished place stayed selected and the next
    // tap on the map silently dragged its mark across the sheet.
    await pump(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final c0 = canvas(tester);
    final s = math.min(c0.width / w, c0.height / h);
    const centre = Offset(w / 2, h / 2);
    Offset onA(Offset p) => canvas(tester).center + (p - centre) * s;
    await tester.tapAt(onA(const Offset(150, 150)));
    await tester.pumpAndSettle();
    await tester.tapAt(
      canvas(tester).center +
          (truth.apply(const Offset(150, 150)) - const Offset(150, 150)) * s,
    );
    await tester.pumpAndSettle();
    // Still on the new map: this tap is a new place, waiting for its twin.
    await tester.tapAt(canvas(tester).center + const Offset(60, 40));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Now tap the very same place on the CS'),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget, reason: 'place 1 is untouched');
  });

  testWidgets('Back steps back, and leaving with work asks', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final c0 = canvas(tester);
    final s = math.min(c0.width / w, c0.height / h);
    await tester.tapAt(
      canvas(tester).center +
          (const Offset(150, 150) - const Offset(400, 300)) * s,
    );
    await tester.pumpAndSettle();
    await tester.tapAt(canvas(tester).center);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left)); // to maps
    await tester.pumpAndSettle();
    expect(find.text('Add both maps of the mouza'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left)); // asks
    await tester.pumpAndSettle();
    expect(find.text('Leave the map?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('ROOT'), findsOneWidget);
  });

  group('report', () {
    testWidgets('overlap rows and the PDF', (tester) async {
      final t = await l10nFor(tester, const Locale('bn'));
      const old = OverlayPlot('CS দাগ ৫৮৫', [
        Offset(0, 0),
        Offset(100, 0),
        Offset(100, 100),
        Offset(0, 100),
      ], false);
      const newer = OverlayPlot('RS দাগ ১২০৩', [
        Offset(25, 0),
        Offset(125, 0),
        Offset(125, 100),
        Offset(25, 100),
      ], true);
      const apart = OverlayPlot('RS দাগ ১২০৪', [
        Offset(500, 500),
        Offset(600, 500),
        Offset(600, 600),
      ], true);
      final rows = OverlayReport.overlaps(const [old, newer, apart]);
      expect(rows.length, 1);
      expect(rows.single.px2, closeTo(7500, 1e-6));
      expect(rows.single.ofOld, closeTo(0.75, 1e-9));

      final (a, b) = (await tester.runAsync(maps))!;
      final bytes = await tester.runAsync(() async {
        Future<ui.Image> dec(Uint8List d) async =>
            (await (await ui.instantiateImageCodec(d)).getNextFrame()).image;
        final ia = await dec(a), ib = await dec(b);
        final frame = OverlayFrame(
          a: ia,
          b: ib,
          bToA: truth.inverse(),
          view: OverlayView.both,
          mix: 0.5,
          tint: true,
          pairs: const [],
          pairColors: const [],
          accent: Colors.lime,
          lengthUnit: LengthUnit.ft,
          lengthLabel: 'ft',
          meterLabel: 'm',
          plots: const [
            OverlayShape(
              [Offset(0, 0), Offset(100, 0), Offset(100, 100)],
              oldInk,
              'CS',
            ),
          ],
        );
        final png = await OverlayReport.renderImage(frame, const [old, newer]);
        final align = MapAlignment.fit([
          for (final p in const [
            Offset(100, 100),
            Offset(700, 120),
            Offset(680, 500),
            Offset(120, 480),
          ])
            (p, truth.apply(p)),
        ])!;
        return OverlayReport.build(
          t: t,
          image: png,
          plots: const [old, newer],
          scale: const MapScale(a: Offset(0, 0), b: Offset(100, 0), meters: 10),
          alignment: align,
          labelOld: 'CS',
          labelNew: 'RS',
          areaUnit: AreaUnit.shotok,
          lengthUnit: LengthUnit.ft,
          imageWidth: w,
        );
      });
      expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(5000));
    });
  });
}
