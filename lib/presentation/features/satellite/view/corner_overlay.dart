import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/geometry/geo_plot.dart';
import '../../../../core/geometry/mercator_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Width of a corner pin, in logical pixels.
const cornerPinSize = 30.0;

/// A round pin with the corner's number, centred on the point (a teardrop
/// pin's tip is hard to put exactly on a field's corner). Drawn the same
/// whether the map shows it or, during a drag, the screen does.
void paintCornerPin(Canvas canvas, Offset c, int n, Color accent) {
  canvas
    ..drawCircle(c, cornerPinSize / 2 - 1, Paint()..color = AppColors.ink)
    ..drawCircle(c, cornerPinSize / 2 - 3, Paint()..color = accent);
  final label = TextPainter(
    text: TextSpan(
      text: NumberFormat.decimalPattern().format(n),
      style: AppTypography.sans(
        size: n > 9 ? 11 : 13,
        weight: FontWeight.w700,
        color: AppColors.ink,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(canvas, c - Offset(label.width / 2, label.height / 2));
}

/// The plot while one of its corners is being dragged: the outline and the
/// pins, drawn here rather than by the map so they follow the finger at
/// once, and above the finger a magnifier showing the ground under the
/// corner, so the finger never hides what is being placed.
class CornerDragPainter extends CustomPainter {
  final MercatorView view;
  final List<GeoPoint> corners;
  final List<List<GeoPoint>> done;

  /// The corner being dragged; null once the finger has lifted (the plot is
  /// still drawn for a moment, until the map draws it again).
  final int? dragging;
  final Offset finger;

  /// The map without the plot on it, to magnify; null until it arrives.
  final ui.Image? picture;
  final Color accent;

  const CornerDragPainter({
    required this.view,
    required this.corners,
    required this.done,
    required this.dragging,
    required this.finger,
    required this.picture,
    required this.accent,
  });

  static const loupeRadius = 58.0;
  static const _zoom = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final c in corners) view.toScreen(c)];
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _plot(canvas, pts, (p) => p, pins: true);
    canvas.restore();
    final i = dragging;
    if (i != null && i < pts.length) _loupe(canvas, size, pts, pts[i]);
  }

  /// The outlines, through [at] (the screen, or the magnifier's view of it).
  void _plot(
    Canvas canvas,
    List<Offset> pts,
    Offset Function(Offset) at, {
    required bool pins,
  }) {
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.75);
    for (final plot in done) {
      if (plot.length < 3) continue;
      final path = Path()
        ..addPolygon([for (final c in plot) at(view.toScreen(c))], true);
      canvas
        ..drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.12))
        ..drawPath(path, faint);
    }
    if (pts.length >= 2) {
      final path = Path()
        ..addPolygon([for (final p in pts) at(p)], pts.length >= 3);
      if (pts.length >= 3) {
        canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.22));
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = accent,
      );
    }
    for (var k = 0; k < pts.length; k++) {
      if (pins) {
        paintCornerPin(canvas, at(pts[k]), k + 1, accent);
      } else if (k != dragging) {
        // In the magnifier the other corners are small dots: a full pin
        // would cover the ground the user is trying to see.
        canvas
          ..drawCircle(at(pts[k]), 5, Paint()..color = AppColors.ink)
          ..drawCircle(at(pts[k]), 3.5, Paint()..color = accent);
      }
    }
  }

  void _loupe(Canvas canvas, Size size, List<Offset> pts, Offset point) {
    const r = loupeRadius;
    var center = finger + const Offset(0, -110);
    if (center.dy < r + 6) center = finger + const Offset(0, 110);
    center = Offset(
      center.dx.clamp(r + 6, math.max(r + 6, size.width - r - 6)),
      center.dy.clamp(r + 6, math.max(r + 6, size.height - r - 6)),
    );
    final circle = Rect.fromCircle(center: center, radius: r);

    canvas
      ..save()
      ..clipPath(Path()..addOval(circle))
      ..drawRect(circle, Paint()..color = AppColors.surface);
    final img = picture;
    if (img != null) {
      // The picture is in the screen's own pixels; find the patch round
      // the corner and stretch it over the glass.
      final k = img.width / size.width;
      canvas.drawImageRect(
        img,
        Rect.fromCenter(
          center: point * k,
          width: 2 * r / _zoom * k,
          height: 2 * r / _zoom * k,
        ),
        circle,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    _plot(canvas, pts, (p) => center + (p - point) * _zoom, pins: false);
    // A dark line under a light one: seen on any ground.
    for (final (color, width) in [
      (AppColors.ink, 3.0),
      (AppColors.danger, 1.4),
    ]) {
      final cross = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(
          center - const Offset(16, 0),
          center - const Offset(4, 0),
          cross,
        )
        ..drawLine(
          center + const Offset(4, 0),
          center + const Offset(16, 0),
          cross,
        )
        ..drawLine(
          center - const Offset(0, 16),
          center - const Offset(0, 4),
          cross,
        )
        ..drawLine(
          center + const Offset(0, 4),
          center + const Offset(0, 16),
          cross,
        );
    }
    canvas
      ..drawCircle(center, 1.5, Paint()..color = AppColors.danger)
      ..restore()
      ..drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent,
      );
  }

  @override
  bool shouldRepaint(covariant CornerDragPainter old) => true;
}

/// Starts a drag only for a touch that lands on a corner, so that dragging
/// a pin moves the pin while dragging anywhere else still moves the map.
class CornerGrabRecognizer extends PanGestureRecognizer {
  CornerGrabRecognizer({super.debugOwner});

  /// Whether a touch at this point (in the map's own coordinates) is on a
  /// corner.
  bool Function(Offset local) onCorner = (_) => false;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      onCorner(event.localPosition) && super.isPointerAllowed(event);
}
