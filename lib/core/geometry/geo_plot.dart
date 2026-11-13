import 'dart:math' as math;

import 'geometry.dart';
import 'sheet_layout.dart';
import 'vertex.dart';

/// A point on the earth, in degrees (WGS84, as GPS and web maps give it).
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// One GPS reading: where, and how sure the phone is (radius in metres).
class GeoFix {
  final GeoPoint point;
  final double accuracy;
  const GeoFix(this.point, this.accuracy);

  /// Several readings taken standing still, as one point: each counts by
  /// how sure it is (1/accuracy²), so one wild reading barely moves it.
  /// The accuracy given back is the combined one, never better than the
  /// best single reading's half: readings in one spot share their errors.
  static GeoFix average(List<GeoFix> fixes) {
    assert(fixes.isNotEmpty);
    var w = 0.0, lat = 0.0, lng = 0.0;
    var best = double.infinity;
    for (final f in fixes) {
      final a = math.max(f.accuracy, 0.5);
      final wi = 1 / (a * a);
      w += wi;
      lat += f.point.lat * wi;
      lng += f.point.lng * wi;
      best = math.min(best, a);
    }
    final combined = math.sqrt(1 / w);
    return GeoFix(GeoPoint(lat / w, lng / w), math.max(combined, best / 2));
  }
}

/// Turns points on the earth into a flat plot in metres, the way a surveyor
/// would draw it: north up, east to the right.
///
/// It lays a flat sheet on the earth at the plot (a local tangent plane on
/// the WGS84 ellipsoid). Over a plot of land, even a large one of a few
/// hundred metres, the earth's curve changes the area by far less than a
/// millionth.
class GeoPlot {
  GeoPlot._();

  static const _a = 6378137.0; // WGS84 semi-major axis, metres
  static const _e2 = 0.00669437999014; // WGS84 first eccentricity squared

  /// Metres per radian north (meridional radius) and east (prime vertical
  /// radius × cos lat) at latitude [lat] in degrees.
  static (double, double) _radii(double lat) {
    final phi = lat * math.pi / 180;
    final s = math.sin(phi);
    final d = 1 - _e2 * s * s;
    final north = _a * (1 - _e2) / (d * math.sqrt(d));
    final east = _a / math.sqrt(d) * math.cos(phi);
    return (north, east);
  }

  static GeoPoint _center(List<GeoPoint> pts) {
    var lat = 0.0, lng = 0.0;
    for (final p in pts) {
      lat += p.lat;
      lng += p.lng;
    }
    return GeoPoint(lat / pts.length, lng / pts.length);
  }

  /// Points as metres from [origin]: x east, y south (screen-down, as the
  /// app's other plots are drawn).
  static List<Vertex> project(List<GeoPoint> pts, GeoPoint origin) {
    final (north, east) = _radii(origin.lat);
    const rad = math.pi / 180;
    return [
      for (final p in pts)
        Vertex(
          (p.lng - origin.lng) * rad * east,
          -(p.lat - origin.lat) * rad * north,
        ),
    ];
  }

  /// The outline in metres, centred on its centroid like a plot drawn by
  /// hand.
  static List<Vertex> toVertices(List<GeoPoint> pts) {
    if (pts.isEmpty) return const [];
    final raw = project(pts, _center(pts));
    if (raw.length < 3) return raw;
    final c = SheetLayout.centroid(raw);
    return [for (final v in raw) Vertex(v.x - c.x, v.y - c.y)];
  }

  /// Area inside [pts], in square metres.
  static double area(List<GeoPoint> pts) =>
      pts.length < 3 ? 0 : Geometry.polygonArea(project(pts, _center(pts)));

  /// Distance between two points, in metres.
  static double distance(GeoPoint p, GeoPoint q) {
    final v = project([p, q], _center([p, q]));
    return Geometry.sideLength(v[0], v[1]);
  }

  /// Length all the way round, in metres.
  static double perimeter(List<GeoPoint> pts) => pts.length < 2
      ? 0
      : Geometry.polygonPerimeter(project(pts, _center(pts)));

  /// The point [east] metres east and [north] metres north of [from].
  static GeoPoint offset(GeoPoint from, {double east = 0, double north = 0}) {
    final (n, e) = _radii(from.lat);
    const deg = 180 / math.pi;
    return GeoPoint(from.lat + north / n * deg, from.lng + east / e * deg);
  }
}
