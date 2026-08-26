import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../../shared/widgets/polygon_painter.dart';
import '../../../../l10n/l10n.dart';

class _Lot {
  double pct;
  final Color color;
  _Lot({required this.pct, required this.color});
}

class SubdivideScreen extends StatefulWidget {
  const SubdivideScreen({super.key});

  @override
  State<SubdivideScreen> createState() => _SubdivideScreenState();
}

class _SubdivideScreenState extends State<SubdivideScreen> {
  Plot? _plot;
  late final List<_Lot> _lots = [
    _Lot(pct: 0.35, color: AppColors.lime),
    _Lot(pct: 0.40, color: AppColors.soil),
    _Lot(pct: 0.25, color: AppColors.sky),
  ];

  void _adjust(int index, double delta) {
    setState(() {
      final next = (_lots[index].pct + delta).clamp(0.05, 0.9);
      final diff = next - _lots[index].pct;
      _lots[index].pct = next;
      // Distribute diff across other lots proportionally.
      final others = [
        for (var i = 0; i < _lots.length; i++)
          if (i != index) i,
      ];
      final otherSum = others.fold<double>(0, (s, i) => s + _lots[i].pct);
      if (otherSum > 0) {
        for (final i in others) {
          _lots[i].pct = (_lots[i].pct - diff * (_lots[i].pct / otherSum))
              .clamp(0.05, 0.9);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;

    if (_plot == null) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Header(
              title: context.l10n.subdivideTitle,
              subtitle: context.l10n.subdivideSubtitle,
            ),
            Expanded(
              child: _PlotPicker(
                onSelect: (p) => setState(() => _plot = p),
              ),
            ),
          ],
        ),
      );
    }

    final verts = _plot!.vertices;
    final totalSqm = Geometry.polygonArea(verts);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SelectedHeader(
            plot: _plot!,
            lotCount: _lots.length,
            onChange: () => setState(() => _plot = null),
          ),
          _Canvas(verts: verts, lots: _lots, accent: accent),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _lots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                return _LotTile(
                  lot: _lots[i],
                  name: context.l10n.subdivideLot(i + 1),
                  totalSqm: totalSqm,
                  areaUnit: settings.areaUnit,
                  onMinus: () => _adjust(i, -0.05),
                  onPlus: () => _adjust(i, 0.05),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.subdivideSaved(_plot!.name),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.l10n.subdivideSaveAction,
                  style: AppTypography.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heroTitle),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.mono(size: 11, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _SelectedHeader extends StatelessWidget {
  final Plot plot;
  final int lotCount;
  final VoidCallback onChange;
  const _SelectedHeader({
    required this.plot,
    required this.lotCount,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.subdivideTitle, style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  context.l10n.subdivideSummary(plot.name, lotCount),
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.swap_horiz, size: 14),
            label: Text(
              context.l10n.actionChange,
              style: AppTypography.sans(size: 12, weight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.line),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlotPicker extends StatefulWidget {
  final ValueChanged<Plot> onSelect;
  const _PlotPicker({required this.onSelect});

  @override
  State<_PlotPicker> createState() => _PlotPickerState();
}

class _PlotPickerState extends State<_PlotPicker> {
  late final Future<List<Plot>> _future = sl<GetPlots>()();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plot>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.lime),
          );
        }
        final plots = snap.data ?? const [];
        if (plots.isEmpty) {
          return _EmptyState();
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: plots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _PlotPickerTile(plot: plots[i], onTap: widget.onSelect),
        );
      },
    );
  }
}

class _PlotPickerTile extends StatelessWidget {
  final Plot plot;
  final ValueChanged<Plot> onTap;
  const _PlotPickerTile({required this.plot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(plot.colorValue);
    final areaSqm = Geometry.polygonArea(plot.vertices);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(plot),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: PlotThumbnail(vertices: plot.vertices, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.name,
                      style: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.subdivideMeta(AreaUnit.sqft.format(areaSqm), AreaUnit.sqft.labelOf(context.l10n), plot.vertices.length),
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        plot.tag.labelOf(context.l10n).toUpperCase(),
                        style: AppTypography.mono(
                          size: 9,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeDim,
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.call_split, size: 28, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.subdivideEmpty,
              style: AppTypography.sans(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.subdivideEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyDim,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.subdivideGoHome,
                style: AppTypography.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  final List<Vertex> verts;
  final List<_Lot> lots;
  final Color accent;
  const _Canvas({
    required this.verts,
    required this.lots,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth, h = constraints.maxHeight;
                final cx = w / 2, cy = h / 2;
                final scale = _autoScale(verts, w, h);
                return Stack(
                  children: [
                    const GridBackground(style: GridStyle.blueprint),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PolygonPainter(
                          vertices: verts,
                          color: accent,
                          scale: scale,
                          center: Offset(cx, cy),
                          fillOpacity: 0.06,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DivisionPainter(
                          verts: verts,
                          lots: lots,
                          names: [
                            for (var i = 0; i < lots.length; i++)
                              context.l10n.subdivideLot(i + 1),
                          ],
                          scale: scale,
                          center: Offset(cx, cy),
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
    );
  }

  static double _autoScale(List<Vertex> verts, double w, double h) {
    final (minX, minY, maxX, maxY) = Geometry.bbox(verts);
    final dx = maxX - minX;
    final dy = maxY - minY;
    final pad = 60.0;
    final sx = dx == 0 ? 5.0 : (w - pad) / dx;
    final sy = dy == 0 ? 5.0 : (h - pad) / dy;
    final s = sx < sy ? sx : sy;
    return s.clamp(2.0, 8.0);
  }
}

class _DivisionPainter extends CustomPainter {
  /// Localized lot labels, parallel to [lots] — a painter has no
  /// BuildContext of its own to look them up with.
  final List<String> names;
  final List<Vertex> verts;
  final List<_Lot> lots;
  final double scale;
  final Offset center;
  _DivisionPainter({
    required this.verts,
    required this.lots,
    required this.names,
    required this.scale,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final (minX, _, maxX, _) = Geometry.bbox(verts);
    final width = maxX - minX;

    // Vertical division lines based on cumulative percentages
    var cum = 0.0;
    final dashed = Paint()
      ..color = AppColors.text.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < lots.length - 1; i++) {
      cum += lots[i].pct;
      final x = minX + width * cum;
      final px = center.dx + x * scale;
      _drawDashedLine(
        canvas,
        Offset(px, center.dy - 100),
        Offset(px, center.dy + 100),
        dashed,
      );
      // Drag handle stubs
      canvas.drawCircle(
        Offset(px, center.dy - 100),
        6,
        Paint()..color = AppColors.text,
      );
      canvas.drawCircle(
        Offset(px, center.dy + 100),
        6,
        Paint()..color = AppColors.text,
      );
    }

    // Lot labels
    cum = 0.0;
    for (var i = 0; i < lots.length; i++) {
      final cx = minX + width * (cum + lots[i].pct / 2);
      final px = center.dx + cx * scale;
      final tp = TextPainter(
        text: TextSpan(
          text: names[i].toUpperCase(),
          style: AppTypography.mono(
            size: 11,
            weight: FontWeight.w600,
            color: lots[i].color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, center.dy - tp.height / 2));
      cum += lots[i].pct;
    }

    // Vertex dots
    for (final v in verts) {
      final p = Offset(center.dx + v.x * scale, center.dy + v.y * scale);
      canvas.drawCircle(p, 4, Paint()..color = AppColors.ink);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.lime,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final delta = b - a;
    final dist = delta.distance;
    final dir = delta / dist;
    var d = 0.0;
    var draw = true;
    while (d < dist) {
      final next = (d + (draw ? 4 : 3)).clamp(0.0, dist);
      if (draw) {
        canvas.drawLine(a + dir * d, a + dir * next, paint);
      }
      d = next;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _DivisionPainter old) =>
      old.lots != lots ||
      !listEquals(old.names, names) ||
      old.scale != scale ||
      old.verts != verts;
}

class _LotTile extends StatelessWidget {
  final _Lot lot;
  final String name;
  final double totalSqm;
  final AreaUnit areaUnit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _LotTile({
    required this.lot,
    required this.name,
    required this.totalSqm,
    required this.areaUnit,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 32,
            decoration: BoxDecoration(
              color: lot.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.sans(
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${(lot.pct * 100).toStringAsFixed(0)}% · ${areaUnit.format(totalSqm * lot.pct)} ${areaUnit.labelOf(context.l10n)}',
                  style: AppTypography.mono(
                    size: 10,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          _SmallStep(symbol: '−', onTap: onMinus),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '${(lot.pct * 100).toStringAsFixed(0)}%',
                style: AppTypography.mono(
                  size: 11,
                  color: lot.color,
                ),
              ),
            ),
          ),
          _SmallStep(symbol: '+', onTap: onPlus),
        ],
      ),
    );
  }
}

class _SmallStep extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;
  const _SmallStep({required this.symbol, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          symbol,
          style: AppTypography.mono(size: 12, color: AppColors.text),
        ),
      ),
    );
  }
}
