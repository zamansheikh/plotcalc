import 'dart:ui' show Offset;

import 'geometry.dart';
import 'sheet_layout.dart';
import 'vertex.dart';

/// Units a known distance on a map is usually given in. Chain and link are
/// the surveyor's Gunter chain, which mouza maps and amins still use:
/// one chain is 66 ft, and 100 links make a chain.
enum MapDistanceUnit {
  foot(0.3048),
  meter(1),
  chain(20.1168),
  link(0.201168);

  final double meters;
  const MapDistanceUnit(this.meters);

  double toMeters(double v) => v * meters;
}

/// A photo of a map made measurable: two points on it, in image pixels, and
/// the real distance between them.
class MapScale {
  final Offset a;
  final Offset b;
  final double meters;

  const MapScale({required this.a, required this.b, required this.meters});

  double get pixels => (b - a).distance;

  bool get isValid => pixels > 0 && meters > 0 && meters.isFinite;

  double get metersPerPixel => meters / pixels;

  /// Image-pixel points as a plot outline in metres, centred on its centroid
  /// so it sits in the middle of the app's other plot views.
  List<Vertex> toVertices(List<Offset> points) {
    final m = metersPerPixel;
    final raw = [for (final p in points) Vertex(p.dx * m, p.dy * m)];
    if (raw.length < 3) return raw;
    final c = SheetLayout.centroid(raw);
    return [for (final v in raw) Vertex(v.x - c.x, v.y - c.y)];
  }

  /// Area of the outline through [points], in square metres.
  double areaOf(List<Offset> points) =>
      points.length < 3 ? 0 : Geometry.polygonArea(toVertices(points));

  /// Real length between two image points, in metres.
  double lengthOf(Offset p, Offset q) => (q - p).distance * metersPerPixel;
}
