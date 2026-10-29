import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/sheet_layout.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// One plot as drawn on a sheet's canvas, already moved and turned into
/// place, in metres.
class CanvasItem {
  final String id;
  final String label;

  /// Second line under the name, e.g. the area.
  final String detail;
  final List<Vertex> outline;
  final Color color;

  const CanvasItem({
    required this.id,
    required this.label,
    required this.outline,
    required this.color,
    this.detail = '',
  });
}

/// The sheet's rows placed by [layout], with any plot missing from it laid
/// out automatically.
List<CanvasItem> canvasItemsOf(
  SheetSummary s,
  Map<String, PlotPlacement> layout,
  AppLocalizations t,
) {
  final shapes = [for (final r in s.rows) (r.plotId, r.vertices)];
  final full = SheetLayout.fill(shapes, layout);
  return [
    for (final r in s.rows)
      CanvasItem(
        id: r.plotId,
        label: r.name,
        detail: s.area(r.areaSqm, t),
        outline: SheetLayout.place(r.vertices, full[r.plotId]!),
        color: Color(r.colorValue),
      ),
  ];
}

/// Scale (pixels per metre) and offset that fit [items] inside [size].
(double, Offset) fitView(List<CanvasItem> items, Size size, {double pad = 28}) {
  if (items.isEmpty || size.isEmpty) return (4, size.center(Offset.zero));
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final it in items) {
    for (final v in it.outline) {
      minX = math.min(minX, v.x);
      minY = math.min(minY, v.y);
      maxX = math.max(maxX, v.x);
      maxY = math.max(maxY, v.y);
    }
  }
  final w = math.max(maxX - minX, 1.0), h = math.max(maxY - minY, 1.0);
  final s = math
      .min((size.width - pad * 2) / w, (size.height - pad * 2) / h)
      .clamp(0.05, 200.0);
  final offset = Offset(
    size.width / 2 - (minX + w / 2) * s,
    size.height / 2 - (minY + h / 2) * s,
  );
  return (s, offset);
}

/// Draws the plots at true scale: a metre grid, each outline with its name,
/// and a scale bar.
class SheetCanvasPainter extends CustomPainter {
  final List<CanvasItem> items;
  final double scale;
  final Offset offset;
  final String? selectedId;
  final Color accent;
  final String meterLabel;
  final bool showScaleBar;

  /// Side lengths are written along each side in this unit.
  final LengthUnit lengthUnit;
  final String lengthLabel;

  const SheetCanvasPainter({
    required this.items,
    required this.scale,
    required this.offset,
    required this.accent,
    required this.meterLabel,
    required this.lengthUnit,
    required this.lengthLabel,
    this.selectedId,
    this.showScaleBar = true,
  });

  Offset _px(Vertex v) =>
      Offset(v.x * scale + offset.dx, v.y * scale + offset.dy);

  /// Grid and scale-bar steps, in metres.
  static const _steps = <double>[
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
  ];

  static double _step(double scale, double minPx) =>
      _steps.firstWhere((m) => m * scale >= minPx, orElse: () => 5000);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    _grid(canvas, size);

    // The selected plot is drawn last, so it sits on top while dragged.
    final order = [
      ...items.where((i) => i.id != selectedId),
      ...items.where((i) => i.id == selectedId),
    ];
    for (final it in order) {
      if (it.outline.length < 3) continue;
      final selected = it.id == selectedId;
      final path = Path()
        ..addPolygon([for (final v in it.outline) _px(v)], true);
      canvas.drawPath(
        path,
        Paint()..color = it.color.withValues(alpha: selected ? 0.32 : 0.18),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1.4
          ..strokeJoin = StrokeJoin.round
          ..color = selected ? accent : it.color,
      );
      if (selected) {
        final dot = Paint()..color = accent;
        for (final v in it.outline) {
          canvas.drawCircle(_px(v), 3, dot);
        }
      }
    }
    // Labels after every fill, so no plot covers another's text. Each one
    // claims its space; a side label that would land on top of something
    // already drawn is left out rather than piled on.
    final taken = <Rect>[];
    for (final it in order) {
      if (it.outline.length >= 3) _label(canvas, it, taken);
    }
    // The selected plot's sides go first, so they are the ones kept.
    for (final it in order.reversed) {
      if (it.outline.length >= 3) {
        _sides(canvas, it, it.id == selectedId, taken);
      }
    }

    if (showScaleBar) _scaleBar(canvas, size);
  }

  void _grid(Canvas canvas, Size size) {
    final step = _step(scale, 22);
    final px = step * scale;
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    final x0 = offset.dx % px, y0 = offset.dy % px;
    for (var x = x0; x < size.width; x += px) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = y0; y < size.height; y += px) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Name, and the area under it, at the plot's centre.
  void _label(Canvas canvas, CanvasItem it, List<Rect> taken) {
    final box = Rect.fromPoints(
      _px(
        Vertex(
          it.outline.map((v) => v.x).reduce(math.min),
          it.outline.map((v) => v.y).reduce(math.min),
        ),
      ),
      _px(
        Vertex(
          it.outline.map((v) => v.x).reduce(math.max),
          it.outline.map((v) => v.y).reduce(math.max),
        ),
      ),
    );
    final maxW = math.max(box.width - 6, 0.0);
    final name = TextPainter(
      text: TextSpan(
        text: it.label,
        style: AppTypography.sans(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    final detail = TextPainter(
      text: TextSpan(
        text: it.detail,
        style: AppTypography.mono(size: 10, color: it.color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    // A label that cannot fit at all would only clutter a tiny plot.
    if (box.width < 24 || box.height < name.height + 2) return;
    final both =
        it.detail.isNotEmpty && box.height > name.height + detail.height + 40;
    final h = both ? name.height + detail.height : name.height;
    final c = _px(SheetLayout.centroid(it.outline));
    final w = both ? math.max(name.width, detail.width) : name.width;
    taken.add(Rect.fromCenter(center: c, width: w + 4, height: h + 2));
    name.paint(canvas, Offset(c.dx - name.width / 2, c.dy - h / 2));
    if (both) {
      detail.paint(
        canvas,
        Offset(c.dx - detail.width / 2, c.dy - h / 2 + name.height),
      );
    }
  }

  /// Each side's length in a small pill at its middle, nudged towards the
  /// inside of the plot, so two plots sharing a boundary each keep their
  /// own label. Skipped where the side is too short on screen to hold it.
  void _sides(Canvas canvas, CanvasItem it, bool selected, List<Rect> taken) {
    final poly = it.outline;
    final c = _px(SheetLayout.centroid(poly));
    for (var i = 0; i < poly.length; i++) {
      final a = _px(poly[i]), b = _px(poly[(i + 1) % poly.length]);
      final edge = b - a;
      final tp = TextPainter(
        text: TextSpan(
          text:
              '${lengthUnit.format(Geometry.sideLength(poly[i], poly[(i + 1) % poly.length]))} '
              '$lengthLabel',
          style: AppTypography.mono(
            size: 9,
            weight: FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.text,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (edge.distance < tp.width + 12) continue;

      // Unit normal, flipped to point at the plot's centre.
      var n = Offset(-edge.dy, edge.dx) / edge.distance;
      final mid = (a + b) / 2;
      if ((c - mid).dx * n.dx + (c - mid).dy * n.dy < 0) n = -n;
      final pos = mid + n * (tp.height / 2 + 5);

      final rect = Rect.fromCenter(
        center: pos,
        width: tp.width + 8,
        height: tp.height + 3,
      );
      if (taken.any((r) => r.overlaps(rect.inflate(2)))) continue;
      taken.add(rect);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas
        ..drawRRect(
          rr,
          Paint()
            ..color = selected ? accent : AppColors.ink.withValues(alpha: 0.85),
        )
        ..drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6
            ..color = selected ? accent : it.color.withValues(alpha: 0.6),
        );
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _scaleBar(Canvas canvas, Size size) {
    final m = _step(scale, 60);
    final w = m * scale;
    final left = 12.0, y = size.height - 14;
    final p = Paint()
      ..color = AppColors.textDim
      ..strokeWidth = 1.5;
    canvas
      ..drawLine(Offset(left, y), Offset(left + w, y), p)
      ..drawLine(Offset(left, y - 4), Offset(left, y + 1), p)
      ..drawLine(Offset(left + w, y - 4), Offset(left + w, y + 1), p);
    final tp = TextPainter(
      text: TextSpan(
        text: '${NumberFormat.decimalPattern().format(m)} $meterLabel',
        style: AppTypography.mono(size: 10, color: AppColors.textDim),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(left + w + 6, y - tp.height / 2 - 1));
  }

  @override
  bool shouldRepaint(covariant SheetCanvasPainter old) => true;
}

/// Read-only picture of a sheet's arrangement, fitted to its box.
class SheetLayoutPreview extends StatelessWidget {
  final List<CanvasItem> items;
  final Color accent;
  final String meterLabel;
  final LengthUnit lengthUnit;
  final String lengthLabel;
  const SheetLayoutPreview({
    super.key,
    required this.items,
    required this.accent,
    required this.meterLabel,
    required this.lengthUnit,
    required this.lengthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final (scale, offset) = fitView(items, size, pad: 18);
        return CustomPaint(
          size: size,
          painter: SheetCanvasPainter(
            items: items,
            scale: scale,
            offset: offset,
            accent: accent,
            meterLabel: meterLabel,
            lengthUnit: lengthUnit,
            lengthLabel: lengthLabel,
          ),
        );
      },
    );
  }
}
