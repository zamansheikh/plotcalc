// Renders the app screens used for the Google Play listing, one PNG per
// screen (1170 x 2532: a 390 x 844 phone at 3x), in Bangla, with demo data.
// tool/store/ then frames them and adds the captions. Not part of
// `flutter test`; run it through tool/store/build.sh, or:
//
//   flutter test tool/screenshots/store_test.dart \
//     --dart-define=SHOTS_DIR=/absolute/output/dir \
//     --dart-define=FONTS_DIR=/absolute/tool/store/.cache/fonts
//
// The analyzer only treats test/ as tests.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/app.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/map_align.dart';
import 'package:plotcalc/core/geometry/presets.dart';
import 'package:plotcalc/core/geometry/sheet_layout.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/input_method.dart';
import 'package:plotcalc/core/router/app_router.dart';
import 'package:plotcalc/core/theme/app_theme.dart';
import 'package:plotcalc/core/theme/app_typography.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/entities/plot_sheet.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:plotcalc/domain/usecases/save_sheet.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/info/data/land_info_loader.dart';
import 'package:plotcalc/presentation/features/mouza/view/mouza_screen.dart';
import 'package:plotcalc/presentation/features/overlay/view/overlay_screen.dart';
import 'package:plotcalc/presentation/features/result/view/result_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:plotcalc/presentation/shared/settings/settings_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _outDir = String.fromEnvironment('SHOTS_DIR');
const _fontsDir = String.fromEnvironment('FONTS_DIR');

/// The fonts a phone shows: the files google_fonts fetches at run time
/// (downloaded by tool/store/fonts.mjs), Roboto and the Material icons.
Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final material = '${sdk.path}/artifacts/material_fonts';
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  for (final name in ['Roboto', 'FlutterTest']) {
    await family(name, [
      for (final w in ['Regular', 'Medium', 'Bold']) '$material/Roboto-$w.ttf',
    ]);
  }
  await family('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  for (final f in Directory('$_fontsDir/app').listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last.replaceAll('.ttf', '');
    await family(name, [f.path]);
  }
}

final _boundaryKey = GlobalKey();

// Demo plots: a family's land in a village, in metres (north is up).
final _day = DateTime(2026, 10, 20);
Plot _plot(
  String id,
  String name,
  List<Vertex> v,
  PlotTag tag,
  int colour, {
  int daysAgo = 0,
}) => Plot(
  id: id,
  name: name,
  vertices: v,
  tag: tag,
  createdAt: _day.subtract(Duration(days: daysAgo)),
  colorValue: colour,
  preferredUnit: AreaUnit.shotok,
);

final _plots = [
  _plot(
    'p1',
    'উত্তরের ধানি জমি',
    const [Vertex(0, 0), Vertex(46, -4), Vertex(52, 27), Vertex(4, 31)],
    PlotTag.agricultural,
    0xFFC8FF5A,
  ),
  _plot(
    'p2',
    'বাড়ির ভিটা',
    const [
      Vertex(0, 0),
      Vertex(21, 0),
      Vertex(21, 14),
      Vertex(9, 17),
      Vertex(0, 14),
    ],
    PlotTag.residential,
    0xFF7DD3FC,
    daysAgo: 2,
  ),
  _plot(
    'p3',
    'পুকুর পাড়',
    const [Vertex(0, 0), Vertex(30, 3), Vertex(27, 22), Vertex(-2, 19)],
    PlotTag.other,
    0xFFD4A574,
    daysAgo: 4,
  ),
  _plot(
    'p4',
    'দক্ষিণের আমবাগান',
    const [
      Vertex(0, 0),
      Vertex(38, 2),
      Vertex(41, 20),
      Vertex(20, 29),
      Vertex(-3, 21),
    ],
    PlotTag.forest,
    0xFF34D399,
    daysAgo: 6,
  ),
  _plot(
    'p5',
    'বাজারের দোকান',
    const [Vertex(0, 0), Vertex(9, 0), Vertex(9, 13), Vertex(0, 13)],
    PlotTag.commercial,
    0xFFFBBF24,
    daysAgo: 9,
  ),
];

// The mouza map: a piece of a CS sheet (Abhirampur, J.L. 147, 16" = 1 mile,
// scanned at 400 dpi, so 80 px is one chain), 700 x 960 px.
const _mapFile = 'tool/store/maps/cs-abhirampur.jpg';
const _mapSize = Size(700, 960);

/// Plot 103 on that sheet, corner by corner.
const _dag103 = [
  Offset(190, 276),
  Offset(503, 320),
  Offset(511, 484),
  Offset(353, 460),
  Offset(350, 403),
  Offset(188, 386),
];

/// The RS survey split 103; its western half, plot 217.
const _dag217 = [
  Offset(190, 276),
  Offset(345, 298),
  Offset(350, 403),
  Offset(188, 386),
];

/// The RS sheet is the CS one redrawn: turned 3°, 6% larger, shifted.
final _ang = 3 * math.pi / 180;
final _rs = PlaneTransform([
  1.06 * math.cos(_ang),
  -1.06 * math.sin(_ang),
  -40,
  1.06 * math.sin(_ang),
  1.06 * math.cos(_ang),
  -45,
  0,
  0,
  1,
]);

Future<Uint8List> _png(ui.Image i) async =>
    (await i.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

/// The CS map as a PNG, and an RS sheet made from it: the same ground at
/// another scale and angle, on newer paper, with plot 103 split in two.
Future<(Uint8List, Uint8List)> _maps() async {
  final bytes = File(_mapFile).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final cs = (await codec.getNextFrame()).image;
  final (w, h) = (_mapSize.width, _mapSize.height);
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFEDE4CF),
  );
  c.save();
  c.transform(_rs.toMatrix4());
  c.drawImage(
    cs,
    Offset.zero,
    Paint()
      ..colorFilter = const ColorFilter.matrix([
        // Lighter, cooler paper: the newer print.
        0.9, 0, 0, 0, 30, //
        0, 0.92, 0, 0, 26, //
        0, 0, 0.95, 0, 30, //
        0, 0, 0, 1, 0,
      ]),
  );
  // The RS split line through plot 103 and the new plot numbers.
  c.drawLine(
    _dag217[1],
    _dag217[2],
    Paint()
      ..color = const Color(0xFF26231E)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round,
  );
  c.restore();
  final out = await rec.endRecording().toImage(w.toInt(), h.toInt());
  return (await _png(cs), await _png(out));
}

void main() {
  late AppLocalizations t;
  setUpAll(() async {
    await _loadFonts();
    await InfoContent.load();
    t = await AppLocalizations.delegate.load(const Locale('bn'));
  });
  tearDown(() => Intl.defaultLocale = null);

  Future<void> capture(WidgetTester tester, String name) async {
    if (_outDir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/bn-$name.png').writeAsBytesSync(bytes!);
  }

  /// Storage with the demo plots, in Bangla.
  Future<void> seed(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'plotcalc.locale.v1': 'bn'});
    await GetIt.I.reset();
    await configureDependencies();
    AppTypography.registerBanglaFallback();
    // Newest last, so the list shows the first one on top.
    for (final p in _plots.reversed) {
      await sl<SavePlot>()(p);
    }
  }

  /// The whole app, as installed.
  Future<GoRouter> start(WidgetTester tester) async {
    await seed(tester);
    await tester.pumpWidget(
      RepaintBoundary(key: _boundaryKey, child: const PlotCalcApp()),
    );
    final context = tester.element(find.byType(Scaffold).first);
    // Areas in decimals (শতক), the unit most buyers and sellers use.
    context.read<SettingsBloc>().add(const AreaUnitChanged(AreaUnit.shotok));
    await settle(tester);
    return GoRouter.of(context);
  }

  /// One screen that needs a photo the app would ask the user for, in the
  /// app's theme and language.
  Future<void> screen(WidgetTester tester, Widget body) async {
    await seed(tester);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        GoRoute(path: '/s', builder: (_, _) => body),
        GoRoute(
          path: AppRoutes.result,
          builder: (_, s) => ResultScreen(args: s.extra as ResultArgs),
        ),
      ],
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundaryKey,
          child: BlocProvider<SettingsBloc>(
            create: (_) =>
                SettingsBloc()..add(const AreaUnitChanged(AreaUnit.shotok)),
            child: MaterialApp.router(
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              locale: const Locale('bn'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
            ),
          ),
        ),
      );
      Intl.defaultLocale = 'bn';
      router.push('/s');
      await tester.pump();
      // Let the photos decode.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await settle(tester);
  }

  shot('home, plots, result, draw', (tester) async {
    final router = await start(tester);
    await capture(tester, '01-home');

    router.go(AppRoutes.history);
    await settle(tester);
    await capture(tester, '02-history');

    final p = _plots.first;
    unawaited(
      router.push(
        AppRoutes.result,
        extra: ResultArgs(
          name: p.name,
          vertices: p.vertices,
          plotId: p.id,
          unit: AreaUnit.shotok,
        ),
      ),
    );
    await settle(tester);
    await capture(tester, '03-result');
    router.pop();
    await settle(tester);

    unawaited(
      router.push(
        AppRoutes.draw,
        extra: DrawArgs(
          method: InputMethod.draw,
          preset: ShapePreset.freeform,
          vertices: p.vertices,
          plotId: p.id,
          name: p.name,
        ),
      ),
    );
    await settle(tester);
    await capture(tester, '04-draw');
  });

  shot('mouza map', (tester) async {
    final (cs, _) = (await tester.runAsync(_maps))!;
    await screen(tester, MouzaScreen(initialPhoto: cs));
    Rect image() {
      final c = tester.getRect(find.byKey(const ValueKey('mouza-canvas')));
      final s = math.min(c.width / _mapSize.width, c.height / _mapSize.height);
      return Rect.fromCenter(
        center: c.center,
        width: _mapSize.width * s,
        height: _mapSize.height * s,
      );
    }

    Offset at(Offset p) {
      final r = image();
      return r.topLeft + p * (r.width / _mapSize.width);
    }

    // Scale: 400 px of the sheet is 5 chains.
    await tester.tapAt(at(const Offset(100, 900)));
    await tester.pump();
    await tester.tapAt(at(const Offset(500, 900)));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('mouza-distance')), '5');
    await tester.tap(find.text(t.mouzaUnitChain));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.mouzaNext));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.fit_screen_outlined));
    await tester.pumpAndSettle();
    for (final p in _dag103) {
      await tester.tapAt(at(p));
      await tester.pump();
    }
    await settle(tester);
    await capture(tester, '05-mouza');
  });

  shot('pantograph', (tester) async {
    final (cs, rs) = (await tester.runAsync(_maps))!;
    await screen(tester, OverlayScreen(initialOld: cs, initialNew: rs));
    await tester.tap(find.text(t.mouzaNext));
    await settle(tester);

    Rect canvas() =>
        tester.getRect(find.byKey(const ValueKey('overlay-canvas')));
    final c0 = canvas();
    final s = math.min(c0.width / _mapSize.width, c0.height / _mapSize.height);
    final centre = _mapSize.center(Offset.zero);
    Offset onA(Offset p) => canvas().center + (p - centre) * s;

    // Places 1 and 2 by hand; 3 and 4 are then put where they belong.
    for (final p in const [Offset(190, 276), Offset(511, 484)]) {
      await tester.tapAt(onA(p));
      await tester.pumpAndSettle();
      await tester.tapAt(canvas().center + (_rs.apply(p) - p) * s);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.overlayNextPair));
      await tester.pumpAndSettle();
    }
    for (final p in const [Offset(503, 320), Offset(188, 386)]) {
      await tester.tapAt(onA(p));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.overlayNextPair));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(t.mouzaNext));
    await tester.pumpAndSettle();

    // Scale, then plot 103 on the CS sheet and 217 on the RS one.
    await tester.tapAt(onA(const Offset(100, 900)));
    await tester.pump();
    await tester.tapAt(onA(const Offset(500, 900)));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('mouza-distance')), '5');
    await tester.tap(find.text(t.mouzaUnitChain));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.mouzaNext));
    await tester.pumpAndSettle();

    Future<void> trace(List<Offset> pts, String name) async {
      for (final p in pts) {
        await tester.tapAt(onA(p));
        await tester.pump();
      }
      await tester.tap(find.text(t.overlayFinishPlot));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, name);
      await tester.tap(find.text(t.actionSave));
      await tester.pumpAndSettle();
    }

    await trace(_dag103, 'CS ১০৩');
    await tester.tap(find.text('RS ${t.overlayPlot}'));
    await tester.pump();
    await trace(_dag217, 'RS ২১৭');
    await settle(tester);
    await capture(tester, '06-pantograph');
  });

  shot('division and sheet', (tester) async {
    final router = await start(tester);
    router.go(AppRoutes.subdivide);
    await settle(tester);
    await tester.tap(find.text(_plots.first.name).first);
    await settle(tester);

    await tester.enterText(find.byKey(const ValueKey('owner-name-0')), 'রহিম');
    await tester.enterText(find.byKey(const ValueKey('owner-name-1')), 'করিম');
    await tester.ensureVisible(find.byKey(const ValueKey('add-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-owner')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('owner-name-2')),
      'ফাতেমা',
    );
    await tester.tap(find.byKey(const ValueKey('mode-shares')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('owner-amount-0')),
      '৮ আনা',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.divisionSidesTab));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('side-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('road-8.0')));
    await tester.pumpAndSettle();
    await capture(tester, '07-division-road');
    await tester.tap(find.text(t.divisionBoundsTab));
    await tester.pumpAndSettle();
    await capture(tester, '07-division-bounds');
    await tester.tap(find.text(t.divisionOwnersTab));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture(tester, '07-division');

    // A sheet of the family's land, with the price per decimal.
    final ids = [for (final p in _plots) p.id];
    final sheet = PlotSheet(
      id: 'sheet1',
      name: 'রহমান পরিবারের জমি',
      plotIds: ids,
      pricePerUnit: 120000,
      createdAt: _day,
      layout: _layout(),
    );
    await sl<SaveSheet>()(sheet);
    router.go(AppRoutes.history);
    await settle(tester);
    unawaited(router.push(AppRoutes.sheet, extra: sheet.id));
    await settle(tester);
    await capture(tester, '08-sheet');
    unawaited(router.push(AppRoutes.sheetArrange, extra: sheet.id));
    await settle(tester);
    await capture(tester, '09-arrange');
  });
}

/// The five plots as they lie: the paddy north, the homestead and pond
/// beside it, the orchard south, the shop by the road.
Map<String, PlotPlacement> _layout() {
  return const {
    'p1': PlotPlacement(26, 14),
    'p2': PlotPlacement(66, 8),
    'p3': PlotPlacement(66, 33),
    'p4': PlotPlacement(24, 50),
    'p5': PlotPlacement(58, 54, 0.12),
  };
}

/// Lets futures (storage, images) finish and animations end.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pumpAndSettle();
  Intl.defaultLocale = 'bn';
}

/// A screenshot test with real shadows (tests draw outlines by default).
void shot(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}
