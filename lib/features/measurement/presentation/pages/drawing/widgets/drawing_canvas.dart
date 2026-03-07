import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/measurement.dart';
import '../../../../../settings/presentation/bloc/measurement_unit_bloc.dart';
import 'shape_painter.dart';

import '../models/resize_constraint.dart';

class DrawingCanvas extends StatelessWidget {
  final List<Point> points;
  final ShapeType selectedShape;
  final String radiusText;
  final Map<int, double> sideMeasurements;
  final Map<String, double> diagonalMeasurements;
  final List<Point> previewPoints;
  final Set<int> selectedIndices;
  final bool isResizeMode;
  final List<Point>? originalPoints;
  final Map<int, double>? originalSideMeasurements;
  final InputUnit inputUnit;
  final bool useCompoundUnits;
  final TransformationController transformationController;
  final Size viewportSize;
  final Function(Offset) onTapDown;
  final VoidCallback onZoomToFit;
  final ResizeConstraint resizeConstraint;
  final int? compensationSideIndex;
  final Set<int> lockedSideIndices;

  const DrawingCanvas({
    super.key,
    required this.points,
    required this.selectedShape,
    required this.radiusText,
    required this.sideMeasurements,
    required this.diagonalMeasurements,
    required this.previewPoints,
    required this.selectedIndices,
    required this.isResizeMode,
    this.originalPoints,
    this.originalSideMeasurements,
    required this.inputUnit,
    this.useCompoundUnits = false,
    required this.transformationController,
    required this.viewportSize,
    required this.onTapDown,
    required this.onZoomToFit,
    this.resizeConstraint = ResizeConstraint.none,
    this.compensationSideIndex,
    this.lockedSideIndices = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            // Transform viewport coordinates to canvas coordinates
            // so taps work even when zoomed out or panned
            final Matrix4 inverse = Matrix4.inverted(
              transformationController.value,
            );
            final Offset canvasPos = MatrixUtils.transformPoint(
              inverse,
              details.localPosition,
            );
            onTapDown(canvasPos);
          },
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: 0.1,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Container(
              color: Colors.grey[200],
              child: CustomPaint(
                size: viewportSize,
                painter: ShapePainter(
                  points,
                  selectedShape,
                  radiusText.isEmpty ? null : double.tryParse(radiusText),
                  sideMeasurements,
                  diagonalMeasurements,
                  previewPoints: previewPoints,
                  selectedIndices: selectedIndices,
                  isResizeMode: isResizeMode,
                  originalPoints: originalPoints,
                  originalSideMeasurements: originalSideMeasurements,
                  inputUnit: inputUnit,
                  useCompoundUnits: useCompoundUnits,
                  resizeConstraint: resizeConstraint,
                  compensationSideIndex: compensationSideIndex,
                  lockedSideIndices: lockedSideIndices,
                  lockedPointIndices: const {},
                ),
                child: Container(),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'zoom_fit',
            onPressed: onZoomToFit,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}
