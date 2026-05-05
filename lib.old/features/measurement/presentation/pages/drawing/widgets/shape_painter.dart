import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/measurement.dart';
import '../../../../../settings/presentation/bloc/measurement_unit_bloc.dart';
import '../models/resize_constraint.dart';

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
  final ResizeConstraint resizeConstraint;
  final int? compensationSideIndex;
  final Set<int> lockedSideIndices;
  final Set<int> lockedPointIndices;
  final List<Point>? originalPoints;
  final Map<int, double>? originalSideMeasurements;

  ShapePainter(
    this.points,
    this.shapeType,
    this.radius,
    this.sideMeasurements,
    this.diagonalMeasurements, {
    this.previewPoints = const [],
    this.selectedIndices = const {},
    this.isResizeMode = false,
    this.originalPoints,
    this.originalSideMeasurements,
    required this.inputUnit,
    this.useCompoundUnits = false,
    this.resizeConstraint = ResizeConstraint.none,
    this.compensationSideIndex,
    this.lockedSideIndices = const {},
    this.lockedPointIndices = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw original shape overlay (ghost) if available
    if (originalPoints != null && originalPoints!.length >= 3) {
      _drawOriginalShapeOverlay(canvas);
    }

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

      // Draw fixed side highlight
      final fixedSideIndices = _getFixedSideIndices();
      final allLockedIndices = {...fixedSideIndices, ...lockedSideIndices};

      for (final fixedSideIndex in allLockedIndices) {
        final p1 = points[fixedSideIndex];
        final p2 = points[(fixedSideIndex + 1) % points.length];

        canvas.drawLine(
          Offset(p1.x, p1.y),
          Offset(p2.x, p2.y),
          Paint()
            ..color = Colors.red
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke,
        );
      }

      // Draw compensation side highlight
      if (compensationSideIndex != null &&
          points.length > compensationSideIndex!) {
        final p1 = points[compensationSideIndex!];
        final p2 = points[(compensationSideIndex! + 1) % points.length];

        canvas.drawLine(
          Offset(p1.x, p1.y),
          Offset(p2.x, p2.y),
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke,
        );
      }

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

  // Returns a list of fixed side indices
  List<int> _getFixedSideIndices() {
    if (!isResizeMode || selectedIndices.isEmpty) return [];
    if (resizeConstraint == ResizeConstraint.none ||
        resizeConstraint == ResizeConstraint.rigid) {
      return [];
    }

    final n = points.length;
    final indices = <int>[];

    if (selectedIndices.length == 1) {
      final k = selectedIndices.first;
      if (resizeConstraint == ResizeConstraint.previousSide) {
        indices.add((k - 1 + n) % n);
      } else if (resizeConstraint == ResizeConstraint.nextSide) {
        indices.add(k);
      }
    } else {
      // Rigid + Constraint
      final sorted = List<int>.from(selectedIndices)..sort();
      int startIndex = sorted.first;
      int endIndex = sorted.last;

      // Wrap around check
      for (int i = 0; i < sorted.length; i++) {
        final current = sorted[i];
        final next = sorted[(i + 1) % sorted.length];
        final dist = (next - current + n) % n;
        if (dist > 1) {
          endIndex = current;
          startIndex = next;
          break;
        }
      }

      if (resizeConstraint == ResizeConstraint.previousSide ||
          resizeConstraint == ResizeConstraint.bothSides) {
        indices.add((startIndex - 1 + n) % n);
      }
      if (resizeConstraint == ResizeConstraint.nextSide ||
          resizeConstraint == ResizeConstraint.bothSides) {
        indices.add(endIndex);
      }
    }
    return indices;
  }

  void _drawPoint(Canvas canvas, Point point, int index, Paint defaultPaint) {
    final offset = Offset(point.x, point.y);

    Paint paintToUse = defaultPaint;
    double radius = 6;

    if (isResizeMode) {
      if (lockedPointIndices.contains(index)) {
        // Locked point
        paintToUse = Paint()..color = Colors.red;
        radius = 8;
        // Draw X or something to indicate lock?
        // For now just Red color is distinct from Green (Selected) and Grey (Unselected)
      } else if (selectedIndices.contains(index)) {
        // Selected point in resize mode
        paintToUse = Paint()
          ..color = Colors.green; // Changed to Green for Move Mode clarity
        radius = 8;

        // Draw selection halo
        canvas.drawCircle(
          offset,
          12,
          Paint()..color = Colors.green.withValues(alpha: 0.3),
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

    // Check if this side is fixed
    final isFixed =
        _getFixedSideIndices().contains(sideIndex) ||
        lockedSideIndices.contains(sideIndex);

    // Draw background for label
    final hasMeasurement = sideMeasurements.containsKey(sideIndex);

    Color bgColor;
    if (isFixed) {
      bgColor = Colors.red; // Highlight fixed side label
    } else {
      bgColor = hasMeasurement ? AppTheme.successColor : Colors.orange;
    }

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    // Prepare text first to measure it
    final labelText = hasMeasurement
        ? _formatLength(inputUnit.fromMeters(sideMeasurements[sideIndex]!))
        : '${sideIndex + 1}';

    // Check if we have original measurement to show diff
    String? diffLine;
    bool sideChanged = false;
    if (originalSideMeasurements != null &&
        originalSideMeasurements!.containsKey(sideIndex) &&
        hasMeasurement) {
      final oldLength = inputUnit.fromMeters(
        originalSideMeasurements![sideIndex]!,
      );
      final newLength = inputUnit.fromMeters(sideMeasurements[sideIndex]!);
      final diff = newLength - oldLength;
      if (diff.abs() > 0.01) {
        sideChanged = true;
        final sign = diff > 0 ? '+' : '';
        diffLine = '$sign${_formatLength(diff)}';
      }
    }

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

    // Draw diff badge below the circle if side changed
    if (sideChanged && diffLine != null) {
      final diffColor = diffLine.startsWith('+')
          ? Colors.green[700]!
          : Colors.red[700]!;
      final diffBgColor = diffLine.startsWith('+')
          ? Colors.green[50]!
          : Colors.red[50]!;

      final diffPainter = TextPainter(
        text: TextSpan(
          text: diffLine,
          style: TextStyle(
            color: diffColor,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      diffPainter.layout();

      final badgeWidth = diffPainter.width + 6;
      final badgeHeight = diffPainter.height + 3;
      final badgeCenter = Offset(
        midpoint.dx,
        midpoint.dy + circleRadius + badgeHeight / 2 + 2,
      );

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: badgeCenter,
          width: badgeWidth,
          height: badgeHeight,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = diffBgColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = diffColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      diffPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - diffPainter.width / 2,
          badgeCenter.dy - diffPainter.height / 2,
        ),
      );
    }
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
      oldDelegate.useCompoundUnits != useCompoundUnits ||
      oldDelegate.originalPoints != originalPoints ||
      oldDelegate.originalSideMeasurements != originalSideMeasurements;

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

  void _drawOriginalShapeOverlay(Canvas canvas) {
    final origPts = originalPoints!;
    final n = origPts.length;

    // Draw ghost fill
    final ghostFillPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final ghostPath = Path();
    ghostPath.moveTo(origPts[0].x, origPts[0].y);
    for (int i = 1; i < n; i++) {
      ghostPath.lineTo(origPts[i].x, origPts[i].y);
    }
    ghostPath.close();
    canvas.drawPath(ghostPath, ghostFillPaint);

    // Draw ghost outline (dashed)
    final ghostStrokePaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < n; i++) {
      final p1 = origPts[i];
      final p2 = origPts[(i + 1) % n];
      _drawDashedLine(
        canvas,
        Offset(p1.x, p1.y),
        Offset(p2.x, p2.y),
        ghostStrokePaint,
      );
    }

    // Draw ghost points (small hollow circles)
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(
        Offset(origPts[i].x, origPts[i].y),
        4,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashLength = 6;
    const double gapLength = 4;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (Offset(dx, dy)).distance;
    if (distance == 0) return;

    final unitDx = dx / distance;
    final unitDy = dy / distance;
    double drawn = 0;
    bool drawing = true;

    while (drawn < distance) {
      final segLen = drawing ? dashLength : gapLength;
      final remaining = distance - drawn;
      final len = segLen > remaining ? remaining : segLen;
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
          Offset(
            start.dx + unitDx * (drawn + len),
            start.dy + unitDy * (drawn + len),
          ),
          paint,
        );
      }
      drawn += len;
      drawing = !drawing;
    }
  }
}
