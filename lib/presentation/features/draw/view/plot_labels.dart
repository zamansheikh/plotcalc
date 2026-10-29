import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// A label's box: centred at [center], turned by [angle] radians.
///
/// Side and diagonal lengths are turned to run along their line, the way a
/// surveyor writes them, so a label sits snugly beside its own side
/// whatever its direction. Angle labels and the canvas's own controls are
/// upright boxes ([angle] 0).
class LabelBox {
  final Offset center;
  final double angle;
  final Size size;

  const LabelBox(this.center, this.size, [this.angle = 0]);

  LabelBox.rect(Rect r) : center = r.center, size = r.size, angle = 0;

  LabelBox.circle(Offset c, double radius)
    : center = c,
      size = Size.square(radius * 2),
      angle = 0;

  LabelBox inflate(double d) =>
      LabelBox(center, Size(size.width + 2 * d, size.height + 2 * d), angle);

  /// Unit vectors along the box's width and height.
  Offset get _u => Offset(math.cos(angle), math.sin(angle));
  Offset get _v => Offset(-math.sin(angle), math.cos(angle));

  List<Offset> get corners {
    final hu = _u * (size.width / 2), hv = _v * (size.height / 2);
    return [
      center - hu - hv,
      center + hu - hv,
      center + hu + hv,
      center - hu + hv,
    ];
  }

  /// The upright rectangle around the box.
  Rect get bounds {
    final c = corners;
    var l = c[0].dx, t = c[0].dy, r = l, b = t;
    for (final p in c) {
      l = math.min(l, p.dx);
      r = math.max(r, p.dx);
      t = math.min(t, p.dy);
      b = math.max(b, p.dy);
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  bool contains(Offset p) {
    final d = p - center;
    return (_dot(d, _u)).abs() <= size.width / 2 &&
        (_dot(d, _v)).abs() <= size.height / 2;
  }

  /// Exact overlap of two turned boxes (separating axis test).
  bool overlaps(LabelBox o) {
    if (!bounds.overlaps(o.bounds)) return false;
    final a = corners, b = o.corners;
    for (final axis in [_u, _v, o._u, o._v]) {
      var minA = double.infinity, maxA = -double.infinity;
      var minB = double.infinity, maxB = -double.infinity;
      for (final p in a) {
        final x = _dot(p, axis);
        minA = math.min(minA, x);
        maxA = math.max(maxA, x);
      }
      for (final p in b) {
        final x = _dot(p, axis);
        minB = math.min(minB, x);
        maxB = math.max(maxB, x);
      }
      if (maxA <= minB || maxB <= minA) return false;
    }
    return true;
  }

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;
}

/// The direction of the line [a]→[b], turned so text along it is never
/// upside down: it reads left to right, or bottom to top when upright.
double readableAngle(Offset a, Offset b) {
  var t = math.atan2(b.dy - a.dy, b.dx - a.dx);
  // A hair's tilt off level or upright is drawn level or upright: it reads
  // better, and nobody can see the difference.
  const snap = 2.5 * math.pi / 180;
  if (t >= math.pi / 2) t -= math.pi;
  if (t < -math.pi / 2) t += math.pi;
  if (t.abs() < snap) return 0;
  if ((t + math.pi / 2).abs() < snap) return -math.pi / 2;
  if ((t - math.pi / 2).abs() < snap) return -math.pi / 2;
  return t;
}

/// Where each measurement label on a canvas goes, worked out so that no
/// label covers another, a corner handle, or the canvas's own controls.
///
/// Placement is greedy, in order of importance: side lengths first (they
/// are always shown), then diagonals, then corner angles. Each label tries a
/// list of spots, best first, and takes the first free one. A side always
/// gets a spot, since its length is the point of the screen; a diagonal or
/// an angle that finds no free spot is left out rather than piled on top of
/// something else.
///
/// The same layout serves painting and tapping, so a tap on a label always
/// hits the label the user sees.
class PlotLabelLayout {
  /// Side `i` runs from corner `i` to corner `i + 1`.
  final Map<int, LabelBox> sides;
  final Map<(int, int), LabelBox> diagonals;
  final Map<int, LabelBox> angles;

  const PlotLabelLayout._(this.sides, this.diagonals, this.angles);

  static const _handleRadius = 15.0;
  static const _gap = 3.0;

  /// [pts] are the corners in canvas coordinates. The `*Size` callbacks give
  /// each label's box (unturned). [reserved] are areas already in use:
  /// overlay buttons, other plots' labels.
  static PlotLabelLayout compute({
    required List<Offset> pts,
    required Size bounds,
    required Size Function(int i) sideSize,
    Size Function(int i, int j)? diagonalSize,
    Iterable<(int, int)> diagonalPairs = const [],
    Size Function(int i)? angleSize,
    List<LabelBox> reserved = const [],
  }) {
    final n = pts.length;
    final taken = <LabelBox>[
      for (final p in pts) LabelBox.circle(p, _handleRadius),
      ...reserved,
    ];
    final area = Offset.zero & bounds;

    bool free(LabelBox r) {
      final b = r.bounds;
      if (!area.contains(b.topLeft) || !area.contains(b.bottomRight)) {
        return false;
      }
      final g = r.inflate(_gap);
      return !taken.any((t) => t.overlaps(g));
    }

    LabelBox? first(Iterable<LabelBox> candidates) {
      for (final r in candidates) {
        if (free(r)) return r;
      }
      return null;
    }

    final c = _centroid(pts);

    // Sides: turned along the side, just outside the plot (where diagonals
    // never run), sliding along it, then a step further out.
    final sides = <int, LabelBox>{};
    for (var i = 0; i < n; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      final size = sideSize(i);
      final d = b - a;
      if (d.distance == 0) continue;
      var normal = Offset(-d.dy, d.dx) / d.distance;
      final mid = (a + b) / 2;
      // Point the normal away from the plot's middle: that is outside.
      if (_dot(mid - c, normal) < 0) normal = -normal;
      final angle = readableAngle(a, b);
      // Turned with its line, the box's depth across the line is its height
      // (or its width, for the rare side snapped upright from a slant).
      final across =
          (math.cos(angle) * normal.dy - math.sin(angle) * normal.dx).abs() *
              size.height /
              2 +
          (math.cos(angle) * normal.dx + math.sin(angle) * normal.dy).abs() *
              size.width /
              2;
      final away = across + 4;
      Iterable<LabelBox> spots() sync* {
        for (var ring = 0; ring < 3; ring++) {
          for (final t in const [0.5, 0.38, 0.62, 0.28, 0.72, 0.2, 0.8]) {
            final at = Offset.lerp(a, b, t)!;
            for (final side in ring == 0 ? const [1.0, -1.0] : const [1.0]) {
              yield LabelBox(
                at + normal * (away + ring * (2 * across + 4)) * side,
                size,
                angle,
              );
            }
          }
        }
      }

      // A side's length is essential: when nothing is free at all, it
      // still goes at its preferred spot.
      final r = first(spots()) ?? LabelBox(mid + normal * away, size, angle);
      sides[i] = r;
      taken.add(r);
    }

    // Diagonals: turned along the line and on it (the pill hides the
    // dashes under it), sliding along it and then off to either side.
    final diagonals = <(int, int), LabelBox>{};
    if (diagonalSize != null) {
      for (final (i, j) in diagonalPairs) {
        final a = pts[i], b = pts[j];
        final size = diagonalSize(i, j);
        final d = b - a;
        if (d.distance == 0) continue;
        final normal = Offset(-d.dy, d.dx) / d.distance;
        final angle = readableAngle(a, b);
        Iterable<LabelBox> spots() sync* {
          for (final t in const [
            0.5,
            0.42,
            0.58,
            0.34,
            0.66,
            0.26,
            0.74,
            0.18,
            0.82,
          ]) {
            final at = Offset.lerp(a, b, t)!;
            for (final off in [0.0, size.height + 2, -size.height - 2]) {
              yield LabelBox(at + normal * off, size, angle);
            }
          }
        }

        final r = first(spots());
        if (r != null) {
          diagonals[(i, j)] = r;
          taken.add(r);
        }
      }
    }

    // Angles: upright, outside each corner, along the line that splits it.
    final angles = <int, LabelBox>{};
    if (angleSize != null) {
      for (var i = 0; i < n; i++) {
        final p = pts[i];
        final size = angleSize(i);
        final u1 = _unit(p - pts[(i - 1 + n) % n]);
        final u2 = _unit(p - pts[(i + 1) % n]);
        var out = _unit(u1 + u2);
        if (out == Offset.zero) out = _unit(p - c);
        // A reflex corner's split line points into the plot: turn it round.
        if (_inside(pts, p + out * 4)) out = -out;
        Iterable<LabelBox> spots() sync* {
          for (final dir in [
            out,
            const Offset(0, -1),
            const Offset(0, 1),
            const Offset(-1, 0),
            const Offset(1, 0),
          ]) {
            final d = _clearance(dir, size);
            for (final extra in const [0.0, 10.0]) {
              yield LabelBox(p + dir * (d + extra), size);
            }
          }
        }

        final r = first(spots());
        if (r != null) {
          angles[i] = r;
          taken.add(r);
        }
      }
    }

    return PlotLabelLayout._(sides, diagonals, angles);
  }

  /// The side whose label is under [p], if any.
  int? sideAt(Offset p) {
    for (final e in sides.entries) {
      if (e.value.inflate(6).contains(p)) return e.key;
    }
    return null;
  }

  /// The diagonal whose label is under [p], if any.
  (int, int)? diagonalAt(Offset p) {
    for (final e in diagonals.entries) {
      if (e.value.inflate(6).contains(p)) return e.key;
    }
    return null;
  }

  /// Every placed label, for checks.
  Iterable<LabelBox> get all => [
    ...sides.values,
    ...diagonals.values,
    ...angles.values,
  ];

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  /// How far along [dir] an upright label of [size] must sit to clear its
  /// corner's handle, with the usual gap: the nearest the label can come.
  static double _clearance(Offset dir, Size size) {
    const reach = _handleRadius + _gap + 1;
    final ux = dir.dx.abs(), uy = dir.dy.abs();
    final alongX = ux < 1e-6 ? double.infinity : (size.width / 2 + reach) / ux;
    final alongY = uy < 1e-6 ? double.infinity : (size.height / 2 + reach) / uy;
    return alongX < alongY ? alongX : alongY;
  }

  static Offset _unit(Offset v) =>
      v.distance == 0 ? Offset.zero : v / v.distance;

  static Offset _centroid(List<Offset> pts) {
    var x = 0.0, y = 0.0;
    for (final p in pts) {
      x += p.dx;
      y += p.dy;
    }
    return pts.isEmpty ? Offset.zero : Offset(x / pts.length, y / pts.length);
  }

  static bool _inside(List<Offset> poly, Offset p) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i], b = poly[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// Measures a label pill: the text plus a little padding.
Size labelPillSize(String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return Size(tp.width + 10, tp.height + 4);
}

/// Draws a label pill in [box], turned with it.
void paintLabelPill(
  Canvas canvas,
  LabelBox box,
  String text, {
  required TextStyle style,
  required Color fill,
  required Color border,
  double borderWidth = 0.8,
}) {
  canvas
    ..save()
    ..translate(box.center.dx, box.center.dy)
    ..rotate(box.angle);
  final rr = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset.zero,
      width: box.size.width,
      height: box.size.height,
    ),
    const Radius.circular(5),
  );
  canvas
    ..drawRRect(rr, Paint()..color = fill)
    ..drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = border,
    );
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  canvas.restore();
}

/// Draws the length of every side of the outline through [pts] (canvas
/// coordinates), each turned along its side and placed by
/// [PlotLabelLayout]: just outside the plot, never on top of each other, a
/// corner, or anything in [reserved]. Returns the boxes it used, so the
/// next outline drawn can keep clear of them too.
///
/// With only two points (an outline still being tapped) the one side is
/// labelled beside its middle.
List<LabelBox> paintSideLengths(
  Canvas canvas,
  List<Offset> pts, {
  required String Function(int i) text,
  required TextStyle style,
  required Color fill,
  required Color border,
  required Size bounds,
  List<LabelBox> reserved = const [],
}) {
  final n = pts.length;
  if (n < 2) return const [];
  final placed = <int, LabelBox>{};
  if (n == 2) {
    final d = pts[1] - pts[0];
    if (d.distance == 0) return const [];
    final size = labelPillSize(text(0), style);
    final normal = Offset(-d.dy, d.dx) / d.distance;
    placed[0] = LabelBox(
      (pts[0] + pts[1]) / 2 + normal * (size.height / 2 + 4),
      size,
      readableAngle(pts[0], pts[1]),
    );
  } else {
    placed.addAll(
      PlotLabelLayout.compute(
        pts: pts,
        bounds: bounds,
        sideSize: (i) => labelPillSize(text(i), style),
        reserved: reserved,
      ).sides,
    );
  }
  for (final e in placed.entries) {
    paintLabelPill(
      canvas,
      e.value,
      text(e.key),
      style: style,
      fill: fill,
      border: border,
    );
  }
  return placed.values.toList();
}
