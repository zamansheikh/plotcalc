import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/map_scale.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_breakdown.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../result/view/result_screen.dart' show ResultArgs;

/// Reads a photo from the camera or the gallery. A seam, so tests can hand
/// the screen an image without a platform picker.
typedef PickMapPhoto = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> _pickWithPlugin(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    // Plenty for tracing, and keeps a 50-megapixel photo out of memory.
    maxWidth: 4096,
    maxHeight: 4096,
    imageQuality: 92,
  );
  return file?.readAsBytes();
}

enum _Step { photo, scale, corners }

/// Measure a plot from a photo of a mouza map, in three plain steps:
/// take the photo, tell the app the length of one known line on it, tap the
/// plot's corners. Everything a CAD program would ask about (layers, units,
/// snapping, scale factors) is decided for the user.
class MouzaScreen extends StatefulWidget {
  /// A photo to start from, skipping the first step.
  final Uint8List? initialPhoto;
  final PickMapPhoto? pickPhoto;

  const MouzaScreen({super.key, this.initialPhoto, this.pickPhoto});

  @override
  State<MouzaScreen> createState() => _MouzaScreenState();
}

class _MouzaScreenState extends State<MouzaScreen> {
  _Step _step = _Step.photo;
  ui.Image? _image;
  bool _loading = false;

  /// Set once leaving is decided, so the back guard lets the pop through.
  bool _leaving = false;

  final List<Offset> _scalePoints = [];
  final _distance = TextEditingController();
  MapDistanceUnit? _unit;

  final List<Offset> _corners = [];

  /// Plots already traced on this map in this visit, shown faintly so they
  /// are not traced twice.
  final List<List<Offset>> _done = [];

  // View: screen pixels per image pixel, and where the image's top-left is.
  double? _viewScale;
  Offset _viewOffset = Offset.zero;
  Size _size = Size.zero;

  // Gesture in progress.
  int? _dragging;
  Offset _grab = Offset.zero;
  Offset? _finger;
  double _startScale = 1;
  Offset _startImagePoint = Offset.zero;

  static const _handleSlop = 28.0;

  @override
  void initState() {
    super.initState();
    final photo = widget.initialPhoto;
    if (photo != null) _load(photo);
  }

  @override
  void dispose() {
    _distance.dispose();
    _image?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- photo

  Future<void> _pick(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.mouzaPickFailed;
    try {
      final bytes = await (widget.pickPhoto ?? _pickWithPlugin)(source);
      if (bytes == null) return; // cancelled
      await _load(bytes);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _load(Uint8List bytes) async {
    setState(() => _loading = true);
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _image?.dispose();
        _image = frame.image;
        _step = _Step.scale;
        _scalePoints.clear();
        _corners.clear();
        _done.clear();
        _viewScale = null; // fit on next layout
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------- scale

  MapDistanceUnit _unitOrDefault() =>
      _unit ??
      (context.read<SettingsBloc>().state.lengthUnit == LengthUnit.m
          ? MapDistanceUnit.meter
          : MapDistanceUnit.foot);

  MapScale? get _mapScale {
    if (_scalePoints.length < 2) return null;
    final v = SheetSummary.parseAmount(_distance.text);
    if (v == null || v <= 0) return null;
    final s = MapScale(
      a: _scalePoints[0],
      b: _scalePoints[1],
      meters: _unitOrDefault().toMeters(v),
    );
    return s.isValid ? s : null;
  }

  // ---------------------------------------------------------------- view

  List<Offset> get _active => _step == _Step.scale ? _scalePoints : _corners;

  bool get _canAdd =>
      _step == _Step.corners ||
      (_step == _Step.scale && _scalePoints.length < 2);

  Offset _toImage(Offset screen) => (screen - _viewOffset) / _viewScale!;
  Offset _toScreen(Offset image) => image * _viewScale! + _viewOffset;

  void _fit() {
    final img = _image;
    if (img == null || _size.isEmpty) return;
    final s = math.min(_size.width / img.width, _size.height / img.height);
    setState(() {
      _viewScale = s;
      _viewOffset = Offset(
        (_size.width - img.width * s) / 2,
        (_size.height - img.height * s) / 2,
      );
    });
  }

  /// Zoom about the middle of the view. Buttons for this matter: pinching
  /// is hard for many people, and impossible one-handed.
  void _zoomBy(double factor) {
    final s0 = _viewScale;
    if (s0 == null || _size.isEmpty) return;
    final center = _size.center(Offset.zero);
    final anchor = _toImage(center);
    final s = (s0 * factor).clamp(0.02, 40.0);
    setState(() {
      _viewScale = s;
      _viewOffset = center - anchor * s;
    });
  }

  int? _hit(Offset screen) {
    final pts = _active;
    int? best;
    var bestD = _handleSlop;
    for (var i = 0; i < pts.length; i++) {
      final d = (_toScreen(pts[i]) - screen).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  Offset _clampToImage(Offset p) {
    final img = _image!;
    return Offset(
      p.dx.clamp(0, img.width.toDouble()),
      p.dy.clamp(0, img.height.toDouble()),
    );
  }

  /// Whether a screen point lands on the photo, not the margin around it.
  bool _onImage(Offset screen) {
    final p = _toImage(screen);
    final img = _image!;
    return p.dx >= 0 && p.dy >= 0 && p.dx <= img.width && p.dy <= img.height;
  }

  /// Adds a point under [screen]. Taps on the empty margin around the photo
  /// are ignored: pinning them to the photo's edge only made stray corners.
  bool _add(Offset screen) {
    if (!_onImage(screen)) return false;
    HapticFeedback.selectionClick();
    setState(() => _active.add(_toImage(screen)));
    return true;
  }

  void _onTapUp(TapUpDetails d) {
    if (_hit(d.localPosition) != null || !_canAdd) return;
    _add(d.localPosition);
  }

  // Press and hold places a point under a magnifier, then follows the
  // finger until it lifts: the precise way to put a corner on a thin line.
  void _onLongPressStart(LongPressStartDetails d) {
    var i = _hit(d.localPosition);
    if (i == null) {
      if (!_canAdd || !_add(d.localPosition)) return;
      i = _active.length - 1;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _dragging = i;
      _grab = _toScreen(_active[i!]) - d.localPosition;
      _finger = d.localPosition;
    });
  }

  void _onLongPressMove(LongPressMoveUpdateDetails d) =>
      _dragTo(d.localPosition);

  void _onLongPressEnd(LongPressEndDetails d) => _endDrag();

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _viewScale!;
    _startImagePoint = _toImage(d.localFocalPoint);
    final i = d.pointerCount == 1 ? _hit(d.localFocalPoint) : null;
    if (i != null) {
      setState(() {
        _dragging = i;
        _grab = _toScreen(_active[i]) - d.localFocalPoint;
        _finger = d.localFocalPoint;
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_dragging != null && d.pointerCount == 1) {
      _dragTo(d.localFocalPoint);
      return;
    }
    final s = (_startScale * d.scale).clamp(0.02, 40.0);
    setState(() {
      _viewScale = s;
      _viewOffset = d.localFocalPoint - _startImagePoint * s;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) => _endDrag();

  void _dragTo(Offset finger) {
    final i = _dragging;
    if (i == null) return;
    setState(() {
      _finger = finger;
      _active[i] = _clampToImage(_toImage(finger + _grab));
    });
  }

  void _endDrag() {
    if (_dragging == null) return;
    setState(() {
      _dragging = null;
      _finger = null;
    });
  }

  // ---------------------------------------------------------------- actions

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
    final scale = _mapScale;
    if (scale == null || _corners.length < 3) return;
    context.push(
      AppRoutes.result,
      extra: ResultArgs(
        name: context.l10n.mouzaDefaultName,
        vertices: scale.toVertices(_corners),
      ),
    );
  }

  Future<void> _back() async {
    switch (_step) {
      case _Step.corners:
        setState(() => _step = _Step.scale);
      case _Step.scale:
        if (_corners.isNotEmpty || _done.isNotEmpty) {
          if (!await _confirmLeave()) return;
        }
        _leave();
      case _Step.photo:
        _leave();
    }
  }

  /// Pops past this screen's own back guard. Popping while the guard still
  /// says "can't pop" is refused, which left Back doing nothing here.
  void _leave() {
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
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

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final t = context.l10n;

    return PopScope(
      canPop: _step == _Step.photo || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          // The body's real height, after the keyboard: the controls below
          // the map may use at most part of it.
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                const SizedBox(height: 8),
                _TopBar(
                  step: _step,
                  accent: accent,
                  onBack: _back,
                  onFit: _image == null || _step == _Step.photo ? null : _fit,
                ),
                Expanded(
                  child: _step == _Step.photo
                      ? _PhotoStep(
                          accent: accent,
                          loading: _loading,
                          onCamera: () => _pick(ImageSource.camera),
                          onGallery: () => _pick(ImageSource.gallery),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ColoredBox(
                              color: AppColors.surface,
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final size = Size(c.maxWidth, c.maxHeight);
                                  // The keyboard squeezes the map; keep what
                                  // was in the middle of it in the middle, so
                                  // the line being measured stays in sight.
                                  if (_viewScale != null &&
                                      !_size.isEmpty &&
                                      size != _size) {
                                    final focus =
                                        _step == _Step.scale &&
                                            _scalePoints.length == 2
                                        // Typing the distance: show the line.
                                        ? (_scalePoints[0] + _scalePoints[1]) /
                                                  2 *
                                                  _viewScale! +
                                              _viewOffset
                                        : _size.center(Offset.zero);
                                    _viewOffset +=
                                        size.center(Offset.zero) - focus;
                                  }
                                  _size = size;
                                  final img = _image!;
                                  if (_viewScale == null) {
                                    final s = math.min(
                                      _size.width / img.width,
                                      _size.height / img.height,
                                    );
                                    _viewScale = s;
                                    _viewOffset = Offset(
                                      (_size.width - img.width * s) / 2,
                                      (_size.height - img.height * s) / 2,
                                    );
                                  }
                                  final canvas = GestureDetector(
                                    key: const ValueKey('mouza-canvas'),
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: _onTapUp,
                                    onLongPressStart: _onLongPressStart,
                                    onLongPressMoveUpdate: _onLongPressMove,
                                    onLongPressEnd: _onLongPressEnd,
                                    onScaleStart: _onScaleStart,
                                    onScaleUpdate: _onScaleUpdate,
                                    onScaleEnd: _onScaleEnd,
                                    child: CustomPaint(
                                      size: _size,
                                      painter: _MapPainter(
                                        image: img,
                                        scale: _viewScale!,
                                        offset: _viewOffset,
                                        step: _step,
                                        scalePoints: _scalePoints,
                                        corners: _corners,
                                        done: _done,
                                        mapScale: _mapScale,
                                        scaleLabel: _distance.text.isEmpty
                                            ? null
                                            : '${_distance.text} '
                                                  '${_unitLabel(t, _unitOrDefault())}',
                                        lengthUnit: settings.lengthUnit,
                                        lengthLabel: settings.lengthUnit
                                            .labelOf(t),
                                        meterLabel: t.unitMeterShort,
                                        accent: accent,
                                        dragging: _dragging,
                                        finger: _finger,
                                      ),
                                    ),
                                  );
                                  return Stack(
                                    children: [
                                      canvas,
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: _ZoomButtons(
                                          onIn: () => _zoomBy(1.6),
                                          onOut: () => _zoomBy(1 / 1.6),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                ),
                if (_step == _Step.scale)
                  _PanelBox(
                    maxHeight: box.maxHeight * 0.45,
                    child: _ScalePanel(
                      points: _scalePoints.length,
                      controller: _distance,
                      unit: _unitOrDefault(),
                      accent: accent,
                      ready: _mapScale != null,
                      onUnit: (u) => setState(() => _unit = u),
                      onChanged: () => setState(() {}),
                      onStartOver: () => setState(() {
                        _scalePoints.clear();
                        _distance.clear();
                      }),
                      onNext: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _step = _Step.corners);
                      },
                    ),
                  ),
                if (_step == _Step.corners)
                  _PanelBox(
                    maxHeight: box.maxHeight * 0.45,
                    child: _CornersPanel(
                      corners: _corners.length,
                      areaSqm: _mapScale?.areaOf(_corners) ?? 0,
                      accent: accent,
                      onUndo: _corners.isEmpty ? null : _undo,
                      onNewPlot: _corners.isEmpty ? null : _newPlot,
                      onScale: () => setState(() => _step = _Step.scale),
                      onResult: _corners.length >= 3 ? _seeResult : null,
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

String _unitLabel(AppLocalizations t, MapDistanceUnit u) => switch (u) {
  MapDistanceUnit.foot => t.mouzaUnitFoot,
  MapDistanceUnit.meter => t.mouzaUnitMeter,
  MapDistanceUnit.chain => t.mouzaUnitChain,
  MapDistanceUnit.link => t.mouzaUnitLink,
};

// ------------------------------------------------------------------ chrome

class _TopBar extends StatelessWidget {
  final _Step step;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback? onFit;
  const _TopBar({
    required this.step,
    required this.accent,
    required this.onBack,
    required this.onFit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final labels = [t.mouzaStepPhoto, t.mouzaStepScale, t.mouzaStepCorners];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          SmallIconButton(icon: Icons.chevron_left, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.mouzaTitle,
                  style: AppTypography.sans(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                // Where you are in the three steps, at a glance.
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.chevron_right,
                            size: 12,
                            color: AppColors.textFaint,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          '${NumberFormat.decimalPattern().format(i + 1)} ${labels[i]}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(
                            size: 10,
                            weight: i == step.index
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i == step.index
                                ? accent
                                : (i < step.index
                                      ? AppColors.textDim
                                      : AppColors.textFaint),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onFit != null)
            SmallIconButton(icon: Icons.fit_screen_outlined, onTap: onFit),
        ],
      ),
    );
  }
}

/// Holds a step's controls under the map. It never takes more than its share
/// of the room left over by the keyboard, and scrolls past that: the map must stay
/// big enough to see the line being measured, even on a small phone with a
/// large font.
class _PanelBox extends StatelessWidget {
  final double maxHeight;
  final Widget child;
  const _PanelBox({required this.maxHeight, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: SingleChildScrollView(child: child),
  );
}

/// Lays its child out normally, but never gets shorter than the tallest it
/// has been. Hints change length as the user taps; if the panel holding
/// them shrank, the map above would grow and slide under the next tap.
/// Unlike a fixed height, this still fits any font size.
class _NoShrink extends SingleChildRenderObjectWidget {
  const _NoShrink({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoShrink();
}

class _RenderNoShrink extends RenderProxyBox {
  double _tallest = 0;

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints, parentUsesSize: true);
    _tallest = math.max(_tallest, c.size.height);
    size = constraints.constrain(Size(c.size.width, _tallest));
  }
}

class _ZoomButtons extends StatelessWidget {
  final VoidCallback onIn;
  final VoidCallback onOut;
  const _ZoomButtons({required this.onIn, required this.onOut});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap, Key key) => Material(
      color: AppColors.ink.withValues(alpha: 0.85),
      shape: const CircleBorder(side: BorderSide(color: AppColors.lineMid)),
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.text),
        ),
      ),
    );
    return Column(
      children: [
        button(Icons.add, onIn, const ValueKey('mouza-zoom-in')),
        const SizedBox(height: 8),
        button(Icons.remove, onOut, const ValueKey('mouza-zoom-out')),
      ],
    );
  }
}

class _PhotoStep extends StatelessWidget {
  final Color accent;
  final bool loading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _PhotoStep({
    required this.accent,
    required this.loading,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    Widget tip(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.sans(size: 13, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Icon(Icons.map_outlined, size: 64, color: accent),
          ),
        ),
        const SizedBox(height: 18),
        Text(t.mouzaPickTitle, style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        Text(t.mouzaPickSub, style: AppTypography.bodyDim),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onCamera,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(
            t.mouzaPickCamera,
            style: AppTypography.sans(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: AppColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onGallery,
          icon: Icon(Icons.photo_library_outlined, size: 18, color: accent),
          label: Text(
            t.mouzaPickGallery,
            style: AppTypography.sans(size: 15, weight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.lineMid),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.mouzaTipsTitle, style: AppTypography.monoLabel),
              tip(Icons.crop_free, t.mouzaTip1),
              tip(Icons.straighten, t.mouzaTip2),
              tip(Icons.wb_sunny_outlined, t.mouzaTip3),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final Color accent;
  const _Hint(this.text, {required this.accent});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.touch_app_outlined, size: 16, color: accent),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: AppTypography.sans(size: 13, color: AppColors.text),
        ),
      ),
    ],
  );
}

ButtonStyle _primary(Color accent) => FilledButton.styleFrom(
  backgroundColor: accent,
  foregroundColor: AppColors.ink,
  disabledBackgroundColor: AppColors.surface,
  disabledForegroundColor: AppColors.textDim,
  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle get _secondary => OutlinedButton.styleFrom(
  foregroundColor: AppColors.text,
  disabledForegroundColor: AppColors.textFaint,
  side: const BorderSide(color: AppColors.lineMid),
  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

class _ScalePanel extends StatelessWidget {
  final int points;
  final TextEditingController controller;
  final MapDistanceUnit unit;
  final Color accent;
  final bool ready;
  final ValueChanged<MapDistanceUnit> onUnit;
  final VoidCallback onChanged;
  final VoidCallback onStartOver;
  final VoidCallback onNext;
  const _ScalePanel({
    required this.points,
    required this.controller,
    required this.unit,
    required this.accent,
    required this.ready,
    required this.onUnit,
    required this.onChanged,
    required this.onStartOver,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The hint changes between the two taps; a panel that shrinks
          // would move the map under the second tap. Once both points are
          // in there is nothing left to tap, so it may size naturally again.
          _NoShrink(
            key: ValueKey(points == 2),
            child: _Hint(switch (points) {
              0 => t.mouzaScaleHintFirst,
              1 => t.mouzaScaleHintSecond,
              _ => t.mouzaDragTip,
            }, accent: accent),
          ),
          if (points == 2) ...[
            const SizedBox(height: 12),
            Text(t.mouzaScaleDistance, style: AppTypography.monoLabel),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.lineMid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      key: const ValueKey('mouza-distance'),
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9০-৯.,]'),
                        ),
                      ],
                      cursorColor: accent,
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTypography.mono(
                        size: 18,
                        weight: FontWeight.w600,
                        color: accent,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: AppTypography.mono(
                          size: 18,
                          color: AppColors.textFaint,
                        ),
                      ),
                      onChanged: (_) => onChanged(),
                      // The keyboard's tick goes on, so the Next button
                      // does not have to be found under the keyboard.
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        if (ready) onNext();
                      },
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final u in MapDistanceUnit.values) ...[
                    if (u != MapDistanceUnit.values.first)
                      const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(_unitLabel(t, u)),
                      selected: u == unit,
                      onSelected: (_) => onUnit(u),
                      showCheckmark: false,
                      labelStyle: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: u == unit ? AppColors.ink : AppColors.text,
                      ),
                      selectedColor: accent,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: u == unit ? accent : AppColors.lineMid,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.mouzaScaleNoBar,
              style: AppTypography.sans(size: 12, color: AppColors.textDim),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (points > 0) ...[
                OutlinedButton(
                  onPressed: onStartOver,
                  style: _secondary,
                  child: Text(
                    t.mouzaStartOver,
                    style: AppTypography.sans(size: 13),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: ready ? onNext : null,
                  style: _primary(accent),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.mouzaNext,
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: ready ? AppColors.ink : AppColors.textDim,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: ready ? AppColors.ink : AppColors.textDim,
                      ),
                    ],
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

class _CornersPanel extends StatelessWidget {
  final int corners;
  final double areaSqm;
  final Color accent;
  final VoidCallback? onUndo;
  final VoidCallback? onNewPlot;
  final VoidCallback onScale;
  final VoidCallback? onResult;
  const _CornersPanel({
    required this.corners,
    required this.areaSqm,
    required this.accent,
    required this.onUndo,
    required this.onNewPlot,
    required this.onScale,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    final unit = settings.areaUnit;
    final chain = AreaBreakdown.of(
      areaSqm,
      settings.breakdown,
    ).parts.map((p) => '${p.formatted} ${p.unit.labelOf(t)}').join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always laid out, filled once there is an area, so the panel's
          // height never changes while corners are tapped: a growing panel
          // shrinks the map and moves it under the finger mid-tap.
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
                  child: Text(
                    corners >= 3 ? unit.format(areaSqm) : '—',
                    key: corners >= 3 ? const ValueKey('mouza-area') : null,
                    style: AppTypography.mono(
                      size: 26,
                      weight: FontWeight.w600,
                      color: corners >= 3 ? accent : AppColors.textFaint,
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
          Text(
            corners >= 3 ? chain : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(size: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 10),
          _NoShrink(
            child: _Hint(
              corners == 0
                  ? t.mouzaTraceHintFirst
                  : t.mouzaTraceHintMore(corners),
              accent: accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: t.actionUndo,
                onPressed: onUndo,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.lineMid),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                icon: Icon(
                  Icons.undo,
                  size: 18,
                  color: onUndo == null ? AppColors.textFaint : AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onScale,
                style: _secondary,
                child: Text(
                  t.mouzaChangeScale,
                  style: AppTypography.sans(size: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onNewPlot,
                style: _secondary,
                child: Text(
                  t.mouzaNewPlot,
                  style: AppTypography.sans(size: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onResult,
                  style: _primary(accent),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t.mouzaSeeResult,
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

// ------------------------------------------------------------------ canvas

class _MapPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;
  final _Step step;
  final List<Offset> scalePoints;
  final List<Offset> corners;
  final List<List<Offset>> done;
  final MapScale? mapScale;
  final String? scaleLabel;
  final LengthUnit lengthUnit;
  final String lengthLabel;
  final String meterLabel;
  final Color accent;
  final int? dragging;
  final Offset? finger;

  _MapPainter({
    required this.image,
    required this.scale,
    required this.offset,
    required this.step,
    required this.scalePoints,
    required this.corners,
    required this.done,
    required this.mapScale,
    required this.scaleLabel,
    required this.lengthUnit,
    required this.lengthLabel,
    required this.meterLabel,
    required this.accent,
    required this.dragging,
    required this.finger,
  });

  static const _scaleColor = AppColors.amber;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    _scene(canvas, scale, offset, labels: true);
    if (mapScale != null) _scaleBar(canvas, size);
    _loupe(canvas, size);
  }

  /// Everything on the map, at a given zoom: used for the view itself and,
  /// much larger, inside the magnifier.
  void _scene(Canvas canvas, double s, Offset o, {required bool labels}) {
    Offset px(Offset p) => p * s + o;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(o.dx, o.dy, image.width * s, image.height * s),
      Paint()..filterQuality = FilterQuality.medium,
    );

    // Plots already traced on this map.
    for (final poly in done) {
      final path = Path()..addPolygon([for (final p in poly) px(p)], true);
      canvas
        ..drawPath(
          path,
          Paint()..color = AppColors.text.withValues(alpha: 0.10),
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = AppColors.text.withValues(alpha: 0.55),
        );
    }

    // The known line used for the scale.
    if (scalePoints.isNotEmpty) {
      final dim = step == _Step.corners;
      final color = _scaleColor.withValues(alpha: dim ? 0.55 : 1);
      if (scalePoints.length == 2) {
        canvas.drawLine(
          px(scalePoints[0]),
          px(scalePoints[1]),
          Paint()
            ..color = color
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
        if (labels && scaleLabel != null) {
          _pill(
            canvas,
            (px(scalePoints[0]) + px(scalePoints[1])) / 2 +
                const Offset(0, -16),
            scaleLabel!,
            fill: _scaleColor,
            ink: AppColors.ink,
          );
        }
      }
      for (var i = 0; i < scalePoints.length; i++) {
        _handle(canvas, px(scalePoints[i]), color, label: '${i + 1}');
      }
    }

    // The plot being traced.
    if (corners.isNotEmpty) {
      final pts = [for (final p in corners) px(p)];
      if (pts.length >= 3) {
        canvas.drawPath(
          Path()..addPolygon(pts, true),
          Paint()..color = accent.withValues(alpha: 0.22),
        );
      }
      final edge = Paint()
        ..color = accent
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i + 1 < pts.length; i++) {
        canvas.drawLine(pts[i], pts[i + 1], edge);
      }
      if (pts.length >= 3) {
        // The closing side, lighter: it moves as corners are added.
        canvas.drawLine(
          pts.last,
          pts.first,
          Paint()
            ..color = accent.withValues(alpha: 0.5)
            ..strokeWidth = 2,
        );
      }
      if (labels && mapScale != null) _sideLabels(canvas, pts);
      for (var i = 0; i < pts.length; i++) {
        _handle(
          canvas,
          pts[i],
          accent,
          first: i == 0,
          active: step == _Step.corners && i == dragging,
        );
      }
    }
  }

  void _sideLabels(Canvas canvas, List<Offset> pts) {
    final ms = mapScale!;
    final n = pts.length;
    final sides = n >= 3 ? n : n - 1;
    for (var i = 0; i < sides; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      if ((b - a).distance < 70) continue;
      final meters = ms.lengthOf(corners[i], corners[(i + 1) % n]);
      _pill(
        canvas,
        (a + b) / 2,
        '${lengthUnit.format(meters)} $lengthLabel',
        fill: AppColors.ink.withValues(alpha: 0.85),
        ink: AppColors.text,
        border: accent.withValues(alpha: 0.6),
      );
    }
  }

  void _handle(
    Canvas canvas,
    Offset at,
    Color color, {
    String? label,
    bool first = false,
    bool active = false,
  }) {
    final r = active ? 9.0 : (first ? 8.0 : 6.5);
    canvas
      ..drawCircle(
        at,
        r + 3,
        Paint()..color = AppColors.ink.withValues(alpha: 0.6),
      )
      ..drawCircle(at, r, Paint()..color = color)
      ..drawCircle(at, r * 0.42, Paint()..color = AppColors.ink);
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: AppTypography.mono(
            size: 10,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final c = at + const Offset(12, -12);
      canvas.drawCircle(c, 8, Paint()..color = color);
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _pill(
    Canvas canvas,
    Offset center,
    String text, {
    required Color fill,
    required Color ink,
    Color? border,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.mono(
          size: 10,
          weight: FontWeight.w600,
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: tp.width + 10,
        height: tp.height + 4,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(r, Paint()..color = fill);
    if (border != null) {
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = border,
      );
    }
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// A bar of a round real length, so the user can see the scale is sane.
  void _scaleBar(Canvas canvas, Size size) {
    final metersPerScreenPx = mapScale!.metersPerPixel / scale;
    const steps = <double>[
      1,
      2,
      5,
      10,
      20,
      50,
      100,
      200,
      500,
      1000,
      2000,
      5000,
    ];
    final m = steps.firstWhere(
      (v) => v / metersPerScreenPx >= 60,
      orElse: () => 10000,
    );
    final w = m / metersPerScreenPx;
    final left = 12.0, y = size.height - 14;
    final shadow = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.7)
      ..strokeWidth = 5;
    final bar = Paint()
      ..color = AppColors.text
      ..strokeWidth = 2;
    for (final p in [shadow, bar]) {
      canvas
        ..drawLine(Offset(left, y), Offset(left + w, y), p)
        ..drawLine(Offset(left, y - 5), Offset(left, y + 2), p)
        ..drawLine(Offset(left + w, y - 5), Offset(left + w, y + 2), p);
    }
    _pill(
      canvas,
      Offset(left + w + 28, y - 1),
      '${m.round()} $meterLabel',
      fill: AppColors.ink.withValues(alpha: 0.8),
      ink: AppColors.text,
    );
  }

  /// While a point is dragged, a magnified view of the spot under it, drawn
  /// above the finger so the finger never hides what is being placed.
  void _loupe(Canvas canvas, Size size) {
    final f = finger;
    final i = dragging;
    if (f == null || i == null) return;
    final pts = step == _Step.scale ? scalePoints : corners;
    if (i >= pts.length) return;
    final point = pts[i];

    const radius = 58.0;
    var center = f + const Offset(0, -110);
    if (center.dy < radius + 6) center = f + const Offset(0, 110);
    center = Offset(
      center.dx.clamp(radius + 6, size.width - radius - 6),
      center.dy.clamp(radius + 6, size.height - radius - 6),
    );

    final zoom = math.max(scale * 3, scale);
    final o = center - point * zoom;
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      )
      ..drawColor(AppColors.surface, BlendMode.src);
    _scene(canvas, zoom, o, labels: false);
    final cross = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 1.2;
    canvas
      ..drawLine(
        center - const Offset(14, 0),
        center + const Offset(14, 0),
        cross,
      )
      ..drawLine(
        center - const Offset(0, 14),
        center + const Offset(0, 14),
        cross,
      )
      ..restore()
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent,
      );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
