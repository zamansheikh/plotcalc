import 'dart:math' as math;

import 'vertex.dart';

class Geometry {
  Geometry._();

  /// Shoelace area in (input units)².
  static double polygonArea(List<Vertex> verts) {
    if (verts.length < 3) return 0;
    var s = 0.0;
    for (var i = 0; i < verts.length; i++) {
      final a = verts[i];
      final b = verts[(i + 1) % verts.length];
      s += a.x * b.y - b.x * a.y;
    }
    return s.abs() / 2;
  }

  static double polygonPerimeter(List<Vertex> verts) {
    if (verts.length < 2) return 0;
    var p = 0.0;
    for (var i = 0; i < verts.length; i++) {
      final a = verts[i];
      final b = verts[(i + 1) % verts.length];
      p += sideLength(a, b);
    }
    return p;
  }

  static double sideLength(Vertex a, Vertex b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static Vertex midpoint(Vertex a, Vertex b) =>
      Vertex((a.x + b.x) / 2, (a.y + b.y) / 2);

  /// Interior angle in degrees at vertex i.
  static double interiorAngle(List<Vertex> verts, int i) {
    final n = verts.length;
    final prev = verts[(i - 1 + n) % n];
    final cur = verts[i];
    final next = verts[(i + 1) % n];
    final v1x = prev.x - cur.x;
    final v1y = prev.y - cur.y;
    final v2x = next.x - cur.x;
    final v2y = next.y - cur.y;
    final dot = v1x * v2x + v1y * v2y;
    final mag = math.sqrt(v1x * v1x + v1y * v1y) *
        math.sqrt(v2x * v2x + v2y * v2y);
    if (mag == 0) return 0;
    final cos = (dot / mag).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  /// Bounding box: returns (minX, minY, maxX, maxY).
  static (double, double, double, double) bbox(List<Vertex> verts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final v in verts) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }
    return (minX, minY, maxX, maxY);
  }
}
