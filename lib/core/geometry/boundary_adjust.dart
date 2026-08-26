import 'dart:math' as math;

import 'geometry.dart';
import 'vertex.dart';

/// Which part of the boundary the user is moving.
enum AdjustTargetKind {
  /// Whole boundary lines, offset parallel to themselves.
  side,

  /// Individual corners, moved along the angle bisector.
  corner,

  /// A corner slid along one of the two boundaries meeting at it.
  ///
  /// Corner B joins sides AB and BC. Sliding B along AB keeps that
  /// boundary's bearing and only changes its length, while BC pivots to
  /// follow — which is what moving a peg along an existing boundary line
  /// actually does on the ground.
  slide,
}

/// The answer to "how far do I move it?".
class BoundarySolution {
  /// Metres each selected element moves. Positive pushes the boundary out
  /// (area grows); negative pulls it in.
  final double offsetM;

  final List<Vertex> vertices;
  final double areaSqm;

  /// How close the solver got, as a fraction of the target. Anything above
  /// [BoundaryAdjust.tolerance] means the target was not reachable by moving
  /// the chosen elements.
  final double relativeError;

  const BoundarySolution({
    required this.offsetM,
    required this.vertices,
    required this.areaSqm,
    required this.relativeError,
  });

  bool get isExact => relativeError <= BoundaryAdjust.tolerance;
}

/// Reshapes a plot to a target area by moving chosen sides or corners,
/// rather than by scaling the whole thing.
///
/// This is the operation a surveyor actually performs: a plot measures 5.2
/// katha and has to be 5.5, so one boundary gets pushed out — and the number
/// that matters is *how far*. Every mode is expressed as "area as a function
/// of offset", and a single solver inverts it.
class BoundaryAdjust {
  const BoundaryAdjust._();

  /// Treated as hitting the target exactly (one part in a million of area).
  static const double tolerance = 1e-6;

  /// +1 for a counter-clockwise plot, -1 for a clockwise one.
  ///
  /// The winding is *measured*, never corrected by reversing the list: the
  /// caller's side and corner indices have to keep meaning the same edges,
  /// and the returned vertices have to come back in the order they went in.
  /// Only the sign of "outward" depends on it.
  static double _winding(List<Vertex> verts) {
    var s = 0.0;
    for (var i = 0; i < verts.length; i++) {
      final a = verts[i];
      final b = verts[(i + 1) % verts.length];
      s += a.x * b.y - b.x * a.y;
    }
    return s < 0 ? -1.0 : 1.0;
  }

  /// Unit outward normal of the edge running from `verts[i]` to `verts[i+1]`.
  static (double, double) _outwardNormal(
    List<Vertex> verts,
    int i,
    double winding,
  ) {
    final a = verts[i];
    final b = verts[(i + 1) % verts.length];
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return (0, 0);
    // Counter-clockwise keeps the interior to the left of a->b, so outward is
    // the right-hand perpendicular; clockwise flips it.
    return (winding * dy / len, -winding * dx / len);
  }

  /// Where two infinite lines meet, or null when they are (near) parallel.
  static Vertex? _lineIntersection(
    Vertex p1,
    Vertex p2,
    Vertex p3,
    Vertex p4,
  ) {
    final d1x = p2.x - p1.x, d1y = p2.y - p1.y;
    final d2x = p4.x - p3.x, d2y = p4.y - p3.y;
    final den = d1x * d2y - d1y * d2x;
    // Scale-aware parallelism check, so it behaves the same on a 2 m plot
    // and a 2 km one.
    final scale = math.max(
      math.sqrt(d1x * d1x + d1y * d1y),
      math.sqrt(d2x * d2x + d2y * d2y),
    );
    if (scale == 0 || den.abs() < 1e-12 * scale * scale) return null;
    final t = ((p3.x - p1.x) * d2y - (p3.y - p1.y) * d2x) / den;
    return Vertex(p1.x + d1x * t, p1.y + d1y * t);
  }

  /// Pushes each side in [sides] out by [offsetM], parallel to itself.
  ///
  /// The corners are not dragged perpendicular; they slide along the
  /// neighbouring boundaries to meet the moved line, which is what keeps the
  /// untouched sides pointing where they always did.
  static List<Vertex> offsetSides(
    List<Vertex> verts,
    Set<int> sides,
    double offsetM,
  ) {
    final n = verts.length;
    if (n < 3 || sides.isEmpty) return List.of(verts);
    final poly = verts;
    final winding = _winding(poly);

    // Each edge's line after the move; untouched edges keep their line.
    final lines = <int, (Vertex, Vertex)>{};
    for (var i = 0; i < n; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % n];
      if (sides.contains(i)) {
        final (nx, ny) = _outwardNormal(poly, i, winding);
        lines[i] = (
          Vertex(a.x + nx * offsetM, a.y + ny * offsetM),
          Vertex(b.x + nx * offsetM, b.y + ny * offsetM),
        );
      } else {
        lines[i] = (a, b);
      }
    }

    // Vertex j is where edge j-1 meets edge j.
    final out = <Vertex>[];
    for (var j = 0; j < n; j++) {
      final prev = lines[(j - 1 + n) % n]!;
      final cur = lines[j]!;
      final hit = _lineIntersection(prev.$1, prev.$2, cur.$1, cur.$2);
      // Parallel neighbours have no meeting point; translating the corner
      // by the same offset is the sensible degenerate answer.
      out.add(hit ?? cur.$1);
    }
    return out;
  }

  /// Moves each corner in [corners] out along its angle bisector by
  /// [offsetM], leaving the others where they are.
  static List<Vertex> moveCorners(
    List<Vertex> verts,
    Set<int> corners,
    double offsetM,
  ) {
    final n = verts.length;
    if (n < 3 || corners.isEmpty) return List.of(verts);
    final poly = verts;
    final winding = _winding(poly);

    final out = <Vertex>[];
    for (var i = 0; i < n; i++) {
      if (!corners.contains(i)) {
        out.add(poly[i]);
        continue;
      }
      // Bisector of the two adjoining edge normals: the direction that grows
      // both neighbouring edges evenly.
      final (n1x, n1y) = _outwardNormal(poly, (i - 1 + n) % n, winding);
      final (n2x, n2y) = _outwardNormal(poly, i, winding);
      var bx = n1x + n2x;
      var by = n1y + n2y;
      final len = math.sqrt(bx * bx + by * by);
      if (len < 1e-12) {
        // A perfect spike: the normals cancel, so fall back to one of them.
        bx = n2x;
        by = n2y;
      } else {
        bx /= len;
        by /= len;
      }
      out.add(Vertex(poly[i].x + bx * offsetM, poly[i].y + by * offsetM));
    }
    return out;
  }

  /// Slides each corner in [corners] along one of the boundaries meeting at
  /// it: the next one (corner -> corner+1) when [alongNext], otherwise the
  /// previous one. Positive [offsetM] moves away from the far end of that
  /// boundary, lengthening it.
  static List<Vertex> slideCorners(
    List<Vertex> verts,
    Set<int> corners,
    double offsetM, {
    required bool alongNext,
  }) {
    final n = verts.length;
    if (n < 3 || corners.isEmpty) return List.of(verts);

    final out = List<Vertex>.of(verts);
    for (final i in corners) {
      if (i < 0 || i >= n) continue;
      final here = verts[i];
      final anchor = alongNext ? verts[(i + 1) % n] : verts[(i - 1 + n) % n];
      final dx = here.x - anchor.x;
      final dy = here.y - anchor.y;
      final len = math.sqrt(dx * dx + dy * dy);
      // A zero-length boundary has no direction to slide along.
      if (len < 1e-12) continue;
      out[i] = Vertex(
        here.x + dx / len * offsetM,
        here.y + dy / len * offsetM,
      );
    }
    return out;
  }

  static List<Vertex> apply(
    List<Vertex> verts,
    AdjustTargetKind kind,
    Set<int> selection,
    double offsetM, {
    bool alongNext = true,
  }) => switch (kind) {
    AdjustTargetKind.side => offsetSides(verts, selection, offsetM),
    AdjustTargetKind.corner => moveCorners(verts, selection, offsetM),
    AdjustTargetKind.slide =>
      slideCorners(verts, selection, offsetM, alongNext: alongNext),
  };

  /// Solves for the offset that makes the plot measure [targetSqm].
  ///
  /// Pushed far enough, an offset boundary crosses its neighbours and the
  /// polygon folds over itself — past that point the area is meaningless and
  /// not monotonic, so a plain bisection over a wide bracket can land on
  /// nonsense. Instead the offset is walked outward from zero and the *first*
  /// crossing is taken, which is both robust and the answer a surveyor wants:
  /// the smallest move that reaches the target.
  static BoundarySolution? solve({
    required List<Vertex> base,
    required double targetSqm,
    required AdjustTargetKind kind,
    required Set<int> selection,
    bool alongNext = true,
  }) {
    if (base.length < 3 || selection.isEmpty) return null;
    if (!targetSqm.isFinite || targetSqm <= 0) return null;
    final baseArea = Geometry.polygonArea(base);
    if (baseArea <= 0) return null;

    double areaAt(double d) => Geometry.polygonArea(
      apply(base, kind, selection, d, alongNext: alongNext),
    );

    BoundarySolution at(double d) {
      final verts = apply(base, kind, selection, d, alongNext: alongNext);
      final area = Geometry.polygonArea(verts);
      return BoundarySolution(
        offsetM: d,
        vertices: verts,
        areaSqm: area,
        relativeError: (area - targetSqm).abs() / targetSqm,
      );
    }

    if ((baseArea - targetSqm).abs() / targetSqm <= tolerance) return at(0);

    final (minX, minY, maxX, maxY) = Geometry.bbox(base);
    final span = math.max(maxX - minX, maxY - minY);
    // Beyond half the plot's own span the shape has stopped resembling what
    // the user drew, and a "solution" out there would be useless anyway.
    final limit = (span <= 0 ? 1.0 : span) * 0.75;
    final dir = targetSqm > baseArea ? 1.0 : -1.0;

    const steps = 600;
    var prevD = 0.0;
    var prevA = baseArea;
    double? loD, hiD;

    for (var i = 1; i <= steps; i++) {
      final d = dir * limit * i / steps;
      final verts = apply(base, kind, selection, d, alongNext: alongNext);
      if (verts.any((v) => !v.x.isFinite || !v.y.isFinite)) break;
      final a = Geometry.polygonArea(verts);
      if (!a.isFinite) break;
      // Straddles the target: the crossing is in (prevD, d].
      if ((prevA - targetSqm) * (a - targetSqm) <= 0) {
        loD = prevD;
        hiD = d;
        break;
      }
      prevD = d;
      prevA = a;
    }

    // Unreachable by moving these elements — hand back the closest we got so
    // the caller can say so rather than pretending.
    if (loD == null || hiD == null) return at(prevD);

    var lo = loD;
    var hi = hiD;
    for (var i = 0; i < 100; i++) {
      final mid = (lo + hi) / 2;
      final a = areaAt(mid);
      if ((a - targetSqm).abs() / targetSqm <= tolerance * 0.01) {
        lo = hi = mid;
        break;
      }
      // Keep the sub-interval that still straddles the target.
      final aLo = areaAt(lo);
      if ((aLo - targetSqm) * (a - targetSqm) <= 0) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return at((lo + hi) / 2);
  }
}
