import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/measurement.dart';
import '../../../../../settings/presentation/bloc/measurement_unit_bloc.dart';

class ShapePainter extends CustomPainter {
  final List<Point> points;
  final ShapeType shapeType;
  final double? radius;
  final Map<int, double> sideMeasurements;
  final Map<String, double> diagonalMeasurements;
  final List<Point> previewPoints;
  final Set<int> selectedIndices;
  final bool isResizeMode;
  final InputUnit inputUnit;
  final bool useCompoundUnits;

  ShapePainter(
    this.points,
    this.shapeType,
    this.radius,
    this.sideMeasurements,
    this.diagonalMeasurements, {
    this.previewPoints = const [],
    this.selectedIndices = const {},
    this.isResizeMode = false,
    required this.inputUnit,
    this.useCompoundUnits = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = AppTheme.accentColor
      ..style = PaintingStyle.fill;

    // Draw preview shape if available (dashed line)
    if (previewPoints.isNotEmpty) {
      final previewPaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final previewPath = Path();
      previewPath.moveTo(previewPoints.first.x, previewPoints.first.y);
      for (var i = 1; i < previewPoints.length; i++) {
        previewPath.lineTo(previewPoints[i].x, previewPoints[i].y);
      }
      previewPath.close();

      // Draw dashed effect manually since Flutter doesn't have built-in dashed path
      // Simple implementation: draw the path with transparency to indicate preview
      canvas.drawPath(
        previewPath,
        previewPaint..color = Colors.orange.withValues(alpha: 0.5),
      );

      // Draw preview points
      for (var point in previewPoints) {
        canvas.drawCircle(
          Offset(point.x, point.y),
          4,
          Paint()..color = Colors.orange.withValues(alpha: 0.5),
        );
      }
    }

    // Draw shape based on type
    if (shapeType == ShapeType.circle && radius != null && points.isNotEmpty) {
      // Draw circle with fixed size, centered on the point
      // The radius value is only used for area calculation, not for visual scaling
      final center = Offset(points[0].x, points[0].y);
      const double fixedRadiusPixels = 80; // Fixed visual size

      canvas.drawCircle(center, fixedRadiusPixels, fillPaint);
      canvas.drawCircle(center, fixedRadiusPixels, paint);
      canvas.drawCircle(center, 6, pointPaint);

      // Draw radius line and label
      final radiusEnd = Offset(center.dx + fixedRadiusPixels, center.dy);
      canvas.drawLine(center, radiusEnd, paint);

      // Draw label
      final midpoint = Offset(
        (center.dx + radiusEnd.dx) / 2,
        (center.dy + radiusEnd.dy) / 2,
      );
      final labelText = _formatLength(radius!);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          midpoint.dx - textPainter.width / 2,
          midpoint.dy - textPainter.height / 2,
        ),
      );
    } else if (shapeType == ShapeType.rectangle && points.length == 4) {
      // Draw rectangle using the 4 corner points
      final path = Path();
      path.moveTo(points[0].x, points[0].y);
      path.lineTo(points[1].x, points[1].y);
      path.lineTo(points[2].x, points[2].y);
      path.lineTo(points[3].x, points[3].y);
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, paint);

      // Draw corner points
      for (int i = 0; i < points.length; i++) {
        _drawPoint(canvas, points[i], i, pointPaint);
      }

      // Draw side labels
      for (var i = 0; i < points.length; i++) {
        _drawSideLabel(
          canvas,
          Offset(points[i].x, points[i].y),
          Offset(
            points[(i + 1) % points.length].x,
            points[(i + 1) % points.length].y,
          ),
          i,
        );
      }
    } else if (points.length >= 2) {
      // Draw polygon/lines
      final path = Path();
      path.moveTo(points.first.x, points.first.y);

      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }

      if (points.length > 2) {
        path.close();
        canvas.drawPath(path, fillPaint);
      }

      canvas.drawPath(path, paint);

      // Draw all points
      for (int i = 0; i < points.length; i++) {
        _drawPoint(canvas, points[i], i, pointPaint);
      }

      // Draw point numbers (labels: 0, 1, 2, 3...)
      for (int i = 0; i < points.length; i++) {
        _drawPointNumber(canvas, Offset(points[i].x, points[i].y), i);
      }

      // Draw diagonals if they exist
      if (diagonalMeasurements.isNotEmpty) {
        _drawDiagonals(canvas);
      }

      // Draw side labels with measurements
      for (var i = 0; i < points.length - 1; i++) {
        _drawSideLabel(
          canvas,
          Offset(points[i].x, points[i].y),
          Offset(points[i + 1].x, points[i + 1].y),
          i,
        );
      }

      // Draw closing side label for closed shapes (3+ points)
      if (points.length >= 3) {
        _drawSideLabel(
          canvas,
          Offset(points.last.x, points.last.y),
          Offset(points.first.x, points.first.y),
          points.length - 1,
        );
      }
    } else if (points.length == 1) {
      // Draw single point
      _drawPoint(canvas, points.first, 0, pointPaint);
    }
  }

  void _drawPoint(Canvas canvas, Point point, int index, Paint defaultPaint) {
    final offset = Offset(point.x, point.y);

    Paint paintToUse = defaultPaint;
    double radius = 6;

    if (isResizeMode) {
      if (selectedIndices.contains(index)) {
        // Selected point in resize mode
        paintToUse = Paint()..color = Colors.deepOrange;
        radius = 8;

        // Draw selection halo
        canvas.drawCircle(
          offset,
          12,
          Paint()..color = Colors.deepOrange.withValues(alpha: 0.3),
        );
      } else {
        // Unselected point in resize mode
        paintToUse = Paint()..color = Colors.grey;
      }
    }

    canvas.drawCircle(offset, radius, paintToUse);
    // Draw point border
    canvas.drawCircle(
      offset,
      radius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawSideLabel(Canvas canvas, Offset start, Offset end, int sideIndex) {
    final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    // Draw background for label
    final hasMeasurement = sideMeasurements.containsKey(sideIndex);
    final bgPaint = Paint()
      ..color = hasMeasurement ? AppTheme.successColor : Colors.orange
      ..style = PaintingStyle.fill;

    // Prepare text first to measure it
    final labelText = hasMeasurement
        ? _formatLength(inputUnit.fromMeters(sideMeasurements[sideIndex]!))
        : '${sideIndex + 1}';

    // Determine font size based on text length
    double fontSize;
    if (labelText.length <= 2) {
      fontSize = 10;
    } else if (labelText.length <= 4) {
      fontSize = 8;
    } else if (labelText.length <= 6) {
      fontSize = 6;
    } else {
      fontSize = 5;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calculate circle radius based on text size with padding
    final circleRadius = (textPainter.width / 2 + 6).clamp(12.0, 20.0);

    canvas.drawCircle(midpoint, circleRadius, bgPaint);
    canvas.drawCircle(
      midpoint,
      circleRadius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw text centered in the circle
    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawPointNumber(Canvas canvas, Offset pointPosition, int pointIndex) {
    // Draw a small label with the point number next to the point
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$pointIndex',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw label above and to the right of the point
    textPainter.paint(
      canvas,
      Offset(pointPosition.dx + 12, pointPosition.dy - 16),
    );
  }

  void _drawDiagonals(Canvas canvas) {
    // Draw diagonal lines between the specified points
    final diagonalPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (String diagonalKey in diagonalMeasurements.keys) {
      final parts = diagonalKey.split('-');
      if (parts.length == 2) {
        final fromIndex = int.tryParse(parts[0]);
        final toIndex = int.tryParse(parts[1]);

        if (fromIndex != null &&
            toIndex != null &&
            fromIndex < points.length &&
            toIndex < points.length) {
          final fromPoint = Offset(points[fromIndex].x, points[fromIndex].y);
          final toPoint = Offset(points[toIndex].x, points[toIndex].y);

          canvas.drawLine(fromPoint, toPoint, diagonalPaint);

          final midpoint = Offset(
            (fromPoint.dx + toPoint.dx) / 2,
            (fromPoint.dy + toPoint.dy) / 2,
          );

          final measurement = diagonalMeasurements[diagonalKey]!;
          final labelText = _formatLength(inputUnit.fromMeters(measurement));

          final textPainter = TextPainter(
            text: TextSpan(
              text: labelText,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();

          const labelPadding = 4.0;
          final labelBgRect = Rect.fromLTWH(
            midpoint.dx - textPainter.width / 2 - labelPadding,
            midpoint.dy - textPainter.height / 2 - labelPadding,
            textPainter.width + labelPadding * 2,
            textPainter.height + labelPadding * 2,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(labelBgRect, const Radius.circular(3)),
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill,
          );

          textPainter.paint(
            canvas,
            Offset(
              midpoint.dx - textPainter.width / 2,
              midpoint.dy - textPainter.height / 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.sideMeasurements != sideMeasurements ||
      oldDelegate.isResizeMode != isResizeMode ||
      oldDelegate.useCompoundUnits != useCompoundUnits;

  String _formatLength(double value) {
    if (!useCompoundUnits) {
      return '${value.toStringAsFixed(2)}${inputUnit.symbol}';
    }

    if (inputUnit == InputUnit.feet) {
      final feet = value.floor();
      final inches = ((value - feet) * 12).round();
      return "$feet' $inches\"";
    } else {
      // Meters
      final meters = value.floor();
      final cm = ((value - meters) * 100).round();
      return '${meters}m ${cm}cm';
    }
  }
}
