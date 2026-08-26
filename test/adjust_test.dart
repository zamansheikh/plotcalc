import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/presets.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/presentation/features/adjust/bloc/adjust_bloc.dart';
import 'package:plotcalc/presentation/features/adjust/bloc/adjust_event.dart';
import 'package:plotcalc/presentation/features/adjust/bloc/adjust_state.dart';

/// Resizing a plot to a target area is a measurement claim: whatever the
/// screen says the adjusted area is, the shape it hands back must actually
/// have that area. This suite checks the claim rather than the plumbing.

List<Vertex> randomPolygon(Random rnd, {double scale = 50}) {
  // Angularly sorted so the polygon is simple (non self-intersecting),
  // which is what the shoelace area assumes.
  final n = 3 + rnd.nextInt(6);
  final angles = List.generate(n, (_) => rnd.nextDouble() * 2 * pi)..sort();
  return [
    for (final a in angles)
      Vertex(
        cos(a) * scale * (0.5 + rnd.nextDouble()),
        sin(a) * scale * (0.5 + rnd.nextDouble()),
      ),
  ];
}

AdjustState stateFor(
  List<Vertex> base,
  double target, {
  AdjustMode mode = AdjustMode.uniform,
  AdjustAnchor anchor = AdjustAnchor.center,
}) => AdjustState(
  baseVertices: base,
  targetSqm: target,
  mode: mode,
  anchor: anchor,
);

void main() {
  group('the adjusted shape really has the target area', () {
    test('20k random polygons x every mode x every anchor', () {
      final rnd = Random(3);
      var worst = 0.0;
      final failures = <String>[];

      for (var t = 0; t < 20000; t++) {
        final base = randomPolygon(rnd);
        final baseArea = Geometry.polygonArea(base);
        if (baseArea <= 0) continue;

        final target = [
          baseArea * (0.01 + rnd.nextDouble() * 5),
          baseArea * 1e-4,
          baseArea * 1e4,
          rnd.nextDouble() * 1e6,
        ][rnd.nextInt(4)];

        final s = stateFor(
          base,
          target,
          mode: AdjustMode.values[rnd.nextInt(AdjustMode.values.length)],
          anchor: AdjustAnchor.values[rnd.nextInt(AdjustAnchor.values.length)],
        );

        final rel = (s.adjustedSqm - target).abs() / target;
        if (rel > worst) worst = rel;
        if (rel > 1e-9) {
          failures.add('${s.mode.name}/${s.anchor.name}: '
              'target $target got ${s.adjustedSqm}');
        }
      }

      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
      expect(worst, lessThan(1e-9), reason: 'worst relative error');
    });

    test('every mode and anchor pairing hits an exact 2x', () {
      final base = ShapePreset.pentagon.vertices;
      final baseArea = Geometry.polygonArea(base);
      for (final mode in AdjustMode.values) {
        for (final anchor in AdjustAnchor.values) {
          final s = stateFor(base, baseArea * 2, mode: mode, anchor: anchor);
          expect(
            s.adjustedSqm,
            closeTo(baseArea * 2, baseArea * 1e-12),
            reason: '${mode.name}/${anchor.name}',
          );
        }
      }
    });

    test('halving is exact too', () {
      final base = ShapePreset.rectangle.vertices;
      final baseArea = Geometry.polygonArea(base);
      for (final mode in AdjustMode.values) {
        final s = stateFor(base, baseArea / 2, mode: mode);
        expect(s.adjustedSqm, closeTo(baseArea / 2, baseArea * 1e-12));
      }
    });

    test('an unchanged target leaves the shape untouched', () {
      final base = ShapePreset.trapezoid.vertices;
      final s = stateFor(base, Geometry.polygonArea(base));
      for (var i = 0; i < base.length; i++) {
        expect(s.adjustedVertices[i].x, closeTo(base[i].x, 1e-9));
        expect(s.adjustedVertices[i].y, closeTo(base[i].y, 1e-9));
      }
    });
  });

  group('what each mode and anchor promises', () {
    final base = ShapePreset.rectangle.vertices;
    final baseArea = Geometry.polygonArea(base);

    test('uniform keeps the aspect ratio', () {
      final s = stateFor(base, baseArea * 4, mode: AdjustMode.uniform);
      final (bx0, by0, bx1, by1) = Geometry.bbox(base);
      final (ax0, ay0, ax1, ay1) = Geometry.bbox(s.adjustedVertices);
      final baseRatio = (bx1 - bx0) / (by1 - by0);
      final adjRatio = (ax1 - ax0) / (ay1 - ay0);
      expect(adjRatio, closeTo(baseRatio, 1e-9));
      // 4x the area means 2x each side.
      expect(ax1 - ax0, closeTo((bx1 - bx0) * 2, 1e-9));
    });

    test('horizontal changes width only', () {
      final s = stateFor(base, baseArea * 3, mode: AdjustMode.horizontal);
      final (bx0, by0, bx1, by1) = Geometry.bbox(base);
      final (ax0, ay0, ax1, ay1) = Geometry.bbox(s.adjustedVertices);
      expect(ax1 - ax0, closeTo((bx1 - bx0) * 3, 1e-9));
      expect(ay1 - ay0, closeTo(by1 - by0, 1e-9), reason: 'height untouched');
    });

    test('vertical changes height only', () {
      final s = stateFor(base, baseArea * 3, mode: AdjustMode.vertical);
      final (bx0, by0, bx1, by1) = Geometry.bbox(base);
      final (ax0, ay0, ax1, ay1) = Geometry.bbox(s.adjustedVertices);
      expect(ay1 - ay0, closeTo((by1 - by0) * 3, 1e-9));
      expect(ax1 - ax0, closeTo(bx1 - bx0, 1e-9), reason: 'width untouched');
    });

    test('each anchor holds its own edge still', () {
      final checks = <AdjustAnchor, void Function(List<Vertex>)>{
        AdjustAnchor.west: (v) => expect(
          Geometry.bbox(v).$1,
          closeTo(Geometry.bbox(base).$1, 1e-9),
          reason: 'west edge must not move',
        ),
        AdjustAnchor.east: (v) => expect(
          Geometry.bbox(v).$3,
          closeTo(Geometry.bbox(base).$3, 1e-9),
          reason: 'east edge must not move',
        ),
        AdjustAnchor.north: (v) => expect(
          Geometry.bbox(v).$2,
          closeTo(Geometry.bbox(base).$2, 1e-9),
          reason: 'north edge must not move',
        ),
        AdjustAnchor.south: (v) => expect(
          Geometry.bbox(v).$4,
          closeTo(Geometry.bbox(base).$4, 1e-9),
          reason: 'south edge must not move',
        ),
      };
      checks.forEach((anchor, check) {
        check(stateFor(base, baseArea * 2.5, anchor: anchor).adjustedVertices);
      });
    });

    test('centre anchor keeps the centre still', () {
      final s = stateFor(base, baseArea * 2.5);
      final (bx0, by0, bx1, by1) = Geometry.bbox(base);
      final (ax0, ay0, ax1, ay1) = Geometry.bbox(s.adjustedVertices);
      expect((ax0 + ax1) / 2, closeTo((bx0 + bx1) / 2, 1e-9));
      expect((ay0 + ay1) / 2, closeTo((by0 + by1) / 2, 1e-9));
    });

    test('the shape keeps its vertex count and stays finite', () {
      for (final mode in AdjustMode.values) {
        final s = stateFor(base, baseArea * 1e6, mode: mode);
        expect(s.adjustedVertices.length, base.length);
        for (final v in s.adjustedVertices) {
          expect(v.x.isFinite && v.y.isFinite, isTrue);
        }
      }
    });
  });

  group('degenerate input is survivable', () {
    test('a target of zero, negative, NaN or infinity keeps the base shape', () {
      final base = ShapePreset.pentagon.vertices;
      final baseArea = Geometry.polygonArea(base);
      for (final bad in [0.0, -50.0, double.nan, double.infinity]) {
        final s = stateFor(base, bad);
        expect(s.adjustedVertices, base, reason: '$bad');
        expect(s.adjustedSqm, closeTo(baseArea, 1e-9), reason: '$bad');
      }
    });

    test('fewer than three vertices produces no area and does not throw', () {
      for (final verts in [
        const <Vertex>[],
        const [Vertex(0, 0)],
        const [Vertex(0, 0), Vertex(1, 1)],
      ]) {
        final s = stateFor(verts, 100);
        expect(s.adjustedSqm, 0);
        expect(s.adjustedVertices, verts);
      }
    });

    test('a collinear (zero-area) plot cannot be scaled into existence', () {
      const flat = [Vertex(0, 0), Vertex(1, 0), Vertex(2, 0)];
      final s = stateFor(flat, 500);
      expect(s.adjustedSqm, 0, reason: 'no area to scale');
      expect(s.adjustedVertices, flat);
    });
  });

  group('bloc', () {
    late AdjustBloc bloc;
    setUp(() => bloc = AdjustBloc());
    tearDown(() => bloc.close());
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('starts at the requested multiple of the base area', () async {
      final base = ShapePreset.pentagon.vertices;
      final baseArea = Geometry.polygonArea(base);
      bloc.add(AdjustInitialized(base: base, initialMultiplier: 1.2));
      await settle();
      expect(bloc.state.targetSqm, closeTo(baseArea * 1.2, 1e-9));
      expect(bloc.state.adjustedSqm, closeTo(baseArea * 1.2, 1e-9));
    });

    test('a negative target is clamped to zero, not applied', () async {
      final base = ShapePreset.square.vertices;
      bloc
        ..add(AdjustInitialized(base: base))
        ..add(const TargetChanged(-1));
      await settle();
      expect(bloc.state.targetSqm, 0);
    });

    test('reset returns to exactly the base area', () async {
      final base = ShapePreset.triangle.vertices;
      final baseArea = Geometry.polygonArea(base);
      bloc
        ..add(AdjustInitialized(base: base))
        ..add(const TargetChanged(99999))
        ..add(const AdjustReset());
      await settle();
      expect(bloc.state.targetSqm, closeTo(baseArea, 1e-9));
      expect(bloc.state.adjustedSqm, closeTo(baseArea, 1e-9));
    });

    test('changing mode or anchor never changes the area', () async {
      final base = ShapePreset.trapezoid.vertices;
      bloc.add(AdjustInitialized(base: base, initialMultiplier: 2.5));
      await settle();
      final target = bloc.state.targetSqm;

      for (final mode in AdjustMode.values) {
        for (final anchor in AdjustAnchor.values) {
          bloc
            ..add(ModeChanged(mode))
            ..add(AnchorChanged(anchor));
          await settle();
          expect(
            bloc.state.adjustedSqm,
            closeTo(target, target * 1e-12),
            reason: '${mode.name}/${anchor.name}',
          );
        }
      }
    });
  });

  group('the figure shown is the figure applied', () {
    test('adjustedVertices is the single source for both', () {
      // The screen used to compute the preview and the applied shape from
      // separate expressions; they now come from one place, so a reading of
      // the preview is a promise about what Apply hands back.
      final base = ShapePreset.freeform.vertices;
      final s = stateFor(base, Geometry.polygonArea(base) * 1.75);
      expect(Geometry.polygonArea(s.adjustedVertices), s.adjustedSqm);
      expect(s.adjustedSqm, closeTo(s.targetSqm, s.targetSqm * 1e-12));
    });
  });
}
