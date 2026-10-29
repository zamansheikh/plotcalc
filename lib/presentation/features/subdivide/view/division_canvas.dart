import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/geometry/division_plan.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/lot_division.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/length_unit.dart';
import '../../draw/view/plot_labels.dart';

const divisionColours = [
  AppColors.lime,
  AppColors.soil,
  AppColors.sky,
  AppColors.amber,
  AppColors.violet,
  AppColors.emerald,
  AppColors.rose,
];

Color ownerColour(int i) => divisionColours[i % divisionColours.length];
const roadColour = Color(0xFF9CA3AF);
const restColour = Color(0xFF6B7280);

Color pieceColour(DivisionPiece p) => switch (p.kind) {
  PieceKind.owner => ownerColour(p.owner!),
  PieceKind.road => roadColour,
  PieceKind.rest => restColour,
};

/// The plot, divided: every lot in its owner's colour with their name, the
/// road, the front side, and the length of every boundary. Tap a side to
/// make it the front; drag a divider to shift land, or its end to turn it.
class DivisionCanvas extends StatefulWidget {
  final List<Vertex> parent;
  final DivisionResult result;
  final int? frontSide;
  final String Function(DivisionPiece p) nameOf;
  final LengthUnit lengthUnit;
  final String lengthLabel;
  final String frontLabel;
  final String northLabel;
  final Color accent;
  final ValueChanged<int> onTapSide;
  final void Function(int index, bool firstEnd, Vertex to) onPivot;
  final void Function(int index, Vertex to) onSlide;
  final VoidCallback onDragEnd;

  const DivisionCanvas({
    super.key,
    required this.parent,
    required this.result,
    required this.frontSide,
    required this.nameOf,
    required this.lengthUnit,
    required this.lengthLabel,
    required this.frontLabel,
    required this.northLabel,
    required this.accent,
    required this.onTapSide,
    required this.onPivot,
    required this.onSlide,
    required this.onDragEnd,
  });

  @override
  State<DivisionCanvas> createState() => _DivisionCanvasState();
}

class _DivisionCanvasState extends State<DivisionCanvas> {
  (int, bool)? _grabbed;
  int? _sliding;

  /// The view, fixed for the length of a drag so the plot does not shift
  /// under the finger as the division changes.
  (double, Offset)? _view;

  (double, Offset) _fit(Size size) {
    final (minX, minY, maxX, maxY) = Geometry.bbox(widget.parent);
    final w = math.max(maxX - minX, 1e-6), h = math.max(maxY - minY, 1e-6);
    // Room around the plot for the boundary lengths.
    const pad = 46.0;
    final s = math.min((size.width - pad * 2) / w, (size.height - pad * 2) / h);
    final o = Offset(
      size.width / 2 - (minX + w / 2) * s,
      size.height / 2 - (minY + h / 2) * s,
    );
    return (s, o);
  }

  static double _segDist(Offset p, Offset a, Offset b) {
    final d = b - a;
    final len2 = d.dx * d.dx + d.dy * d.dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * d.dx + (p - a).dy * d.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + d * t)).distance;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final (scale, offset) = _view ?? _fit(size);
        Offset px(Vertex v) => Offset(v.x * scale, v.y * scale) + offset;
        Vertex world(Offset p) =>
            Vertex((p.dx - offset.dx) / scale, (p.dy - offset.dy) / scale);
        final cuts = widget.result.cuts;
        final parent = widget.parent;

        return GestureDetector(
          key: const ValueKey('division-canvas'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            int? best;
            var bestD = 26.0;
            for (var i = 0; i < parent.length; i++) {
              final dd = _segDist(
                d.localPosition,
                px(parent[i]),
                px(parent[(i + 1) % parent.length]),
              );
              if (dd < bestD) {
                bestD = dd;
                best = i;
              }
            }
            if (best != null) widget.onTapSide(best);
          },
          onPanStart: (d) {
            _grabbed = null;
            _sliding = null;
            var best = 30.0;
            for (var i = 0; i < cuts.length; i++) {
              for (final first in [true, false]) {
                final end = first ? cuts[i].a : cuts[i].b;
                final dd = (px(end) - d.localPosition).distance;
                if (dd < best) {
                  best = dd;
                  _grabbed = (i, first);
                }
              }
            }
            if (_grabbed == null) {
              var bestLine = 28.0;
              for (var i = 0; i < cuts.length; i++) {
                final dd = _segDist(
                  d.localPosition,
                  px(cuts[i].a),
                  px(cuts[i].b),
                );
                if (dd < bestLine) {
                  bestLine = dd;
                  _sliding = i;
                }
              }
            }
            if (_grabbed != null || _sliding != null) {
              setState(() => _view = (scale, offset));
            }
          },
          onPanUpdate: (d) {
            final g = _grabbed;
            if (g != null) {
              widget.onPivot(g.$1, g.$2, world(d.localPosition));
            } else if (_sliding != null) {
              widget.onSlide(_sliding!, world(d.localPosition));
            }
          },
          onPanEnd: (_) {
            final moved = _grabbed != null || _sliding != null;
            _grabbed = null;
            _sliding = null;
            setState(() => _view = null);
            if (moved) widget.onDragEnd();
          },
          child: CustomPaint(
            size: size,
            painter: _DivisionPainter(
              parent: parent,
              result: widget.result,
              frontSide: widget.frontSide,
              nameOf: widget.nameOf,
              lengthUnit: widget.lengthUnit,
              lengthLabel: widget.lengthLabel,
              frontLabel: widget.frontLabel,
              northLabel: widget.northLabel,
              accent: widget.accent,
              scale: scale,
              offset: offset,
            ),
          ),
        );
      },
    );
  }
}

class _DivisionPainter extends CustomPainter {
  final List<Vertex> parent;
  final DivisionResult result;
  final int? frontSide;
  final String Function(DivisionPiece p) nameOf;
  final LengthUnit lengthUnit;
  final String lengthLabel;
  final String frontLabel;
  final String northLabel;
  final Color accent;
  final double scale;
  final Offset offset;

  _DivisionPainter({
    required this.parent,
    required this.result,
    required this.frontSide,
    required this.nameOf,
    required this.lengthUnit,
    required this.lengthLabel,
    required this.frontLabel,
    required this.northLabel,
    required this.accent,
    required this.scale,
    required this.offset,
  });

  Offset _px(Vertex v) => Offset(v.x * scale, v.y * scale) + offset;

  Path _path(List<Vertex> poly) =>
      Path()..addPolygon([for (final v in poly) _px(v)], true);

  String _len(Vertex a, Vertex b) =>
      '${lengthUnit.format(Geometry.sideLength(a, b))} $lengthLabel';

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (parent.length < 3) return;
    final taken = <LabelBox>[
      // The north arrow, top left.
      LabelBox.rect(const Rect.fromLTWH(0, 0, 44, 52)),
    ];

    // Pieces.
    for (final p in result.pieces) {
      if (p.vertices.length < 3) continue;
      final colour = pieceColour(p);
      final path = _path(p.vertices);
      canvas.drawPath(
        path,
        Paint()
          ..color = colour.withValues(
            alpha: p.kind == PieceKind.owner ? 0.26 : 0.18,
          ),
      );
      if (p.kind == PieceKind.road) _hatch(canvas, path, colour);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = colour.withValues(alpha: 0.9),
      );
    }

    // The plot's own boundary, and its front side.
    canvas.drawPath(
      _path(parent),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.text.withValues(alpha: 0.6),
    );
    final f = frontSide;
    if (f != null && f < parent.length) {
      canvas.drawLine(
        _px(parent[f]),
        _px(parent[(f + 1) % parent.length]),
        Paint()
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }

    // Dividers and their handles.
    for (final cut in result.cuts) {
      canvas.drawLine(
        _px(cut.a),
        _px(cut.b),
        Paint()
          ..strokeWidth = 2.2
          ..color = AppColors.text,
      );
    }

    // The dividers' handles: nothing may cover them.
    for (final cut in result.cuts) {
      taken
        ..add(LabelBox.circle(_px(cut.a), 11))
        ..add(LabelBox.circle(_px(cut.b), 11));
    }

    // Names first, in the middle of each piece. A road is long and thin:
    // its name runs along it, slid clear of the handles.
    for (final p in result.pieces) {
      if (p.vertices.length < 3) continue;
      final c = _px(_centroid(p.vertices));
      final style = AppTypography.sans(
        size: 11,
        weight: FontWeight.w700,
        color: AppColors.ink,
      );
      final name = nameOf(p);
      var box = LabelBox(c, labelPillSize(name, style));
      if (p.kind == PieceKind.road) {
        final pts = [for (final v in p.vertices) _px(v)];
        var a = pts[0], b = pts[1];
        for (var i = 0; i < pts.length; i++) {
          final q = pts[(i + 1) % pts.length];
          if ((q - pts[i]).distance > (b - a).distance) {
            a = pts[i];
            b = q;
          }
        }
        final dir = (b - a) / math.max((b - a).distance, 1e-6);
        final span = (b - a).distance;
        final angle = readableAngle(a, b);
        for (final k in const [0.0, 0.18, -0.18, 0.32, -0.32, 0.42, -0.42]) {
          final candidate = LabelBox(c + dir * (span * k), box.size, angle);
          if (!taken.any((o) => o.overlaps(candidate))) {
            box = candidate;
            break;
          }
        }
      }
      paintLabelPill(
        canvas,
        box,
        name,
        style: style,
        fill: pieceColour(p),
        border: pieceColour(p),
      );
      taken.add(box);
    }

    // The front marker, outside the front side's middle.
    if (f != null && f < parent.length) {
      final a = _px(parent[f]), b = _px(parent[(f + 1) % parent.length]);
      final d = b - a;
      if (d.distance > 0) {
        var n = Offset(-d.dy, d.dx) / d.distance;
        final mid = (a + b) / 2;
        final c = _px(_centroid(parent));
        if ((mid - c).dx * n.dx + (mid - c).dy * n.dy < 0) n = -n;
        final style = AppTypography.sans(
          size: 10,
          weight: FontWeight.w700,
          color: AppColors.ink,
        );
        final sz = labelPillSize('▲ $frontLabel', style);
        final box = LabelBox(
          mid + n * (sz.height / 2 + 26),
          sz,
          readableAngle(a, b),
        );
        paintLabelPill(
          canvas,
          box,
          '▲ $frontLabel',
          style: style,
          fill: accent,
          border: accent,
        );
        taken.add(box);
      }
    }

    // Every stretch of the plot's boundary, split where a divider or the
    // road meets it, measured outside the plot.
    final ends = [
      for (final cut in result.cuts) ...[cut.a, cut.b],
      ...?result.road?.vertices,
    ];
    final boundary = <Vertex>[];
    for (var i = 0; i < parent.length; i++) {
      for (final (a, _) in LotDivision.splitEdge(
        parent[i],
        parent[(i + 1) % parent.length],
        ends,
      )) {
        boundary.add(a);
      }
    }
    final lengthStyle = AppTypography.mono(
      size: 10,
      weight: FontWeight.w600,
      color: AppColors.text,
    );
    taken.addAll(
      paintSideLengths(
        canvas,
        [for (final v in boundary) _px(v)],
        text: (i) => _len(boundary[i], boundary[(i + 1) % boundary.length]),
        style: lengthStyle,
        fill: AppColors.ink.withValues(alpha: 0.85),
        border: AppColors.lineMid,
        bounds: size,
        reserved: taken,
      ),
    );

    // Each divider's own length, on the line.
    for (final cut in result.cuts) {
      final a = _px(cut.a), b = _px(cut.b);
      final text = _len(cut.a, cut.b);
      final sz = labelPillSize(text, lengthStyle);
      final angle = readableAngle(a, b);
      LabelBox? placed;
      // On the line first; failing that, just beside it.
      final d = b - a;
      final normal = d.distance == 0
          ? Offset.zero
          : Offset(-d.dy, d.dx) / d.distance;
      search:
      for (final off in [0.0, sz.height / 2 + 4, -(sz.height / 2 + 4)]) {
        for (final t in const [0.5, 0.35, 0.65, 0.22, 0.78]) {
          final box = LabelBox(Offset.lerp(a, b, t)! + normal * off, sz, angle);
          if (!taken.any((o) => o.overlaps(box.inflate(2)))) {
            placed = box;
            break search;
          }
        }
      }
      if (placed != null) {
        paintLabelPill(
          canvas,
          placed,
          text,
          // Dark on light: a divider's own length, set apart from the
          // boundary's.
          style: lengthStyle.copyWith(color: AppColors.ink),
          fill: AppColors.text,
          border: AppColors.text,
        );
        taken.add(placed);
      }
    }

    for (final cut in result.cuts) {
      for (final e in [cut.a, cut.b]) {
        canvas
          ..drawCircle(_px(e), 8, Paint()..color = AppColors.ink)
          ..drawCircle(
            _px(e),
            8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = AppColors.text,
          );
      }
    }

    _north(canvas);
  }

  void _hatch(Canvas canvas, Path path, Color colour) {
    canvas
      ..save()
      ..clipPath(path);
    final b = path.getBounds();
    final paint = Paint()
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.45);
    for (var x = b.left - b.height; x < b.right; x += 7) {
      canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), paint);
    }
    canvas.restore();
  }

  void _north(Canvas canvas) {
    const c = Offset(22, 26);
    final paint = Paint()..color = AppColors.textDim;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - 14)
        ..lineTo(c.dx - 6, c.dy + 2)
        ..lineTo(c.dx + 6, c.dy + 2)
        ..close(),
      paint,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: northLabel,
        style: AppTypography.sans(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.textDim,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + 6));
  }

  static Vertex _centroid(List<Vertex> p) {
    var x = 0.0, y = 0.0;
    for (final v in p) {
      x += v.x;
      y += v.y;
    }
    return Vertex(x / p.length, y / p.length);
  }

  @override
  bool shouldRepaint(covariant _DivisionPainter old) => true;
}
