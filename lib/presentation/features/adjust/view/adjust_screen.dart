import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/presets.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/polygon_painter.dart';
import '../bloc/adjust_bloc.dart';
import '../bloc/adjust_event.dart';
import '../bloc/adjust_state.dart';
import '../../../../l10n/l10n.dart';

class AdjustArgs {
  final String name;
  final List<Vertex> vertices;
  const AdjustArgs({required this.name, required this.vertices});
}

class AdjustScreen extends StatelessWidget {
  final AdjustArgs args;
  const AdjustScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final base = args.vertices.isEmpty
        ? ShapePreset.freeform.vertices
        : args.vertices;
    return BlocProvider(
      create: (_) => AdjustBloc()..add(AdjustInitialized(base: base)),
      child: _AdjustView(name: args.name),
    );
  }
}

class _AdjustView extends StatelessWidget {
  final String name;
  const _AdjustView({required this.name});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: BlocBuilder<AdjustBloc, AdjustState>(
          builder: (context, state) {
            if (state.baseVertices.isEmpty) {
              return const SizedBox.shrink();
            }
            final baseSqm = Geometry.polygonArea(state.baseVertices);
            final adjustedVerts = _scale(state, state.targetSqm / baseSqm);
            final adjustedSqm = Geometry.polygonArea(adjustedVerts);
            return Column(
              children: [
                const SizedBox(height: 8),
                _TopBar(name: name),
                _TargetCard(
                  state: state,
                  baseSqm: baseSqm,
                  adjustedSqm: adjustedSqm,
                  areaUnit: settings.areaUnit,
                  accent: settings.accent,
                ),
                _CanvasArea(
                  state: state,
                  adjustedVerts: adjustedVerts,
                  adjustedSqm: adjustedSqm,
                  accent: settings.accent,
                  gridStyle: settings.gridStyle,
                  areaUnit: settings.areaUnit,
                ),
                _ModeRow(state: state, accent: settings.accent),
                _AnchorRow(state: state),
                const SizedBox(height: 12),
                _BottomActions(
                  accent: settings.accent,
                  adjustedVerts: adjustedVerts,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<Vertex> _scale(AdjustState s, double ratio) {
    if (ratio <= 0) ratio = 0.0001;
    double sx = 1, sy = 1;
    switch (s.mode) {
      case AdjustMode.uniform:
        sx = sy = math.sqrt(ratio);
        break;
      case AdjustMode.horizontal:
        sx = ratio;
        break;
      case AdjustMode.vertical:
        sy = ratio;
        break;
    }
    final (minX, minY, maxX, maxY) = Geometry.bbox(s.baseVertices);
    var ax = (minX + maxX) / 2;
    var ay = (minY + maxY) / 2;
    switch (s.anchor) {
      case AdjustAnchor.west:
        ax = minX;
        break;
      case AdjustAnchor.east:
        ax = maxX;
        break;
      case AdjustAnchor.north:
        ay = minY;
        break;
      case AdjustAnchor.south:
        ay = maxY;
        break;
      case AdjustAnchor.center:
        break;
    }
    return s.baseVertices
        .map((v) => Vertex(ax + (v.x - ax) * sx, ay + (v.y - ay) * sy))
        .toList();
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  const _TopBar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SmallIconButton(
            icon: Icons.chevron_left,
            onTap: () => context.pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  context.l10n.adjustTitle,
                  style: AppTypography.sans(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                Text(
                  name.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
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
            onTap: () => context.read<AdjustBloc>().add(const AdjustReset()),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final AdjustState state;
  final double baseSqm;
  final double adjustedSqm;
  final AreaUnit areaUnit;
  final Color accent;

  const _TargetCard({
    required this.state,
    required this.baseSqm,
    required this.adjustedSqm,
    required this.areaUnit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final baseInUnit = areaUnit.fromSqm(baseSqm);
    final targetInUnit = areaUnit.fromSqm(state.targetSqm);
    final pct = baseInUnit == 0 ? 0.0 : (targetInUnit / baseInUnit - 1) * 100;
    final delta = adjustedSqm - baseSqm;
    final stepSqm = areaUnit == AreaUnit.sqft
        ? AreaUnit.sqft.toSqm(100)
        : areaUnit.toSqm(0.05);

    final fmt = areaUnit.format(state.targetSqm);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.lineMid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              GridBackground(
                style: context.watch<SettingsBloc>().state.gridStyle,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.adjustTargetArea,
                        style: AppTypography.mono(
                          size: 9,
                          color: AppColors.textFaint,
                          letterSpacing: 1.32,
                        ),
                      ),
                      Text(
                        context.l10n.adjustPctFromBase('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}'),
                        style: AppTypography.mono(
                          size: 9,
                          color: pct >= 0 ? accent : AppColors.rose,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StepBtn(
                        symbol: '−',
                        onTap: () => context.read<AdjustBloc>().add(
                              TargetChanged(state.targetSqm - stepSqm),
                            ),
                      ),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                fmt,
                                style: AppTypography.mono(
                                  size: 32,
                                  weight: FontWeight.w500,
                                  color: accent,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                areaUnit.labelOf(context.l10n),
                                style: AppTypography.mono(
                                  size: 13,
                                  color: AppColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _StepBtn(
                        symbol: '+',
                        onTap: () => context.read<AdjustBloc>().add(
                              TargetChanged(state.targetSqm + stepSqm),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Multiplier presets
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    children: [
                      for (final m in [0.5, 0.75, 1.0, 1.2, 1.5, 2.0])
                        _MultBtn(
                          mult: m,
                          baseSqm: baseSqm,
                          targetSqm: state.targetSqm,
                          accent: accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.adjustBaseValue(areaUnit.format(baseSqm), areaUnit.labelOf(context.l10n)),
                        style: AppTypography.mono(
                          size: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                      Text(
                        'Δ ${delta >= 0 ? '+' : ''}${areaUnit.format(delta.abs() * (delta < 0 ? -1 : 1))} ${areaUnit.labelOf(context.l10n)}',
                        style: AppTypography.mono(
                          size: 10,
                          color: delta >= 0 ? accent : AppColors.rose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;
  const _StepBtn({required this.symbol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          symbol,
          style: AppTypography.mono(
            size: 18,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MultBtn extends StatelessWidget {
  final double mult;
  final double baseSqm;
  final double targetSqm;
  final Color accent;
  const _MultBtn({
    required this.mult,
    required this.baseSqm,
    required this.targetSqm,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final active = (targetSqm - baseSqm * mult).abs() < baseSqm * 0.001;
    return InkWell(
      onTap: () =>
          context.read<AdjustBloc>().add(TargetChanged(baseSqm * mult)),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$mult×',
          style: AppTypography.mono(
            size: 10,
            color: active ? AppColors.ink : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

class _CanvasArea extends StatelessWidget {
  final AdjustState state;
  final List<Vertex> adjustedVerts;
  final double adjustedSqm;
  final Color accent;
  final GridStyle gridStyle;
  final AreaUnit areaUnit;

  const _CanvasArea({
    required this.state,
    required this.adjustedVerts,
    required this.adjustedSqm,
    required this.accent,
    required this.gridStyle,
    required this.areaUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth, h = constraints.maxHeight;
                final cx = w / 2, cy = h / 2;
                final scale = _autoScale(adjustedVerts, w, h);
                return Stack(
                  children: [
                    GridBackground(style: gridStyle),
                    // Base outline (dashed)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PolygonPainter(
                          vertices: state.baseVertices,
                          color: AppColors.text.withValues(alpha: 0.35),
                          scale: scale,
                          center: Offset(cx, cy),
                          fillOpacity: 0,
                          strokeWidth: 1,
                          strokeDash: const [4, 3],
                        ),
                      ),
                    ),
                    // Adjusted polygon
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PolygonPainter(
                          vertices: adjustedVerts,
                          color: accent,
                          scale: scale,
                          center: Offset(cx, cy),
                          fillOpacity: 0.16,
                        ),
                      ),
                    ),
                    // Vertices
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _VertexPainter(
                          vertices: adjustedVerts,
                          accent: accent,
                          scale: scale,
                          center: Offset(cx, cy),
                        ),
                      ),
                    ),
                    // Anchor marker
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AnchorPainter(
                          state: state,
                          scale: scale,
                          center: Offset(cx, cy),
                        ),
                      ),
                    ),
                    // Live area chip
                    Positioned(
                      left: 0,
                      right: 0,
                      top: cy - 14,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.85),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${areaUnit.format(adjustedSqm)} ${areaUnit.labelOf(context.l10n)}',
                            style: AppTypography.mono(
                              size: 13,
                              weight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Row(
                        children: [
                          _LegendItem(
                            sample: _Dashed(),
                            label: context.l10n.adjustBase,
                          ),
                          const SizedBox(width: 12),
                          _LegendItem(
                            sample: Container(
                              width: 12,
                              height: 2,
                              color: accent,
                            ),
                            label: context.l10n.adjustAdjusted,
                          ),
                          const SizedBox(width: 12),
                          _LegendItem(
                            sample: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppColors.soil),
                              ),
                            ),
                            label: context.l10n.adjustAnchor,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static double _autoScale(List<Vertex> verts, double w, double h) {
    if (verts.length < 2) return 4.2;
    final (minX, minY, maxX, maxY) = Geometry.bbox(verts);
    final dx = (maxX - minX);
    final dy = (maxY - minY);
    final pad = 60.0;
    final sx = dx == 0 ? 4.2 : (w - pad) / dx;
    final sy = dy == 0 ? 4.2 : (h - pad) / dy;
    final s = math.min(sx, sy);
    return s.clamp(2.0, 8.0);
  }
}

class _Dashed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 2,
      child: CustomPaint(
        painter: _DashedPainter(),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 4, size.width), size.height / 2),
        paint,
      );
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _VertexPainter extends CustomPainter {
  final List<Vertex> vertices;
  final Color accent;
  final double scale;
  final Offset center;
  _VertexPainter({
    required this.vertices,
    required this.accent,
    required this.scale,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final v in vertices) {
      final p = Offset(center.dx + v.x * scale, center.dy + v.y * scale);
      canvas.drawCircle(
        p,
        9,
        Paint()..color = accent.withValues(alpha: 0.18),
      );
      canvas.drawCircle(p, 4, Paint()..color = AppColors.ink);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VertexPainter old) =>
      old.vertices != vertices ||
      old.scale != scale ||
      old.center != center ||
      old.accent != accent;
}

class _AnchorPainter extends CustomPainter {
  final AdjustState state;
  final double scale;
  final Offset center;
  _AnchorPainter({
    required this.state,
    required this.scale,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (state.baseVertices.isEmpty) return;
    final (minX, minY, maxX, maxY) = Geometry.bbox(state.baseVertices);
    var ax = (minX + maxX) / 2;
    var ay = (minY + maxY) / 2;
    switch (state.anchor) {
      case AdjustAnchor.west:
        ax = minX;
        break;
      case AdjustAnchor.east:
        ax = maxX;
        break;
      case AdjustAnchor.north:
        ay = minY;
        break;
      case AdjustAnchor.south:
        ay = maxY;
        break;
      case AdjustAnchor.center:
        break;
    }
    final p = Offset(center.dx + ax * scale, center.dy + ay * scale);
    final paint = Paint()
      ..color = AppColors.soil
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(p, 6, paint);
    canvas.drawLine(p.translate(-8, 0), p.translate(8, 0), paint);
    canvas.drawLine(p.translate(0, -8), p.translate(0, 8), paint);
  }

  @override
  bool shouldRepaint(covariant _AnchorPainter old) =>
      old.state.anchor != state.anchor ||
      old.state.baseVertices != state.baseVertices;
}

class _LegendItem extends StatelessWidget {
  final Widget sample;
  final String label;
  const _LegendItem({required this.sample, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        sample,
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.mono(size: 9, color: AppColors.textDim),
        ),
      ],
    );
  }
}

class _ModeRow extends StatelessWidget {
  final AdjustState state;
  final Color accent;
  const _ModeRow({required this.state, required this.accent});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (AdjustMode.uniform, context.l10n.adjustUniform, Icons.crop_free),
      (AdjustMode.horizontal, context.l10n.adjustWidth, Icons.swap_horiz),
      (AdjustMode.vertical, context.l10n.adjustHeight, Icons.swap_vert),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.adjustExpandDirection,
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < modes.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _ModeBtn(
                    mode: modes[i].$1,
                    label: modes[i].$2,
                    icon: modes[i].$3,
                    active: state.mode == modes[i].$1,
                    accent: accent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final AdjustMode mode;
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  const _ModeBtn({
    required this.mode,
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AdjustBloc>().add(ModeChanged(mode)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent : AppColors.surface,
          border: active ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? AppColors.ink : AppColors.text,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.sans(
                size: 12,
                weight: FontWeight.w500,
                color: active ? AppColors.ink : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  final AdjustState state;
  const _AnchorRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      (AdjustAnchor.north, context.l10n.adjustAnchorN),
      (AdjustAnchor.east, context.l10n.adjustAnchorE),
      (AdjustAnchor.center, '·'),
      (AdjustAnchor.west, context.l10n.adjustAnchorW),
      (AdjustAnchor.south, context.l10n.adjustAnchorS),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.adjustAnchorFrom,
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _AnchorBtn(
                    anchor: items[i].$1,
                    label: items[i].$2,
                    active: state.anchor == items[i].$1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorBtn extends StatelessWidget {
  final AdjustAnchor anchor;
  final String label;
  final bool active;
  const _AnchorBtn({
    required this.anchor,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AdjustBloc>().add(AnchorChanged(anchor)),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.soil : AppColors.surface,
          border: active ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.mono(
            size: 12,
            weight: FontWeight.w600,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final Color accent;
  final List<Vertex> adjustedVerts;
  const _BottomActions({required this.accent, required this.adjustedVerts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: OutlinedButton(
              onPressed: () =>
                  context.read<AdjustBloc>().add(const AdjustReset()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.l10n.actionReset,
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
            flex: 16,
            child: FilledButton(
              onPressed: () => context.pop(adjustedVerts),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.adjustApply,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.check, size: 14, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
