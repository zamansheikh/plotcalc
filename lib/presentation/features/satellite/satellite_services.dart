import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, Uint8List, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';

import '../../../core/geometry/geo_plot.dart';
import 'view/google_geo_map.dart';

/// Everything the satellite screen needs from outside the app: a map, the
/// phone's location, and turning a place name into a point. Seams, so tests
/// can stand in for Google's map view and the GPS.
class SatelliteServices {
  final GeoMapBuilder map;
  final GeoLocation location;

  /// A place name, as typed, to a point on the map; `null` if not found.
  /// Throws when the lookup itself fails (no internet).
  final Future<GeoPoint?> Function(String query) geocode;

  const SatelliteServices({
    required this.map,
    required this.location,
    required this.geocode,
  });

  static final device = SatelliteServices(
    map: googleGeoMap,
    location: DeviceLocation(),
    geocode: geocodeOnDevice,
  );
}

// ------------------------------------------------------------------- map

/// What the screen can ask of the map once it is up.
abstract class GeoMapController {
  Future<void> moveTo(GeoPoint p, {double? zoom});
  Future<void> zoomBy(double delta);

  /// Brings all of [points] into view.
  Future<void> fit(List<GeoPoint> points);

  /// The point on the earth drawn at [local], measured from the map
  /// widget's top-left corner; null if the map cannot say.
  Future<GeoPoint?> pointAt(Offset local);

  /// A picture of the map as it is now (PNG), for the magnifier; null if
  /// the map cannot give one.
  Future<Uint8List?> snapshot();
}

/// What the screen hands the map to draw, and how the map reports back.
class GeoMapProps {
  final GeoPoint initialCenter;
  final double initialZoom;
  final List<GeoPoint> corners;

  /// Plots finished earlier in this visit, drawn faintly.
  final List<List<GeoPoint>> done;
  final Color accent;
  final bool satellite;

  /// The blue "you are here" dot; only once location may be used.
  final bool myLocation;

  /// Corners can be placed with a tap (not while walking).
  final bool editable;

  /// Whether the map draws the corners and outlines itself. Off while a
  /// corner is being dragged: the screen draws them then, so they follow
  /// the finger at once and stay out of the magnifier's picture.
  final bool shapes;

  /// The edges of the map that controls lie over; the plot is kept clear
  /// of them when the map moves to show it.
  final EdgeInsets covered;
  final ValueChanged<GeoPoint> onTap;
  final ValueChanged<GeoMapController> onReady;

  /// The zoom level, each time the view moves (Google's: 0 the whole
  /// world, 20 a house).
  final ValueChanged<double> onZoom;

  /// The view has come to rest.
  final VoidCallback onIdle;

  const GeoMapProps({
    required this.onZoom,
    required this.initialCenter,
    required this.initialZoom,
    required this.corners,
    required this.done,
    required this.accent,
    required this.satellite,
    required this.myLocation,
    required this.editable,
    this.shapes = true,
    this.covered = EdgeInsets.zero,
    required this.onTap,
    required this.onReady,
    required this.onIdle,
  });
}

typedef GeoMapBuilder = Widget Function(GeoMapProps props);

// -------------------------------------------------------------- location

enum LocationAccess { granted, denied, deniedForever, serviceOff }

abstract class GeoLocation {
  /// Whether location may be used now, without asking.
  Future<LocationAccess> check();

  /// Asks for permission if it may still be asked for.
  Future<LocationAccess> request();

  /// The last place the phone knew it was, if any; quick, may be old.
  Future<GeoFix?> lastKnown();

  /// Readings as they come, the most precise the phone can give.
  Stream<GeoFix> fixes();

  /// Where the user can fix [why]: the location switch, or the app's
  /// permissions.
  Future<void> openSettings(LocationAccess why);
}

class DeviceLocation implements GeoLocation {
  static LocationAccess _of(LocationPermission p) => switch (p) {
    LocationPermission.whileInUse ||
    LocationPermission.always => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    _ => LocationAccess.denied,
  };

  static GeoFix _fix(Position p) =>
      GeoFix(GeoPoint(p.latitude, p.longitude), p.accuracy);

  @override
  Future<LocationAccess> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _of(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    final now = await check();
    if (now != LocationAccess.denied) return now;
    return _of(await Geolocator.requestPermission());
  }

  @override
  Future<GeoFix?> lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : _fix(p);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<GeoFix> fixes() => Geolocator.getPositionStream(
    // A reading a second while walking a boundary; Android's default is
    // every five.
    locationSettings: defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            intervalDuration: const Duration(seconds: 1),
          )
        : const LocationSettings(accuracy: LocationAccuracy.best),
  ).map(_fix);

  @override
  Future<void> openSettings(LocationAccess why) async {
    if (why == LocationAccess.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}

// ------------------------------------------------------------- geocoding

/// "23.81, 90.41" typed straight in, as a surveyor might, needs no lookup.
GeoPoint? parseLatLng(String text) {
  final m = RegExp(
    r'^\s*(-?\d+(?:\.\d+)?)\s*[,\s]\s*(-?\d+(?:\.\d+)?)\s*$',
  ).firstMatch(text);
  if (m == null) return null;
  final lat = double.parse(m[1]!);
  final lng = double.parse(m[2]!);
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return GeoPoint(lat, lng);
}

/// Looks a place up with the phone's own geocoder (free; Android's and
/// iOS's built-in one), in Bangladesh first.
Future<GeoPoint?> geocodeOnDevice(String query) async {
  final q = query.trim();
  if (q.isEmpty) return null;
  final direct = parseLatLng(q);
  if (direct != null) return direct;
  final geocoder = gc.Geocoding();
  for (final attempt in [
    if (!q.toLowerCase().contains('bangladesh')) '$q, Bangladesh',
    q,
  ]) {
    // Nothing found is an empty list; a failed lookup throws.
    final found = await geocoder.locationFromAddress(attempt);
    if (found.isNotEmpty) {
      return GeoPoint(found.first.latitude, found.first.longitude);
    }
  }
  return null;
}
