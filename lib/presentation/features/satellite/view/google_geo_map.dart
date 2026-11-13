import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/geometry/geo_plot.dart';
import '../satellite_services.dart';
import 'corner_overlay.dart';

/// The real map: Google's, through the Maps SDK, which Google does not
/// charge for on Android or iOS. It stays free only while nothing paid is
/// switched on here: no map ID (cloud styling, advanced markers), and no
/// Places or Geocoding API (place search uses the phone's own geocoder).
Widget googleGeoMap(GeoMapProps props) => _GoogleGeoMap(props: props);

class _GoogleGeoMap extends StatefulWidget {
  final GeoMapProps props;
  const _GoogleGeoMap({required this.props});

  @override
  State<_GoogleGeoMap> createState() => _GoogleGeoMapState();
}

class _GoogleGeoMapState extends State<_GoogleGeoMap>
    implements GeoMapController {
  GoogleMapController? _map;

  /// Numbered corner pins, drawn once per number and colour.
  final Map<String, BitmapDescriptor> _icons = {};
  final Set<String> _drawing = {};

  static LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);
  static GeoPoint _gp(LatLng l) => GeoPoint(l.latitude, l.longitude);

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ controller

  @override
  Future<void> moveTo(GeoPoint p, {double? zoom}) async {
    await _map?.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(_ll(p))
          : CameraUpdate.newLatLngZoom(_ll(p), zoom),
    );
  }

  @override
  Future<void> zoomBy(double delta) async {
    await _map?.animateCamera(CameraUpdate.zoomBy(delta));
  }

  @override
  Future<void> fit(List<GeoPoint> points) async {
    if (points.isEmpty) return;
    if (points.length == 1) return moveTo(points.first, zoom: 19);
    var s = points.first.lat, n = s, w = points.first.lng, e = w;
    for (final p in points) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)),
        // Room for the corner pins, inside the map's own padding.
        28,
      ),
    );
  }

  @override
  Future<GeoPoint?> pointAt(Offset local) async {
    final map = _map;
    if (map == null || !mounted) return null;
    // Android's map counts in the screen's own pixels, iOS's in points.
    final k = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1.0;
    try {
      return _gp(
        await map.getLatLng(
          ScreenCoordinate(
            x: (local.dx * k).round(),
            y: (local.dy * k).round(),
          ),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> snapshot() async {
    try {
      return await _map?.takeSnapshot();
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------------- pins

  String _key(int n, Color c) => '$n-${c.toARGB32()}';

  void _ensureIcons(int count, Color accent) {
    for (var i = 1; i <= count; i++) {
      final key = _key(i, accent);
      if (_icons.containsKey(key) || !_drawing.add(key)) continue;
      _pin(i, accent).then((icon) {
        if (!mounted) return;
        setState(() => _icons[key] = icon);
      });
    }
  }

  Future<BitmapDescriptor> _pin(int n, Color accent) async {
    const size = cornerPinSize;
    const ratio = 3.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    paintCornerPin(canvas, const Offset(size / 2, size / 2), n, accent);
    final image = await recorder.endRecording().toImage(
      (size * ratio).round(),
      (size * ratio).round(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(
      png!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final p = widget.props;
    _ensureIcons(p.corners.length, p.accent);
    final pts = [for (final c in p.corners) _ll(c)];

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _ll(p.initialCenter),
        zoom: p.initialZoom,
      ),
      onMapCreated: (c) {
        _map = c;
        p.onReady(this);
      },
      onCameraMove: (c) => p.onZoom(c.zoom),
      onCameraIdle: p.onIdle,
      // Satellite with road and place names on it: easier to find a field.
      mapType: p.satellite ? MapType.hybrid : MapType.normal,
      // North stays up and the view flat, as on a mouza map.
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      buildingsEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      padding: p.covered,
      myLocationEnabled: p.myLocation,
      myLocationButtonEnabled: false,
      onTap: p.editable ? (l) => p.onTap(_gp(l)) : null,
      markers: {
        if (p.shapes)
          for (var i = 0; i < pts.length; i++)
            Marker(
              markerId: MarkerId('corner-$i'),
              position: pts[i],
              icon:
                  _icons[_key(i + 1, p.accent)] ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    HSVColor.fromColor(p.accent).hue,
                  ),
              anchor: _icons.containsKey(_key(i + 1, p.accent))
                  ? const Offset(0.5, 0.5)
                  : const Offset(0.5, 1),
              // Corners are moved by the screen's own press-and-hold, with
              // its magnifier; the map's marker drag has none.
              consumeTapEvents: true,
            ),
      },
      polygons: {
        if (p.shapes) ...{
          for (var i = 0; i < p.done.length; i++)
            if (p.done[i].length >= 3)
              Polygon(
                polygonId: PolygonId('done-$i'),
                points: [for (final c in p.done[i]) _ll(c)],
                strokeColor: Colors.white.withValues(alpha: 0.75),
                strokeWidth: 2,
                fillColor: Colors.white.withValues(alpha: 0.12),
              ),
          if (pts.length >= 3)
            Polygon(
              polygonId: const PolygonId('plot'),
              points: pts,
              strokeColor: p.accent,
              strokeWidth: 3,
              fillColor: p.accent.withValues(alpha: 0.22),
            ),
        },
      },
      polylines: {
        if (p.shapes && pts.length == 2)
          Polyline(
            polylineId: const PolylineId('first-side'),
            points: pts,
            color: p.accent,
            width: 3,
          ),
      },
    );
  }
}
