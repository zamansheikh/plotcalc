import 'dart:ui' show Offset;

/// Area shared by two plot outlines, for "how much of the old দাগ lies in
/// the new one".
///
/// Works for any simple polygon, convex or not: [b] is cut into triangles
/// (ear clipping), [a] is clipped against each triangle (Sutherland–Hodgman,
/// which is exact against a convex window even when the subject is
/// concave), and the pieces' areas add up.
class PolygonOverlap {
  PolygonOverlap._();

  static double signedArea(List<Offset> p) {
    var s = 0.0;
    for (var i = 0; i < p.length; i++) {
      final a = p[i], b = p[(i + 1) % p.length];
      s += a.dx * b.dy - b.dx * a.dy;
    }
    return s / 2;
  }

  static double area(List<Offset> p) => p.length < 3 ? 0 : signedArea(p).abs();

  /// Area of the region inside both [a] and [b].
  static double intersectionArea(List<Offset> a, List<Offset> b) {
    if (a.length < 3 || b.length < 3) return 0;
    final sa = signedArea(a);
    if (sa == 0) return 0;
    var total = 0.0;
    for (final tri in triangulate(b)) {
      final piece = clipToConvex(a, tri);
      if (piece.length < 3) continue;
      // Clipping keeps the subject's winding, so the signed area of every
      // piece has the subject's sign — even where a concave subject leaves
      // zero-width seams along the window's edge.
      total += signedArea(piece) * sa.sign;
    }
    return total < 0 ? 0 : total;
  }

  /// Ear-clipping triangulation of a simple polygon.
  static List<List<Offset>> triangulate(List<Offset> poly) {
    final pts = _withoutRepeats(poly);
    if (pts.length < 3) return const [];
    final ccw = signedArea(pts) > 0;
    final idx = List<int>.generate(pts.length, (i) => i);
    final out = <List<Offset>>[];
    var guard = pts.length * pts.length;
    while (idx.length > 3 && guard-- > 0) {
      var clipped = false;
      for (var k = 0; k < idx.length; k++) {
        final ip = idx[(k - 1 + idx.length) % idx.length];
        final ic = idx[k];
        final inx = idx[(k + 1) % idx.length];
        final p = pts[ip], c = pts[ic], n = pts[inx];
        final turn = _cross(c - p, n - c);
        if (turn == 0) {
          // Straight-through point: contributes nothing, drop it.
          idx.removeAt(k);
          clipped = true;
          break;
        }
        if ((turn > 0) != ccw) continue; // reflex corner
        var inside = false;
        for (final j in idx) {
          if (j == ip || j == ic || j == inx) continue;
          if (_inTriangle(pts[j], p, c, n)) {
            inside = true;
            break;
          }
        }
        if (inside) continue;
        out.add([p, c, n]);
        idx.removeAt(k);
        clipped = true;
        break;
      }
      if (!clipped) break; // not simple; fall back below
    }
    if (idx.length == 3) {
      out.add([pts[idx[0]], pts[idx[1]], pts[idx[2]]]);
    } else if (idx.length > 3) {
      // A self-touching outline: fan the rest rather than give up.
      for (var k = 1; k + 1 < idx.length; k++) {
        out.add([pts[idx[0]], pts[idx[k]], pts[idx[k + 1]]]);
      }
    }
    return out;
  }

  /// Sutherland–Hodgman: the part of [subject] inside the convex [window].
  static List<Offset> clipToConvex(List<Offset> subject, List<Offset> window) {
    var out = subject;
    final ccw = signedArea(window) > 0;
    for (var i = 0; i < window.length && out.isNotEmpty; i++) {
      final e0 = window[i], e1 = window[(i + 1) % window.length];
      bool inside(Offset p) {
        final c = _cross(e1 - e0, p - e0);
        return ccw ? c >= 0 : c <= 0;
      }

      final input = out;
      out = [];
      for (var j = 0; j < input.length; j++) {
        final cur = input[j];
        final prev = input[(j - 1 + input.length) % input.length];
        final cin = inside(cur), pin = inside(prev);
        if (cin) {
          if (!pin) out.add(_intersect(prev, cur, e0, e1));
          out.add(cur);
        } else if (pin) {
          out.add(_intersect(prev, cur, e0, e1));
        }
      }
    }
    return out;
  }

  static double _cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

  static bool _inTriangle(Offset p, Offset a, Offset b, Offset c) {
    final d1 = _cross(b - a, p - a);
    final d2 = _cross(c - b, p - b);
    final d3 = _cross(a - c, p - c);
    final neg = d1 < 0 || d2 < 0 || d3 < 0;
    final pos = d1 > 0 || d2 > 0 || d3 > 0;
    return !(neg && pos);
  }

  static Offset _intersect(Offset p, Offset q, Offset a, Offset b) {
    final r = q - p, s = b - a;
    final den = _cross(r, s);
    if (den == 0) return q;
    final t = _cross(a - p, s) / den;
    return p + r * t;
  }

  static List<Offset> _withoutRepeats(List<Offset> p) {
    final out = <Offset>[];
    for (final q in p) {
      if (out.isEmpty || (out.last - q).distance > 1e-9) out.add(q);
    }
    if (out.length > 1 && (out.first - out.last).distance <= 1e-9) {
      out.removeLast();
    }
    return out;
  }
}
