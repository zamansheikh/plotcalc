import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'geo_plot.dart';

/// A north-up web map as it sits on the screen, pinned by the points on the
/// earth at two opposite corners of its view. Between them such a map is
/// linear in longitude and in Mercator's stretched latitude, so any point
/// converts both ways at once, without asking the map (which only answers
/// later, too late to follow a finger).
class MercatorView {
  final Size size;
  final GeoPoint topLeft;
  final GeoPoint bottomRight;

  const MercatorView({
    required this.size,
    required this.topLeft,
    required this.bottomRight,
  });

  /// Mercator's y for a latitude in degrees.
  static double _y(double lat) =>
      math.log(math.tan(math.pi / 4 + lat * math.pi / 360));

  static double _lat(double y) =>
      (2 * math.atan(math.exp(y)) - math.pi / 2) * 180 / math.pi;

  bool get isValid =>
      size.width > 0 &&
      size.height > 0 &&
      bottomRight.lng > topLeft.lng &&
      bottomRight.lat < topLeft.lat;

  /// Where [p] is drawn, from the view's top-left corner.
  Offset toScreen(GeoPoint p) {
    final y0 = _y(topLeft.lat);
    return Offset(
      (p.lng - topLeft.lng) / (bottomRight.lng - topLeft.lng) * size.width,
      (_y(p.lat) - y0) / (_y(bottomRight.lat) - y0) * size.height,
    );
  }

  /// The point on the earth drawn at [o].
  GeoPoint toGeo(Offset o) {
    final y0 = _y(topLeft.lat);
    return GeoPoint(
      _lat(y0 + o.dy / size.height * (_y(bottomRight.lat) - y0)),
      topLeft.lng + o.dx / size.width * (bottomRight.lng - topLeft.lng),
    );
  }
}
