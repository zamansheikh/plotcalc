import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/presentation/features/draw/view/plot_labels.dart';

/// Every diagonal of an n-gon, as (i, j) with i < j.
Iterable<(int, int)> diagonals(int n) sync* {
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (j != i + 1 && !(i == 0 && j == n - 1)) yield (i, j);
    }
  }
}

PlotLabelLayout layoutOf(
  List<Offset> pts, {
  Size bounds = const Size(700, 900),
}) => PlotLabelLayout.compute(
  pts: pts,
  bounds: bounds,
  sideSize: (_) => const Size(72, 18),
  diagonalPairs: diagonals(pts.length),
  diagonalSize: (_, _) => const Size(66, 16),
  angleSize: (_) => const Size(28, 14),
  reserved: [LabelBox.rect(const Rect.fromLTWH(0, 0, 64, 64))],
);

void expectNoOverlaps(PlotLabelLayout l, List<Offset> pts) {
  final all = l.all.toList();
  for (var a = 0; a < all.length; a++) {
    for (var b = a + 1; b < all.length; b++) {
      expect(
        all[a].overlaps(all[b]),
        isFalse,
        reason: 'labels ${all[a]} and ${all[b]} overlap',
      );
    }
    for (final p in pts) {
      expect(
        all[a].overlaps(LabelBox.circle(p, 12)),
        isFalse,
        reason: 'label ${all[a]} covers the corner at $p',
      );
    }
  }
}

void main() {
  // The five-sided plot from the report: three diagonals crossing near the
  // middle used to stack their labels on one spot.
  const reported = [
    Offset(128, 360),
    Offset(550, 320),
    Offset(635, 635),
    Offset(483, 618),
    Offset(108, 698),
  ];

  test('the reported plot: no label overlaps another or a corner', () {
    final l = layoutOf(reported);
    expect(l.sides.length, 5, reason: 'every side is labelled');
    expect(l.diagonals.length, 5, reason: 'room for all five diagonals');
    expectNoOverlaps(l, reported);
  });

  test('a crowded eight-sided plot still never overlaps', () {
    final pts = [
      for (var i = 0; i < 8; i++)
        Offset(
          350 + 160 * math.cos(i * math.pi / 4),
          450 + 160 * math.sin(i * math.pi / 4),
        ),
    ];
    final l = layoutOf(pts);
    expect(l.sides.length, 8);
    // Twenty diagonals cannot all fit; those that do must not collide.
    expect(l.diagonals, isNotEmpty);
    expectNoOverlaps(l, pts);
  });

  test('side labels sit outside the plot when there is room', () {
    const square = [
      Offset(200, 200),
      Offset(500, 200),
      Offset(500, 500),
      Offset(200, 500),
    ];
    final l = layoutOf(square);
    final inside = const Rect.fromLTRB(200, 200, 500, 500);
    for (final r in l.sides.values) {
      expect(inside.contains(r.center), isFalse);
    }
  });

  test('labels beside an upright side clear the plot entirely', () {
    // A tall, narrow plot: a wide label beside its long sides used to stick
    // into the plot and cover its name.
    const tall = [
      Offset(300, 200),
      Offset(360, 200),
      Offset(360, 600),
      Offset(300, 600),
    ];
    final l = PlotLabelLayout.compute(
      pts: tall,
      bounds: const Size(700, 900),
      sideSize: (_) => const Size(110, 18),
    );
    const inside = Rect.fromLTRB(300, 200, 360, 600);
    for (final i in [1, 3]) {
      expect(
        l.sides[i]!.overlaps(LabelBox.rect(inside)),
        isFalse,
        reason: 'side $i',
      );
    }
  });

  test('a reflex corner gets its angle outside the plot', () {
    // An L shape: the corner at (300, 300) points into the plot.
    const ell = [
      Offset(150, 150),
      Offset(450, 150),
      Offset(450, 300),
      Offset(300, 300),
      Offset(300, 450),
      Offset(150, 450),
    ];
    final l = layoutOf(ell);
    final angle = l.angles[3]!;
    // Outside the L means the empty square to the bottom right.
    expect(angle.center.dx, greaterThan(300));
    expect(angle.center.dy, greaterThan(300));
  });

  test('taps find the label that is drawn', () {
    final l = layoutOf(reported);
    for (final e in l.sides.entries) {
      expect(l.sideAt(e.value.center), e.key);
    }
    for (final e in l.diagonals.entries) {
      expect(l.diagonalAt(e.value.center), e.key);
    }
    expect(l.sideAt(const Offset(-50, -50)), isNull);
  });

  test('labels stay out of the reserved corner and on the canvas', () {
    final l = layoutOf(reported);
    const reserved = Rect.fromLTWH(0, 0, 64, 64);
    const canvas = Rect.fromLTWH(0, 0, 700, 900);
    for (final r in l.all) {
      expect(r.overlaps(LabelBox.rect(reserved)), isFalse);
      final b = r.bounds;
      expect(
        canvas.contains(b.topLeft) && canvas.contains(b.bottomRight),
        isTrue,
      );
    }
  });

  group('turned labels', () {
    test('lengths run along their side and never read upside down', () {
      const quad = [
        Offset(200, 200),
        Offset(480, 260),
        Offset(430, 560),
        Offset(180, 470),
      ];
      final l = layoutOf(quad);
      for (final e in l.sides.entries) {
        final a = quad[e.key], b = quad[(e.key + 1) % quad.length];
        final along = math.atan2(b.dy - a.dy, b.dx - a.dx);
        final angle = e.value.angle;
        final diff = (angle - along) % math.pi;
        expect(
          math.min(diff, math.pi - diff),
          lessThan(1e-9),
          reason: 'side ${e.key} is turned with its side',
        );
        expect(angle, greaterThanOrEqualTo(-math.pi / 2));
        expect(angle, lessThan(math.pi / 2));
      }
    });

    test('an upright side reads bottom to top; near-level reads level', () {
      expect(
        readableAngle(const Offset(0, 0), const Offset(0, 100)),
        closeTo(-math.pi / 2, 1e-9),
      );
      expect(
        readableAngle(const Offset(0, 100), const Offset(0, 0)),
        closeTo(-math.pi / 2, 1e-9),
      );
      expect(readableAngle(const Offset(100, 0), const Offset(0, 0)), 0);
      expect(readableAngle(const Offset(0, 0), const Offset(100, 2)), 0);
    });

    test('a turned label sits right beside its line', () {
      const sq = [
        Offset(200, 200),
        Offset(500, 300),
        Offset(450, 600),
        Offset(150, 500),
      ];
      final l = layoutOf(sq);
      final box = l.sides[0]!;
      final a = sq[0], b = sq[1];
      final d = (b - a) / (b - a).distance;
      final n = Offset(-d.dy, d.dx);
      final c = box.center - a;
      final dist = (c.dx * n.dx + c.dy * n.dy).abs();
      expect(dist, lessThan(box.size.height / 2 + 8));
    });

    test('turned boxes overlap exactly, not by their upright bounds', () {
      const a = LabelBox(Offset(100, 100), Size(120, 16), math.pi / 4);
      const b = LabelBox(Offset(120, 80), Size(120, 16), math.pi / 4);
      expect(a.bounds.overlaps(b.bounds), isTrue);
      expect(a.overlaps(b), isFalse);
      const c = LabelBox(Offset(105, 100), Size(120, 16), -math.pi / 4);
      expect(a.overlaps(c), isTrue, reason: 'crossing boxes');
      expect(a.contains(const Offset(100, 100)), isTrue);
      expect(a.contains(const Offset(100, 130)), isFalse);
    });
  });
}
