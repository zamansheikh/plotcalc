import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/lot_division.dart';
import 'package:plotcalc/core/geometry/vertex.dart';

/// Lot boundaries end up in deeds, so "lot 1 is 3 shotok" has to be true of
/// the piece drawn, not just of the instruction that produced it.

const square = [
  Vertex(0, 0),
  Vertex(30, 0),
  Vertex(30, 20),
  Vertex(0, 20),
];

/// A triangle: half its width is nowhere near half its area, which is what
/// makes cutting by width wrong.
const triangle = [
  Vertex(0, 0),
  Vertex(40, 0),
  Vertex(0, 30),
];

/// A "C": a vertical cut crosses it four times.
const cShape = [
  Vertex(0, 0), Vertex(30, 0), Vertex(30, 8), Vertex(10, 8),
  Vertex(10, 20), Vertex(30, 20), Vertex(30, 28), Vertex(0, 28),
];

List<Vertex> simplePolygon(Random rnd, {required bool convex}) {
  final n = (convex ? 3 : 4) + rnd.nextInt(5);
  final pts = List.generate(n, (_) {
    final a = rnd.nextDouble() * 2 * pi;
    final r = convex ? 30.0 : 30 * (0.3 + rnd.nextDouble() * 1.4);
    return Vertex(cos(a) * r, sin(a) * r);
  });
  // Angle-sorted about their own centroid, so the outline never crosses
  // itself — a self-intersecting polygon has no meaningful area at all.
  final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / n;
  final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / n;
  pts.sort(
    (p, q) => atan2(p.y - cy, p.x - cx).compareTo(atan2(q.y - cy, q.x - cx)),
  );
  return pts;
}

void main() {
  group('cuts land on area, not on width', () {
    test('half a triangle by area is not half its width', () {
      final total = Geometry.polygonArea(triangle);
      final cut = LotDivision.offsetForArea(triangle, 0, total / 2);
      final (minX, _, maxX, _) = Geometry.bbox(triangle);
      final midWidth = (minX + maxX) / 2;

      expect(LotDivision.areaBefore(triangle, 0, cut), closeTo(total / 2, 1e-6));
      // The old behaviour cut at the middle of the bounding box, which on
      // this triangle hands over 75% of the land.
      expect((cut - midWidth).abs(), greaterThan(1),
          reason: 'an area cut and a width cut are different places');
      expect(
        LotDivision.areaBefore(triangle, 0, midWidth) / total,
        closeTo(0.75, 0.01),
        reason: 'cutting by width would have given lot 1 three quarters',
      );
    });

    test('on a rectangle the two happen to agree', () {
      final total = Geometry.polygonArea(square);
      final cut = LotDivision.offsetForArea(square, 0, total / 2);
      expect(cut, closeTo(15, 1e-6));
    });
  });

  group('lots get the land they were promised', () {
    test('an equal split of a triangle really is equal', () {
      final total = Geometry.polygonArea(triangle);
      final lots = LotDivision.divide(triangle, LotDivision.equalShares(3));
      for (final l in lots) {
        expect(l.areaSqm, closeTo(total / 3, total * 1e-6));
      }
    });

    test('the 5 shotok story: 3 and 2', () {
      // Total 600; lot 1 wants 360, lot 2 wants 240.
      final lots = LotDivision.divide(square, [3, 2]);
      expect(lots[0].areaSqm, closeTo(360, 1e-6));
      expect(lots[1].areaSqm, closeTo(240, 1e-6));
    });

    test('shares can be given as percentages or as areas alike', () {
      final byPercent = LotDivision.divide(square, [0.6, 0.4]);
      final byArea = LotDivision.divide(square, [360, 240]);
      for (var i = 0; i < 2; i++) {
        expect(byArea[i].areaSqm, closeTo(byPercent[i].areaSqm, 1e-9));
      }
    });

    test('nothing is lost or double counted', () {
      final total = Geometry.polygonArea(cShape);
      for (final shares in [
        [1.0, 1.0],
        [1.0, 2.0, 3.0],
        [0.1, 0.2, 0.3, 0.4],
      ]) {
        final lots = LotDivision.divide(cShape, shares);
        final sum = lots.fold<double>(0, (a, l) => a + l.areaSqm);
        expect(sum, closeTo(total, total * 1e-6), reason: '$shares');
      }
    });

    test('it works where a cut crosses the plot four times', () {
      final total = Geometry.polygonArea(cShape);
      final lots = LotDivision.divide(cShape, [1, 1]);
      expect(lots[0].areaSqm, closeTo(total / 2, total * 1e-6));
      expect(lots[1].areaSqm, closeTo(total / 2, total * 1e-6));
    });

    test('6k random plots x 2-6 lots all land on their target', () {
      final rnd = Random(13);
      final failures = <String>[];
      var worst = 0.0;

      for (final convex in [true, false]) {
        for (var t = 0; t < 3000; t++) {
          final poly = simplePolygon(rnd, convex: convex);
          final total = Geometry.polygonArea(poly);
          if (total <= 1) continue;

          final n = 2 + rnd.nextInt(5);
          final shares = List.generate(n, (_) => 0.1 + rnd.nextDouble());
          final sum = shares.fold<double>(0, (a, b) => a + b);
          final lots = LotDivision.divide(poly, shares);
          expect(lots.length, n);

          var accounted = 0.0;
          for (var i = 0; i < n; i++) {
            final want = total * shares[i] / sum;
            final rel = (lots[i].areaSqm - want).abs() / total;
            accounted += lots[i].areaSqm;
            if (rel > worst) worst = rel;
            if (rel > 1e-6) failures.add('lot $i off by $rel');
          }
          if ((accounted - total).abs() / total > 1e-6) {
            failures.add('total drift');
          }
        }
      }

      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
      expect(worst, lessThan(1e-6));
    });
  });

  group('dragging a boundary', () {
    test('moves land between its two neighbours only', () {
      final shares = [0.25, 0.25, 0.5];
      final lines = LotDivision.cutLines(square, shares);
      // Slide the first divider to the right.
      final moved = LotDivision.sharesAfterMove(
        square, shares, null, 0, Vertex(lines[0].a.x + 5, 0),
      );
      expect(moved[0], greaterThan(shares[0]));
      expect(moved[1], lessThan(shares[1]));
      expect(moved[2], closeTo(shares[2], 1e-9),
          reason: 'the far lot keeps the land it already had');
      expect(moved.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-9));
    });

    test('a lot cannot be dragged out of existence', () {
      final shares = [0.5, 0.5];
      final moved = LotDivision.sharesAfterMove(
        square, shares, null, 0, const Vertex(1e6, 0),
      );
      expect(moved[1], greaterThan(0));
      expect(moved.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-9));
    });

    test('dragging a cut that does not exist changes nothing', () {
      final shares = [0.5, 0.5];
      expect(
        LotDivision.sharesAfterMove(square, shares, null, 5, const Vertex(10, 0)),
        shares,
      );
      expect(
        LotDivision.sharesAfterMove(square, shares, null, -1, const Vertex(10, 0)),
        shares,
      );
    });
  });

  group('degenerate input', () {
    test('too few vertices, no shares, or zero area give nothing', () {
      expect(LotDivision.divide(const [Vertex(0, 0)], [1]), isEmpty);
      expect(LotDivision.divide(square, const []), isEmpty);
      expect(
        LotDivision.divide(
          const [Vertex(0, 0), Vertex(1, 0), Vertex(2, 0)],
          [1, 1],
        ),
        isEmpty,
      );
    });

    test('shares that are zero, negative or not finite are ignored', () {
      final lots = LotDivision.divide(square, [1, 0, -3, double.nan, 1]);
      expect(lots.length, 5);
      final total = Geometry.polygonArea(square);
      // The two usable shares split it; the rest take nothing.
      expect(lots[0].areaSqm, closeTo(total / 2, 1e-6));
      expect(lots.last.areaSqm, closeTo(total / 2, 1e-6));
    });

    test('a single lot is the whole plot', () {
      final lots = LotDivision.divide(square, [1]);
      expect(lots.single.areaSqm, closeTo(Geometry.polygonArea(square), 1e-9));
    });

    test('equalShares always sums to one', () {
      for (var n = 1; n <= 12; n++) {
        expect(
          LotDivision.equalShares(n).fold<double>(0, (a, b) => a + b),
          closeTo(1, 1e-12),
        );
      }
    });
  });

  group('a divider at any angle', () {
    // A boundary is a chord, not a vertical line — the whole point of being
    // able to drag one end.

    test('the area holds whichever way the divider is turned', () {
      final total = Geometry.polygonArea(square);
      for (var deg = 0; deg < 360; deg += 15) {
        final angle = deg * pi / 180;
        final lots = LotDivision.divide(square, [1, 1], angles: [angle]);
        expect(lots[0].areaSqm, closeTo(total / 2, total * 1e-6),
            reason: 'at $deg degrees');
        expect(lots[1].areaSqm, closeTo(total / 2, total * 1e-6),
            reason: 'at $deg degrees');
      }
    });

    test('an uneven split holds at an angle too', () {
      final total = Geometry.polygonArea(triangle);
      final lots = LotDivision.divide(
        triangle, [3, 2], angles: [0.7],
      );
      expect(lots[0].areaSqm, closeTo(total * 0.6, total * 1e-6));
      expect(lots[1].areaSqm, closeTo(total * 0.4, total * 1e-6));
    });

    test('each divider can take its own angle', () {
      final total = Geometry.polygonArea(square);
      final lots = LotDivision.divide(
        square, [1, 1, 1], angles: [0.0, 1.1],
      );
      for (final l in lots) {
        expect(l.areaSqm, closeTo(total / 3, total * 1e-6));
      }
    });

    test('the divider is reported where it meets the plot', () {
      final lines = LotDivision.cutLines(square, [1, 1]);
      expect(lines.length, 1);
      // A vertical cut across a 30x20 rectangle spans its full height.
      expect(lines.single.lengthM, closeTo(20, 1e-6));
      expect(lines.single.a.x, closeTo(15, 1e-6));
      expect(lines.single.b.x, closeTo(15, 1e-6));
    });

    test('turning the divider makes it longer than the straight one', () {
      final straight = LotDivision.cutLines(square, [1, 1]).single;
      final tilted = LotDivision.cutLines(
        square, [1, 1], angles: [0.6],
      ).single;
      expect(tilted.lengthM, greaterThan(straight.lengthM));
    });

    test('pivoting about one end aims the line at the dragged point', () {
      const fixed = Vertex(0, 0);
      // Dragging straight up should give a vertical line, i.e. angle 0
      // in the normal-facing convention this uses.
      final angle = LotDivision.angleAfterDrag(fixed, const Vertex(0, 10));
      final lots = LotDivision.divide(square, [1, 1], angles: [angle]);
      final total = Geometry.polygonArea(square);
      expect(lots[0].areaSqm, closeTo(total / 2, total * 1e-6),
          reason: 'the area is kept whatever the pivot did');
    });

    test('dragging both ends onto each other does not break it', () {
      const p = Vertex(4, 4);
      final angle = LotDivision.angleAfterDrag(p, p);
      expect(angle, LotDivision.defaultAngle);
      final lots = LotDivision.divide(square, [1, 1], angles: [angle]);
      expect(lots.length, 2);
      expect(lots.every((l) => l.areaSqm.isFinite), isTrue);
    });

    test('6k random plots at random angles keep every promise', () {
      final rnd = Random(17);
      final failures = <String>[];
      for (final convex in [true, false]) {
        for (var t = 0; t < 3000; t++) {
          final poly = simplePolygon(rnd, convex: convex);
          final total = Geometry.polygonArea(poly);
          if (total <= 1) continue;
          final n = 2 + rnd.nextInt(4);
          final shares = List.generate(n, (_) => 0.15 + rnd.nextDouble());
          final angles = List.generate(n - 1, (_) => rnd.nextDouble() * 2 * pi);
          final sum = shares.fold<double>(0, (a, b) => a + b);
          final lots = LotDivision.divide(poly, shares, angles: angles);

          var accounted = 0.0;
          for (var i = 0; i < n; i++) {
            final want = total * shares[i] / sum;
            accounted += lots[i].areaSqm;
            if ((lots[i].areaSqm - want).abs() / total > 1e-6) {
              failures.add('lot $i');
            }
          }
          if ((accounted - total).abs() / total > 1e-6) failures.add('drift');
          for (final line in LotDivision.cutLines(
            poly, shares, angles: angles,
          )) {
            if (line.lengthM <= 0) failures.add('zero-length divider');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
    });
  });

  group('a side cut by a divider reads as its pieces', () {
    // A divider landing halfway along a 25 ft boundary makes it two 12.5 ft
    // boundaries. Quoting the original 25 describes a line no lot has.

    test('a middle divider splits a side evenly', () {
      const a = Vertex(0, 0);
      const b = Vertex(25, 0);
      final parts = LotDivision.splitEdge(a, b, [const Vertex(12.5, 0)]);
      expect(parts.length, 2);
      expect(Geometry.sideLength(parts[0].$1, parts[0].$2), closeTo(12.5, 1e-9));
      expect(Geometry.sideLength(parts[1].$1, parts[1].$2), closeTo(12.5, 1e-9));
    });

    test('the pieces still add up to the whole side', () {
      const a = Vertex(0, 0);
      const b = Vertex(30, 40); // length 50
      final parts = LotDivision.splitEdge(
        a, b, [const Vertex(9, 12), const Vertex(21, 28)],
      );
      expect(parts.length, 3);
      final sum = parts.fold<double>(
        0,
        (t, p) => t + Geometry.sideLength(p.$1, p.$2),
      );
      expect(sum, closeTo(50, 1e-9));
    });

    test('an untouched side stays one piece', () {
      const a = Vertex(0, 0);
      const b = Vertex(25, 0);
      final parts = LotDivision.splitEdge(a, b, [const Vertex(60, 0)]);
      expect(parts.length, 1);
      expect(Geometry.sideLength(parts.single.$1, parts.single.$2), 25);
    });

    test('a point near the line but not on it does not split it', () {
      const a = Vertex(0, 0);
      const b = Vertex(25, 0);
      final parts = LotDivision.splitEdge(a, b, [const Vertex(12.5, 4)]);
      expect(parts.length, 1, reason: 'that point is not on this side');
    });

    test('a divider landing exactly on a corner does not split', () {
      const a = Vertex(0, 0);
      const b = Vertex(25, 0);
      final parts = LotDivision.splitEdge(a, b, [a, b]);
      expect(parts.length, 1);
    });

    test('a zero-length side yields nothing rather than dividing by zero', () {
      const a = Vertex(4, 4);
      expect(LotDivision.splitEdge(a, a, [a]), isEmpty);
    });

    test('the real case: the divider ends land on the plot sides', () {
      // 30x20 split down the middle: two sides get cut in half.
      final line = LotDivision.cutLines(square, [1, 1]).single;
      final ends = [line.a, line.b];
      var halves = 0;
      for (var i = 0; i < square.length; i++) {
        final parts = LotDivision.splitEdge(
          square[i],
          square[(i + 1) % square.length],
          ends,
        );
        if (parts.length == 2) {
          halves++;
          for (final p in parts) {
            expect(Geometry.sideLength(p.$1, p.$2), closeTo(15, 1e-6));
          }
        }
      }
      expect(halves, 2, reason: 'top and bottom are each cut in half');
    });
  });
}
