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

/// Splits a plot into lots along parallel cuts.
///
/// The cuts are placed by **area**, not by width. Putting a line at 35% of
/// the bounding box only gives 35% of the land on a rectangle; on any other
/// shape the strip drawn and the figure quoted disagree, which is the kind
/// of mistake that ends up in a deed.
class LotDivision {
  const LotDivision._();

  /// Treated as hitting a target area exactly.
  static const double tolerance = 1e-9;

  /// Clips [poly] to one side of the vertical line `x = cut`.
  ///
  /// Sutherland–Hodgman. On a non-convex plot the result can contain
  /// zero-width bridges where the cut crosses more than twice; the shoelace
  /// area stays correct, which is what the quoted figure depends on.
  static List<Vertex> clip(List<Vertex> poly, double cut, {required bool keepLeft}) {
    if (poly.length < 3) return const [];
    bool inside(Vertex v) => keepLeft ? v.x <= cut : v.x >= cut;

    final out = <Vertex>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final aIn = inside(a);
      final bIn = inside(b);
      if (aIn) out.add(a);
      if (aIn != bIn) {
        final dx = b.x - a.x;
        // aIn != bIn means the edge straddles the line, so it cannot be
        // vertical and dx cannot be zero.
        final t = (cut - a.x) / dx;
        out.add(Vertex(cut, a.y + (b.y - a.y) * t));
      }
    }
    return out;
  }

  /// Area of the part of [poly] left of `x = cut`.
  static double areaLeftOf(List<Vertex> poly, double cut) =>
      Geometry.polygonArea(clip(poly, cut, keepLeft: true));

  /// The x where the area to the left equals [targetSqm].
  ///
  /// Area to the left grows monotonically with x for any simple polygon, so
  /// a plain bisection is safe here — unlike moving a boundary, which can
  /// fold the shape over.
  static double cutForArea(List<Vertex> poly, double targetSqm) {
    final (minX, _, maxX, _) = Geometry.bbox(poly);
    if (targetSqm <= 0) return minX;
    final total = Geometry.polygonArea(poly);
    if (targetSqm >= total) return maxX;

    var lo = minX;
    var hi = maxX;
    for (var i = 0; i < 100; i++) {
      final mid = (lo + hi) / 2;
      final a = areaLeftOf(poly, mid);
      if ((a - targetSqm).abs() <= total * tolerance) return mid;
      if (a < targetSqm) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  /// Divides [poly] into lots taking the given [shares] of its area.
  ///
  /// Shares are normalised, so they can be given as percentages, as target
  /// areas, or as plain weights.
  static List<Lot> divide(List<Vertex> poly, List<double> shares) {
    if (poly.length < 3 || shares.isEmpty) return const [];
    final total = Geometry.polygonArea(poly);
    if (total <= 0) return const [];

    final positive = shares.map((s) => s.isFinite && s > 0 ? s : 0.0).toList();
    final sum = positive.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return const [];
    final normalised = positive.map((s) => s / sum).toList();

    final (minX, _, maxX, _) = Geometry.bbox(poly);
    final lots = <Lot>[];
    var cumulative = 0.0;
    var previousCut = minX;

    for (var i = 0; i < normalised.length; i++) {
      cumulative += normalised[i];
      // The last lot takes whatever is left, so rounding can never leave a
      // sliver unaccounted for.
      final cut = i == normalised.length - 1
          ? maxX
          : cutForArea(poly, total * cumulative);
      final strip = clip(
        clip(poly, cut, keepLeft: true),
        previousCut,
        keepLeft: false,
      );
      lots.add(Lot(share: normalised[i], vertices: strip));
      previousCut = cut;
    }
    return lots;
  }

  /// Cut positions in plot coordinates, for drawing and for dragging.
  static List<double> cuts(List<Vertex> poly, List<double> shares) {
    final divided = divide(poly, shares);
    if (divided.length < 2) return const [];
    final total = Geometry.polygonArea(poly);
    final out = <double>[];
    var cumulative = 0.0;
    for (var i = 0; i < divided.length - 1; i++) {
      cumulative += divided[i].share;
      out.add(cutForArea(poly, total * cumulative));
    }
    return out;
  }

  /// Shares implied by dragging the cut at [index] to `x`.
  ///
  /// Only the two lots either side of that cut change; the rest keep the
  /// land they already had, which is what dragging one line should mean.
  static List<double> sharesAfterDrag(
    List<Vertex> poly,
    List<double> shares,
    int index,
    double x, {
    double minShare = 0.01,
  }) {
    if (index < 0 || index >= shares.length - 1) return shares;
    final total = Geometry.polygonArea(poly);
    if (total <= 0) return shares;

    final next = List<double>.of(shares);
    final pairShare = next[index] + next[index + 1];

    // Area up to the start of this pair stays put.
    final before = next.take(index).fold<double>(0, (a, b) => a + b);
    final leftShare = (areaLeftOf(poly, x) / total) - before;

    final clamped = leftShare.clamp(minShare, pairShare - minShare);
    next[index] = clamped;
    next[index + 1] = pairShare - clamped;
    return next;
  }

  /// Equal shares for [count] lots.
  static List<double> equalShares(int count) =>
      List.filled(math.max(count, 1), 1 / math.max(count, 1));
}
