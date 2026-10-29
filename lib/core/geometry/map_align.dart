import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

/// A plane-to-plane mapping (a 3×3 homogeneous matrix, row-major). Covers
/// everything a second map can differ by: shift, turn, scale, uneven paper
/// shrinkage and the slant of a photo taken at an angle.
class PlaneTransform {
  final List<double> m;
  const PlaneTransform(this.m);

  static const identity = PlaneTransform([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  Offset apply(Offset p) {
    final w = m[6] * p.dx + m[7] * p.dy + m[8];
    return Offset(
      (m[0] * p.dx + m[1] * p.dy + m[2]) / w,
      (m[3] * p.dx + m[4] * p.dy + m[5]) / w,
    );
  }

  PlaneTransform inverse() {
    final a = m[0], b = m[1], c = m[2];
    final d = m[3], e = m[4], f = m[5];
    final g = m[6], h = m[7], i = m[8];
    final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    final k = 1 / det;
    return PlaneTransform([
      (e * i - f * h) * k,
      (c * h - b * i) * k,
      (b * f - c * e) * k,
      (f * g - d * i) * k,
      (a * i - c * g) * k,
      (c * d - a * f) * k,
      (d * h - e * g) * k,
      (b * g - a * h) * k,
      (a * e - b * d) * k,
    ]);
  }

  /// How many target pixels one source pixel becomes near [p].
  double localScale(Offset p) {
    final o = apply(p);
    final x = apply(p + const Offset(1, 0)) - o;
    final y = apply(p + const Offset(0, 1)) - o;
    return math.sqrt((x.dx * y.dy - x.dy * y.dx).abs());
  }

  /// For `Canvas.transform`: the same mapping as a column-major 4×4 matrix.
  Float64List toMatrix4() => Float64List.fromList([
    m[0], m[3], 0, m[6], //
    m[1], m[4], 0, m[7], //
    0, 0, 1, 0, //
    m[2], m[5], 0, m[8], //
  ]);
}

/// Which family of transform an alignment used.
enum AlignModel { similarity, affine, projective }

/// How well the matched points agree with each other.
enum AlignQuality {
  /// Too few points to check: every model fits them exactly.
  unchecked,
  good,
  fair,
  poor,
}

/// The fit of a second map ("B") onto a first ("A") from pairs of points
/// the user marked on both: the same road crossing, the same boundary
/// corner.
///
/// The model grows with the evidence, and always keeps one pair more than it
/// needs once there are four, so the pairs can check each other:
/// two pairs → shift, turn and scale; three or four → also uneven
/// stretch; five or more → also perspective, but only when that fits
/// clearly better. A single mistaken tap then shows up as a large residual
/// instead of being silently absorbed into a warped map.
class MapAlignment {
  /// (point on A, point on B), in each image's pixels.
  final List<(Offset, Offset)> pairs;

  /// Maps B's pixels onto A's.
  final PlaneTransform bToA;
  final AlignModel model;

  /// Distance, in A pixels, between where each pair's B point lands and its
  /// A point. All zero while the fit is exact.
  final List<double> residuals;

  /// The pair whose removal makes the rest agree best, and how well they
  /// then agree. Only computed from five pairs up: with four, dropping any
  /// one leaves an exact fit, which says nothing.
  final int? _bestDrop;
  final double _bestDropRms;

  const MapAlignment._(
    this.pairs,
    this.bToA,
    this.model,
    this.residuals, [
    this._bestDrop,
    this._bestDropRms = double.infinity,
  ]);

  /// True once there are more pairs than the model needs.
  bool get checkable => pairs.length >= 4;

  double get rms {
    if (residuals.isEmpty) return 0;
    final s = residuals.fold<double>(0, (t, r) => t + r * r);
    return math.sqrt(s / residuals.length);
  }

  /// Agreement, judged against the size of map A: on a 16-inch-to-the-mile
  /// sheet scanned at 4096 px, "good" is within roughly a hair's width of
  /// the drawn lines.
  AlignQuality quality(double imageWidth) {
    if (!checkable) return AlignQuality.unchecked;
    final r = rms / imageWidth;
    if (r < 0.0015) return AlignQuality.good;
    if (r < 0.004) return AlignQuality.fair;
    return AlignQuality.poor;
  }

  /// The pair that was most likely marked in the wrong place: the one
  /// whose removal leaves the others in close agreement. A wrong pair pulls
  /// the whole fit, so its own residual alone does not single it out.
  /// Null when the pairs agree, or when there are too few to tell which.
  int? suspect(double imageWidth) {
    final drop = _bestDrop;
    if (drop == null || quality(imageWidth) == AlignQuality.good) return null;
    return _bestDropRms < 0.4 * rms ? drop : null;
  }

  /// Fits B onto A. Null with fewer than two usable pairs.
  static MapAlignment? fit(List<(Offset, Offset)> pairs) =>
      _fit(pairs, findOutlier: true);

  static MapAlignment? _fit(
    List<(Offset, Offset)> pairs, {
    required bool findOutlier,
  }) {
    if (pairs.length < 2) return null;
    final a = [for (final p in pairs) p.$1];
    final b = [for (final p in pairs) p.$2];
    // Two pairs on the same spot fix nothing.
    if ((a[0] - a[1]).distance < 1e-6 || (b[0] - b[1]).distance < 1e-6) {
      if (pairs.length == 2) return null;
    }

    PlaneTransform? t;
    var model = AlignModel.similarity;
    if (pairs.length >= 3) {
      t = _affine(b, a);
      model = AlignModel.affine;
    }
    if (pairs.length >= 5 && t != null) {
      final p = _projective(b, a);
      if (p != null && _rms(p, b, a) < 0.7 * _rms(t, b, a)) {
        t = p;
        model = AlignModel.projective;
      }
    }
    if (t == null) {
      t = _similarity(b, a);
      model = AlignModel.similarity;
    }
    if (t == null) return null;
    final tr = t;
    final residuals = [
      for (var i = 0; i < pairs.length; i++) (tr.apply(b[i]) - a[i]).distance,
    ];
    int? bestDrop;
    var bestRms = double.infinity;
    if (findOutlier && pairs.length >= 5) {
      for (var i = 0; i < pairs.length; i++) {
        final rest = [...pairs]..removeAt(i);
        final f = _fit(rest, findOutlier: false);
        if (f != null && f.rms < bestRms) {
          bestRms = f.rms;
          bestDrop = i;
        }
      }
    }
    return MapAlignment._(
      List.unmodifiable(pairs),
      tr,
      model,
      residuals,
      bestDrop,
      bestRms,
    );
  }

  static double _rms(PlaneTransform t, List<Offset> from, List<Offset> to) {
    var s = 0.0;
    for (var i = 0; i < from.length; i++) {
      final d = (t.apply(from[i]) - to[i]).distance;
      s += d * d;
    }
    return math.sqrt(s / from.length);
  }

  // Points are centred and scaled before solving, so pixel coordinates in
  // the thousands do not swamp the arithmetic (Hartley normalisation).
  static (PlaneTransform, PlaneTransform) _normalisers(List<Offset> pts) {
    var cx = 0.0, cy = 0.0;
    for (final p in pts) {
      cx += p.dx;
      cy += p.dy;
    }
    cx /= pts.length;
    cy /= pts.length;
    var d = 0.0;
    for (final p in pts) {
      d += (p - Offset(cx, cy)).distance;
    }
    d /= pts.length;
    final s = d < 1e-9 ? 1.0 : math.sqrt2 / d;
    final n = PlaneTransform([s, 0, -s * cx, 0, s, -s * cy, 0, 0, 1]);
    return (n, n.inverse());
  }

  static PlaneTransform _compose(PlaneTransform x, PlaneTransform y) {
    // x after y.
    final a = x.m, b = y.m;
    return PlaneTransform([
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++)
          a[r * 3] * b[c] + a[r * 3 + 1] * b[3 + c] + a[r * 3 + 2] * b[6 + c],
    ]);
  }

  static PlaneTransform? _solveNormalised(
    List<Offset> from,
    List<Offset> to,
    PlaneTransform? Function(List<Offset>, List<Offset>) solve,
  ) {
    final (nf, _) = _normalisers(from);
    final (nt, ntInv) = _normalisers(to);
    final f = [for (final p in from) nf.apply(p)];
    final t = [for (final p in to) nt.apply(p)];
    final h = solve(f, t);
    if (h == null) return null;
    return _compose(ntInv, _compose(h, nf));
  }

  static PlaneTransform? _similarity(List<Offset> from, List<Offset> to) =>
      _solveNormalised(from, to, (f, t) {
        // x' = a·x − b·y + c ;  y' = b·x + a·y + d
        final rows = <List<double>>[];
        final rhs = <double>[];
        for (var i = 0; i < f.length; i++) {
          rows.add([f[i].dx, -f[i].dy, 1, 0]);
          rhs.add(t[i].dx);
          rows.add([f[i].dy, f[i].dx, 0, 1]);
          rhs.add(t[i].dy);
        }
        final x = _leastSquares(rows, rhs);
        if (x == null) return null;
        return PlaneTransform([x[0], -x[1], x[2], x[1], x[0], x[3], 0, 0, 1]);
      });

  static PlaneTransform? _affine(List<Offset> from, List<Offset> to) =>
      _solveNormalised(from, to, (f, t) {
        final rows = [
          for (final p in f) [p.dx, p.dy, 1.0],
        ];
        final x = _leastSquares(rows, [for (final p in t) p.dx]);
        final y = _leastSquares(rows, [for (final p in t) p.dy]);
        if (x == null || y == null) return null;
        return PlaneTransform([x[0], x[1], x[2], y[0], y[1], y[2], 0, 0, 1]);
      });

  static PlaneTransform? _projective(List<Offset> from, List<Offset> to) =>
      _solveNormalised(from, to, (f, t) {
        final rows = <List<double>>[];
        final rhs = <double>[];
        for (var i = 0; i < f.length; i++) {
          final x = f[i].dx, y = f[i].dy, u = t[i].dx, v = t[i].dy;
          rows.add([x, y, 1, 0, 0, 0, -x * u, -y * u]);
          rhs.add(u);
          rows.add([0, 0, 0, x, y, 1, -x * v, -y * v]);
          rhs.add(v);
        }
        final h = _leastSquares(rows, rhs);
        if (h == null) return null;
        return PlaneTransform([...h, 1]);
      });

  /// Solves the normal equations AᵀA·x = Aᵀb by Gaussian elimination with
  /// partial pivoting. Null when the system is singular (points in a line).
  static List<double>? _leastSquares(List<List<double>> a, List<double> b) {
    final n = a.first.length;
    final m = [
      for (var i = 0; i < n; i++)
        [
          for (var j = 0; j < n; j++)
            a.fold<double>(0, (s, r) => s + r[i] * r[j]),
          b.asMap().entries.fold<double>(
            0,
            (s, e) => s + a[e.key][i] * e.value,
          ),
        ],
    ];
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var r = col + 1; r < n; r++) {
        if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
      }
      if (m[pivot][col].abs() < 1e-10) return null;
      final tmp = m[col];
      m[col] = m[pivot];
      m[pivot] = tmp;
      for (var r = 0; r < n; r++) {
        if (r == col) continue;
        final k = m[r][col] / m[col][col];
        for (var c = col; c <= n; c++) {
          m[r][c] -= k * m[col][c];
        }
      }
    }
    return [for (var i = 0; i < n; i++) m[i][n] / m[i][i]];
  }
}
