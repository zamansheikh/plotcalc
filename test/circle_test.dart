import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/presets.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/data/repositories/plot_repository_impl.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/input_method.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/presentation/features/draw/bloc/draw_bloc.dart';
import 'package:plotcalc/presentation/features/draw/bloc/draw_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plot circle(double r) => Plot(
  id: 'c1',
  name: 'Pond',
  vertices: circleVertices(r),
  tag: PlotTag.other,
  createdAt: DateTime.utc(2026, 1, 1),
  colorValue: 0xFF00FF00,
  circleRadiusM: r,
);

void main() {
  _drawBehaviour();

  group('exact circle maths', () {
    test('area and circumference use the real formulae', () {
      for (final r in [1.0, 7.5, 22.0, 100.0]) {
        expect(Geometry.circleArea(r), closeTo(math.pi * r * r, 1e-9));
        expect(Geometry.circleCircumference(r), closeTo(2 * math.pi * r, 1e-9));
      }
    });

    test('radiusForArea inverts circleArea', () {
      for (final r in [0.5, 12.0, 99.9]) {
        expect(Geometry.radiusForArea(Geometry.circleArea(r)), closeTo(r, 1e-9));
      }
    });

    test('a non-positive area gives a zero radius, not NaN', () {
      expect(Geometry.radiusForArea(0), 0);
      expect(Geometry.radiusForArea(-5), 0);
    });
  });

  group('polygon approximation', () {
    test('has the advertised number of segments', () {
      expect(circleVertices(10).length, circleSegments);
      expect(ShapePreset.circle.vertices.length, circleSegments);
    });

    test('every vertex sits on the circle', () {
      const r = 17.0;
      for (final v in circleVertices(r)) {
        expect(math.sqrt(v.x * v.x + v.y * v.y), closeTo(r, 1e-9));
      }
    });

    test('the drawn shape is visually a circle, to within 0.2%', () {
      // The polygon is only ever drawn; the number the user reads comes from
      // the exact formula. 72 sides lands ~0.13% under.
      for (final r in [1.0, 22.0, 250.0]) {
        final polygon = Geometry.polygonArea(circleVertices(r));
        final exact = Geometry.circleArea(r);
        expect((polygon - exact).abs() / exact, lessThan(0.002), reason: 'r=\$r');
      }
    });

    test('the drawn perimeter is within 0.2% of the circumference', () {
      for (final r in [1.0, 22.0, 250.0]) {
        final polygon = Geometry.polygonPerimeter(circleVertices(r));
        final exact = Geometry.circleCircumference(r);
        expect((polygon - exact).abs() / exact, lessThan(0.002), reason: 'r=\$r');
      }
    });

    test('a plot reports the exact circle area, never the polygon one', () {
      const r = 22.0;
      final p = circle(r);
      expect(p.areaSqm, closeTo(Geometry.circleArea(r), 1e-9));
      expect(p.perimeterM, closeTo(Geometry.circleCircumference(r), 1e-9));
      // Which is measurably more than the drawn polygon.
      expect(p.areaSqm, greaterThan(Geometry.polygonArea(p.vertices)));
    });

    test('a polygon plot still reports its shoelace area', () {
      final p = circle(10).copyWith(clearCircle: true);
      expect(p.areaSqm, closeTo(Geometry.polygonArea(p.vertices), 1e-9));
    });

    test('a zero radius degenerates safely', () {
      final v = circleVertices(0);
      expect(v.length, circleSegments);
      expect(Geometry.polygonArea(v), 0);
    });
  });

  group('persistence', () {
    late PlotRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GetIt.I.reset();
      final prefs = await SharedPreferences.getInstance();
      sl.registerSingleton<SharedPreferences>(prefs);
      repo = PlotRepositoryImpl(prefs);
    });

    test('a circle is still a circle after a restart', () async {
      await repo.save(circle(12.5));
      final back = (await PlotRepositoryImpl(sl<SharedPreferences>()).getAll())
          .single;
      expect(back.isCircle, isTrue);
      expect(back.circleRadiusM, closeTo(12.5, 1e-9));
    });

    test('a polygon does not gain a radius', () async {
      await repo.save(circle(5).copyWith(clearCircle: true));
      final back = (await repo.getAll()).single;
      expect(back.isCircle, isFalse);
      expect(back.circleRadiusM, isNull);
    });

    test('the field is omitted when unset, so old plots are untouched', () {
      final json = circle(5).copyWith(clearCircle: true).toJson();
      expect(json.containsKey('circleRadiusM'), isFalse);
    });

    test('a plot from before circles existed loads as a polygon', () {
      final legacy = {
        'id': 'old',
        'name': 'Legacy',
        'vertices': [
          {'x': 0.0, 'y': 0.0},
          {'x': 9.0, 'y': 0.0},
          {'x': 9.0, 'y': 9.0},
        ],
        'tag': 'other',
        'createdAt': '2025-06-01T00:00:00.000Z',
        'colorValue': 255,
      };
      expect(Plot.fromJson(legacy).isCircle, isFalse);
    });

    test('a nonsense radius is treated as "not a circle"', () {
      for (final bad in [null, 0, -3, 'big', true]) {
        final json = circle(5).toJson()..['circleRadiusM'] = bad;
        expect(Plot.fromJson(json).isCircle, isFalse, reason: '$bad');
      }
    });

    test('editing the outline drops the radius', () {
      final edited = circle(9).copyWith(clearCircle: true);
      expect(edited.isCircle, isFalse);
      expect(edited.vertices, circle(9).vertices, reason: 'shape is kept');
    });
  });

  group('area reported to the user', () {
    test('a circle reports its exact area, not the polygon estimate', () {
      const r = 22.0;
      final exact = Geometry.circleArea(r);
      // What the result screen will show for a 22m-radius pond.
      expect(AreaUnit.sqm.format(exact), isNotEmpty);
      expect(exact, closeTo(1520.53, 0.01));
    });
  });
}

/// The first cut of this feature dropped a 72-vertex polygon into a canvas
/// built for 3-8 vertices: every handle, edge label and diagonal at once.
/// These pin the two root causes.
void _drawBehaviour() {
  group('drawing a circle', () {
    late DrawBloc bloc;
    setUp(() => bloc = DrawBloc());
    tearDown(() => bloc.close());

    /// Bloc handlers run on the event loop, so state has to be awaited.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    Future<void> start(ShapePreset preset) async {
      bloc.add(DrawInitialized(
        DrawArgs(method: InputMethod.draw, preset: preset),
      ));
      await settle();
    }

    test('the circle preset arrives as a circle, not a 72-gon', () async {
      await start(ShapePreset.circle);
      expect(bloc.state.circleRadiusM, closeTo(circlePresetRadius, 1e-9));
      expect(bloc.state.vertices.length, circleSegments);
    });

    test('other presets carry no radius', () async {
      for (final p in ShapePreset.values.where((p) => p != ShapePreset.circle)) {
        final b = DrawBloc()
          ..add(DrawInitialized(
            DrawArgs(method: InputMethod.draw, preset: p),
          ));
        await settle();
        expect(b.state.circleRadiusM, isNull, reason: p.name);
        await b.close();
      }
    });

    test('typing a radius produces a circle', () async {
      bloc.add(TypeShapeGenerated(circleVertices(15), circleRadiusM: 15));
      await settle();
      expect(bloc.state.circleRadiusM, 15);
    });

    test('dragging resizes the circle instead of destroying it', () async {
      await start(ShapePreset.circle);
      bloc.add(const CircleRadiusChanged(40));
      await settle();

      expect(bloc.state.circleRadiusM, 40, reason: 'still a circle');
      expect(bloc.state.vertices.length, circleSegments);
      for (final v in bloc.state.vertices) {
        expect(math.sqrt(v.x * v.x + v.y * v.y), closeTo(40, 1e-9));
      }
    });

    test('a stray drag to the centre cannot make a zero-size circle', () async {
      await start(ShapePreset.circle);
      bloc.add(const CircleRadiusChanged(0));
      await settle();
      expect(bloc.state.circleRadiusM, greaterThan(0));
    });

    test('resizing a polygon is ignored', () async {
      await start(ShapePreset.square);
      bloc.add(const CircleRadiusChanged(40));
      await settle();
      expect(bloc.state.circleRadiusM, isNull);
    });

    test('editing a vertex does turn a circle into a polygon', () async {
      await start(ShapePreset.circle);
      bloc.add(const VertexMoved(index: 0, position: Vertex(99, 99)));
      await settle();
      expect(bloc.state.circleRadiusM, isNull);
    });
  });
}
