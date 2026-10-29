import 'package:flutter/painting.dart';

/// Where each measurement label on the drawing canvas goes, worked out so
/// that no label covers another, a corner handle, or the canvas's own
/// buttons.
///
/// Placement is greedy, in order of importance: side lengths first (they
/// are always shown), then diagonals, then corner angles. Each label tries a
/// list of spots along its line, best first, and takes the first free one.
/// A side always gets a spot, since its length is the point of the screen;
/// a diagonal or an angle that finds no free spot is left out rather than
/// piled on top of something else.
///
/// The same layout serves painting and tapping, so a tap on a label always
/// hits the label the user sees.
class PlotLabelLayout {
  /// Side `i` runs from corner `i` to corner `i + 1`.
  final Map<int, Rect> sides;
  final Map<(int, int), Rect> diagonals;
  final Map<int, Rect> angles;

  const PlotLabelLayout._(this.sides, this.diagonals, this.angles);

  static const _handleRadius = 15.0;
  static const _gap = 3.0;

  /// [pts] are the corners in canvas coordinates. The `*Size` callbacks give
  /// each label's box. [reserved] are areas covered by overlay buttons.
  static PlotLabelLayout compute({
    required List<Offset> pts,
    required Size bounds,
    required Size Function(int i) sideSize,
    Size Function(int i, int j)? diagonalSize,
    Iterable<(int, int)> diagonalPairs = const [],
    Size Function(int i)? angleSize,
    List<Rect> reserved = const [],
  }) {
    final n = pts.length;
    final taken = <Rect>[
      for (final p in pts) Rect.fromCircle(center: p, radius: _handleRadius),
      ...reserved,
    ];
    final area = Offset.zero & bounds;

    bool free(Rect r) =>
        area.contains(r.topLeft) &&
        area.contains(r.bottomRight) &&
        !taken.any((t) => t.overlaps(r.inflate(_gap)));

    Rect? first(Iterable<Rect> candidates) {
      for (final r in candidates) {
        if (free(r)) return r;
      }
      return null;
    }

    final c = _centroid(pts);

    // Sides: just outside the plot first, where diagonals never run.
    final sides = <int, Rect>{};
    for (var i = 0; i < n; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      final size = sideSize(i);
      final d = b - a;
      if (d.distance == 0) continue;
      var normal = Offset(-d.dy, d.dx) / d.distance;
      final mid = (a + b) / 2;
      // Point the normal away from the plot's middle: that is outside.
      if (_dot(mid - c, normal) < 0) normal = -normal;
      final away = size.height / 2 + 6;
      Iterable<Rect> spots() sync* {
        for (final t in const [0.5, 0.38, 0.62, 0.28, 0.72, 0.2, 0.8]) {
          final at = Offset.lerp(a, b, t)!;
          for (final side in const [1.0, -1.0]) {
            yield Rect.fromCenter(
              center: at + normal * away * side,
              width: size.width,
              height: size.height,
            );
          }
        }
      }

      // A side's length is essential: when nothing is free (a very short
      // side), it still goes at its preferred spot.
      final r =
          first(spots()) ??
          Rect.fromCenter(
            center: mid + normal * away,
            width: size.width,
            height: size.height,
          );
      sides[i] = r;
      taken.add(r);
    }

    // Diagonals: on the line itself (the pill hides the dashes under it),
    // sliding along it and then off to either side until there is room.
    final diagonals = <(int, int), Rect>{};
    if (diagonalSize != null) {
      for (final (i, j) in diagonalPairs) {
        final a = pts[i], b = pts[j];
        final size = diagonalSize(i, j);
        final d = b - a;
        if (d.distance == 0) continue;
        final normal = Offset(-d.dy, d.dx) / d.distance;
        Iterable<Rect> spots() sync* {
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
            for (final off in [0.0, size.height, -size.height]) {
              yield Rect.fromCenter(
                center: at + normal * off,
                width: size.width,
                height: size.height,
              );
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

    // Angles: outside each corner, along the line that splits it.
    final angles = <int, Rect>{};
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
        Iterable<Rect> spots() sync* {
          for (final dir in [
            out,
            const Offset(0, -1),
            const Offset(0, 1),
            const Offset(-1, 0),
            const Offset(1, 0),
          ]) {
            final d = _clearance(dir, size);
            for (final extra in const [0.0, 10.0]) {
              yield Rect.fromCenter(
                center: p + dir * (d + extra),
                width: size.width,
                height: size.height,
              );
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
  Iterable<Rect> get all => [
    ...sides.values,
    ...diagonals.values,
    ...angles.values,
  ];

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  /// How far along [dir] a label of [size] must sit to clear its corner's
  /// handle, with the usual gap: the nearest the label can come.
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
