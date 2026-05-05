import 'package:flutter/material.dart';

import '../../../core/geometry/vertex.dart';

class PolygonPainter extends CustomPainter {
  final List<Vertex> vertices;
  final Color color;
  final double scale;
  final Offset center;
  final double fillOpacity;
  final double strokeWidth;
  final List<double>? strokeDash;

  PolygonPainter({
    required this.vertices,
    required this.color,
    required this.scale,
    required this.center,
    this.fillOpacity = 0.12,
    this.strokeWidth = 1.5,
    this.strokeDash,
  });

  Path buildPath() {
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
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.length < 3) return;
    final path = buildPath();
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: fillOpacity);
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    if (strokeDash == null) {
      canvas.drawPath(path, stroke);
    } else {
      _drawDashed(canvas, path, stroke, strokeDash!);
    }
  }

  static void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dash,
  ) {
    final dashed = Path();
    for (final m in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      var i = 0;
      while (distance < m.length) {
        final len = dash[i % dash.length];
        if (draw) {
          dashed.addPath(
            m.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
        i++;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant PolygonPainter old) =>
      old.vertices != vertices ||
      old.color != color ||
      old.scale != scale ||
      old.center != center ||
      old.fillOpacity != fillOpacity ||
      old.strokeWidth != strokeWidth;
}
