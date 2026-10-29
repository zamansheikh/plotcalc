import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/map_align.dart';
import '../../../../core/geometry/map_scale.dart';
import '../../../../core/geometry/polygon_overlap.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../history/view/plot_actions_sheet.dart' show showRenameDialog;
import '../../mouza/view/map_widgets.dart';
import '../../result/view/result_screen.dart' show ResultArgs;
import 'overlay_canvas.dart';
import 'overlay_report.dart';

enum _Step { maps, match, scale, measure }

/// Lay two surveys of one mouza over each other — CS on RS, say — to see
/// where an old দাগ lies now and how much of it falls in each new one.
///
/// Four steps, each doing one thing: add both photos; mark a few places
/// found on both (the app switches maps for you, shows what to look for,
/// and from the third place on puts the mark where it should be); set the
/// scale once; trace plots on either survey and read the shared area.
class OverlayScreen extends StatefulWidget {
  final PickMapPhoto? pickPhoto;
  final Uint8List? initialOld;
  final Uint8List? initialNew;

  const OverlayScreen({
    super.key,
    this.pickPhoto,
    this.initialOld,
    this.initialNew,
  });

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _View {
  double? scale;
  Offset offset = Offset.zero;
}

class _OverlayScreenState extends State<OverlayScreen> {
  _Step _step = _Step.maps;
  bool _leaving = false;

  ui.Image? _a;
  ui.Image? _b;
  bool _loadingA = false;
  bool _loadingB = false;
  String _labelA = 'CS';
  String _labelB = 'RS';

  // Matching.
  final List<(Offset, Offset)> _pairs = [];
  Offset? _pendingA;
  Offset? _pendingB;
  int? _selected;
  bool _guessed = false;

  /// Whether a tap on the map moves the selected place's mark. Only right
  /// after the app guessed a mark, or after the user picked a place from
  /// its number: a place just finished by hand stays highlighted, but the
  /// next tap starts the next place, which is what anyone tapping on.
  bool _tapMoves = false;
  MapAlignment? _align;
  OverlayView _view = OverlayView.a;

  // Overlay look.
  double _mix = 0.5;
  bool _tint = true;

  // Scale.
  final List<Offset> _scalePoints = [];
  final _distance = TextEditingController();
  MapDistanceUnit? _unit;

  // Measuring.
  final List<OverlayPlot> _plots = [];
  final List<Offset> _draft = [];
  bool _draftOnNew = false;

  // Views: one in A's pixels (also used for the overlay), one in B's.
  final _viewA = _View();
  final _viewB = _View();
  Size _size = Size.zero;

  // Gesture in progress.
  int? _dragging;
  Offset _grab = Offset.zero;
  Offset? _finger;
  double _startScale = 1;
  Offset _startImagePoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.initialOld != null) _load(widget.initialOld!, old: true);
    if (widget.initialNew != null) _load(widget.initialNew!, old: false);
  }

  @override
  void dispose() {
    _distance.dispose();
    _a?.dispose();
    _b?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ photos

  Future<void> _pick(bool old) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (c) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(c.l10n.mouzaPickCamera),
                onTap: () => Navigator.of(c).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(c.l10n.mouzaPickGallery),
                onTap: () => Navigator.of(c).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.mouzaPickFailed;
    try {
      final bytes = await (widget.pickPhoto ?? pickMapPhotoWithPlugin)(source);
      if (bytes != null) await _load(bytes, old: old);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _load(Uint8List bytes, {required bool old}) async {
    setState(() => old ? _loadingA = true : _loadingB = true);
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        if (old) {
          _a?.dispose();
          _a = frame.image;
          _viewA.scale = null;
        } else {
          _b?.dispose();
          _b = frame.image;
          _viewB.scale = null;
        }
        // A new photo invalidates everything matched against the old one.
        _pairs.clear();
        _pendingA = _pendingB = null;
        _selected = null;
        _align = null;
        _scalePoints.clear();
        _plots.clear();
        _draft.clear();
      });
    } finally {
      if (mounted) setState(() => old ? _loadingA = false : _loadingB = false);
    }
  }

  // ------------------------------------------------------------ geometry

  _View get _currentView => _view == OverlayView.b ? _viewB : _viewA;
  ui.Image get _currentImage => _view == OverlayView.b ? _b! : _a!;

  Offset _toImage(Offset screen) {
    final v = _currentView;
    return (screen - v.offset) / v.scale!;
  }

  Offset _toScreen(Offset image) {
    final v = _currentView;
    return image * v.scale! + v.offset;
  }

  bool _onImage(Offset imagePoint, ui.Image img) =>
      imagePoint.dx >= 0 &&
      imagePoint.dy >= 0 &&
      imagePoint.dx <= img.width &&
      imagePoint.dy <= img.height;

  /// In the overlay, a point counts as on the map when it is on either
  /// photo.
  bool _onOverlay(Offset aPoint) {
    if (_onImage(aPoint, _a!)) return true;
    final t = _align?.bToA;
    return t != null && _onImage(t.inverse().apply(aPoint), _b!);
  }

  void _fitView(_View v, ui.Image img) {
    if (_size.isEmpty) return;
    final s = math.min(_size.width / img.width, _size.height / img.height);
    v.scale = s;
    v.offset = Offset(
      (_size.width - img.width * s) / 2,
      (_size.height - img.height * s) / 2,
    );
  }

  void _fit() {
    setState(() => _fitView(_currentView, _currentImage));
  }

  void _zoomBy(double factor) {
    final v = _currentView;
    if (v.scale == null || _size.isEmpty) return;
    final c = _size.center(Offset.zero);
    final anchor = (c - v.offset) / v.scale!;
    setState(() {
      v.scale = (v.scale! * factor).clamp(0.02, 40.0);
      v.offset = c - anchor * v.scale!;
    });
  }

  /// Centres [v] on [p] at [scale] (when given).
  void _centre(_View v, Offset p, {double? scale}) {
    if (_size.isEmpty) return;
    v.scale = scale ?? v.scale;
    v.offset = _size.center(Offset.zero) - p * v.scale!;
  }

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

  // ------------------------------------------------------------ matching

  void _refit() => _align = MapAlignment.fit(_pairs);

  /// Shows the other map for the twin of a just-marked point, at the same
  /// ground scale, centred where the twin should be.
  void _switchForTwin({required bool toNew, required Offset mark}) {
    final from = toNew ? _viewA : _viewB;
    final to = toNew ? _viewB : _viewA;
    final fromImg = toNew ? _a! : _b!;
    final toImg = toNew ? _b! : _a!;
    if (to.scale == null) _fitView(to, toImg);
    final t = _align?.bToA;
    if (t != null) {
      final m = toNew ? t.inverse() : t;
      final there = m.apply(mark);
      final s = from.scale! * (toNew ? t.inverse() : t).localScale(mark);
      _centre(to, there, scale: s.clamp(0.02, 40.0));
    } else {
      // No fit yet: assume both sheets are framed alike.
      final rel = Offset(mark.dx / fromImg.width, mark.dy / fromImg.height);
      final s = from.scale! * fromImg.width / toImg.width;
      _centre(
        to,
        Offset(rel.dx * toImg.width, rel.dy * toImg.height),
        scale: s.clamp(0.02, 40.0),
      );
    }
    _view = toNew ? OverlayView.b : OverlayView.a;
  }

  void _matchTap(Offset screen) {
    if (_view == OverlayView.both) return;
    final onA = _view == OverlayView.a;
    final p = _toImage(screen);
    if (!_onImage(p, _currentImage)) return;
    HapticFeedback.selectionClick();
    setState(() {
      // With a place picked for checking, a tap says "no, it is here": move
      // its mark.
      final sel = _selected;
      if (sel != null && _tapMoves) {
        final (pa, pb) = _pairs[sel];
        _pairs[sel] = onA ? (p, pb) : (pa, p);
        _guessed = false;
        _refit();
        return;
      }
      final waiting = onA ? _pendingB : _pendingA;
      if (waiting != null) {
        // Completes a pair.
        _pairs.add(onA ? (p, waiting) : (waiting, p));
        _pendingA = _pendingB = null;
        _selected = _pairs.length - 1;
        _guessed = false;
        _tapMoves = false;
        _refit();
        return;
      }
      _selected = null;
      _tapMoves = false;
      final t = _align?.bToA;
      if (t != null) {
        // Enough to predict: place the twin and let the user check it.
        final twin = onA ? t.inverse().apply(p) : t.apply(p);
        if (_onImage(twin, onA ? _b! : _a!)) {
          _pairs.add(onA ? (p, twin) : (twin, p));
          _selected = _pairs.length - 1;
          _guessed = true;
          _tapMoves = true;
          _refit();
          _switchForTwin(toNew: onA, mark: p);
          return;
        }
      }
      if (onA) {
        _pendingA = p;
      } else {
        _pendingB = p;
      }
      _guessed = false;
      _switchForTwin(toNew: onA, mark: p);
    });
  }

  void _nextPlace() {
    setState(() {
      _selected = null;
      _tapMoves = false;
      _guessed = false;
      _pendingA = _pendingB = null;
      _view = OverlayView.a;
    });
  }

  void _removeSelected() {
    final i = _selected;
    if (i == null) return;
    setState(() {
      _pairs.removeAt(i);
      _selected = null;
      _tapMoves = false;
      _guessed = false;
      _refit();
    });
  }

  void _selectPair(int i) {
    setState(() {
      _selected = i;
      _tapMoves = true;
      _pendingA = _pendingB = null;
      _guessed = false;
      if (_view == OverlayView.both) _view = OverlayView.a;
      final p = _view == OverlayView.a ? _pairs[i].$1 : _pairs[i].$2;
      _centre(_currentView, p);
    });
  }

  Color _pairColor(int i) {
    final al = _align;
    if (al == null || !al.checkable) return AppColors.sky;
    final w = _a!.width.toDouble();
    if (al.suspect(w) == i) return AppColors.danger;
    final r = al.residuals[i] / w;
    if (r < 0.0015) return AppColors.emerald;
    if (r < 0.004) return AppColors.amber;
    return AppColors.danger;
  }

  // ------------------------------------------------------------ dragging

  /// The points the current step lets the user drag, in the view's pixels.
  List<Offset> get _draggable => switch (_step) {
    _Step.match =>
      _selected == null
          ? const []
          : [
              _view == OverlayView.b
                  ? _pairs[_selected!].$2
                  : _pairs[_selected!].$1,
            ],
    _Step.scale => _scalePoints,
    _Step.measure => _draft,
    _Step.maps => const [],
  };

  void _setDraggable(int i, Offset p) {
    switch (_step) {
      case _Step.match:
        final k = _selected!;
        final (a, b) = _pairs[k];
        _pairs[k] = _view == OverlayView.b ? (a, p) : (p, b);
        _guessed = false;
        _refit();
      case _Step.scale:
        _scalePoints[i] = p;
      case _Step.measure:
        _draft[i] = p;
      case _Step.maps:
        break;
    }
  }

  int? _hit(Offset screen) {
    final pts = _draggable;
    int? best;
    var bestD = 28.0;
    for (var i = 0; i < pts.length; i++) {
      final d = (_toScreen(pts[i]) - screen).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void _onTapUp(TapUpDetails d) {
    switch (_step) {
      case _Step.match:
        // Correcting a place: every tap moves its mark, however close to
        // where it already is — a small nudge is the usual correction.
        if (!_tapMoves && _hit(d.localPosition) != null) return;
        _matchTap(d.localPosition);
      case _Step.scale:
        if (_hit(d.localPosition) != null || _scalePoints.length >= 2) return;
        final p = _toImage(d.localPosition);
        if (!_onOverlay(p)) return;
        HapticFeedback.selectionClick();
        setState(() => _scalePoints.add(p));
      case _Step.measure:
        if (_hit(d.localPosition) != null) return;
        final p = _toImage(d.localPosition);
        if (!_onOverlay(p)) return;
        HapticFeedback.selectionClick();
        setState(() => _draft.add(p));
      case _Step.maps:
        break;
    }
  }

  void _startDrag(int i, Offset finger) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragging = i;
      _grab = _toScreen(_draggable[i]) - finger;
      _finger = finger;
    });
  }

  void _onLongPressStart(LongPressStartDetails d) {
    var i = _hit(d.localPosition);
    if (i == null) {
      // Press and hold places a point under the magnifier, the precise way.
      final before = _draggable.length;
      _onTapUp(
        TapUpDetails(
          kind: ui.PointerDeviceKind.touch,
          localPosition: d.localPosition,
          globalPosition: d.globalPosition,
        ),
      );
      if (_step == _Step.match) {
        // A match tap may switch maps; only follow it on the same map.
        if (_selected == null || _view == OverlayView.both) return;
        if (_guessed) return;
        i = 0;
      } else {
        if (_draggable.length == before) return;
        i = _draggable.length - 1;
      }
    }
    _startDrag(i, d.localPosition);
  }

  void _onScaleStart(ScaleStartDetails d) {
    final v = _currentView;
    _startScale = v.scale!;
    _startImagePoint = _toImage(d.localFocalPoint);
    final i = d.pointerCount == 1 ? _hit(d.localFocalPoint) : null;
    if (i != null) _startDrag(i, d.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_dragging != null && d.pointerCount == 1) {
      _dragTo(d.localFocalPoint);
      return;
    }
    final v = _currentView;
    setState(() {
      v.scale = (_startScale * d.scale).clamp(0.02, 40.0);
      v.offset = d.localFocalPoint - _startImagePoint * v.scale!;
    });
  }

  void _dragTo(Offset finger) {
    final i = _dragging;
    if (i == null) return;
    setState(() {
      _finger = finger;
      _setDraggable(i, _toImage(finger + _grab));
    });
  }

  void _endDrag() {
    if (_dragging == null) return;
    setState(() {
      _dragging = null;
      _finger = null;
    });
  }

  // ------------------------------------------------------------ measuring

  Future<void> _finishPlot() async {
    if (_draft.length < 3) return;
    final t = context.l10n;
    final label = _draftOnNew ? _labelB : _labelA;
    final count = _plots.where((p) => p.onNew == _draftOnNew).length + 1;
    final name = await showRenameDialog(
      context,
      currentName:
          '$label ${t.overlayPlot} ${NumberFormat.decimalPattern().format(count)}',
      accent: context.read<SettingsBloc>().state.accent,
      title: t.overlayPlotNameTitle,
    );
    if (name == null || !mounted) return;
    setState(() {
      _plots.add(OverlayPlot(name, List.of(_draft), _draftOnNew));
      _draft.clear();
    });
  }

  void _openPlot(OverlayPlot p) {
    final s = _mapScale;
    if (s == null) return;
    context.push(
      AppRoutes.result,
      extra: ResultArgs(name: p.name, vertices: s.toVertices(p.points)),
    );
  }

  Future<void> _report() async {
    final s = _mapScale;
    if (s == null || _plots.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.l10n;
    final settings = context.read<SettingsBloc>().state;
    try {
      await OverlayReport.share(
        t: t,
        frame: _frame(context, forReport: true),
        plots: _plots,
        scale: s,
        alignment: _align!,
        labelOld: _labelA,
        labelNew: _labelB,
        areaUnit: settings.areaUnit,
        lengthUnit: settings.lengthUnit,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.exportFailed)));
    }
  }

  // ------------------------------------------------------------ navigation

  bool get _hasWork => _pairs.isNotEmpty || _plots.isNotEmpty;

  Future<void> _back() async {
    switch (_step) {
      case _Step.measure:
        setState(() {
          _step = _Step.scale;
          _draft.clear();
        });
      case _Step.scale:
        setState(() {
          _step = _Step.match;
          _view = OverlayView.both;
        });
      case _Step.match:
        setState(() {
          _step = _Step.maps;
          _pendingA = _pendingB = null;
        });
      case _Step.maps:
        if (_hasWork && !await _confirmLeave()) return;
        _leave();
    }
  }

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
          t.overlayLeaveBody,
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

  void _goTo(_Step step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _dragging = null;
      if (step == _Step.match) {
        _view = OverlayView.a;
      } else if (step != _Step.maps) {
        _view = OverlayView.both;
      }
    });
  }

  // ------------------------------------------------------------ build

  OverlayFrame _frame(BuildContext context, {bool forReport = false}) {
    final settings = context.read<SettingsBloc>().state;
    final t = context.l10n;
    return OverlayFrame(
      a: _a!,
      b: _b!,
      bToA: _align?.bToA,
      view: forReport ? OverlayView.both : _view,
      mix: _mix,
      tint: forReport ? true : _tint,
      // The matched places only matter while matching; afterwards their
      // markers would sit among the scale points and plot corners.
      pairs: forReport || _step != _Step.match ? const [] : _pairs,
      pairColors: [for (var i = 0; i < _pairs.length; i++) _pairColor(i)],
      selectedPair: _selected,
      pendingA: _pendingA,
      pendingB: _pendingB,
      // Shown only while being set; when measuring, the scale bar in the
      // corner tells the scale without covering the map.
      scalePoints: _step == _Step.scale ? _scalePoints : const [],
      scaleLabel: _distance.text.isEmpty
          ? null
          : '${_distance.text} ${mapDistanceUnitLabel(t, _unitOrDefault())}',
      mapScale: _mapScale,
      plots: [
        for (final p in _plots)
          OverlayShape(p.points, p.onNew ? newInk : oldInk, p.name),
      ],
      draft: forReport ? const [] : _draft,
      draftColor: _draftOnNew ? newInk : oldInk,
      accent: settings.accent,
      lengthUnit: settings.lengthUnit,
      lengthLabel: settings.lengthUnit.labelOf(t),
      meterLabel: t.unitMeterShort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final t = context.l10n;

    return PopScope(
      canPop: (_step == _Step.maps && !_hasWork) || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                const SizedBox(height: 8),
                _TopBar(
                  step: _step,
                  accent: accent,
                  onBack: _back,
                  onFit: _step == _Step.maps ? null : _fit,
                  onReport:
                      _step == _Step.measure &&
                          _plots.isNotEmpty &&
                          _mapScale != null
                      ? _report
                      : null,
                ),
                Expanded(
                  child: _step == _Step.maps
                      ? _MapsStep(
                          a: _a,
                          b: _b,
                          loadingA: _loadingA,
                          loadingB: _loadingB,
                          labelA: _labelA,
                          labelB: _labelB,
                          accent: accent,
                          onPick: _pick,
                          onLabel: (old, l) =>
                              setState(() => old ? _labelA = l : _labelB = l),
                        )
                      : _canvas(context),
                ),
                if (_step != _Step.maps &&
                    (_view == OverlayView.both || _step == _Step.match))
                  _ViewBar(
                    view: _view,
                    labelA: _labelA,
                    labelB: _labelB,
                    canOverlay: _align != null,
                    showSwitch: _step == _Step.match,
                    mix: _mix,
                    tint: _tint,
                    accent: accent,
                    onView: (v) => setState(() {
                      _view = v;
                      if (v == OverlayView.b && _viewB.scale == null) {
                        _fitView(_viewB, _b!);
                      }
                      // Checking a place: show it on the map just opened,
                      // not wherever that map was last left.
                      final sel = _selected;
                      if (sel != null && v != OverlayView.both) {
                        final (pa, pb) = _pairs[sel];
                        _centre(_currentView, v == OverlayView.a ? pa : pb);
                      }
                    }),
                    onMix: (m) => setState(() => _mix = m),
                    onTint: () => setState(() => _tint = !_tint),
                  ),
                MapPanelBox(
                  maxHeight: box.maxHeight * 0.42,
                  child: switch (_step) {
                    _Step.maps => _MapsNext(
                      ready: _a != null && _b != null,
                      accent: accent,
                      onNext: () => _goTo(_Step.match),
                    ),
                    _Step.match => _MatchPanel(
                      pairs: _pairs.length,
                      waitingOn: _pendingA != null
                          ? _labelB
                          : (_pendingB != null ? _labelA : null),
                      guessed: _guessed,
                      moving: _tapMoves && !_guessed && _selected != null,
                      selected: _selected,
                      pairColors: [
                        for (var i = 0; i < _pairs.length; i++) _pairColor(i),
                      ],
                      alignment: _align,
                      imageWidth: _a?.width.toDouble() ?? 1,
                      accent: accent,
                      onSelect: _selectPair,
                      onRemove: _selected == null ? null : _removeSelected,
                      onNextPlace: _nextPlace,
                      onNext: _align == null ? null : () => _goTo(_Step.scale),
                    ),
                    _Step.scale => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Text(
                            t.overlayScaleHint,
                            style: AppTypography.sans(
                              size: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                        ),
                        MapScalePanel(
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
                          onNext: () => _goTo(_Step.measure),
                        ),
                      ],
                    ),
                    _Step.measure => _MeasurePanel(
                      plots: _plots,
                      draftCorners: _draft.length,
                      draftOnNew: _draftOnNew,
                      labelA: _labelA,
                      labelB: _labelB,
                      scale: _mapScale,
                      accent: accent,
                      onLayer: (onNew) => setState(() {
                        _draftOnNew = onNew;
                      }),
                      onUndo: _draft.isEmpty
                          ? null
                          : () => setState(() => _draft.removeLast()),
                      onFinish: _draft.length >= 3 ? _finishPlot : null,
                      onOpen: _openPlot,
                      onDelete: (p) => setState(() => _plots.remove(p)),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _canvas(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            // Keep what was in the middle in the middle when the keyboard
            // or a panel changes the room.
            if (!_size.isEmpty && size != _size) {
              final shift =
                  size.center(Offset.zero) - _size.center(Offset.zero);
              for (final v in [_viewA, _viewB]) {
                if (v.scale != null) v.offset += shift;
              }
            }
            _size = size;
            if (_viewA.scale == null) _fitView(_viewA, _a!);
            if (_viewB.scale == null) _fitView(_viewB, _b!);
            final v = _currentView;

            // The other map around the place being matched, so the user
            // knows what to look for.
            ({ui.Image image, Offset at, String label, Color color})? inset;
            if (_step == _Step.match && _view != OverlayView.both) {
              final onA = _view == OverlayView.a;
              Offset? there;
              if (onA && _pendingB != null) there = _pendingB;
              if (!onA && _pendingA != null) there = _pendingA;
              if (_selected != null) {
                there = onA ? _pairs[_selected!].$2 : _pairs[_selected!].$1;
              }
              if (there != null) {
                inset = (
                  image: onA ? _b! : _a!,
                  at: there,
                  label: onA ? _labelB : _labelA,
                  color: onA ? newInk : oldInk,
                );
              }
            }

            final dragging = _dragging;
            final canvas = GestureDetector(
              key: const ValueKey('overlay-canvas'),
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onLongPressStart: _onLongPressStart,
              onLongPressMoveUpdate: (d) => _dragTo(d.localPosition),
              onLongPressEnd: (_) => _endDrag(),
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: (_) => _endDrag(),
              child: CustomPaint(
                size: size,
                painter: OverlayPainter(
                  frame: _frame(context),
                  scale: v.scale!,
                  offset: v.offset,
                  inset: inset,
                  finger: _finger,
                  dragPoint: dragging == null || dragging >= _draggable.length
                      ? null
                      : _draggable[dragging],
                ),
              ),
            );
            return Stack(
              children: [
                canvas,
                Positioned(
                  right: 10,
                  top: 10,
                  child: MapZoomButtons(
                    onIn: () => _zoomBy(1.6),
                    onOut: () => _zoomBy(1 / 1.6),
                  ),
                ),
                if (_step == _Step.match && _view != OverlayView.both)
                  Positioned(
                    left: inset == null ? 10 : 140,
                    top: 10,
                    child: _MapTag(
                      label: _view == OverlayView.a ? _labelA : _labelB,
                      color: _view == OverlayView.a ? oldInk : newInk,
                      semantic: t.overlayTitle,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ chrome

class _TopBar extends StatelessWidget {
  final _Step step;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback? onFit;
  final VoidCallback? onReport;
  const _TopBar({
    required this.step,
    required this.accent,
    required this.onBack,
    required this.onFit,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final labels = [
      t.overlayStepMaps,
      t.overlayStepMatch,
      t.mouzaStepScale,
      t.overlayStepMeasure,
    ];
    final n = NumberFormat.decimalPattern();
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
                  t.overlayTitle,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < labels.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.chevron_right,
                              size: 12,
                              color: AppColors.textFaint,
                            ),
                          ),
                        Text(
                          '${n.format(i + 1)} ${labels[i]}',
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
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onReport != null) ...[
            SmallIconButton(
              icon: Icons.picture_as_pdf_outlined,
              onTap: onReport,
            ),
            const SizedBox(width: 6),
          ],
          if (onFit != null)
            SmallIconButton(icon: Icons.fit_screen_outlined, onTap: onFit),
        ],
      ),
    );
  }
}

class _MapTag extends StatelessWidget {
  final String label;
  final Color color;
  final String semantic;
  const _MapTag({
    required this.label,
    required this.color,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTypography.sans(
        size: 14,
        weight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

// ------------------------------------------------------------ step 1: maps

class _MapsStep extends StatelessWidget {
  final ui.Image? a;
  final ui.Image? b;
  final bool loadingA;
  final bool loadingB;
  final String labelA;
  final String labelB;
  final Color accent;
  final ValueChanged<bool> onPick;
  final void Function(bool old, String label) onLabel;

  const _MapsStep({
    required this.a,
    required this.b,
    required this.loadingA,
    required this.loadingB,
    required this.labelA,
    required this.labelB,
    required this.accent,
    required this.onPick,
    required this.onLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text(t.overlayMapsTitle, style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        Text(t.overlayMapsSub, style: AppTypography.bodyDim),
        const SizedBox(height: 16),
        _MapSlot(
          title: t.overlayMapOld,
          image: a,
          loading: loadingA,
          label: labelA,
          choices: const ['CS', 'SA', 'RS'],
          color: oldInk,
          accent: accent,
          onPick: () => onPick(true),
          onLabel: (l) => onLabel(true, l),
        ),
        const SizedBox(height: 12),
        _MapSlot(
          title: t.overlayMapNew,
          image: b,
          loading: loadingB,
          label: labelB,
          choices: const ['RS', 'BS', 'SA'],
          color: newInk,
          accent: accent,
          onPick: () => onPick(false),
          onLabel: (l) => onLabel(false, l),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.overlaySameSheet,
                style: AppTypography.sans(size: 12, color: AppColors.textDim),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapSlot extends StatelessWidget {
  final String title;
  final ui.Image? image;
  final bool loading;
  final String label;
  final List<String> choices;
  final Color color;
  final Color accent;
  final VoidCallback onPick;
  final ValueChanged<String> onLabel;

  const _MapSlot({
    required this.title,
    required this.image,
    required this.loading,
    required this.label,
    required this.choices,
    required this.color,
    required this.accent,
    required this.onPick,
    required this.onLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final img = image;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: img == null ? AppColors.line : color.withValues(alpha: 0.8),
          width: img == null ? 1 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 92,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: loading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                    )
                  : img == null
                  ? Icon(Icons.add_photo_alternate_outlined, color: accent)
                  : RawImage(image: img, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in [...choices, t.overlaySurveyOther])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: c == label,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => onLabel(c),
                            labelStyle: AppTypography.sans(
                              size: 12,
                              weight: FontWeight.w600,
                              color: c == label ? Colors.white : AppColors.text,
                            ),
                            selectedColor: color,
                            backgroundColor: AppColors.ink,
                            side: BorderSide(
                              color: c == label ? color : AppColors.lineMid,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onPick,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    img == null ? Icons.add : Icons.swap_horiz,
                    size: 16,
                    color: accent,
                  ),
                  label: Text(
                    img == null ? t.overlayAddPhoto : t.actionChange,
                    style: AppTypography.sans(size: 13, color: accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapsNext extends StatelessWidget {
  final bool ready;
  final Color accent;
  final VoidCallback onNext;
  const _MapsNext({
    required this.ready,
    required this.accent,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: ready ? onNext : null,
        style: mapPrimaryButtonStyle(accent),
        child: Text(
          context.l10n.mouzaNext,
          style: AppTypography.sans(
            size: 14,
            weight: FontWeight.w600,
            color: ready ? AppColors.ink : AppColors.textDim,
          ),
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------ view bar

/// Which map is shown, and — over each other — how the two are blended.
class _ViewBar extends StatelessWidget {
  final OverlayView view;
  final String labelA;
  final String labelB;
  final bool canOverlay;
  final bool showSwitch;
  final double mix;
  final bool tint;
  final Color accent;
  final ValueChanged<OverlayView> onView;
  final ValueChanged<double> onMix;
  final VoidCallback onTint;

  const _ViewBar({
    required this.view,
    required this.labelA,
    required this.labelB,
    required this.canOverlay,
    required this.showSwitch,
    required this.mix,
    required this.tint,
    required this.accent,
    required this.onView,
    required this.onMix,
    required this.onTint,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    Widget seg(OverlayView v, String label, Color color, bool enabled) {
      final on = view == v;
      return Expanded(
        child: InkWell(
          onTap: enabled ? () => onView(v) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: AppTypography.sans(
                size: 13,
                weight: FontWeight.w700,
                color: !enabled
                    ? AppColors.textFaint
                    : (on ? Colors.white : AppColors.textDim),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          if (showSwitch)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  seg(OverlayView.a, labelA, oldInk, true),
                  seg(OverlayView.b, labelB, newInk, true),
                  seg(
                    OverlayView.both,
                    t.overlayViewBoth,
                    overlapInk,
                    canOverlay,
                  ),
                ],
              ),
            ),
          if (view == OverlayView.both)
            Row(
              children: [
                _Swatch(label: labelA, color: oldInk),
                Expanded(
                  child: Slider(
                    key: const ValueKey('overlay-mix'),
                    value: mix,
                    onChanged: onMix,
                    activeColor: overlapInk,
                    inactiveColor: AppColors.lineMid,
                  ),
                ),
                _Swatch(label: labelB, color: newInk),
                IconButton(
                  tooltip: t.overlayColours,
                  onPressed: onTint,
                  icon: Icon(
                    tint ? Icons.palette : Icons.palette_outlined,
                    color: tint ? accent : AppColors.textDim,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final String label;
  final Color color;
  const _Swatch({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: AppTypography.sans(
        size: 12,
        weight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

// ------------------------------------------------------------ step 2: match

class _MatchPanel extends StatelessWidget {
  final int pairs;
  final String? waitingOn;
  final bool guessed;
  final bool moving;
  final int? selected;
  final List<Color> pairColors;
  final MapAlignment? alignment;
  final double imageWidth;
  final Color accent;
  final ValueChanged<int> onSelect;
  final VoidCallback? onRemove;
  final VoidCallback onNextPlace;
  final VoidCallback? onNext;

  const _MatchPanel({
    required this.pairs,
    required this.waitingOn,
    required this.guessed,
    required this.moving,
    required this.selected,
    required this.pairColors,
    required this.alignment,
    required this.imageWidth,
    required this.accent,
    required this.onSelect,
    required this.onRemove,
    required this.onNextPlace,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final n = NumberFormat.decimalPattern();
    final al = alignment;
    final hint = waitingOn != null
        ? t.overlayMatchOther(waitingOn!)
        : guessed
        ? t.overlayMatchGuessed
        : moving
        ? t.overlayMovePlace(n.format(selected! + 1))
        : (pairs == 0 ? t.overlayMatchStart : t.overlayMatchMore(pairs));

    String? quality;
    Color qualityColor = AppColors.textDim;
    if (al != null) {
      final suspect = al.suspect(imageWidth);
      switch (al.quality(imageWidth)) {
        case AlignQuality.unchecked:
          quality = t.overlayQualityUnchecked(4 - pairs);
        case AlignQuality.good:
          quality = t.overlayQualityGood;
          qualityColor = AppColors.emerald;
        case AlignQuality.fair:
          quality = suspect != null
              ? t.overlaySuspect(n.format(suspect + 1))
              : t.overlayQualityFair;
          qualityColor = AppColors.amber;
        case AlignQuality.poor:
          quality = suspect != null
              ? t.overlaySuspect(n.format(suspect + 1))
              : '${t.overlayQualityPoor}. ${t.overlayQualityPoorWhich}';
          qualityColor = AppColors.danger;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          NoShrink(child: MapHint(hint, accent: accent)),
          if (pairs > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pairs,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final on = selected == i;
                  return InkWell(
                    onTap: () => onSelect(i),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? pairColors[i] : AppColors.surface,
                        border: Border.all(color: pairColors[i], width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        n.format(i + 1),
                        style: AppTypography.mono(
                          size: 13,
                          weight: FontWeight.w700,
                          color: on ? AppColors.ink : AppColors.text,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (quality != null) ...[
            const SizedBox(height: 8),
            Text(
              quality,
              key: const ValueKey('overlay-quality'),
              style: AppTypography.sans(
                size: 13,
                weight: FontWeight.w600,
                color: qualityColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (onRemove != null) ...[
                OutlinedButton.icon(
                  onPressed: onRemove,
                  style: mapSecondaryButtonStyle,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    t.overlayRemovePair,
                    style: AppTypography.sans(size: 13),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (selected != null || waitingOn != null) ...[
                OutlinedButton(
                  onPressed: onNextPlace,
                  style: mapSecondaryButtonStyle,
                  child: Text(
                    t.overlayNextPair,
                    style: AppTypography.sans(size: 13),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: onNext,
                  style: mapPrimaryButtonStyle(accent),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      onNext == null ? t.overlayNeedTwo : t.mouzaNext,
                      style: AppTypography.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: onNext == null
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

// ------------------------------------------------------------ step 4: measure

class _MeasurePanel extends StatelessWidget {
  final List<OverlayPlot> plots;
  final int draftCorners;
  final bool draftOnNew;
  final String labelA;
  final String labelB;
  final MapScale? scale;
  final Color accent;
  final ValueChanged<bool> onLayer;
  final VoidCallback? onUndo;
  final VoidCallback? onFinish;
  final ValueChanged<OverlayPlot> onOpen;
  final ValueChanged<OverlayPlot> onDelete;

  const _MeasurePanel({
    required this.plots,
    required this.draftCorners,
    required this.draftOnNew,
    required this.labelA,
    required this.labelB,
    required this.scale,
    required this.accent,
    required this.onLayer,
    required this.onUndo,
    required this.onFinish,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    final unit = settings.areaUnit;
    final ms = scale;
    String area(double px2) => ms == null
        ? '—'
        : '${unit.format(px2 * ms.metersPerPixel * ms.metersPerPixel)} '
              '${unit.labelOf(t)}';

    final overlaps = OverlayReport.overlaps(plots);

    Widget layer(bool onNew) {
      final on = draftOnNew == onNew;
      final color = onNew ? newInk : oldInk;
      return Expanded(
        child: InkWell(
          onTap: () => onLayer(onNew),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${onNew ? labelB : labelA} ${t.overlayPlot}',
              style: AppTypography.sans(
                size: 13,
                weight: FontWeight.w700,
                color: on ? Colors.white : AppColors.textDim,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [layer(false), layer(true)]),
          ),
          const SizedBox(height: 8),
          NoShrink(
            child: MapHint(
              draftCorners == 0
                  ? t.overlayTraceHint
                  : t.mouzaTraceHintMore(draftCorners),
              accent: accent,
            ),
          ),
          const SizedBox(height: 10),
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
                ),
                icon: Icon(
                  Icons.undo,
                  size: 18,
                  color: onUndo == null ? AppColors.textFaint : AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onFinish,
                  style: mapPrimaryButtonStyle(accent),
                  child: Text(
                    t.overlayFinishPlot,
                    style: AppTypography.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: onFinish == null
                          ? AppColors.textDim
                          : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (plots.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(t.overlayPlotsHeader, style: AppTypography.monoLabel),
            const SizedBox(height: 4),
            for (final p in plots)
              InkWell(
                onTap: () => onOpen(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: p.onNew ? newInk : oldInk,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(size: 13),
                        ),
                      ),
                      Text(
                        area(PolygonOverlap.area(p.points)),
                        style: AppTypography.mono(size: 12, color: accent),
                      ),
                      IconButton(
                        tooltip: t.actionDelete,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onDelete(p),
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(t.overlayOverlapHeader, style: AppTypography.monoLabel),
            const SizedBox(height: 4),
            if (!plots.any((p) => p.onNew) || !plots.any((p) => !p.onNew))
              Text(
                t.overlayOverlapEmpty,
                style: AppTypography.sans(size: 12, color: AppColors.textDim),
              )
            else if (overlaps.isEmpty)
              Text(
                t.overlayNoOverlap,
                style: AppTypography.sans(size: 12, color: AppColors.textDim),
              )
            else
              for (final o in overlaps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: overlapInk,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${o.old.name} ∩ ${o.newer.name}',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sans(
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              t.overlayOverlapShare(
                                SheetSummary.percent(o.ofOld),
                                o.old.name,
                                SheetSummary.percent(o.ofNew),
                                o.newer.name,
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sans(
                                size: 11,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        area(o.px2),
                        key: ValueKey('overlap-${o.old.name}-${o.newer.name}'),
                        style: AppTypography.mono(
                          size: 13,
                          weight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
