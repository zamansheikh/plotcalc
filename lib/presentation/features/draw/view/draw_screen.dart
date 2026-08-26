import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/presets.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/input_method.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/save_plot.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/polygon_painter.dart';
import '../bloc/draw_bloc.dart';
import '../bloc/draw_event.dart';
import '../bloc/draw_state.dart';
import '../../result/view/result_screen.dart';
import 'edge_edit_dialog.dart';
import 'save_plot_sheet.dart';
import 'type_input_sheet.dart';
import '../../../../l10n/l10n.dart';

class DrawScreen extends StatelessWidget {
  final DrawArgs args;
  const DrawScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DrawBloc()..add(DrawInitialized(args)),
      child: _DrawView(args: args),
    );
  }
}

class _DrawView extends StatefulWidget {
  final DrawArgs args;
  const _DrawView({required this.args});

  @override
  State<_DrawView> createState() => _DrawViewState();
}

class _DrawViewState extends State<_DrawView> {
  bool _typeSheetInFlight = false;

  Future<void> _maybeShowTypeSheet() async {
    if (_typeSheetInFlight || !mounted) return;
    _typeSheetInFlight = true;
    final settings = context.read<SettingsBloc>().state;
    final result = await showTypeInputSheet(
      context,
      preset: widget.args.preset,
      lengthUnit: settings.lengthUnit,
      accent: settings.accent,
    );
    _typeSheetInFlight = false;
    if (!mounted) return;
    if (result != null) {
      // circleVertices() is centred on the origin, so any vertex's distance
      // from it is the radius the user typed.
      final radius = widget.args.preset == ShapePreset.circle && result.isNotEmpty
          ? Geometry.sideLength(const Vertex(0, 0), result.first)
          : null;
      context
          .read<DrawBloc>()
          .add(TypeShapeGenerated(result, circleRadiusM: radius));
    } else {
      context.read<DrawBloc>().add(const TypeInputAcknowledged());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: BlocConsumer<DrawBloc, DrawState>(
          listenWhen: (prev, curr) =>
              prev.awaitingTypeInput != curr.awaitingTypeInput,
          listener: (context, state) {
            if (state.awaitingTypeInput) _maybeShowTypeSheet();
          },
          builder: (context, state) {
            // A circle reports exact figures; the 72-gon is only what's drawn.
            final r = state.circleRadiusM;
            final areaSqm = r != null
                ? Geometry.circleArea(r)
                : Geometry.polygonArea(state.vertices);
            final perimM = r != null
                ? Geometry.circleCircumference(r)
                : Geometry.polygonPerimeter(state.vertices);
            return Column(
              children: [
                const SizedBox(height: 8),
                _TopBar(state: state),
                _ReadoutRow(
                  areaSqm: areaSqm,
                  perimM: perimM,
                  sides: state.vertices.length,
                  circleRadiusM: r,
                  areaUnit: settings.areaUnit,
                  lengthUnit: settings.lengthUnit,
                  accent: settings.accent,
                ),
                Expanded(
                  child: _Canvas(settings: settings, state: state),
                ),
                if (state.isPlacingTaps)
                  _TapHint(state: state, accent: settings.accent)
                else if (state.vertices.isNotEmpty)
                  _VertexInfo(state: state, accent: settings.accent)
                else
                  const SizedBox(height: 56),
                const SizedBox(height: 12),
                _BottomActions(
                  state: state,
                  accent: settings.accent,
                  areaUnit: settings.areaUnit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final DrawState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SmallIconButton(icon: Icons.chevron_left, onTap: () => context.pop()),
          Expanded(
            child: Column(
              children: [
                Text(
                  switch (state.inputMethod) {
                    InputMethod.draw => context.l10n.drawTitle,
                    InputMethod.tap =>
                      state.isPlacingTaps
                          ? context.l10n.drawTitleTap
                          : context.l10n.drawTitleEdit,
                    InputMethod.type => context.l10n.drawTitleEdit,
                  },
                  style: AppTypography.sans(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                Text(
                  context.l10n.drawVerticesUnsaved(state.vertices.length),
                  style: AppTypography.mono(
                    size: 10,
                    color: AppColors.textFaint,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SmallIconButton(
            icon: Icons.undo,
            onTap: () => context.read<DrawBloc>().add(const DrawUndone()),
          ),
        ],
      ),
    );
  }
}

class _ReadoutRow extends StatelessWidget {
  final double areaSqm;
  final double perimM;
  final int sides;
  final double? circleRadiusM;
  final AreaUnit areaUnit;
  final LengthUnit lengthUnit;
  final Color accent;

  const _ReadoutRow({
    required this.areaSqm,
    required this.perimM,
    required this.sides,
    required this.areaUnit,
    required this.lengthUnit,
    required this.accent,
    this.circleRadiusM,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ReadoutTile(
              label: context.l10n.drawArea,
              value: areaUnit.format(areaSqm),
              unit: areaUnit.labelOf(context.l10n),
              valueColor: accent,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ReadoutTile(
              label: context.l10n.drawPerimeter,
              value: lengthUnit.format(perimM),
              unit: lengthUnit.labelOf(context.l10n),
              valueColor: AppColors.text,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            // "72 sides" is meaningless for a circle; its radius is the
            // number the user actually gave and cares about.
            child: circleRadiusM != null
                ? _ReadoutTile(
                    label: context.l10n.drawRadius,
                    value: lengthUnit.format(circleRadiusM!),
                    unit: lengthUnit.labelOf(context.l10n),
                    valueColor: AppColors.text,
                  )
                : _ReadoutTile(
                    label: context.l10n.drawSides,
                    value: '$sides',
                    unit: '',
                    valueColor: AppColors.text,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReadoutTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  const _ReadoutTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono(
              size: 9,
              color: AppColors.textFaint,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(
                    size: 16,
                    weight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTypography.mono(size: 10, color: AppColors.textDim),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Canvas extends StatefulWidget {
  final SettingsState settings;
  final DrawState state;
  const _Canvas({required this.settings, required this.state});

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    final accent = widget.settings.accent;
    final gridStyle = widget.settings.gridStyle == GridStyle.dots
        ? GridStyle.blueprint
        : widget.settings.gridStyle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              // While placing taps we pin scale + origin so each vertex lands
              // exactly under the finger and earlier vertices don't shift
              // around as new ones are added. Auto-fit takes over after Done.
              final isPlacing = widget.state.isPlacingTaps;
              final scale = isPlacing
                  ? 5.2
                  : _autoScale(widget.state.vertices, w, h);

              double cx, cy;
              if (isPlacing || widget.state.vertices.isEmpty) {
                cx = w / 2;
                cy = h / 2;
              } else {
                // Center the polygon's bounding box in the canvas so vertices
                // can never drift off-screen as the user drags one outward.
                final (minX, minY, maxX, maxY) = Geometry.bbox(
                  widget.state.vertices,
                );
                final polyCx = (minX + maxX) / 2;
                final polyCy = (minY + maxY) / 2;
                cx = w / 2 - polyCx * scale;
                cy = h / 2 - polyCy * scale;
              }
              return Stack(
                children: [
                  GridBackground(style: gridStyle),
                  if (widget.settings.mapUnderlay)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.18,
                        child: CustomPaint(painter: _MapStub()),
                      ),
                    ),
                  // Canvas tap/drag handler. Goes BEFORE the overlay buttons
                  // so they can intercept hits in their regions.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: widget.state.isPlacingTaps
                          ? null
                          : (d) {
                              final hit = _hitTest(
                                d.localPosition,
                                widget.state.vertices,
                                scale,
                                Offset(cx, cy),
                              );
                              if (hit != null) {
                                setState(() => _draggingIndex = hit);
                                context.read<DrawBloc>().add(
                                  VertexSelected(hit),
                                );
                              }
                            },
                      onPanUpdate: widget.state.isPlacingTaps
                          ? null
                          : (d) {
                              if (_draggingIndex == null) return;
                              final mx = (d.localPosition.dx - cx) / scale;
                              final my = (d.localPosition.dy - cy) / scale;
                              context.read<DrawBloc>().add(
                                VertexMoved(
                                  index: _draggingIndex!,
                                  position: Vertex(mx, my),
                                ),
                              );
                            },
                      onPanEnd: widget.state.isPlacingTaps
                          ? null
                          : (_) => setState(() => _draggingIndex = null),
                      onTapUp: (d) {
                        if (widget.state.isPlacingTaps) {
                          // Tap mode: drop a vertex at the world position.
                          final mx = (d.localPosition.dx - cx) / scale;
                          final my = (d.localPosition.dy - cy) / scale;
                          context.read<DrawBloc>().add(
                            TapVertexAdded(Vertex(mx, my)),
                          );
                          return;
                        }
                        // Edit mode: tap on vertex selects, tap near edge
                        // midpoint inserts a new vertex.
                        final hitV = _hitTest(
                          d.localPosition,
                          widget.state.vertices,
                          scale,
                          Offset(cx, cy),
                        );
                        if (hitV != null) {
                          context.read<DrawBloc>().add(VertexSelected(hitV));
                          return;
                        }
                        // Diagonal label hit (only when overlay is on).
                        if (widget.state.showDiagonals &&
                            widget.state.vertices.length >= 4) {
                          final hitD = _hitDiagonalMidpoint(
                            d.localPosition,
                            widget.state.vertices,
                            scale,
                            Offset(cx, cy),
                          );
                          if (hitD != null) {
                            _openEdgeEdit(
                              fromIdx: hitD.$1,
                              toIdx: hitD.$2,
                              isDiagonal: true,
                            );
                            return;
                          }
                        }
                        final hitE = _hitEdgeMidpoint(
                          d.localPosition,
                          widget.state.vertices,
                          scale,
                          Offset(cx, cy),
                        );
                        if (hitE != null) {
                          final n = widget.state.vertices.length;
                          _openEdgeEdit(
                            fromIdx: hitE,
                            toIdx: (hitE + 1) % n,
                            isDiagonal: false,
                          );
                        }
                      },
                      child: CustomPaint(
                        painter: _DrawCanvasPainter(
                          vertices: widget.state.vertices,
                          selectedIndex: widget.state.selectedIndex,
                          showAngles:
                              widget.state.showAngles &&
                              !widget.state.isPlacingTaps,
                          showDiagonals:
                              widget.state.showDiagonals &&
                              !widget.state.isPlacingTaps,
                          accent: accent,
                          scale: scale,
                          center: Offset(cx, cy),
                          areaUnit: widget.settings.areaUnit,
                          lengthUnit: widget.settings.lengthUnit,
                          lengthLabel: widget.settings.lengthUnit.labelOf(
                            context.l10n,
                          ),
                          isPlacing: widget.state.isPlacingTaps,
                        ),
                      ),
                    ),
                  ),
                  // Decorative overlays — IgnorePointer so taps fall through
                  // to the GestureDetector below.
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IgnorePointer(child: _Compass(accent: accent)),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: IgnorePointer(child: _ScaleBar(scale: scale)),
                  ),
                  // Interactive overlay — sits above the GestureDetector so
                  // its InkWell wins the hit-test in its region.
                  if (!widget.state.isPlacingTaps &&
                      widget.state.vertices.length >= 4)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _DiagonalsToggle(
                        active: widget.state.showDiagonals,
                        accent: accent,
                        onTap: () => context.read<DrawBloc>().add(
                          const DiagonalsToggled(),
                        ),
                      ),
                    ),
                  if (widget.state.isPlacingTaps &&
                      widget.state.vertices.isEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              context.l10n.drawFirstVertexHint,
                              textAlign: TextAlign.center,
                              style: AppTypography.mono(
                                size: 12,
                                color: AppColors.textDim,
                                letterSpacing: 0.4,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static double _autoScale(List<Vertex> verts, double w, double h) {
    if (verts.isEmpty) return 5.2;
    final (minX, minY, maxX, maxY) = Geometry.bbox(verts);
    final dx = (maxX - minX);
    final dy = (maxY - minY);
    // Reserve room for vertex handles + side-length labels around the bbox.
    const pad = 90.0;
    final sx = dx == 0 ? 5.2 : (w - pad) / dx;
    final sy = dy == 0 ? 5.2 : (h - pad) / dy;
    final s = math.min(sx, sy);
    // Lower bound stays generous so big polygons (>200m) still fit;
    // upper bound prevents a tiny polygon from filling the whole canvas.
    return s.clamp(0.4, 10.0);
  }

  static int? _hitTest(
    Offset p,
    List<Vertex> verts,
    double scale,
    Offset center,
  ) {
    for (var i = 0; i < verts.length; i++) {
      final v = verts[i];
      final pos = Offset(center.dx + v.x * scale, center.dy + v.y * scale);
      if ((pos - p).distance <= 24) return i;
    }
    return null;
  }

  static int? _hitEdgeMidpoint(
    Offset p,
    List<Vertex> verts,
    double scale,
    Offset center,
  ) {
    for (var i = 0; i < verts.length; i++) {
      final a = verts[i];
      final b = verts[(i + 1) % verts.length];
      final mid = Offset(
        center.dx + ((a.x + b.x) / 2) * scale,
        center.dy + ((a.y + b.y) / 2) * scale,
      );
      if ((mid - p).distance <= 24) return i;
    }
    return null;
  }

  static (int, int)? _hitDiagonalMidpoint(
    Offset p,
    List<Vertex> verts,
    double scale,
    Offset center,
  ) {
    for (final (i, j) in _diagonalPairs(verts.length)) {
      final a = verts[i];
      final b = verts[j];
      final pa = Offset(center.dx + a.x * scale, center.dy + a.y * scale);
      final pb = Offset(center.dx + b.x * scale, center.dy + b.y * scale);
      // Mirror the perpendicular offset that the painter applies, so taps
      // land where the label is actually drawn.
      final labelCenter = _DrawCanvasPainter._diagonalLabelCenter(pa, pb);
      if ((labelCenter - p).distance <= 22) return (i, j);
    }
    return null;
  }

  /// Opens the length-adjust dialog for any pair of vertices. When the pair
  /// is adjacent (i.e. a side, not a diagonal) the dialog also offers an
  /// "Insert vertex at midpoint" secondary action, preserving the previous
  /// tap-edge-to-insert behaviour.
  Future<void> _openEdgeEdit({
    required int fromIdx,
    required int toIdx,
    required bool isDiagonal,
  }) async {
    final accent = widget.settings.accent;
    final lengthUnit = widget.settings.lengthUnit;
    final from = widget.state.vertices[fromIdx];
    final to = widget.state.vertices[toIdx];
    final currentLen = Geometry.sideLength(from, to);
    final result = await showEdgeEditDialog(
      context,
      fromIndex: fromIdx,
      toIndex: toIdx,
      currentLengthMeters: currentLen,
      lengthUnit: lengthUnit,
      accent: accent,
      isDiagonal: isDiagonal,
      canInsertMidpoint: !isDiagonal,
    );
    if (result == null || !mounted) return;
    final bloc = context.read<DrawBloc>();
    switch (result) {
      case EdgeLengthChanged(:final newLengthMeters, :final moveTo):
        bloc.add(
          DiagonalAdjusted(
            fromIndex: fromIdx,
            toIndex: toIdx,
            newLengthMeters: newLengthMeters,
            moveTo: moveTo,
          ),
        );
        break;
      case EdgeInsertMidpoint():
        // Sides only: insert at midpoint of edge `fromIdx` (which equals
        // edge between fromIdx and fromIdx+1).
        bloc.add(VertexInserted(fromIdx));
        break;
    }
  }
}

/// Iterate over (i, j) pairs that form diagonals (non-side, non-self,
/// non-duplicate). Caller must guarantee `n >= 3`.
Iterable<(int, int)> _diagonalPairs(int n) sync* {
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final isSide = (j == i + 1) || (i == 0 && j == n - 1);
      if (!isSide) yield (i, j);
    }
  }
}

class _DrawCanvasPainter extends CustomPainter {
  /// Pre-resolved unit label: a painter has no BuildContext to translate with.
  final String lengthLabel;

  final List<Vertex> vertices;
  final int selectedIndex;
  final bool showAngles;
  final bool showDiagonals;
  final Color accent;
  final double scale;
  final Offset center;
  final AreaUnit areaUnit;
  final LengthUnit lengthUnit;
  final bool isPlacing;

  _DrawCanvasPainter({
    required this.vertices,
    required this.selectedIndex,
    required this.showAngles,
    required this.showDiagonals,
    required this.accent,
    required this.scale,
    required this.center,
    required this.areaUnit,
    required this.lengthUnit,
    required this.lengthLabel,
    this.isPlacing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.isEmpty) return;
    // While placing taps, draw open polyline + vertices even with <3 verts.
    if (isPlacing && vertices.length < 3) {
      _paintPolyline(canvas);
      _paintVertices(canvas);
      return;
    }
    if (vertices.length < 3) return;
    // Polygon
    final poly = PolygonPainter(
      vertices: vertices,
      color: accent,
      scale: scale,
      center: center,
      fillOpacity: 0.12,
    );
    poly.paint(canvas, size);

    // Diagonals (rendered before side labels so labels stack on top).
    if (showDiagonals && vertices.length >= 4) {
      _paintDiagonals(canvas);
    }

    // Side length labels
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      final mid = Offset(
        center.dx + ((a.x + b.x) / 2) * scale,
        center.dy + ((a.y + b.y) / 2) * scale,
      );
      final ang = math.atan2(b.y - a.y, b.x - a.x);
      final ox = -math.sin(ang) * 12;
      final oy = math.cos(ang) * 12;
      final isSelected =
          selectedIndex == i || selectedIndex == (i + 1) % vertices.length;
      final rect = Rect.fromCenter(
        center: Offset(mid.dx + ox, mid.dy + oy),
        width: 56,
        height: 18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = isSelected ? accent : AppColors.ink.withValues(alpha: 0.85),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = isSelected ? accent : AppColors.lineMid,
      );
      final len = Geometry.sideLength(a, b);
      final tp = TextPainter(
        text: TextSpan(
          text: '${lengthUnit.format(len)} $lengthLabel',
          style: AppTypography.mono(
            size: 10,
            weight: FontWeight.w500,
            color: isSelected ? AppColors.ink : AppColors.text,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
      );
    }

    // Angle labels
    if (showAngles) {
      for (var i = 0; i < vertices.length; i++) {
        final v = vertices[i];
        final px = center.dx + v.x * scale;
        final py = center.dy + v.y * scale;
        final angle = Geometry.interiorAngle(vertices, i);
        final tp = TextPainter(
          text: TextSpan(
            text: '${angle.round()}°',
            style: AppTypography.mono(size: 9, color: AppColors.textDim),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(px - tp.width / 2, py - 22));
      }
    }

    // Vertices
    for (var i = 0; i < vertices.length; i++) {
      final v = vertices[i];
      final pos = Offset(center.dx + v.x * scale, center.dy + v.y * scale);
      final selected = selectedIndex == i;
      canvas.drawCircle(
        pos,
        selected ? 16 : 12,
        Paint()..color = accent.withValues(alpha: selected ? 0.25 : 0.12),
      );
      canvas.drawCircle(pos, selected ? 8 : 6, Paint()..color = AppColors.ink);
      canvas.drawCircle(
        pos,
        selected ? 8 : 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2 : 1.5
          ..color = accent,
      );
      if (selected) {
        canvas.drawCircle(pos, 2, Paint()..color = accent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawCanvasPainter old) =>
      old.vertices != vertices ||
      old.selectedIndex != selectedIndex ||
      old.showAngles != showAngles ||
      old.showDiagonals != showDiagonals ||
      old.scale != scale ||
      old.center != center ||
      old.accent != accent ||
      old.lengthLabel != lengthLabel ||
      old.isPlacing != isPlacing;

  void _paintDiagonals(Canvas canvas) {
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (final (i, j) in _diagonalPairs(vertices.length)) {
      final a = vertices[i];
      final b = vertices[j];
      final pa = Offset(center.dx + a.x * scale, center.dy + a.y * scale);
      final pb = Offset(center.dx + b.x * scale, center.dy + b.y * scale);
      _drawDashedLine(canvas, pa, pb, stroke);
      // Label sits beside the line, not on it — perpendicular offset based
      // on the diagonal's angle. Two diagonals that share a midpoint (e.g.
      // a rectangle's pair) end up with labels in different regions because
      // their perpendicular vectors point different ways.
      final mid = _diagonalLabelCenter(pa, pb);
      final rect = Rect.fromCenter(center: mid, width: 56, height: 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = AppColors.ink.withValues(alpha: 0.9),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = accent.withValues(alpha: 0.55),
      );
      final len = Geometry.sideLength(a, b);
      final tp = TextPainter(
        text: TextSpan(
          text: '${lengthUnit.format(len)} $lengthLabel',
          style: AppTypography.mono(
            size: 9,
            color: accent.withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
      );
    }
  }

  /// Where to place a diagonal's length label. Pulls the label off the line
  /// perpendicular to it, so two crossing diagonals don't end up with
  /// overlapping labels at the shared midpoint.
  static Offset _diagonalLabelCenter(Offset a, Offset b) {
    final midX = (a.dx + b.dx) / 2;
    final midY = (a.dy + b.dy) / 2;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return Offset(midX, midY);
    const offset = 14.0;
    return Offset(midX + (-dy / dist) * offset, midY + (dx / dist) * offset);
  }

  static void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    final delta = b - a;
    final dist = delta.distance;
    if (dist == 0) return;
    final dir = delta / dist;
    var d = 0.0;
    var draw = true;
    while (d < dist) {
      final next = (d + (draw ? dash : gap)).clamp(0.0, dist);
      if (draw) canvas.drawLine(a + dir * d, a + dir * next, paint);
      d = next;
      draw = !draw;
    }
  }

  /// Open polyline through all vertices in order (used while placing taps
  /// before there are enough points to form a closed polygon).
  void _paintPolyline(Canvas canvas) {
    if (vertices.length < 2) return;
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < vertices.length; i++) {
      final v = vertices[i];
      final p = Offset(center.dx + v.x * scale, center.dy + v.y * scale);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, stroke);
  }

  void _paintVertices(Canvas canvas) {
    for (var i = 0; i < vertices.length; i++) {
      final v = vertices[i];
      final pos = Offset(center.dx + v.x * scale, center.dy + v.y * scale);
      canvas.drawCircle(
        pos,
        9,
        Paint()..color = accent.withValues(alpha: 0.18),
      );
      canvas.drawCircle(pos, 5, Paint()..color = AppColors.ink);
      canvas.drawCircle(
        pos,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent,
      );
    }
  }
}

class _Compass extends StatelessWidget {
  final Color accent;
  const _Compass({required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'N',
          style: AppTypography.mono(
            size: 10,
            weight: FontWeight.w600,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _DiagonalsToggle extends StatelessWidget {
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _DiagonalsToggle({
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.limeDim
                : AppColors.ink.withValues(alpha: 0.7),
            border: Border.all(color: active ? accent : AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline,
                size: 13,
                color: active ? accent : AppColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.drawDiag,
                style: AppTypography.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  color: active ? accent : AppColors.textDim,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleBar extends StatelessWidget {
  final double scale;
  const _ScaleBar({required this.scale});
  @override
  Widget build(BuildContext context) {
    final width = scale * 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: width,
              height: 6,
              color: AppColors.text.withValues(alpha: 0.4),
            ),
            Container(
              width: width,
              height: 6,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.text.withValues(alpha: 0.4)),
                  bottom: BorderSide(
                    color: AppColors.text.withValues(alpha: 0.4),
                  ),
                  right: BorderSide(
                    color: AppColors.text.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '0    10    20 m',
          style: AppTypography.mono(size: 9, color: AppColors.textDim),
        ),
      ],
    );
  }
}

class _MapStub extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.soil
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.6,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.7,
        size.width,
        size.height * 0.55,
      );
    canvas.drawPath(path, p);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.65,
        size.height * 0.18,
        size.width * 0.22,
        size.height * 0.18,
      ),
      Paint()
        ..color = AppColors.soil
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _TapHint extends StatelessWidget {
  final DrawState state;
  final Color accent;
  const _TapHint({required this.state, required this.accent});

  @override
  Widget build(BuildContext context) {
    final n = state.vertices.length;
    final canFinish = n >= 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.lineMid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeDim,
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                canFinish ? Icons.check : Icons.touch_app_outlined,
                size: 16,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canFinish
                        ? context.l10n.drawHintDone
                        : context.l10n.drawHintMin,
                    style: AppTypography.sans(
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.drawHintPlaced(n),
                    style: AppTypography.mono(
                      size: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (n > 0)
              OutlinedButton(
                onPressed: () =>
                    context.read<DrawBloc>().add(const DrawUndone()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(context.l10n.actionUndo, style: AppTypography.mono(size: 10)),
              ),
          ],
        ),
      ),
    );
  }
}

class _VertexInfo extends StatelessWidget {
  final DrawState state;
  final Color accent;
  const _VertexInfo({required this.state, required this.accent});

  @override
  Widget build(BuildContext context) {
    final mLabel = context.l10n.unitMeterShort;
    final i = state.selectedIndex.clamp(0, state.vertices.length - 1);
    final v = state.vertices[i];
    final ang = Geometry.interiorAngle(state.vertices, i);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.lineMid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeDim,
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'V${i + 1}',
                style: AppTypography.mono(
                  size: 12,
                  weight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.drawVertexOf(i + 1, state.vertices.length),
                    style: AppTypography.sans(
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'x: ${v.x.toStringAsFixed(1)}$mLabel · y: ${v.y.toStringAsFixed(1)}$mLabel · ∠ ${ang.round()}°',
                    style: AppTypography.mono(
                      size: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.read<DrawBloc>().add(VertexRemoved(i)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(context.l10n.actionRemove, style: AppTypography.mono(size: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final DrawState state;
  final Color accent;
  final AreaUnit areaUnit;
  const _BottomActions({
    required this.state,
    required this.accent,
    required this.areaUnit,
  });

  Future<void> _save(BuildContext context) async {
    final hhmm = DateTime.now().toIso8601String().substring(11, 16);
    final result = await showSavePlotSheet(
      context,
      defaultName: context.l10n.drawDefaultName(hhmm),
      accent: accent,
    );
    if (result == null) return;
    final repo = sl<SavePlot>();
    final plot = Plot(
      id: const Uuid().v4(),
      name: result.name,
      vertices: state.vertices,
      tag: result.tag,
      createdAt: DateTime.now(),
      colorValue: accent.toARGB32(),
      circleRadiusM: state.circleRadiusM,
    );
    await repo(plot);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.drawSavedToast(result.name, result.tag.labelOf(context.l10n)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (state.isPlacingTaps) {
      return _PlacingActions(state: state, accent: accent);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: OutlinedButton(
              onPressed: state.vertices.length >= 3
                  ? () => _save(context)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.line),
                backgroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.l10n.saveSheetTitle,
                style: AppTypography.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: state.vertices.length >= 3
                      ? AppColors.text
                      : AppColors.textDim,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 14,
            child: FilledButton(
              onPressed: state.vertices.length >= 3
                  ? () {
                      context.push(
                        AppRoutes.result,
                        extra: ResultArgs(
                          name: context.l10n.defaultPlotLabel,
                          vertices: state.vertices,
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                disabledForegroundColor: AppColors.textDim,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.actionCalculate,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: state.vertices.length >= 3
                          ? AppColors.ink
                          : AppColors.textDim,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: state.vertices.length >= 3
                        ? AppColors.ink
                        : AppColors.textDim,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacingActions extends StatelessWidget {
  final DrawState state;
  final Color accent;
  const _PlacingActions({required this.state, required this.accent});

  @override
  Widget build(BuildContext context) {
    final canFinish = state.vertices.length >= 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.line),
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.l10n.actionCancel,
                style: AppTypography.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 14,
            child: FilledButton(
              onPressed: canFinish
                  ? () => context.read<DrawBloc>().add(
                      const TapPlacementCompleted(),
                    )
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                disabledForegroundColor: AppColors.textDim,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.actionDone,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: canFinish ? AppColors.ink : AppColors.textDim,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check,
                    size: 14,
                    color: canFinish ? AppColors.ink : AppColors.textDim,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
