import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/map_align.dart';
import 'package:plotcalc/core/geometry/polygon_overlap.dart';

/// A made-up "RS sheet": the CS sheet turned 3°, shrunk unevenly (paper
/// shrinks more one way than the other), shifted, and photographed with a
/// little tilt. [truth] maps CS pixels to RS pixels.
const _h = [
  0.985, -0.06, 140.0, //
  0.045, 0.962, -60.0, //
  0.000004, -0.000003, 1.0,
];
final truth = PlaneTransform(_h);

Offset csToRs(Offset p) => truth.apply(p);

void main() {
  group('alignment', () {
    // Spread over a 4000 × 3000 sheet, as the user is told to spread them.
    const cs = [
      Offset(400, 300),
      Offset(3600, 350),
      Offset(3500, 2700),
      Offset(500, 2600),
      Offset(2000, 1500),
      Offset(1200, 900),
    ];

    List<(Offset, Offset)> pairs(int n) => [
      for (var i = 0; i < n; i++) (cs[i], csToRs(cs[i])),
    ];

    test('fewer than two pairs fits nothing', () {
      expect(MapAlignment.fit(const []), isNull);
      expect(MapAlignment.fit([pairs(1).first]), isNull);
    });

    test('two pairs: shift, turn and scale, exactly through both', () {
      final a = MapAlignment.fit(pairs(2))!;
      expect(a.model, AlignModel.similarity);
      expect(a.checkable, isFalse);
      expect(a.quality(4000), AlignQuality.unchecked);
      for (final (p, q) in pairs(2)) {
        expect((a.bToA.apply(q) - p).distance, lessThan(1e-6));
      }
    });

    test('four pairs: uneven stretch, and the pairs check each other', () {
      final a = MapAlignment.fit(pairs(4))!;
      expect(a.model, AlignModel.affine);
      expect(a.checkable, isTrue);
      // An affine fit cannot follow the photo's tilt, but stays within a
      // few pixels of it: fair, and nothing to blame on a single pair.
      expect(a.rms, lessThan(12));
      expect(a.quality(4000), isNot(AlignQuality.poor));
      expect(a.suspect(4000), isNull);
    });

    test('six pairs recover the tilt too, to the pixel', () {
      final a = MapAlignment.fit(pairs(6))!;
      expect(a.model, AlignModel.projective);
      expect(a.rms, lessThan(0.01));
      // Anywhere on the sheet, not just at the pairs.
      for (final p in const [Offset(3000, 2000), Offset(800, 2200)]) {
        expect((a.bToA.apply(csToRs(p)) - p).distance, lessThan(0.05));
      }
    });

    test('with four pairs a bad one shows, but cannot be named', () {
      final ps = pairs(4);
      ps[2] = (ps[2].$1, ps[2].$2 + const Offset(90, 40));
      final a = MapAlignment.fit(ps)!;
      expect(a.quality(4000), AlignQuality.poor);
      expect(a.suspect(4000), isNull);
    });

    test('one mistapped pair stands out', () {
      final ps = pairs(6);
      // Pair 3's RS point was put 90 px off — a neighbouring road crossing.
      ps[3] = (ps[3].$1, ps[3].$2 + const Offset(90, 40));
      final a = MapAlignment.fit(ps)!;
      expect(a.suspect(4000), 3);
      expect(a.quality(4000), isNot(AlignQuality.good));
    });

    test('the inverse goes back', () {
      final a = MapAlignment.fit(pairs(6))!;
      final inv = a.bToA.inverse();
      const p = Offset(1234, 2345);
      expect((inv.apply(a.bToA.apply(p)) - p).distance, lessThan(1e-6));
    });

    test('matrix for the canvas matches apply()', () {
      final a = MapAlignment.fit(pairs(6))!;
      final m = a.bToA.toMatrix4();
      const p = Offset(700, 800);
      // Column-major 4×4 applied to (x, y, 0, 1).
      final x = m[0] * p.dx + m[4] * p.dy + m[12];
      final y = m[1] * p.dx + m[5] * p.dy + m[13];
      final w = m[3] * p.dx + m[7] * p.dy + m[15];
      final q = a.bToA.apply(p);
      expect(x / w, closeTo(q.dx, 1e-6));
      expect(y / w, closeTo(q.dy, 1e-6));
    });

    test('local scale reflects shrinkage', () {
      final a = MapAlignment.fit(pairs(6))!;
      // RS is about 3% smaller, so one RS pixel is about 1.03 CS pixels.
      expect(a.bToA.localScale(const Offset(2000, 1500)), closeTo(1.03, 0.02));
    });
  });

  group('overlap', () {
    const square = [Offset(0, 0), Offset(10, 0), Offset(10, 10), Offset(0, 10)];

    test('half of a square overlapping another', () {
      const shifted = [
        Offset(5, 0),
        Offset(15, 0),
        Offset(15, 10),
        Offset(5, 10),
      ];
      expect(
        PolygonOverlap.intersectionArea(square, shifted),
        closeTo(50, 1e-9),
      );
    });

    test('winding does not matter', () {
      final reversed = square.reversed.toList();
      expect(
        PolygonOverlap.intersectionArea(reversed, square),
        closeTo(100, 1e-9),
      );
      expect(
        PolygonOverlap.intersectionArea(square, reversed),
        closeTo(100, 1e-9),
      );
    });

    test('apart is zero, inside is all of the smaller', () {
      const far = [Offset(20, 20), Offset(30, 20), Offset(30, 30)];
      const inner = [Offset(2, 2), Offset(4, 2), Offset(4, 4), Offset(2, 4)];
      expect(PolygonOverlap.intersectionArea(square, far), 0);
      expect(PolygonOverlap.intersectionArea(square, inner), closeTo(4, 1e-9));
      expect(PolygonOverlap.intersectionArea(inner, square), closeTo(4, 1e-9));
    });

    test('concave outlines, either way round', () {
      // An L of area 300 inside a 20 × 20 square.
      const ell = [
        Offset(0, 0),
        Offset(20, 0),
        Offset(20, 10),
        Offset(10, 10),
        Offset(10, 20),
        Offset(0, 20),
      ];
      const big = [Offset(0, 0), Offset(20, 0), Offset(20, 20), Offset(0, 20)];
      // A strip across the middle, 20 × 6, crossing both arms of the L.
      const strip = [
        Offset(-5, 7),
        Offset(25, 7),
        Offset(25, 13),
        Offset(-5, 13),
      ];
      expect(PolygonOverlap.area(ell), 300);
      expect(PolygonOverlap.intersectionArea(ell, big), closeTo(300, 1e-9));
      expect(PolygonOverlap.intersectionArea(big, ell), closeTo(300, 1e-9));
      // Strip ∩ L: rows 7–10 full width (20 × 3) + rows 10–13 left arm
      // (10 × 3) = 90.
      expect(PolygonOverlap.intersectionArea(ell, strip), closeTo(90, 1e-9));
      expect(PolygonOverlap.intersectionArea(strip, ell), closeTo(90, 1e-9));
    });

    test('triangles of a concave polygon add up to it', () {
      const star = [
        Offset(0, 10),
        Offset(4, 4),
        Offset(10, 0),
        Offset(4, -4),
        Offset(0, -10),
        Offset(-4, -4),
        Offset(-10, 0),
        Offset(-4, 4),
      ];
      final tris = PolygonOverlap.triangulate(star);
      expect(tris.length, star.length - 2);
      final sum = tris.fold<double>(0, (s, t) => s + PolygonOverlap.area(t));
      expect(sum, closeTo(PolygonOverlap.area(star), 1e-9));
    });

    test('random overlaps never exceed either area', () {
      final rnd = math.Random(7);
      List<Offset> blob() {
        final cx = rnd.nextDouble() * 50, cy = rnd.nextDouble() * 50;
        final n = 3 + rnd.nextInt(6);
        return [
          for (var i = 0; i < n; i++)
            Offset(
              cx + (8 + rnd.nextDouble() * 12) * math.cos(i * 2 * math.pi / n),
              cy + (8 + rnd.nextDouble() * 12) * math.sin(i * 2 * math.pi / n),
            ),
        ];
      }

      for (var k = 0; k < 200; k++) {
        final a = blob(), b = blob();
        final o = PolygonOverlap.intersectionArea(a, b);
        expect(o, lessThanOrEqualTo(PolygonOverlap.area(a) + 1e-6));
        expect(o, lessThanOrEqualTo(PolygonOverlap.area(b) + 1e-6));
        expect(
          o,
          closeTo(PolygonOverlap.intersectionArea(b, a), 1e-6),
          reason: 'symmetric',
        );
      }
    });
  });
}
