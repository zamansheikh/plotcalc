import 'package:flutter/material.dart';

import '../../../core/geometry/vertex.dart';

class PlotThumbnail extends StatelessWidget {
  final List<Vertex> vertices;
  final Color color;
  const PlotThumbnail({super.key, required this.vertices, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThumbPainter(vertices, color),
      size: Size.infinite,
    );
  }
}

class _ThumbPainter extends CustomPainter {
  final List<Vertex> verts;
  final Color color;
  _ThumbPainter(this.verts, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (verts.length < 3) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final v in verts) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }
    final w = maxX - minX, h = maxY - minY;
    if (w == 0 || h == 0) return;

    const padding = 4.0;
    final scale = (size.width - padding * 2) / w;
    final scaleY = (size.height - padding * 2) / h;
    final s = scale < scaleY ? scale : scaleY;
    final ox = (size.width - w * s) / 2 - minX * s;
    final oy = (size.height - h * s) / 2 - minY * s;

    final path = Path();
    for (var i = 0; i < verts.length; i++) {
      final p = Offset(verts[i].x * s + ox, verts[i].y * s + oy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) =>
      old.verts != verts || old.color != color;
}
