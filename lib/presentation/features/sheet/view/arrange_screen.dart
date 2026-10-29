import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/sheet_layout.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/plot_sheet.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../../domain/usecases/get_sheets.dart';
import '../../../../domain/usecases/save_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import 'sheet_canvas.dart';

/// A canvas holding the sheet's plots at true scale. Drag a plot to move
/// it, turn it with the buttons, pinch or drag the background to look
/// around, then save.
class ArrangeScreen extends StatefulWidget {
  final String sheetId;
  const ArrangeScreen({super.key, required this.sheetId});

  @override
  State<ArrangeScreen> createState() => _ArrangeScreenState();
}

class _ArrangeScreenState extends State<ArrangeScreen> {
  /// One turn-button press, in degrees.
  static const turnStep = 15.0;

  PlotSheet? _sheet;
  SheetSummary? _summary;
  Map<String, PlotPlacement> _layout = {};
  String? _selected;
  bool _dirty = false;

  // View: pixels per metre, and where the world origin sits on screen.
  double? _scale;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;

  // Gesture in progress.
  String? _dragging;
  double _startScale = 1;
  Offset _startWorld = Offset.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sheet = await sl<GetSheets>().byId(widget.sheetId);
    final plots = await sl<GetPlots>()();
    if (!mounted || sheet == null) return;
    final settings = context.read<SettingsBloc>().state;
    final summary = SheetSummary.of(
      sheet,
      plots,
      fallbackUnit: settings.areaUnit,
      breakdown: settings.breakdown,
    );
    setState(() {
      _sheet = sheet;
      _summary = summary;
      _layout = SheetLayout.fill(_shapes(summary), sheet.layout);
    });
  }

  List<(String, List<Vertex>)> _shapes(SheetSummary s) => [
    for (final r in s.rows) (r.plotId, r.vertices),
  ];

  List<CanvasItem> get _items => [
    for (final r in _summary!.rows)
      CanvasItem(
        id: r.plotId,
        label: r.name,
        detail: _summary!.area(r.areaSqm, context.l10n),
        outline: SheetLayout.place(r.vertices, _layout[r.plotId]!),
        color: Color(r.colorValue),
      ),
  ];

  Offset _toWorld(Offset px) => (px - _offset) / _scale!;

  /// Topmost plot under [px]; the selected one is drawn on top, so it wins.
  String? _hit(Offset px) {
    final w = _toWorld(px);
    final pt = Vertex(w.dx, w.dy);
    final items = _items;
    final sel = items.where((i) => i.id == _selected);
    for (final it in [...sel, ...items.reversed]) {
      if (SheetLayout.contains(it.outline, pt)) return it.id;
    }
    return null;
  }

  void _fit() {
    final (s, o) = fitView(_items, _size);
    setState(() {
      _scale = s;
      _offset = o;
    });
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _scale!;
    _startWorld = _toWorld(d.localFocalPoint);
    final hit = d.pointerCount == 1 ? _hit(d.localFocalPoint) : null;
    setState(() {
      _dragging = hit;
      if (hit != null) _selected = hit;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final id = _dragging;
    if (id != null && d.pointerCount == 1) {
      final delta = d.focalPointDelta / _scale!;
      setState(() {
        _layout = {..._layout, id: _layout[id]!.moved(delta.dx, delta.dy)};
        _dirty = true;
      });
      return;
    }
    // Pan and zoom the view, keeping the point under the fingers still.
    final s = (_startScale * d.scale).clamp(0.05, 200.0);
    setState(() {
      _scale = s;
      _offset = d.localFocalPoint - _startWorld * s;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    final id = _dragging;
    _dragging = null;
    if (id == null) return;
    // Fourteen pixels of slack, however far the view is zoomed.
    final snapped = SheetLayout.snap(
      id,
      _shapes(_summary!),
      _layout,
      14 / _scale!,
    );
    setState(() => _layout = {..._layout, id: snapped});
  }

  void _onTapUp(TapUpDetails d) {
    setState(() => _selected = _hit(d.localPosition));
  }

  void _turn(double degrees) {
    final id = _selected;
    if (id == null) return;
    setState(() {
      _layout = {..._layout, id: _layout[id]!.turned(degrees * math.pi / 180)};
      _dirty = true;
    });
  }

  void _autoArrange() {
    setState(() {
      _layout = SheetLayout.fill(_shapes(_summary!), const {});
      _dirty = true;
    });
    _fit();
  }

  Future<void> _save() async {
    final sheet = _sheet!;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.l10n;
    // Re-read first: the price or plot list may have changed elsewhere.
    final latest = await sl<GetSheets>().byId(sheet.id) ?? sheet;
    await sl<SaveSheet>()(latest.copyWith(layout: _layout));
    if (!mounted) return;
    setState(() => _dirty = false);
    messenger.showSnackBar(SnackBar(content: Text(t.sheetLayoutSaved)));
  }

  Future<void> _confirmLeave() async {
    final t = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t.sheetDiscardTitle,
          style: AppTypography.sans(size: 16, weight: FontWeight.w600),
        ),
        content: Text(
          t.sheetDiscardBody,
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
    if (discard == true && mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final t = context.l10n;
    final summary = _summary;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    SmallIconButton(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.sheetArrangeTitle.toUpperCase(),
                            style: AppTypography.mono(
                              size: 9,
                              color: AppColors.textFaint,
                              letterSpacing: 1.3,
                            ),
                          ),
                          Text(
                            _sheet?.name ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(
                              size: 15,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _dirty ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.ink,
                        disabledBackgroundColor: AppColors.surface,
                        disabledForegroundColor: AppColors.textDim,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t.actionSave,
                        style: AppTypography.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: _dirty ? AppColors.ink : AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: summary == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.lime,
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, c) {
                                _size = Size(c.maxWidth, c.maxHeight);
                                if (_scale == null) {
                                  final (s, o) = fitView(_items, _size);
                                  _scale = s;
                                  _offset = o;
                                }
                                return GestureDetector(
                                  key: const ValueKey('arrange-canvas'),
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: _onTapUp,
                                  onScaleStart: _onScaleStart,
                                  onScaleUpdate: _onScaleUpdate,
                                  onScaleEnd: _onScaleEnd,
                                  child: CustomPaint(
                                    size: _size,
                                    painter: SheetCanvasPainter(
                                      items: _items,
                                      scale: _scale!,
                                      offset: _offset,
                                      selectedId: _selected,
                                      accent: accent,
                                      meterLabel: t.unitMeterShort,
                                      lengthUnit: settings.lengthUnit,
                                      lengthLabel: settings.lengthUnit.labelOf(
                                        t,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
              if (summary != null)
                _Toolbar(
                  summary: summary,
                  selected: _selected,
                  accent: accent,
                  onTurnLeft: () => _turn(-turnStep),
                  onTurnRight: () => _turn(turnStep),
                  onFit: _fit,
                  onAuto: _autoArrange,
                  angle: _selected == null ? null : _layout[_selected]?.angle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final SheetSummary summary;
  final String? selected;
  final double? angle;
  final Color accent;
  final VoidCallback onTurnLeft;
  final VoidCallback onTurnRight;
  final VoidCallback onFit;
  final VoidCallback onAuto;
  const _Toolbar({
    required this.summary,
    required this.selected,
    required this.angle,
    required this.accent,
    required this.onTurnLeft,
    required this.onTurnRight,
    required this.onFit,
    required this.onAuto,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final row = summary.rows.where((r) => r.plotId == selected).firstOrNull;
    final degrees = angle == null ? 0 : (angle! * 180 / math.pi).round();

    Widget tool(IconData icon, String tip, VoidCallback? onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: onTap == null ? AppColors.textFaint : AppColors.text,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row == null
                ? t.sheetArrangeHint
                : '${row.name} · ${summary.area(row.areaSqm, t)} · $degrees°',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono(
              size: 11,
              color: row == null ? AppColors.textFaint : accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tool(
                Icons.rotate_left,
                t.sheetTurnLeft,
                row == null ? null : onTurnLeft,
              ),
              const SizedBox(width: 8),
              tool(
                Icons.rotate_right,
                t.sheetTurnRight,
                row == null ? null : onTurnRight,
              ),
              const Spacer(),
              tool(
                Icons.auto_awesome_mosaic_outlined,
                t.sheetAutoArrange,
                onAuto,
              ),
              const SizedBox(width: 8),
              tool(Icons.fit_screen_outlined, t.sheetFitView, onFit),
            ],
          ),
        ],
      ),
    );
  }
}
