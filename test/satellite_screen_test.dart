import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/geo_plot.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/mercator_view.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/mouza/view/mouza_entry_card.dart';
import 'package:plotcalc/presentation/features/result/view/result_screen.dart'
    show ResultArgs;
import 'package:plotcalc/presentation/features/satellite/satellite_services.dart';
import 'package:plotcalc/presentation/features/satellite/view/satellite_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The phone's location, as the test says.
class FakeLocation implements GeoLocation {
  LocationAccess access;

  /// What asking for permission turns `denied` into.
  LocationAccess onRequest;
  GeoFix? last;
  int requests = 0;
  LocationAccess? settingsOpenedFor;
  final readings = StreamController<GeoFix>.broadcast();

  FakeLocation({
    this.access = LocationAccess.denied,
    this.onRequest = LocationAccess.granted,
    this.last,
  });

  @override
  Future<LocationAccess> check() async => access;

  @override
  Future<LocationAccess> request() async {
    requests++;
    if (access == LocationAccess.denied) access = onRequest;
    return access;
  }

  @override
  Future<GeoFix?> lastKnown() async => last;

  @override
  Stream<GeoFix> fixes() => readings.stream;

  @override
  Future<void> openSettings(LocationAccess why) async =>
      settingsOpenedFor = why;
}

class FakeCamera implements GeoMapController {
  final moves = <(GeoPoint, double?)>[];
  final fits = <List<GeoPoint>>[];

  @override
  Future<void> moveTo(GeoPoint p, {double? zoom}) async => moves.add((p, zoom));

  @override
  Future<void> zoomBy(double delta) async {}

  @override
  Future<void> fit(List<GeoPoint> points) async => fits.add(points);

  /// The ground the fake map shows.
  MercatorView? view;

  @override
  Future<GeoPoint?> pointAt(Offset local) async => view?.toGeo(local);

  @override
  Future<Uint8List?> snapshot() async => null;
}

/// The panel holds its height with unseen copies of its longer texts; this
/// keeps to the one on screen.
extension on Finder {
  Finder get shown => hitTestable();
}

void main() {
  const dhaka = GeoPoint(23.8103, 90.4125);

  /// A field 100 m × 100 m, corners in walking order.
  final field = [
    dhaka,
    GeoPlot.offset(dhaka, east: 100),
    GeoPlot.offset(dhaka, east: 100, north: 100),
    GeoPlot.offset(dhaka, north: 100),
  ];

  late FakeLocation location;
  late FakeCamera camera;
  GeoMapProps? map;
  ResultArgs? opened;
  late Future<GeoPoint?> Function(String) geocode;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
    location = FakeLocation();
    camera = FakeCamera();
    map = null;
    opened = null;
    geocode = (_) async => null;
  });

  Future<GoRouter> pump(
    WidgetTester tester, {
    Size size = const Size(800, 1500),
    String locale = 'en',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final services = SatelliteServices(
      map: (p) {
        map = p;
        return const ColoredBox(
          key: ValueKey('fake-map'),
          color: Color(0xFF334433),
        );
      },
      location: location,
      geocode: (q) => geocode(q),
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('ROOT')),
        ),
        GoRoute(
          path: '/s',
          builder: (_, _) => SatelliteScreen(services: services),
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
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: MaterialApp.router(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    router.push('/s');
    await tester.pumpAndSettle();
    // The map reports in once it is up, as Google's does. It shows the
    // ground round Dhaka at half a metre to the pixel, north up.
    final shown = tester.getSize(find.byKey(const ValueKey('fake-map')));
    camera.view = MercatorView(
      size: shown,
      topLeft: GeoPlot.offset(
        dhaka,
        east: -shown.width / 4,
        north: shown.height / 4,
      ),
      bottomRight: GeoPlot.offset(
        dhaka,
        east: shown.width / 4,
        north: -shown.height / 4,
      ),
    );
    map!.onReady(camera);
    await tester.pump();
    return router;
  }

  /// Zooms the fake map in close enough to place corners, and lets it come
  /// to rest.
  Future<void> zoomIn(WidgetTester tester) async {
    map!.onZoom(19);
    map!.onIdle();
    await tester.pump();
  }

  /// Where a point on the earth is on the test's screen.
  Offset onScreen(WidgetTester tester, GeoPoint p) =>
      tester.getTopLeft(find.byKey(const ValueKey('fake-map'))) +
      camera.view!.toScreen(p);

  Finder dragLayer() => find.byKey(const ValueKey('sat-drag'));

  Future<void> tapMap(WidgetTester tester, GeoPoint p) async {
    map!.onTap(p);
    await tester.pump();
  }

  bool hasArea() =>
      find.byKey(const ValueKey('sat-area')).evaluate().isNotEmpty;

  group('tap on the map', () {
    testWidgets('corners make the field; the result is its real size', (
      tester,
    ) async {
      await pump(tester);
      expect(
        find.textContaining('Find the land and zoom in.').shown,
        findsOneWidget,
      );
      expect(map!.editable, isTrue);
      expect(map!.satellite, isTrue);

      // Too far out, a tap could be in the next field.
      await tapMap(tester, dhaka);
      expect(map!.corners, isEmpty);
      expect(find.text('Zoom in closer, then tap the corner.'), findsOneWidget);

      map!.onZoom(18);
      for (final c in field.take(3)) {
        await tapMap(tester, c);
      }
      expect(map!.corners, hasLength(3));
      expect(hasArea(), isTrue);
      expect(find.textContaining('3 corners'), findsOneWidget);

      await tapMap(tester, field[3]);
      await tester.tap(find.byKey(const ValueKey('sat-result')));
      await tester.pumpAndSettle();
      expect(find.text('RESULT'), findsOneWidget);
      expect(opened!.vertices, hasLength(4));
      expect(Geometry.polygonArea(opened!.vertices), closeTo(10000, 0.5));
      expect(opened!.name, 'Plot from the satellite map');
    });

    testWidgets('dragging a pin moves that corner, under a magnifier', (
      tester,
    ) async {
      await pump(tester);
      await zoomIn(tester);
      for (final c in field) {
        await tapMap(tester, c);
      }
      final before = GeoPlot.area(map!.corners);
      expect(map!.shapes, isTrue);
      expect(dragLayer(), findsNothing);

      // Take the north-east pin and pull it 50 m north (100 px).
      final g = await tester.startGesture(onScreen(tester, field[2]));
      await g.moveBy(const Offset(0, -40));
      await tester.pump();
      // The screen draws the plot now, with the magnifier; the map stops.
      expect(dragLayer(), findsOneWidget);
      expect(map!.shapes, isFalse);
      await g.moveBy(const Offset(0, -60));
      await tester.pump();
      await g.up();
      await tester.pump();

      expect(map!.corners, hasLength(4));
      expect(
        GeoPlot.distance(map!.corners[2], GeoPlot.offset(field[2], north: 50)),
        lessThan(0.05),
      );
      expect(GeoPlot.area(map!.corners), closeTo(before + 2500, 5));
      // The map draws the plot again; the screen's copy goes a moment later.
      expect(map!.shapes, isTrue);
      await tester.pump(const Duration(milliseconds: 300));
      expect(dragLayer(), findsNothing);
    });

    testWidgets('a swipe away from the pins is left to the map', (
      tester,
    ) async {
      await pump(tester);
      await zoomIn(tester);
      await tapMap(tester, field[0]);
      final g = await tester.startGesture(
        onScreen(tester, field[0]) + const Offset(120, 90),
      );
      await g.moveBy(const Offset(0, -80));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(dragLayer(), findsNothing);
      expect(map!.corners, [field[0]]);
    });

    testWidgets('press and hold puts a corner down and follows the finger', (
      tester,
    ) async {
      await pump(tester);
      await zoomIn(tester);
      final start = onScreen(tester, GeoPlot.offset(dhaka, east: 30));
      final g = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(map!.corners, hasLength(1));
      expect(
        GeoPlot.distance(map!.corners.single, GeoPlot.offset(dhaka, east: 30)),
        lessThan(0.05),
      );
      expect(dragLayer(), findsOneWidget);

      // 20 m east, 10 m north.
      await g.moveBy(const Offset(40, -20));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        GeoPlot.distance(
          map!.corners.single,
          GeoPlot.offset(dhaka, east: 50, north: 10),
        ),
        lessThan(0.05),
      );
      expect(dragLayer(), findsNothing);
    });

    testWidgets('press and hold on a pin takes that pin, adding none', (
      tester,
    ) async {
      await pump(tester);
      await zoomIn(tester);
      for (final c in field.take(3)) {
        await tapMap(tester, c);
      }
      // A little off the pin's middle: it must not jump under the finger.
      final g = await tester.startGesture(
        onScreen(tester, field[1]) + const Offset(8, 6),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(map!.corners, hasLength(3));
      expect(GeoPlot.distance(map!.corners[1], field[1]), lessThan(0.05));
      await g.moveBy(const Offset(-20, 0));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        GeoPlot.distance(map!.corners[1], GeoPlot.offset(field[1], east: -10)),
        lessThan(0.05),
      );
    });

    testWidgets('press and hold from far out asks to zoom in first', (
      tester,
    ) async {
      await pump(tester);
      map!.onIdle();
      await tester.pump();
      final g = await tester.startGesture(onScreen(tester, dhaka));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await g.up();
      await tester.pump();
      expect(map!.corners, isEmpty);
      expect(find.text('Zoom in closer, then tap the corner.'), findsOneWidget);
    });

    testWidgets('corners can be undone, or kept as a done plot', (
      tester,
    ) async {
      await pump(tester);
      await zoomIn(tester);
      for (final c in field) {
        await tapMap(tester, c);
      }
      await tester.tap(find.byKey(const ValueKey('sat-undo')));
      await tester.pump();
      expect(map!.corners, hasLength(3));

      await tester.tap(find.byKey(const ValueKey('sat-new-plot')));
      await tester.pump();
      expect(map!.corners, isEmpty);
      expect(map!.done, hasLength(1));
      expect(hasArea(), isFalse);
    });

    testWidgets('fit brings the corners into view', (tester) async {
      await pump(tester);
      map!.onZoom(19);
      await tapMap(tester, field[0]);
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pump();
      expect(camera.fits.single, [field[0]]);
    });

    testWidgets('leaving with corners asks first', (tester) async {
      await pump(tester);
      map!.onZoom(19);
      await tapMap(tester, field[0]);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Leave the map?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sat-leave')));
      await tester.pumpAndSettle();
      expect(find.text('ROOT'), findsOneWidget);
    });

    testWidgets('the map type switches; the estimate note closes', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('sat-note')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sat-note-close')));
      await tester.tap(find.byKey(const ValueKey('sat-layer')));
      await tester.pump();
      expect(find.byKey(const ValueKey('sat-note')), findsNothing);
      expect(map!.satellite, isFalse);
    });
  });

  // A panel that grows as corners go in shrinks the map and slides it
  // under the finger between two taps.
  for (final locale in ['en', 'bn']) {
    testWidgets('the map stays put while corners are tapped ($locale)', (
      tester,
    ) async {
      await pump(tester, size: const Size(380, 800), locale: locale);
      Rect mapRect() => tester.getRect(find.byKey(const ValueKey('fake-map')));
      final before = mapRect();
      map!.onZoom(19);
      for (var i = 0; i < 12; i++) {
        await tapMap(
          tester,
          GeoPlot.offset(dhaka, east: 40.0 * (i % 4), north: 30.0 * (i ~/ 4)),
        );
        expect(mapRect(), before, reason: 'after corner ${i + 1}');
      }
      expect(tester.takeException(), isNull);
    });
  }

  group('place search', () {
    testWidgets('found: the map goes there', (tester) async {
      final savar = const GeoPoint(23.8583, 90.2667);
      String? asked;
      geocode = (q) async {
        asked = q;
        return savar;
      };
      await pump(tester);
      await tester.enterText(find.byKey(const ValueKey('sat-search')), 'Savar');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(asked, 'Savar');
      expect(camera.moves.last, (savar, 16.0));
    });

    testWidgets('not found, and no internet, say so', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const ValueKey('sat-search')), 'Xyz');
      await tester.tap(find.byKey(const ValueKey('sat-search-go')));
      await tester.pumpAndSettle();
      expect(find.text('Couldn\'t find “Xyz”'), findsOneWidget);

      geocode = (_) async => throw Exception('IO_ERROR');
      await tester.tap(find.byKey(const ValueKey('sat-search-go')));
      await tester.pumpAndSettle();
      expect(find.text('Search failed — check the internet'), findsOneWidget);
      expect(camera.moves, isEmpty);
    });
  });

  group('location', () {
    testWidgets('opens over the user when location is already allowed', (
      tester,
    ) async {
      location
        ..access = LocationAccess.granted
        ..last = const GeoFix(dhaka, 12);
      await pump(tester);
      expect(camera.moves.single, (dhaka, 17.0));
      expect(map!.myLocation, isTrue);
      // It never asked.
      expect(location.requests, 0);
    });

    testWidgets('does not ask for location just to open', (tester) async {
      await pump(tester);
      expect(location.requests, 0);
      expect(camera.moves, isEmpty);
      expect(map!.myLocation, isFalse);
    });

    testWidgets('my location asks, then goes there', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-me')));
      await tester.pump();
      expect(location.requests, 1);
      location.readings.add(const GeoFix(dhaka, 5));
      await tester.pumpAndSettle();
      expect(camera.moves.last, (dhaka, 18.0));
      expect(map!.myLocation, isTrue);
    });

    testWidgets('location switched off: says so, offers the setting', (
      tester,
    ) async {
      location.access = LocationAccess.serviceOff;
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-me')));
      await tester.pumpAndSettle();
      expect(find.text('The phone\'s location is off.'), findsOneWidget);
      await tester.tap(find.text('Turn on'));
      await tester.pump();
      expect(location.settingsOpenedFor, LocationAccess.serviceOff);
    });
  });

  group('walk with GPS', () {
    /// Stand at [p] for a corner: a reading a second for three seconds.
    Future<void> standAt(WidgetTester tester, GeoPoint p) async {
      location.readings.add(GeoFix(p, 4));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sat-add-here')));
      await tester.pump();
      for (var s = 0; s < 3; s++) {
        location.readings.add(GeoFix(p, 4));
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();
    }

    testWidgets('walking the four corners measures the field', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pump();
      expect(location.requests, 1);
      expect(map!.editable, isFalse);
      expect(find.text('Finding GPS…'), findsOneWidget);
      // No reading yet: nothing to record.
      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(const ValueKey('sat-add-here')),
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNull,
      );

      // The first reading brings the map to the user.
      location.readings.add(const GeoFix(dhaka, 4));
      await tester.pump();
      expect(camera.moves.last, (dhaka, 19.0));
      expect(find.text('GPS accuracy ±4 m'), findsOneWidget);

      // Taps on the map do nothing while walking.
      map!.onZoom(19);
      await tapMap(tester, field[1]);
      expect(map!.corners, isEmpty);

      await tester.tap(find.byKey(const ValueKey('sat-add-here')));
      await tester.pump();
      expect(find.text('Hold still… 3'), findsOneWidget);
      for (var s = 0; s < 3; s++) {
        location.readings.add(const GeoFix(dhaka, 4));
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();
      expect(map!.corners, hasLength(1));
      expect(GeoPlot.distance(map!.corners.single, dhaka), lessThan(1e-6));

      for (final c in field.skip(1)) {
        await standAt(tester, c);
      }
      expect(map!.corners, hasLength(4));
      expect(GeoPlot.area(map!.corners), closeTo(10000, 1));
      expect(find.textContaining('4 corners'), findsOneWidget);
    });

    testWidgets('readings while standing are averaged', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pump();
      location.readings.add(const GeoFix(dhaka, 4));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sat-add-here')));
      await tester.pump();
      // Two good readings 2 m either side, one wild one 30 m off.
      for (final (p, acc) in [
        (GeoPlot.offset(dhaka, east: 2), 3.0),
        (GeoPlot.offset(dhaka, east: -2), 3.0),
        (GeoPlot.offset(dhaka, north: 30), 30.0),
      ]) {
        location.readings.add(GeoFix(p, acc));
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();
      expect(GeoPlot.distance(map!.corners.single, dhaka), lessThan(0.5));
    });

    testWidgets('no reading while standing: it waits, then says so', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pump();
      location.readings.add(const GeoFix(dhaka, 4));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sat-add-here')));
      await tester.pump();
      // Three seconds of standing, and nothing arrives.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      // The reading from before the press is not used in its place.
      expect(map!.corners, isEmpty);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sat-add-here')),
          matching: find.text('Finding GPS…'),
        ),
        findsOneWidget,
      );
      for (var s = 0; s < 4; s++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();
      expect(map!.corners, isEmpty);
      expect(find.text('No GPS reading yet, press again.'), findsOneWidget);
    });

    testWidgets('a late reading while waiting still makes the corner', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pump();
      location.readings.add(const GeoFix(dhaka, 4));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sat-add-here')));
      await tester.pump();
      for (var s = 0; s < 4; s++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final late = GeoPlot.offset(dhaka, east: 12);
      location.readings.add(GeoFix(late, 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(GeoPlot.distance(map!.corners.single, late), lessThan(0.01));
    });

    testWidgets('weak GPS is pointed out', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pump();
      location.readings.add(const GeoFix(dhaka, 25));
      await tester.pump();
      expect(find.textContaining('Weak GPS').shown, findsOneWidget);
    });

    testWidgets('permission refused: the walk says what is missing', (
      tester,
    ) async {
      location.onRequest = LocationAccess.deniedForever;
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sat-gps')),
          matching: find.text('Location permission was not given.'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('sat-allow')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SnackBarAction, 'Turn on'));
      await tester.pump();
      expect(location.settingsOpenedFor, LocationAccess.deniedForever);
    });

    testWidgets('back to tapping stops the GPS', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('sat-mode-walk')));
      await tester.pump();
      expect(location.readings.hasListener, isTrue);
      await tester.tap(find.byKey(const ValueKey('sat-mode-tap')));
      await tester.pump();
      expect(location.readings.hasListener, isFalse);
      expect(map!.editable, isTrue);
    });
  });

  testWidgets('Home opens the satellite map', (tester) async {
    tester.view.physicalSize = const Size(800, 1300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    String? pushed;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: MapToolsRow(accent: Color(0xFFC8FF5A)),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.satellite,
          builder: (_, s) {
            pushed = s.uri.path;
            return const Scaffold(body: Text('SAT'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('bn'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
    expect(find.text('স্যাটেলাইট ম্যাপে মাপুন'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-satellite')));
    await tester.pumpAndSettle();
    expect(pushed, AppRoutes.satellite);
  });
}
