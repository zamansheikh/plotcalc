import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/presets.dart';
import '../../../../core/export/plot_export.dart';
import '../../../../core/export/plot_summary.dart';
import '../../../../core/units/area_breakdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/polygon_painter.dart';
import '../../../../l10n/l10n.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  Plot? _a;
  Plot? _b;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Resolved before the await: the placeholder names are only needed when
    // there aren't two saved plots, and reaching for `context` after an
    // async gap isn't safe.
    final t = context.l10n;
    final all = await sl<GetPlots>()();
    if (all.length >= 2) {
      _a = all[0];
      _b = all[1];
    } else if (all.length == 1) {
      _a = all[0];
      _b = Plot(
        id: 'demo-b',
        name: t.compareDemoPlot,
        vertices: ShapePreset.rectangle.vertices,
        tag: PlotTag.other,
        createdAt: DateTime.now(),
        colorValue: AppColors.soil.toARGB32(),
      );
    } else {
      _a = Plot(
        id: 'demo-a',
        name: t.compareNameA,
        vertices: ShapePreset.freeform.vertices,
        tag: PlotTag.other,
        createdAt: DateTime.now(),
        colorValue: AppColors.lime.toARGB32(),
      );
      _b = Plot(
        id: 'demo-b',
        name: t.compareNameB,
        vertices: ShapePreset.rectangle.vertices,
        tag: PlotTag.other,
        createdAt: DateTime.now(),
        colorValue: AppColors.soil.toARGB32(),
      );
    }
    if (mounted) setState(() {});
  }

  PlotSummary _summaryOf(Plot plot, SettingsState settings) {
    final areaSqm = Geometry.polygonArea(plot.vertices);
    return PlotSummary(
      name: plot.name,
      areaSqm: areaSqm,
      perimeterM: Geometry.polygonPerimeter(plot.vertices),
      sides: plot.vertices.length,
      unit: settings.areaUnit,
      breakdown: AreaBreakdown.of(areaSqm, settings.breakdown),
    );
  }

  Future<void> _share() async {
    final a = _a;
    final b = _b;
    if (a == null || b == null) return;
    final t = context.l10n;
    final settings = context.read<SettingsBloc>().state;
    await PlotExport.shareComparison(
      _summaryOf(a, settings),
      _summaryOf(b, settings),
      t,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final areaUnit = settings.areaUnit;
    if (_a == null || _b == null) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.lime),
        ),
      );
    }
    final aArea = Geometry.polygonArea(_a!.vertices);
    final bArea = Geometry.polygonArea(_b!.vertices);
    final ratio = bArea == 0 ? 0.0 : aArea / bArea;
    final delta = aArea - bArea;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(onShare: _share),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PlotCard(
                              tag: context.l10n.comparePlotA,
                              tagColor: accent,
                              plot: _a!,
                              area: aArea,
                              areaUnit: areaUnit,
                              gridStyle: settings.gridStyle,
                              accent: accent,
                              fillColor: accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PlotCard(
                              tag: context.l10n.comparePlotB,
                              tagColor: AppColors.soil,
                              plot: _b!,
                              area: bArea,
                              areaUnit: areaUnit,
                              gridStyle: settings.gridStyle,
                              accent: accent,
                              fillColor: AppColors.soil,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.compareOverlay,
                          style: AppTypography.mono(
                            size: 11,
                            color: AppColors.textFaint,
                            letterSpacing: 1.32,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 130,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                final h = constraints.maxHeight;
                                final cx = w / 2, cy = h / 2;
                                final scale = _scale(_a!, _b!, w, h);
                                return Stack(
                                  children: [
                                    const GridBackground(
                                      style: GridStyle.blueprint,
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: PolygonPainter(
                                          vertices: _a!.vertices,
                                          color: accent,
                                          scale: scale,
                                          center: Offset(cx, cy),
                                          fillOpacity: 0.18,
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: PolygonPainter(
                                          vertices: _b!.vertices,
                                          color: AppColors.soil,
                                          scale: scale,
                                          center: Offset(cx, cy),
                                          fillOpacity: 0.18,
                                          strokeDash: const [4, 3],
                                        ),
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
                    const SizedBox(height: 14),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: context.l10n.compareRatio,
                              value: '${ratio.toStringAsFixed(2)}×',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _StatTile(
                              label: context.l10n.compareDelta,
                              value:
                                  '${delta >= 0 ? '+' : ''}${areaUnit.format(delta.abs())}',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _StatTile(
                              label: context.l10n.compareTotal,
                              value: areaUnit.format(aArea + bArea),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.compareRelative,
                              style: AppTypography.mono(
                                size: 10,
                                color: AppColors.textFaint,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Bar(
                              name: 'A',
                              area: aArea,
                              max: aArea > bArea ? aArea : bArea,
                              color: accent,
                              areaUnit: areaUnit,
                            ),
                            const SizedBox(height: 8),
                            _Bar(
                              name: 'B',
                              area: bArea,
                              max: aArea > bArea ? aArea : bArea,
                              color: AppColors.soil,
                              areaUnit: areaUnit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _scale(Plot a, Plot b, double w, double h) {
    final all = [...a.vertices, ...b.vertices];
    final (minX, minY, maxX, maxY) = Geometry.bbox(all);
    final dx = maxX - minX;
    final dy = maxY - minY;
    final sx = dx == 0 ? 2.5 : (w - 30) / dx;
    final sy = dy == 0 ? 2.5 : (h - 30) / dy;
    final s = sx < sy ? sx : sy;
    return s.clamp(1.0, 6.0);
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onShare;

  const _TopBar({required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmallIconButton(
            icon: Icons.chevron_left,
            onTap: () => context.pop(),
          ),
          Text(
            context.l10n.compareTitle,
            style: AppTypography.sans(size: 14, weight: FontWeight.w600),
          ),
          SmallIconButton(
            icon: Icons.ios_share,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _PlotCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final Plot plot;
  final double area;
  final AreaUnit areaUnit;
  final GridStyle gridStyle;
  final Color accent;
  final Color fillColor;
  const _PlotCard({
    required this.tag,
    required this.tagColor,
    required this.plot,
    required this.area,
    required this.areaUnit,
    required this.gridStyle,
    required this.accent,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tag,
          style: AppTypography.mono(
            size: 9,
            color: tagColor,
            letterSpacing: 1.32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plot.name,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sans(size: 13, weight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 130,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth, h = constraints.maxHeight;
                  return Stack(
                    children: [
                      GridBackground(style: gridStyle),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AutoFitPolyPainter(
                            vertices: plot.vertices,
                            color: fillColor,
                            size: Size(w, h),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          areaUnit.format(area),
          overflow: TextOverflow.ellipsis,
          style: AppTypography.mono(
            size: 22,
            weight: FontWeight.w500,
            color: fillColor,
          ),
        ),
        Text(
          context.l10n.compareUnitSides(areaUnit.labelOf(context.l10n), plot.vertices.length),
          style: AppTypography.mono(
            size: 10,
            color: AppColors.textDim,
          ),
        ),
      ],
    );
  }
}

class _AutoFitPolyPainter extends CustomPainter {
  final List vertices;
  final Color color;
  final Size size;
  _AutoFitPolyPainter({
    required this.vertices,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (vertices.length < 3) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final v in vertices) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }
    final w = maxX - minX, h = maxY - minY;
    const pad = 8.0;
    final sx = w == 0 ? 1.0 : (canvasSize.width - pad * 2) / w;
    final sy = h == 0 ? 1.0 : (canvasSize.height - pad * 2) / h;
    final s = sx < sy ? sx : sy;
    final ox = (canvasSize.width - w * s) / 2 - minX * s;
    final oy = (canvasSize.height - h * s) / 2 - minY * s;

    final path = Path();
    for (var i = 0; i < vertices.length; i++) {
      final p = Offset(vertices[i].x * s + ox, vertices[i].y * s + oy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final dot = Paint()..color = color;
    for (final v in vertices) {
      canvas.drawCircle(Offset(v.x * s + ox, v.y * s + oy), 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _AutoFitPolyPainter old) =>
      old.vertices != vertices || old.color != color;
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
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
          Text(
            value,
            style: AppTypography.mono(size: 14, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String name;
  final double area;
  final double max;
  final Color color;
  final AreaUnit areaUnit;
  const _Bar({
    required this.name,
    required this.area,
    required this.max,
    required this.color,
    required this.areaUnit,
  });

  @override
  Widget build(BuildContext context) {
    final w = max == 0 ? 0.0 : area / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTypography.mono(size: 10, color: color),
            ),
            Text(
              '${areaUnit.format(area)} ${areaUnit.labelOf(context.l10n)}',
              style: AppTypography.mono(
                size: 10,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: w.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
