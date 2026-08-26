import 'dart:math' as math;

import 'geometry.dart';
import 'vertex.dart';

/// One piece of a subdivided plot.
class Lot {
  /// Share of the parent plot this lot is meant to take, 0..1.
  final double share;

  /// The piece itself. Its area is what the lot actually measures — the
  /// share is only the instruction.
  final List<Vertex> vertices;

  const Lot({required this.share, required this.vertices});

  double get areaSqm => Geometry.polygonArea(vertices);
}

/// Where a dividing line meets the plot, so it can be drawn and dragged.
class CutLine {
  final Vertex a;
  final Vertex b;

  /// Direction the line faces, as an angle in radians. Dragging an end
  /// changes this; the position is then re-solved to keep the lot's area.
  final double angle;

  const CutLine({required this.a, required this.b, required this.angle});

  double get lengthM => Geometry.sideLength(a, b);
}

/// Splits a plot into lots by straight dividing lines.
///
/// Two things this gets right that a naive version does not. Cuts are placed
/// by **area**, not by width: half the width of a triangle is three quarters
/// of its land. And a cut may run at any angle, because real boundaries are
/// rarely all parallel — the divider is a chord, not a vertical line.
class LotDivision {
  const LotDivision._();

  static const double tolerance = 1e-9;

  /// Straight down the page: the direction a divider takes unless moved.
  static const double defaultAngle = 0;

  /// Signed distance of [v] along the direction [angle].
  static double _along(Vertex v, double angle) =>
      v.x * math.cos(angle) + v.y * math.sin(angle);

  /// Keeps the part of [poly] where the distance along [angle] is at most
  /// [offset] (or at least, when [keepNear] is false).
  ///
  /// Sutherland–Hodgman. On a non-convex plot the result can contain
  /// zero-width bridges where the line crosses more than twice; the shoelace
  /// area stays correct, which is what the quoted figure depends on.
  static List<Vertex> clip(
    List<Vertex> poly,
    double angle,
    double offset, {
    required bool keepNear,
  }) {
    if (poly.length < 3) return const [];
    double d(Vertex v) => _along(v, angle) - offset;
    bool inside(Vertex v) => keepNear ? d(v) <= 0 : d(v) >= 0;

    final out = <Vertex>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final aIn = inside(a);
      final bIn = inside(b);
      if (aIn) out.add(a);
      if (aIn != bIn) {
        final da = d(a);
        final db = d(b);
        // aIn != bIn means the edge straddles the line, so da != db.
        final t = da / (da - db);
        out.add(Vertex(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t));
      }
    }
    return out;
  }

  /// Area of the part of [poly] on the near side of the line.
  static double areaBefore(List<Vertex> poly, double angle, double offset) =>
      Geometry.polygonArea(clip(poly, angle, offset, keepNear: true));

  /// The offset at which the near side measures [targetSqm].
  ///
  /// Area on one side of a moving line grows monotonically with the offset
  /// for any simple polygon, so a plain bisection is safe here.
  static double offsetForArea(
    List<Vertex> poly,
    double angle,
    double targetSqm,
  ) {
    if (poly.length < 3) return 0;
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final v in poly) {
      final d = _along(v, angle);
      if (d < lo) lo = d;
      if (d > hi) hi = d;
    }
    final total = Geometry.polygonArea(poly);
    if (targetSqm <= 0) return lo;
    if (targetSqm >= total) return hi;

    for (var i = 0; i < 100; i++) {
      final mid = (lo + hi) / 2;
      final a = areaBefore(poly, angle, mid);
      if ((a - targetSqm).abs() <= total * tolerance) return mid;
      if (a < targetSqm) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  /// Where the dividing line meets the plot's boundary.
  static CutLine? lineFor(List<Vertex> poly, double angle, double offset) {
    if (poly.length < 3) return null;
    double d(Vertex v) => _along(v, angle) - offset;
    final hits = <Vertex>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final da = d(a);
      final db = d(b);
      if ((da <= 0 && db > 0) || (da > 0 && db <= 0)) {
        final t = da / (da - db);
        hits.add(Vertex(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t));
      }
    }
    if (hits.length < 2) return null;
    // A line can cross a non-convex plot several times; the outermost pair
    // spans the division as drawn.
    var first = hits.first;
    var last = hits.first;
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final h in hits) {
      // Position along the line itself, i.e. perpendicular to [angle].
      final p = -h.x * math.sin(angle) + h.y * math.cos(angle);
      if (p < lo) {
        lo = p;
        first = h;
      }
      if (p > hi) {
        hi = p;
        last = h;
      }
    }
    return CutLine(a: first, b: last, angle: angle);
  }

  /// Divides [poly] into lots taking the given [shares] of its area, each
  /// separated by a line running at the matching angle in [angles].
  ///
  /// Lots are cut off one after another, which is how a plot is actually
  /// subdivided: the second boundary is drawn on what is left after the
  /// first, not on the original.
  static List<Lot> divide(
    List<Vertex> poly,
    List<double> shares, {
    List<double>? angles,
  }) {
    if (poly.length < 3 || shares.isEmpty) return const [];
    final total = Geometry.polygonArea(poly);
    if (total <= 0) return const [];

    final normalised = _normalise(shares);
    if (normalised == null) return const [];

    final lots = <Lot>[];
    var remainder = poly;
    var remainingShare = 1.0;

    for (var i = 0; i < normalised.length; i++) {
      if (i == normalised.length - 1) {
        // The last lot takes whatever is left, so rounding can never leave
        // a sliver unaccounted for.
        lots.add(Lot(share: normalised[i], vertices: remainder));
        break;
      }
      final angle = _angleAt(angles, i);
      final want = total * normalised[i];
      final offset = offsetForArea(remainder, angle, want);
      lots.add(
        Lot(
          share: normalised[i],
          vertices: clip(remainder, angle, offset, keepNear: true),
        ),
      );
      remainder = clip(remainder, angle, offset, keepNear: false);
      remainingShare -= normalised[i];
      if (remainingShare <= 0) break;
    }
    return lots;
  }

  /// The dividing lines, in order, for drawing and dragging.
  static List<CutLine> cutLines(
    List<Vertex> poly,
    List<double> shares, {
    List<double>? angles,
  }) {
    if (poly.length < 3 || shares.length < 2) return const [];
    final total = Geometry.polygonArea(poly);
    final normalised = _normalise(shares);
    if (normalised == null || total <= 0) return const [];

    final out = <CutLine>[];
    var remainder = poly;
    for (var i = 0; i < normalised.length - 1; i++) {
      final angle = _angleAt(angles, i);
      final offset = offsetForArea(remainder, angle, total * normalised[i]);
      final line = lineFor(remainder, angle, offset);
      if (line != null) out.add(line);
      remainder = clip(remainder, angle, offset, keepNear: false);
    }
    return out;
  }

  /// The angle a divider takes once one of its ends is dragged to [to].
  ///
  /// The other end stays put, so the line pivots about it. The offset is not
  /// taken from the drag: it is re-solved afterwards so the lot keeps the
  /// area it was promised — you choose the direction, the area holds.
  static double angleAfterDrag(Vertex fixedEnd, Vertex to) {
    final dx = to.x - fixedEnd.x;
    final dy = to.y - fixedEnd.y;
    if (dx * dx + dy * dy < 1e-12) return defaultAngle;
    // The stored angle is the line's normal, a quarter turn from the line.
    return math.atan2(dy, dx) - math.pi / 2;
  }

  /// Shares implied by dragging the divider at [index] sideways to [point].
  ///
  /// Only the two lots either side change; the rest keep the land they had.
  static List<double> sharesAfterMove(
    List<Vertex> poly,
    List<double> shares,
    List<double>? angles,
    int index,
    Vertex point, {
    double minShare = 0.01,
  }) {
    if (index < 0 || index >= shares.length - 1) return shares;
    final total = Geometry.polygonArea(poly);
    final normalised = _normalise(shares);
    if (normalised == null || total <= 0) return shares;

    // Rebuild the remainder this divider actually sits on.
    var remainder = poly;
    for (var i = 0; i < index; i++) {
      final a = _angleAt(angles, i);
      final o = offsetForArea(remainder, a, total * normalised[i]);
      remainder = clip(remainder, a, o, keepNear: false);
    }

    final angle = _angleAt(angles, index);
    final remainderArea = Geometry.polygonArea(remainder);
    if (remainderArea <= 0) return shares;

    final near = areaBefore(remainder, angle, _along(point, angle));
    final pairShare = normalised[index] + normalised[index + 1];
    final wanted = (near / total).clamp(minShare, pairShare - minShare);

    final next = List<double>.of(normalised);
    next[index] = wanted;
    next[index + 1] = pairShare - wanted;
    return next;
  }

  static List<double>? _normalise(List<double> shares) {
    final positive = shares.map((s) => s.isFinite && s > 0 ? s : 0.0).toList();
    final sum = positive.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return null;
    return positive.map((s) => s / sum).toList();
  }

  static double _angleAt(List<double>? angles, int i) =>
      angles != null && i < angles.length ? angles[i] : defaultAngle;

  /// Equal shares for [count] lots.
  static List<double> equalShares(int count) =>
      List.filled(math.max(count, 1), 1 / math.max(count, 1));
}
