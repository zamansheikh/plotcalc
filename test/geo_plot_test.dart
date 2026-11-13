import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/geo_plot.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/mercator_view.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/presentation/features/satellite/satellite_services.dart'
    show parseLatLng;

void main() {
  const dhaka = GeoPoint(23.8103, 90.4125);

  /// Corners of a field [east] × [north] metres, its south-west corner at
  /// [sw], in walking order.
  List<GeoPoint> field(GeoPoint sw, double east, double north) => [
    sw,
    GeoPlot.offset(sw, east: east),
    GeoPlot.offset(sw, east: east, north: north),
    GeoPlot.offset(sw, north: north),
  ];

  group('distances on the earth', () {
    test('a degree of longitude on the equator is 111,319.49 m', () {
      // The WGS84 equator: 2π × 6,378,137 m / 360.
      expect(
        GeoPlot.distance(const GeoPoint(0, 0), const GeoPoint(0, 1)),
        closeTo(111319.49, 0.01),
      );
    });

    test('a degree of latitude from the equator is 110,574 m', () {
      // The WGS84 meridian arc from 0° to 1°: 110,574.4 m.
      expect(
        GeoPlot.distance(const GeoPoint(0, 0), const GeoPoint(1, 0)),
        closeTo(110574.4, 1),
      );
    });

    test('offset and distance agree, in Dhaka', () {
      final east = GeoPlot.offset(dhaka, east: 100);
      final north = GeoPlot.offset(dhaka, north: 100);
      expect(GeoPlot.distance(dhaka, east), closeTo(100, 1e-3));
      expect(GeoPlot.distance(dhaka, north), closeTo(100, 1e-3));
      // Going east in Dhaka changes longitude more than latitude changes
      // going north: a degree of longitude is shorter there.
      expect(east.lng - dhaka.lng, greaterThan(north.lat - dhaka.lat));
    });
  });

  group('area', () {
    test('a field 100 m × 100 m is 10,000 m²', () {
      expect(GeoPlot.area(field(dhaka, 100, 100)), closeTo(10000, 0.5));
      expect(GeoPlot.perimeter(field(dhaka, 100, 100)), closeTo(400, 0.01));
    });

    test('a square chain is ten shotok', () {
      // 66 ft × 66 ft = a tenth of an acre = 10 shotok.
      final sq = field(const GeoPoint(24.3636, 88.6241), 20.1168, 20.1168);
      expect(AreaUnit.shotok.fromSqm(GeoPlot.area(sq)), closeTo(10, 1e-3));
    });

    test('the same field anywhere, any way round', () {
      final here = GeoPlot.area(field(dhaka, 60, 35));
      final north = GeoPlot.area(field(const GeoPoint(26.33, 88.55), 60, 35));
      final reversed = GeoPlot.area(field(dhaka, 60, 35).reversed.toList());
      expect(here, closeTo(2100, 0.2));
      expect(north, closeTo(2100, 0.2));
      expect(reversed, closeTo(here, 1e-6));
    });

    test('fewer than three corners have no area', () {
      expect(GeoPlot.area([dhaka, GeoPlot.offset(dhaka, east: 10)]), 0);
    });

    test('as a plot: metres, centred, north up', () {
      final v = GeoPlot.toVertices(field(dhaka, 60, 35));
      expect(Geometry.polygonArea(v), closeTo(2100, 0.2));
      final cx = v.fold<double>(0, (s, p) => s + p.x) / v.length;
      final cy = v.fold<double>(0, (s, p) => s + p.y) / v.length;
      expect(cx, closeTo(0, 1e-6));
      expect(cy, closeTo(0, 1e-6));
      // The south-west corner is left and down (screen y grows down).
      expect(v[0].x, lessThan(0));
      expect(v[0].y, greaterThan(0));
      expect(Geometry.sideLength(v[0], v[1]), closeTo(60, 1e-3));
      expect(Geometry.sideLength(v[1], v[2]), closeTo(35, 1e-3));
    });
  });

  group('GPS readings', () {
    test('a sure reading outweighs a vague one', () {
      final a = GeoFix(dhaka, 2);
      final b = GeoFix(GeoPlot.offset(dhaka, east: 100), 20);
      final avg = GeoFix.average([a, b]);
      // Weights 1/4 and 1/400: 100/101 m from the sure one.
      expect(GeoPlot.distance(avg.point, dhaka), closeTo(100 / 101, 0.01));
      expect(avg.accuracy, closeTo(2, 0.05));
    });

    test('equal readings meet in the middle', () {
      final b = GeoPlot.offset(dhaka, north: 10);
      final avg = GeoFix.average([GeoFix(dhaka, 4), GeoFix(b, 4)]);
      expect(GeoPlot.distance(avg.point, dhaka), closeTo(5, 1e-3));
      expect(avg.accuracy, closeTo(2.83, 0.01));
    });
  });

  group('a map view on the screen', () {
    // 400 × 600 px showing 200 m × 300 m round Dhaka: half a metre a pixel.
    final view = MercatorView(
      size: const Size(400, 600),
      topLeft: GeoPlot.offset(dhaka, east: -100, north: 150),
      bottomRight: GeoPlot.offset(dhaka, east: 100, north: -150),
    );

    test('its corners are the corners of the screen', () {
      expect(view.isValid, isTrue);
      final tl = view.toScreen(view.topLeft);
      final br = view.toScreen(view.bottomRight);
      expect(tl.dx, closeTo(0, 1e-6));
      expect(tl.dy, closeTo(0, 1e-6));
      expect(br.dx, closeTo(400, 1e-6));
      expect(br.dy, closeTo(600, 1e-6));
    });

    test('north is up, east is right, to scale', () {
      final c = view.toScreen(dhaka);
      expect(c.dx, closeTo(200, 0.01));
      expect(c.dy, closeTo(300, 0.01));
      final ne = view.toScreen(GeoPlot.offset(dhaka, east: 50, north: 25));
      expect(ne.dx, closeTo(300, 0.01));
      expect(ne.dy, closeTo(250, 0.01));
    });

    test('a point goes to the screen and back unchanged', () {
      for (final o in const [
        Offset(0, 0),
        Offset(37.5, 512.25),
        Offset(400, 600),
      ]) {
        final back = view.toScreen(view.toGeo(o));
        expect(back.dx, closeTo(o.dx, 1e-6));
        expect(back.dy, closeTo(o.dy, 1e-6));
      }
      final p = GeoPlot.offset(dhaka, east: -63, north: 41);
      expect(GeoPlot.distance(view.toGeo(view.toScreen(p)), p), lessThan(1e-6));
    });

    test('a view with no size, or upside down, is not usable', () {
      expect(
        MercatorView(
          size: Size.zero,
          topLeft: view.topLeft,
          bottomRight: view.bottomRight,
        ).isValid,
        isFalse,
      );
      expect(
        MercatorView(
          size: const Size(400, 600),
          topLeft: view.bottomRight,
          bottomRight: view.topLeft,
        ).isValid,
        isFalse,
      );
    });
  });

  group('typed coordinates', () {
    test('lat, lng in any of the usual spellings', () {
      expect(parseLatLng('23.8103, 90.4125'), const GeoPoint(23.8103, 90.4125));
      expect(parseLatLng(' 23.8 90.4 '), const GeoPoint(23.8, 90.4));
      expect(parseLatLng('-1.5,36'), const GeoPoint(-1.5, 36));
    });

    test('place names and impossible numbers are not coordinates', () {
      expect(parseLatLng('Savar'), isNull);
      expect(parseLatLng('Road 12, Dhanmondi'), isNull);
      expect(parseLatLng('123, 45'), isNull);
    });
  });
}
