import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/boundary_adjust.dart';
import 'package:plotcalc/core/geometry/presets.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/vertex.dart';

/// Moving a boundary to hit a target area is a claim a surveyor will act on
/// — they will go and peg the ground at the distance this reports. So the
/// bar is not "usually right": when it reports success the area must really
/// be the target, and when it cannot reach the target it must say so.

const square20 = [
  Vertex(0, 0),
  Vertex(20, 0),
  Vertex(20, 20),
  Vertex(0, 20),
];

List<Vertex> convexPolygon(Random rnd, {double scale = 30}) {
  final n = 3 + rnd.nextInt(4);
  final angles = List.generate(n, (_) => rnd.nextDouble() * 2 * pi)..sort();
  final r = scale * (0.8 + rnd.nextDouble() * 0.4);
  return [for (final a in angles) Vertex(cos(a) * r, sin(a) * r)];
}

List<Vertex> spikyPolygon(Random rnd, {double scale = 30}) {
  final n = 3 + rnd.nextInt(6);
  final angles = List.generate(n, (_) => rnd.nextDouble() * 2 * pi)..sort();
  return [
    for (final a in angles)
      Vertex(cos(a) * scale * (0.3 + rnd.nextDouble() * 1.4),
             sin(a) * scale * (0.3 + rnd.nextDouble() * 1.4)),
  ];
}

void main() {
  group('the arithmetic a surveyor can check by hand', () {
    test('pushing one side of a 20x20 square out by 1m adds exactly 20 m2', () {
      final moved = BoundaryAdjust.offsetSides(square20, {0}, 1);
      expect(Geometry.polygonArea(moved), closeTo(420, 1e-9));
    });

    test('pulling that side in by 1m removes exactly 20 m2', () {
      final moved = BoundaryAdjust.offsetSides(square20, {0}, -1);
      expect(Geometry.polygonArea(moved), closeTo(380, 1e-9));
    });

    test('two opposite sides each move half as far', () {
      // 400 -> 440 by moving sides 0 and 2: each contributes 20*d.
      final s = BoundaryAdjust.solve(
        base: square20,
        targetSqm: 440,
        kind: AdjustTargetKind.side,
        selection: {0, 2},
      )!;
      expect(s.isExact, isTrue);
      expect(s.offsetM, closeTo(1, 1e-6));
    });

    test('all four sides out by 1m gives a 22x22 square', () {
      final moved = BoundaryAdjust.offsetSides(square20, {0, 1, 2, 3}, 1);
      expect(Geometry.polygonArea(moved), closeTo(484, 1e-9));
    });

    test('the untouched sides keep their direction', () {
      // The point of a parallel offset: only the moved line changes, the
      // neighbours just get longer or shorter.
      final moved = BoundaryAdjust.offsetSides(square20, {0}, 3);
      // Sides 1 and 3 are vertical before and must stay vertical.
      expect(moved[1].x, closeTo(moved[2].x, 1e-9));
      expect(moved[3].x, closeTo(moved[0].x, 1e-9));
    });

    test('a solved offset is what actually reaches the target', () {
      // The 5.2 -> 5.5 katha story, in metres.
      const katha = 66.8901888;
      final base = square20;
      final target = Geometry.polygonArea(base) * (5.5 / 5.2);
      final s = BoundaryAdjust.solve(
        base: base,
        targetSqm: target,
        kind: AdjustTargetKind.side,
        selection: {1},
      )!;
      expect(s.isExact, isTrue);
      expect(Geometry.polygonArea(s.vertices), closeTo(target, target * 1e-6));
      expect(s.offsetM, greaterThan(0), reason: 'growing pushes out');
      expect(katha, greaterThan(0)); // documents the unit the story uses
    });

    test('shrinking 5.2 -> 5.0 pulls the boundary in', () {
      final target = Geometry.polygonArea(square20) * (5.0 / 5.2);
      final s = BoundaryAdjust.solve(
        base: square20,
        targetSqm: target,
        kind: AdjustTargetKind.side,
        selection: {0},
      )!;
      expect(s.isExact, isTrue);
      expect(s.offsetM, lessThan(0), reason: 'shrinking pulls in');
      expect(Geometry.polygonArea(s.vertices), closeTo(target, target * 1e-6));
    });
  });

  group('a reported success is never a lie', () {
    test('12k random cases: exact means exact', () {
      final rnd = Random(5);
      final lies = <String>[];
      var solved = 0, attempted = 0;

      for (final spiky in [false, true]) {
        for (final kind in AdjustTargetKind.values) {
          for (var t = 0; t < 3000; t++) {
            final base = spiky ? spikyPolygon(rnd) : convexPolygon(rnd);
            final baseArea = Geometry.polygonArea(base);
            if (baseArea <= 1) continue;
            final n = base.length;
            final sel = <int>{};
            final count = 1 + rnd.nextInt(n);
            while (sel.length < count) {
              sel.add(rnd.nextInt(n));
            }
            final target = baseArea * (0.85 + rnd.nextDouble() * 0.3);

            final s = BoundaryAdjust.solve(
              base: base, targetSqm: target, kind: kind, selection: sel,
            );
            if (s == null) continue;
            attempted++;
            if (!s.isExact) continue;
            solved++;

            final actual = Geometry.polygonArea(s.vertices);
            final rel = (actual - target).abs() / target;
            if (rel > 1e-6) lies.add('${kind.name} rel=$rel');
            if (s.vertices.any((v) => !v.x.isFinite || !v.y.isFinite)) {
              lies.add('${kind.name} non-finite');
            }
            if (s.vertices.length != n) lies.add('${kind.name} vertex count');
          }
        }
      }

      expect(lies, isEmpty, reason: lies.take(5).join('\n'));
      // Guards against a regression that quietly stops solving anything.
      expect(solved / attempted, greaterThan(0.95),
          reason: 'solved $solved of $attempted');
    });

    test('an unreachable target is reported, not faked', () {
      // One side of a long thin plot cannot double the area within the
      // search range; the solver must admit that.
      const thin = [
        Vertex(0, 0),
        Vertex(100, 0),
        Vertex(100, 1),
        Vertex(0, 1),
      ];
      final s = BoundaryAdjust.solve(
        base: thin,
        targetSqm: Geometry.polygonArea(thin) * 500,
        kind: AdjustTargetKind.side,
        selection: {1},
      )!;
      expect(s.isExact, isFalse);
      // Still hands back something finite so the UI can show the best effort.
      expect(s.vertices.every((v) => v.x.isFinite && v.y.isFinite), isTrue);
    });

    test('the smallest move is the one returned', () {
      // A boundary pushed far enough folds the polygon over and the area can
      // come back around; the answer must be the near one, not the far one.
      final s = BoundaryAdjust.solve(
        base: square20,
        targetSqm: 420,
        kind: AdjustTargetKind.side,
        selection: {0},
      )!;
      expect(s.offsetM, closeTo(1, 1e-6));
    });
  });

  group('corners', () {
    test('moving one corner reaches the target', () {
      final s = BoundaryAdjust.solve(
        base: square20,
        targetSqm: 420,
        kind: AdjustTargetKind.corner,
        selection: {0},
      )!;
      expect(s.isExact, isTrue);
      expect(Geometry.polygonArea(s.vertices), closeTo(420, 1e-4));
    });

    test('only the chosen corners move', () {
      final moved = BoundaryAdjust.moveCorners(square20, {2}, 3);
      // Corner 2 in CCW order; the other three must be untouched.
      var unchanged = 0;
      for (final v in moved) {
        if (square20.any((b) => (b.x - v.x).abs() < 1e-9 &&
                                (b.y - v.y).abs() < 1e-9)) {
          unchanged++;
        }
      }
      expect(unchanged, 3);
    });

    test('moving every corner grows the plot', () {
      final moved = BoundaryAdjust.moveCorners(square20, {0, 1, 2, 3}, 2);
      expect(Geometry.polygonArea(moved),
          greaterThan(Geometry.polygonArea(square20)));
    });
  });

  group('winding and orientation', () {
    test('a clockwise plot behaves the same as a counter-clockwise one', () {
      final cw = square20.reversed.toList();
      final a = BoundaryAdjust.solve(
        base: square20, targetSqm: 440,
        kind: AdjustTargetKind.side, selection: {0},
      )!;
      final b = BoundaryAdjust.solve(
        base: cw, targetSqm: 440,
        kind: AdjustTargetKind.side, selection: {0},
      )!;
      expect(a.isExact && b.isExact, isTrue);
      expect(a.areaSqm, closeTo(b.areaSqm, 1e-6));
      expect(a.offsetM.sign, b.offsetM.sign, reason: 'both push outward');
    });

    test('a small offset grows or shrinks a well-conditioned plot', () {
      // offsetSides is a raw geometric operation with no monotonicity
      // guarantee in general: where a side is very short and its neighbour
      // nearly parallel, the mitred corner slides far enough to invert the
      // edge at *any* offset. Providing a usable answer despite that is the
      // solver's job — see "a reported success is never a lie".
      for (final base in [
        square20,
        ShapePreset.pentagon.vertices,
        ShapePreset.rectangle.vertices,
        ShapePreset.trapezoid.vertices,
      ]) {
        final area = Geometry.polygonArea(base);
        final d = 0.02 * area / Geometry.polygonPerimeter(base);
        for (var i = 0; i < base.length; i++) {
          expect(Geometry.polygonArea(BoundaryAdjust.offsetSides(base, {i}, d)),
              greaterThan(area), reason: 'side $i out');
          expect(Geometry.polygonArea(BoundaryAdjust.offsetSides(base, {i}, -d)),
              lessThan(area), reason: 'side $i in');
        }
      }
    });

    test('a clockwise plot keeps its vertex order and side numbering', () {
      // Regression: the winding used to be normalised by reversing the list,
      // which silently renumbered the sides and handed the caller its plot
      // back inside out.
      final cw = square20.reversed.toList();
      final moved = BoundaryAdjust.offsetSides(cw, {0}, 1);
      expect(moved.length, cw.length);
      // Side 0 runs cw[0] -> cw[1]; only those two corners may move.
      expect(moved[2].x, closeTo(cw[2].x, 1e-9));
      expect(moved[2].y, closeTo(cw[2].y, 1e-9));
      expect(moved[3].x, closeTo(cw[3].x, 1e-9));
      expect(moved[3].y, closeTo(cw[3].y, 1e-9));
      expect(Geometry.polygonArea(moved), closeTo(420, 1e-9),
          reason: 'positive offset must grow it whichever way it winds');
    });

    test('the same side is chosen no matter which way the plot winds', () {
      for (var i = 0; i < 4; i++) {
        final ccw = BoundaryAdjust.offsetSides(square20, {i}, 1);
        final cw = BoundaryAdjust.offsetSides(
          square20.reversed.toList(), {i}, 1,
        );
        expect(Geometry.polygonArea(ccw), closeTo(420, 1e-9), reason: 'ccw $i');
        expect(Geometry.polygonArea(cw), closeTo(420, 1e-9), reason: 'cw $i');
      }
    });

    test('a sliver folds if pushed far, and the solver still copes', () {
      // Documents the limit of the raw operation, and that solve() does not
      // inherit it: it walks out from zero and takes the first crossing.
      const sliver = [Vertex(0, 0), Vertex(30, 0), Vertex(30, 0.4)];
      final area = Geometry.polygonArea(sliver);
      final far = Geometry.polygonArea(
        BoundaryAdjust.offsetSides(sliver, {2}, 20),
      );
      expect(far, isNot(closeTo(area + 20 * 30, area)),
          reason: 'a naive linear expectation does not hold once it folds');

      final s = BoundaryAdjust.solve(
        base: sliver, targetSqm: area * 1.2,
        kind: AdjustTargetKind.side, selection: {2},
      )!;
      expect(s.isExact, isTrue);
      expect(Geometry.polygonArea(s.vertices),
          closeTo(area * 1.2, area * 1e-5));
    });
  });

  group('degenerate input', () {
    test('too few vertices, empty selection or bad target give null', () {
      expect(
        BoundaryAdjust.solve(
          base: const [Vertex(0, 0), Vertex(1, 1)],
          targetSqm: 10,
          kind: AdjustTargetKind.side,
          selection: {0},
        ),
        isNull,
      );
      expect(
        BoundaryAdjust.solve(
          base: square20,
          targetSqm: 10,
          kind: AdjustTargetKind.side,
          selection: const {},
        ),
        isNull,
      );
      for (final bad in [0.0, -5.0, double.nan, double.infinity]) {
        expect(
          BoundaryAdjust.solve(
            base: square20,
            targetSqm: bad,
            kind: AdjustTargetKind.side,
            selection: {0},
          ),
          isNull,
          reason: '$bad',
        );
      }
    });

    test('a zero-area plot cannot be solved', () {
      const flat = [Vertex(0, 0), Vertex(1, 0), Vertex(2, 0)];
      expect(
        BoundaryAdjust.solve(
          base: flat, targetSqm: 50,
          kind: AdjustTargetKind.side, selection: {0},
        ),
        isNull,
      );
    });

    test('asking for the area it already has is a no-op', () {
      final s = BoundaryAdjust.solve(
        base: square20, targetSqm: 400,
        kind: AdjustTargetKind.side, selection: {0},
      )!;
      expect(s.offsetM, 0);
      expect(s.isExact, isTrue);
    });
  });
}
