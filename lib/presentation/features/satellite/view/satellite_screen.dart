import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/geometry/geo_plot.dart';
import '../../../../core/geometry/mercator_view.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_breakdown.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../mouza/view/map_widgets.dart';
import '../../result/view/result_screen.dart' show ResultArgs;
import '../satellite_services.dart';
import 'corner_overlay.dart';

enum SatelliteMode { tap, walk }

/// Measure land on a satellite map: find the field, then either tap its
/// corners on the photo, or walk round it and stop at each corner. The area
/// shows as it grows, in the app's units, and opens in the usual result
/// screen to save, share or print.
class SatelliteScreen extends StatefulWidget {
  /// The map, GPS and place search; the phone's own when not given.
  final SatelliteServices? services;

  const SatelliteScreen({super.key, this.services});

  @override
  State<SatelliteScreen> createState() => _SatelliteScreenState();
}

class _SatelliteScreenState extends State<SatelliteScreen> {
  late final SatelliteServices _s = widget.services ?? SatelliteServices.device;

  /// The whole country; the map opens here unless the phone already knows
  /// where it is.
  static const _bangladesh = GeoPoint(23.685, 90.3563);
  static const _countryZoom = 6.6;

  /// Closer than this, a finger's width is a few metres on the ground;
  /// further out a tap could land in the next field.
  static const _minTapZoom = 16.0;

  /// GPS radius, metres, past which a corner would be a guess.
  static const _weakGps = 10.0;

  /// Seconds of standing still per walked corner.
  static const _holdSeconds = 3;

  /// Seconds more to wait when no reading came in while standing.
  static const _graceSeconds = 4;

  /// How near a corner a touch must land to take hold of it.
  static const _grabRadius = 30.0;

  SatelliteMode _mode = SatelliteMode.tap;
  final List<GeoPoint> _corners = [];
  final List<List<GeoPoint>> _done = [];
  bool _satellite = true;
  bool _noteOpen = true;
  bool _leaving = false;

  GeoMapController? _map;
  GeoPoint? _pendingCenter;
  double _zoom = _countryZoom;

  LocationAccess? _access;
  StreamSubscription<GeoFix>? _sub;
  GeoFix? _fix;
  DateTime? _fixAt;
  bool _followedOnce = false;
  bool _locating = false;

  /// Seconds left while a walked corner is being read; null when not.
  int? _countdown;
  final List<GeoFix> _samples = [];

  final _search = TextEditingController();
  bool _searching = false;

  // The map's view as last read while it was at rest; null while it moves.
  // With it a touch is matched to a corner, and a finger to a point on the
  // earth, at once.
  MercatorView? _view;
  Size _mapSize = Size.zero;
  int _viewAge = 0;
  Timer? _reread;

  // A corner under the finger.
  _CornerDrag? _drag;
  Offset _finger = Offset.zero;
  bool _holding = false;
  ui.Image? _picture;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    _startWhereThePhoneIs();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reread?.cancel();
    _settle?.cancel();
    _picture?.dispose();
    _search.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- location

  /// If location is already allowed, open over the user rather than the
  /// whole country; never asks for permission just for this.
  Future<void> _startWhereThePhoneIs() async {
    final access = await _s.location.check();
    if (!mounted || access != LocationAccess.granted) return;
    setState(() => _access = access);
    final last = await _s.location.lastKnown();
    if (!mounted || last == null || _corners.isNotEmpty) return;
    _goTo(last.point, 17);
  }

  void _goTo(GeoPoint p, double zoom) {
    final map = _map;
    if (map == null) {
      _pendingCenter = p;
      _zoom = zoom;
    } else {
      map.moveTo(p, zoom: zoom);
    }
  }

  void _onMapReady(GeoMapController c) {
    _map = c;
    final p = _pendingCenter;
    if (p != null) {
      _pendingCenter = null;
      c.moveTo(p, zoom: _zoom);
    }
  }

  /// Asks for location if needed; tells the user what is in the way if it
  /// cannot be had.
  Future<bool> _ensureLocation() async {
    final access = await _s.location.request();
    if (!mounted) return false;
    setState(() => _access = access);
    if (access == LocationAccess.granted) return true;
    _showLocationProblem(access);
    return false;
  }

  void _showLocationProblem(LocationAccess access) {
    final t = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            access == LocationAccess.serviceOff
                ? t.satLocationOff
                : t.satPermissionDenied,
          ),
          action: access == LocationAccess.denied
              ? null
              : SnackBarAction(
                  label: t.satOpenSettings,
                  onPressed: () => _s.location.openSettings(access),
                ),
        ),
      );
  }

  void _listen() {
    _sub ??= _s.location.fixes().listen(
      (f) {
        if (!mounted) return;
        setState(() {
          _fix = f;
          _fixAt = DateTime.now();
        });
        if (_countdown != null) _samples.add(f);
        if (!_followedOnce && _mode == SatelliteMode.walk) {
          _followedOnce = true;
          _goTo(f.point, 19);
        }
      },
      // A lost signal shows as no fresh reading; nothing to report here.
      onError: (_) {},
    );
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
    _fix = null;
    _fixAt = null;
  }

  Future<void> _goToMe() async {
    if (_locating || !await _ensureLocation()) return;
    setState(() => _locating = true);
    GeoFix? f = _freshFix;
    if (f == null) {
      try {
        f = await _s.location.fixes().first.timeout(const Duration(seconds: 8));
      } catch (_) {
        f = await _s.location.lastKnown();
      }
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (f == null) {
      _snack(context.l10n.satNoFix);
      return;
    }
    _goTo(f.point, 18);
  }

  /// The latest reading, if it is recent enough to stand for "now".
  GeoFix? get _freshFix {
    final at = _fixAt;
    if (_fix == null || at == null) return null;
    return DateTime.now().difference(at) < const Duration(seconds: 10)
        ? _fix
        : null;
  }

  Future<void> _setMode(SatelliteMode m) async {
    if (m == _mode || _countdown != null) return;
    setState(() => _mode = m);
    if (m == SatelliteMode.walk) {
      if (await _ensureLocation() && mounted && _mode == SatelliteMode.walk) {
        _listen();
      }
    } else {
      setState(_stopListening);
    }
  }

  /// Reads the corner the user is standing on: every reading over a few
  /// seconds, averaged, is steadier than any one of them. Only readings
  /// that arrive while standing count: an earlier one says where the phone
  /// was on the way here.
  Future<void> _captureCorner() async {
    if (_countdown != null) return;
    _samples.clear();
    for (var s = _holdSeconds; s > 0; s--) {
      setState(() => _countdown = s);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    // Nothing came in: give the GPS a little longer before giving up.
    for (var s = 0; _samples.isEmpty && s < _graceSeconds; s++) {
      setState(() => _countdown = 0);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    final fixes = List.of(_samples);
    _samples.clear();
    setState(() => _countdown = null);
    if (fixes.isEmpty) {
      _snack(context.l10n.satNoFix);
      return;
    }
    final at = GeoFix.average(fixes).point;
    setState(() => _corners.add(at));
    _map?.moveTo(at);
  }

  // ---------------------------------------------------------------- map

  void _onTap(GeoPoint p) {
    if (_mode != SatelliteMode.tap) return;
    if (_zoom < _minTapZoom) {
      _snack(context.l10n.satZoomIn);
      return;
    }
    setState(() => _corners.add(p));
  }

  // --------------------------------------------- placing with precision

  /// Reads where the map's view sits on the earth, from the map itself.
  Future<MercatorView?> _readView() async {
    final map = _map;
    final size = _mapSize;
    if (map == null || size.isEmpty) return null;
    final age = ++_viewAge;
    final topLeft = await map.pointAt(Offset.zero);
    final bottomRight = await map.pointAt(size.bottomRight(Offset.zero));
    // The map moved or changed size while it was asked: the answer is old.
    if (!mounted || age != _viewAge) return null;
    if (topLeft == null || bottomRight == null) return null;
    final view = MercatorView(
      size: size,
      topLeft: topLeft,
      bottomRight: bottomRight,
    );
    return _view = view.isValid ? view : null;
  }

  void _viewMoved() {
    _viewAge++;
    _view = null;
  }

  int? _cornerAt(Offset local, MercatorView view) {
    int? best;
    var nearest = _grabRadius;
    for (var i = 0; i < _corners.length; i++) {
      final d = (view.toScreen(_corners[i]) - local).distance;
      if (d < nearest) {
        nearest = d;
        best = i;
      }
    }
    return best;
  }

  bool get _canDrag =>
      _mode == SatelliteMode.tap && (_drag == null || _drag!.lifted);

  /// Press and hold: takes hold of the corner there, or puts a new one
  /// down, under a magnifier; it then follows the finger until it lifts.
  Future<void> _onHoldStart(LongPressStartDetails d) async {
    if (!_canDrag) return;
    _holding = true;
    _finger = d.localPosition;
    final view = _view ?? await _readView();
    if (!mounted || !_holding || view == null || !_canDrag) return;
    var i = _cornerAt(d.localPosition, view);
    if (i == null) {
      if (_zoom < _minTapZoom) {
        _snack(context.l10n.satZoomIn);
        return;
      }
      _corners.add(view.toGeo(d.localPosition));
      i = _corners.length - 1;
    }
    _beginDrag(i, d.localPosition, view);
    // Catch up with any movement while the map was being read.
    _dragTo(_finger);
  }

  void _beginDrag(int i, Offset finger, MercatorView view) {
    HapticFeedback.mediumImpact();
    _settle?.cancel();
    setState(() {
      _drag = _CornerDrag(
        index: i,
        grab: view.toScreen(_corners[i]) - finger,
        view: view,
      );
      _finger = finger;
    });
    _takePicture(view);
  }

  void _dragTo(Offset finger) {
    final drag = _drag;
    if (drag == null || drag.lifted) return;
    final at = finger + drag.grab;
    setState(() {
      _finger = finger;
      _corners[drag.index] = drag.view.toGeo(
        Offset(at.dx.clamp(0, _mapSize.width), at.dy.clamp(0, _mapSize.height)),
      );
    });
  }

  void _endDrag() {
    _holding = false;
    final drag = _drag;
    if (drag == null || drag.lifted) return;
    HapticFeedback.selectionClick();
    // The map draws the plot again from here; this screen's own drawing of
    // it stays a moment longer, so there is no blink between the two.
    setState(() => _drag = drag.asLifted());
    _settle = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final old = _picture;
      setState(() {
        _drag = null;
        _picture = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    });
  }

  /// A picture of the bare map for the magnifier, taken once the map has
  /// stopped drawing the plot itself (or its pins would be in the way).
  Future<void> _takePicture(MercatorView view) async {
    final map = _map;
    if (map == null) return;
    bool current() => mounted && identical(_drag?.view, view) && !_drag!.lifted;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!current()) return;
    final bytes = await map.snapshot();
    if (bytes == null || !current()) return;
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    if (!current()) {
      image.dispose();
      return;
    }
    final old = _picture;
    setState(() => _picture = image);
    old?.dispose();
  }

  Future<void> _find(String query) async {
    final q = query.trim();
    if (q.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final t = context.l10n;
    GeoPoint? at;
    var failed = false;
    try {
      at = await _s.geocode(q);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() => _searching = false);
    if (at == null) {
      _snack(failed ? t.satSearchFailed : t.satSearchNone(q));
      return;
    }
    _goTo(at, 16);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------------------------------------------------- actions

  void _undo() {
    if (_corners.isEmpty) return;
    setState(() => _corners.removeLast());
  }

  void _newPlot() {
    setState(() {
      if (_corners.length >= 3) _done.add(List.of(_corners));
      _corners.clear();
    });
  }

  void _seeResult() {
    if (_corners.length < 3) return;
    context.push(
      AppRoutes.result,
      extra: ResultArgs(
        name: context.l10n.satDefaultName,
        vertices: GeoPlot.toVertices(_corners),
      ),
    );
  }

  Future<void> _back() async {
    if (_corners.isNotEmpty || _done.isNotEmpty) {
      if (!await _confirmLeave()) return;
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    // Pops once the guard has been rebuilt to let it through.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<bool> _confirmLeave() async {
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t.mouzaLeaveTitle,
          style: AppTypography.sans(size: 16, weight: FontWeight.w600),
        ),
        content: Text(
          t.mouzaLeaveBody,
          style: AppTypography.sans(size: 13, color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(
              t.actionCancel,
              style: AppTypography.sans(size: 13, color: AppColors.textDim),
            ),
          ),
          FilledButton(
            key: const ValueKey('sat-leave'),
            onPressed: () => Navigator.of(c).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.text,
            ),
            child: Text(
              t.sheetDiscard,
              style: AppTypography.sans(size: 13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  // --------------------------------------------------------------- build

  /// The map, the gestures laid over it, and the plot as drawn by this
  /// screen while a corner is dragged.
  Widget _mapLayer(Color accent) => LayoutBuilder(
    builder: (context, c) {
      final size = c.biggest;
      if (size != _mapSize) {
        _mapSize = size;
        // The map shows a different stretch of ground now; read it again
        // once it has settled into its new size.
        _viewMoved();
        _reread?.cancel();
        _reread = Timer(const Duration(milliseconds: 400), _readView);
      }
      final drag = _drag;
      return RawGestureDetector(
        key: const ValueKey('sat-map'),
        gestures: {
          // A quick tap or a swipe never becomes one of these, so both
          // still reach the map: a tap places a corner, a swipe moves it.
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(debugOwner: this),
                (r) => r
                  ..onLongPressStart = _onHoldStart
                  ..onLongPressMoveUpdate = (d) {
                    _finger = d.localPosition;
                    _dragTo(d.localPosition);
                  }
                  ..onLongPressEnd = ((_) => _endDrag())
                  ..onLongPressCancel = _endDrag,
              ),
          // Dragging from a pin moves the pin at once, without the hold.
          CornerGrabRecognizer:
              GestureRecognizerFactoryWithHandlers<CornerGrabRecognizer>(
                () => CornerGrabRecognizer(debugOwner: this),
                (r) => r
                  ..dragStartBehavior = DragStartBehavior.down
                  ..onCorner = (p) {
                    final view = _view;
                    return _canDrag &&
                        view != null &&
                        _cornerAt(p, view) != null;
                  }
                  ..onStart = (d) {
                    final view = _view;
                    if (view == null || !_canDrag) return;
                    final i = _cornerAt(d.localPosition, view);
                    if (i != null) _beginDrag(i, d.localPosition, view);
                  }
                  ..onUpdate = ((d) => _dragTo(d.localPosition))
                  ..onEnd = ((_) => _endDrag())
                  ..onCancel = _endDrag,
              ),
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _s.map(
              GeoMapProps(
                initialCenter: _bangladesh,
                initialZoom: _countryZoom,
                corners: List.unmodifiable(_corners),
                done: List.unmodifiable(_done),
                accent: accent,
                satellite: _satellite,
                myLocation: _access == LocationAccess.granted,
                editable: _mode == SatelliteMode.tap,
                shapes: drag == null || drag.lifted,
                // The search box above, the round buttons on the right.
                covered: const EdgeInsets.only(top: 58, right: 60),
                onTap: _onTap,
                onReady: _onMapReady,
                onZoom: (z) {
                  _zoom = z;
                  _viewMoved();
                },
                onIdle: () {
                  _readView();
                },
              ),
            ),
            if (drag != null)
              IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('sat-drag'),
                  painter: CornerDragPainter(
                    view: drag.view,
                    corners: List.of(_corners),
                    done: _done,
                    dragging: drag.lifted ? null : drag.index,
                    finger: _finger,
                    picture: _picture,
                    accent: accent,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    final t = context.l10n;
    final walking = _mode == SatelliteMode.walk;

    return PopScope(
      canPop: _leaving || (_corners.isEmpty && _done.isEmpty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Row(
                    children: [
                      SmallIconButton(icon: Icons.chevron_left, onTap: _back),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.satTitle,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            size: 15,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_corners.isNotEmpty)
                        SmallIconButton(
                          icon: Icons.fit_screen_outlined,
                          onTap: () => _map?.fit(_corners),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: Stack(
                          children: [
                            Positioned.fill(child: _mapLayer(accent)),
                            Positioned(
                              left: 10,
                              right: 10,
                              top: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SearchBox(
                                    controller: _search,
                                    busy: _searching,
                                    accent: accent,
                                    onSubmit: _find,
                                  ),
                                  if (_noteOpen) ...[
                                    const SizedBox(height: 8),
                                    _ApproxNote(
                                      onClose: () =>
                                          setState(() => _noteOpen = false),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Column(
                                children: [
                                  _RoundButton(
                                    key: const ValueKey('sat-layer'),
                                    icon: _satellite
                                        ? Icons.map_outlined
                                        : Icons.satellite_alt_outlined,
                                    tooltip: _satellite
                                        ? t.satMapStreet
                                        : t.satMapSatellite,
                                    onTap: () => setState(
                                      () => _satellite = !_satellite,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _RoundButton(
                                    key: const ValueKey('sat-me'),
                                    icon: Icons.my_location,
                                    tooltip: t.satMyLocation,
                                    busy: _locating,
                                    onTap: _goToMe,
                                  ),
                                  const SizedBox(height: 8),
                                  MapZoomButtons(
                                    onIn: () => _map?.zoomBy(1),
                                    onOut: () => _map?.zoomBy(-1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                MapPanelBox(
                  maxHeight: box.maxHeight * 0.5,
                  child: _Panel(
                    mode: _mode,
                    corners: _corners.length,
                    areaSqm: GeoPlot.area(_corners),
                    accent: accent,
                    access: _access,
                    fix: walking ? _freshFix : null,
                    weakGps: _weakGps,
                    countdown: _countdown,
                    onMode: _setMode,
                    onCapture:
                        _access == LocationAccess.granted &&
                            _freshFix != null &&
                            _countdown == null
                        ? _captureCorner
                        : null,
                    onAllowLocation: () async {
                      if (await _ensureLocation() && mounted) _listen();
                    },
                    onUndo: _corners.isEmpty || _countdown != null
                        ? null
                        : _undo,
                    onNewPlot: _corners.isEmpty || _countdown != null
                        ? null
                        : _newPlot,
                    onResult: _corners.length >= 3 && _countdown == null
                        ? _seeResult
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A corner with a finger on it.
class _CornerDrag {
  final int index;

  /// From the finger to the corner, so the corner does not jump under the
  /// finger when it is taken hold of.
  final Offset grab;

  /// The map's view when the drag began; it cannot move while a finger
  /// holds a corner.
  final MercatorView view;

  /// The finger has gone. This screen's drawing of the plot lingers until
  /// the map has drawn its own again.
  final bool lifted;

  const _CornerDrag({
    required this.index,
    required this.grab,
    required this.view,
    this.lifted = false,
  });

  _CornerDrag asLifted() =>
      _CornerDrag(index: index, grab: grab, view: view, lifted: true);
}

// --------------------------------------------------------------- overlays

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final Color accent;
  final ValueChanged<String> onSubmit;
  const _SearchBox({
    required this.controller,
    required this.busy,
    required this.accent,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.92),
        border: Border.all(color: AppColors.lineMid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: AppColors.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('sat-search'),
              controller: controller,
              textInputAction: TextInputAction.search,
              cursorColor: accent,
              style: AppTypography.sans(size: 14),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: context.l10n.satSearchHint,
                hintStyle: AppTypography.sans(
                  size: 14,
                  color: AppColors.textFaint,
                ),
              ),
              onSubmitted: onSubmit,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          if (busy)
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
            )
          else
            IconButton(
              key: const ValueKey('sat-search-go'),
              onPressed: () => onSubmit(controller.text),
              icon: Icon(Icons.arrow_forward, size: 18, color: accent),
            ),
        ],
      ),
    );
  }
}

class _ApproxNote extends StatelessWidget {
  final VoidCallback onClose;
  const _ApproxNote({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sat-note'),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.88),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 16, color: AppColors.amber),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.satApproxNote,
              style: AppTypography.sans(size: 12, color: AppColors.text),
            ),
          ),
          InkWell(
            key: const ValueKey('sat-note-close'),
            onTap: onClose,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 16, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.ink.withValues(alpha: 0.85),
      shape: const CircleBorder(side: BorderSide(color: AppColors.lineMid)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.text,
                  ),
                )
              : Icon(icon, size: 20, color: AppColors.text),
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------------ panel

class _Panel extends StatelessWidget {
  final SatelliteMode mode;
  final int corners;
  final double areaSqm;
  final Color accent;
  final LocationAccess? access;
  final GeoFix? fix;
  final double weakGps;
  final int? countdown;
  final ValueChanged<SatelliteMode> onMode;
  final VoidCallback? onCapture;
  final VoidCallback onAllowLocation;
  final VoidCallback? onUndo;
  final VoidCallback? onNewPlot;
  final VoidCallback? onResult;

  const _Panel({
    required this.mode,
    required this.corners,
    required this.areaSqm,
    required this.accent,
    required this.access,
    required this.fix,
    required this.weakGps,
    required this.countdown,
    required this.onMode,
    required this.onCapture,
    required this.onAllowLocation,
    required this.onUndo,
    required this.onNewPlot,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    final unit = settings.areaUnit;
    String chainOf(double sqm) => AreaBreakdown.of(
      sqm,
      settings.breakdown,
    ).parts.map((p) => '${p.formatted} ${p.unit.labelOf(t)}').join(' · ');
    final walking = mode == SatelliteMode.walk;
    final areaStyle = AppTypography.mono(size: 26, weight: FontWeight.w600);
    final chainStyle = AppTypography.sans(size: 12, color: AppColors.textDim);
    // The hint before the first corner, and after it. Room is kept for
    // both from the start (and for a two-digit count).
    final hints = walking
        ? [t.satHintWalkFirst, t.satHintWalkMore(math.max(corners, 10))]
        : [t.satHintTapFirst, t.satHintTapMore(math.max(corners, 10))];

    Widget modeChip(SatelliteMode m, IconData icon, String label) {
      final on = m == mode;
      return Expanded(
        child: InkWell(
          key: ValueKey('sat-mode-${m.name}'),
          onTap: () => onMode(m),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              color: on ? accent.withValues(alpha: 0.16) : Colors.transparent,
              border: Border.all(color: on ? accent : AppColors.lineMid),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: on ? accent : AppColors.textDim),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      size: 13,
                      weight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on ? AppColors.text : AppColors.textDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              modeChip(
                SatelliteMode.tap,
                Icons.touch_app_outlined,
                t.satModeTap,
              ),
              const SizedBox(width: 8),
              modeChip(
                SatelliteMode.walk,
                Icons.directions_walk,
                t.satModeWalk,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // The panel's height must not change while corners are tapped: a
          // growing panel shrinks the map and moves it under the finger
          // mid-tap. So each line that changes keeps room for its tallest
          // form: Bengali digits stand taller than the dash they replace,
          // and the later hint is longer than the first.
          Text(t.mouzaAreaSoFar, style: AppTypography.monoLabel),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _Reserve(
                    heightOnly: true,
                    standIns: [Text(unit.format(1234.5), style: areaStyle)],
                    child: Text(
                      corners >= 3 ? unit.format(areaSqm) : '—',
                      key: corners >= 3 ? const ValueKey('sat-area') : null,
                      style: areaStyle.copyWith(
                        color: corners >= 3 ? accent : AppColors.textFaint,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit.labelOf(t),
                style: AppTypography.sans(size: 13, color: AppColors.textDim),
              ),
            ],
          ),
          _Reserve(
            standIns: [Text(chainOf(1000), maxLines: 1, style: chainStyle)],
            child: Text(
              corners >= 3 ? chainOf(areaSqm) : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: chainStyle,
            ),
          ),
          const SizedBox(height: 12),
          _Reserve(
            standIns: [for (final text in hints) MapHint(text, accent: accent)],
            child: MapHint(
              corners == 0
                  ? hints.first
                  : (walking
                        ? t.satHintWalkMore(corners)
                        : t.satHintTapMore(corners)),
              accent: accent,
            ),
          ),
          if (walking) ...[
            const SizedBox(height: 12),
            _GpsLine(
              access: access,
              fix: fix,
              weak: weakGps,
              accent: accent,
              onAllow: onAllowLocation,
            ),
            const SizedBox(height: 12),
            _CaptureButton(
              accent: accent,
              countdown: countdown,
              onTap: onCapture,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _PanelButton(
                key: const ValueKey('sat-undo'),
                tooltip: t.actionUndo,
                width: _PanelButton.height,
                fill: AppColors.surface,
                border: AppColors.lineMid,
                onTap: onUndo,
                child: Icon(
                  Icons.undo,
                  size: 18,
                  color: onUndo == null ? AppColors.textFaint : AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              _PanelButton(
                key: const ValueKey('sat-new-plot'),
                fill: Colors.transparent,
                border: AppColors.lineMid,
                onTap: onNewPlot,
                child: Text(
                  t.mouzaNewPlot,
                  maxLines: 1,
                  style: AppTypography.sans(
                    size: 13,
                    color: onNewPlot == null
                        ? AppColors.textFaint
                        : AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PanelButton(
                  key: const ValueKey('sat-result'),
                  fill: onResult == null ? AppColors.surface : accent,
                  onTap: onResult,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t.mouzaSeeResult,
                      maxLines: 1,
                      style: AppTypography.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: onResult == null
                            ? AppColors.textDim
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the panel's buttons. Drawn by hand: Material's own buttons each
/// add different margins and minimum sizes, so side by side they came out
/// at three heights and not flush with the panel's edge.
class _PanelButton extends StatelessWidget {
  static const height = 48.0;

  final VoidCallback? onTap;
  final Color fill;
  final Color? border;
  final String? tooltip;

  /// Fixed width, for a square icon button; otherwise as wide as its label
  /// (or as its parent makes it).
  final double? width;
  final Widget child;

  const _PanelButton({
    super.key,
    required this.onTap,
    required this.fill,
    required this.child,
    this.border,
    this.tooltip,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border == null ? BorderSide.none : BorderSide(color: border!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            width: width,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width == null ? 14 : 0),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// "Corner here": ready, reading the corner (not pressable, but plainly
/// busy rather than switched off), or waiting for GPS.
class _CaptureButton extends StatelessWidget {
  final Color accent;

  /// Seconds left of standing still; 0 while waiting on a late reading;
  /// null when not reading.
  final int? countdown;
  final VoidCallback? onTap;
  const _CaptureButton({
    required this.accent,
    required this.countdown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final reading = countdown != null;
    final ready = !reading && onTap != null;
    final color = ready
        ? AppColors.ink
        : (reading ? AppColors.text : AppColors.textDim);
    return SizedBox(
      width: double.infinity,
      child: _PanelButton(
        key: const ValueKey('sat-add-here'),
        fill: ready
            ? accent
            : (reading ? accent.withValues(alpha: 0.16) : AppColors.surface),
        border: reading ? accent : null,
        onTap: reading ? null : onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Icon(Icons.add_location_alt_outlined, size: 18, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                !reading
                    ? t.satAddHere
                    : (countdown == 0
                          ? t.satWaitingGps
                          : t.satHold(countdown!)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  size: 15,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [child] in the room the tallest of [standIns] would take. The
/// stand-ins are laid out but never seen: other forms the child will take.
class _Reserve extends StatelessWidget {
  final List<Widget> standIns;
  final Widget child;

  /// Keep the stand-ins' height but not their width: for a line whose
  /// neighbours should sit right after what is shown.
  final bool heightOnly;
  const _Reserve({
    required this.standIns,
    required this.child,
    this.heightOnly = false,
  });

  @override
  Widget build(BuildContext context) => Stack(
    alignment: AlignmentDirectional.centerStart,
    children: [
      for (final s in standIns)
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: heightOnly
              ? SizedBox(
                  width: 0,
                  child: OverflowBox(
                    fit: OverflowBoxFit.deferToChild,
                    alignment: AlignmentDirectional.centerStart,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: s,
                  ),
                )
              : s,
        ),
      child,
    ],
  );
}

/// How good the GPS is right now, or what is stopping it.
class _GpsLine extends StatelessWidget {
  final LocationAccess? access;
  final GeoFix? fix;
  final double weak;
  final Color accent;
  final VoidCallback onAllow;
  const _GpsLine({
    required this.access,
    required this.fix,
    required this.weak,
    required this.accent,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final blocked = access != null && access != LocationAccess.granted;
    final (IconData icon, Color color, String text) = blocked
        ? (
            Icons.location_disabled,
            AppColors.danger,
            access == LocationAccess.serviceOff
                ? t.satLocationOff
                : t.satPermissionDenied,
          )
        : fix == null
        ? (Icons.gps_not_fixed, AppColors.textDim, t.satWaitingGps)
        : fix!.accuracy > weak
        ? (
            Icons.gps_not_fixed,
            AppColors.amber,
            '${t.satAccuracy(fix!.accuracy.round())} · ${t.satAccuracyWeak}',
          )
        : (Icons.gps_fixed, accent, t.satAccuracy(fix!.accuracy.round()));
    return Row(
      key: const ValueKey('sat-gps'),
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: _Reserve(
            standIns: [
              Text(
                '${t.satAccuracy(88)} · ${t.satAccuracyWeak}',
                style: AppTypography.sans(size: 12),
              ),
            ],
            child: Text(
              text,
              style: AppTypography.sans(size: 12, color: color),
            ),
          ),
        ),
        if (blocked)
          TextButton(
            key: const ValueKey('sat-allow'),
            onPressed: onAllow,
            child: Text(
              t.satOpenSettings,
              style: AppTypography.sans(
                size: 13,
                weight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }
}
