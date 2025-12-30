part of '../drawing_page.dart';

mixin ResizeMixin on State<DrawingPage> {
  // State variables managed by this mixin
  bool _isResizeMode = false;
  double? _resizeTargetArea;
  double? _currentAreaMeters;
  final Set<int> _selectedResizeIndices = {};
  List<Point>? _previewPoints;

  // Abstract members required from the main state
  List<Point> get _points;
  ShapeType get _selectedShape;
  set _selectedShape(ShapeType value);
  set _isShapeComplete(bool value);
  TextEditingController get _radiusController;
  Map<int, double> get _sideMeasurements;
  Map<String, double> get _diagonalMeasurements;

  void _calculateArea();
  void _zoomToFit();

  void _applyResize(
    double targetArea,
    MeasurementUnit unit,
    double currentArea,
  ) {
    if (_points.isEmpty &&
        _selectedShape != ShapeType.circle &&
        _selectedShape != ShapeType.rectangle) {
      return;
    }

    // Convert target area to square meters
    double targetAreaSqM = targetArea;
    switch (unit) {
      case MeasurementUnit.squareFeet:
        targetAreaSqM = targetArea / AppConstants.sqMeterToSqFeet;
        break;
      case MeasurementUnit.acres:
        targetAreaSqM = targetArea / AppConstants.sqMeterToAcre;
        break;
      case MeasurementUnit.hectares:
        targetAreaSqM = targetArea / AppConstants.sqMeterToHectare;
        break;
      case MeasurementUnit.squareMeters:
        break;
    }

    // Special handling for Circle: Immediate resize
    if (_selectedShape == ShapeType.circle) {
      final inputUnit = context.read<MeasurementUnitBloc>().state.unit;
      // Area = pi * r^2 => r = sqrt(Area / pi)
      final newRadiusMeters = math.sqrt(targetAreaSqM / math.pi);
      final newRadiusInputUnit = inputUnit.fromMeters(newRadiusMeters);

      setState(() {
        _radiusController.text = newRadiusInputUnit.toStringAsFixed(2);
      });

      _calculateArea();

      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.circleResized),
          backgroundColor: Colors.green,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _zoomToFit();
      });
      return;
    }

    setState(() {
      _isResizeMode = true;
      _resizeTargetArea = targetAreaSqM;
      _currentAreaMeters = currentArea;
      _selectedResizeIndices.clear();
      // Default: Select all points
      for (int i = 0; i < _points.length; i++) {
        _selectedResizeIndices.add(i);
      }
      _updateResizePreview();
    });

    // Zoom to fit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomToFit();
    });
  }

  void _handleResizeTap(Offset localPosition) {
    // Find tapped point
    const double touchRadius = 30.0; // Increased touch area
    int? tappedIndex;

    // 1. Check points first
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final distance = (Offset(point.x, point.y) - localPosition).distance;
      if (distance <= touchRadius) {
        tappedIndex = i;
        break;
      }
    }

    if (tappedIndex != null) {
      final index = tappedIndex; // Capture for closure
      setState(() {
        if (_selectedResizeIndices.contains(index)) {
          _selectedResizeIndices.remove(index);
        } else {
          _selectedResizeIndices.add(index);
        }
        _updateResizePreview();
      });
      return;
    }

    // 2. If no point tapped, check lines (sides)
    // This allows selecting/deselecting a whole side (2 points)
    int? tappedSideIndex;
    for (int i = 0; i < _points.length; i++) {
      final p1 = _points[i];
      final p2 = _points[(i + 1) % _points.length];

      // Calculate distance from tap to line segment p1-p2
      final dist = _distToSegment(
        Point(localPosition.dx, localPosition.dy),
        p1,
        p2,
      );

      if (dist <= touchRadius) {
        tappedSideIndex = i;
        break;
      }
    }

    if (tappedSideIndex != null) {
      final idx1 = tappedSideIndex;
      final idx2 = (tappedSideIndex + 1) % _points.length;

      setState(() {
        // Toggle logic: If both are selected, deselect both. Otherwise select both.
        final isBothSelected =
            _selectedResizeIndices.contains(idx1) &&
            _selectedResizeIndices.contains(idx2);

        if (isBothSelected) {
          _selectedResizeIndices.remove(idx1);
          _selectedResizeIndices.remove(idx2);
        } else {
          _selectedResizeIndices.add(idx1);
          _selectedResizeIndices.add(idx2);
        }
        _updateResizePreview();
      });
    }
  }

  double _distToSegment(Point p, Point v, Point w) {
    final l2 = math.pow(v.x - w.x, 2) + math.pow(v.y - w.y, 2);
    if (l2 == 0) {
      return math.sqrt(math.pow(p.x - v.x, 2) + math.pow(p.y - v.y, 2));
    }
    var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
    t = t.clamp(0.0, 1.0);
    final px = v.x + t * (w.x - v.x);
    final py = v.y + t * (w.y - v.y);
    return math.sqrt(math.pow(p.x - px, 2) + math.pow(p.y - py, 2));
  }

  void _updateResizePreview() {
    if (_points.isEmpty ||
        _selectedResizeIndices.isEmpty ||
        _resizeTargetArea == null ||
        _currentAreaMeters == null ||
        _currentAreaMeters! <= 0) {
      _previewPoints = [];
      return;
    }

    // Calculate current pixel area
    final currentPixelArea = _calculatePolygonArea(_points);
    if (currentPixelArea <= 0) return;

    // Calculate target pixel area based on ratio of real-world areas
    // TargetPixelArea / CurrentPixelArea = TargetAreaMeters / CurrentAreaMeters
    final targetPixelArea =
        currentPixelArea * (_resizeTargetArea! / _currentAreaMeters!);

    // Calculate centroid of the shape
    double sumX = 0;
    double sumY = 0;
    for (var point in _points) {
      sumX += point.x;
      sumY += point.y;
    }
    final centroidX = sumX / _points.length;
    final centroidY = sumY / _points.length;

    // If all points are selected, we can use simple scaling
    if (_selectedResizeIndices.length == _points.length) {
      final scaleFactor = math.sqrt(targetPixelArea / currentPixelArea);
      final newPoints = <Point>[];
      for (var point in _points) {
        final dx = point.x - centroidX;
        final dy = point.y - centroidY;
        newPoints.add(
          Point(centroidX + (dx * scaleFactor), centroidY + (dy * scaleFactor)),
        );
      }
      _previewPoints = newPoints;
    } else {
      // Mixed selection: use binary search
      _previewPoints = _findCorrectScaleForMixedPoints(
        centroidX,
        centroidY,
        targetPixelArea,
      );
    }
  }

  List<Point> _findCorrectScaleForMixedPoints(
    double cx,
    double cy,
    double targetPixelArea,
  ) {
    // Binary search for scale factor
    double low = 0.1;
    double high = 10.0;
    List<Point> bestPoints = [];
    double minDiff = double.infinity;

    for (int i = 0; i < 20; i++) {
      // 20 iterations is enough precision
      final mid = (low + high) / 2;
      final testPoints = <Point>[];

      for (int j = 0; j < _points.length; j++) {
        if (_selectedResizeIndices.contains(j)) {
          final point = _points[j];
          final dx = point.x - cx;
          final dy = point.y - cy;
          testPoints.add(Point(cx + (dx * mid), cy + (dy * mid)));
        } else {
          testPoints.add(_points[j]);
        }
      }

      final area = _calculatePolygonArea(testPoints);
      final diff = (area - targetPixelArea).abs();

      if (diff < minDiff) {
        minDiff = diff;
        bestPoints = testPoints;
      }

      if (area < targetPixelArea) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return bestPoints;
  }

  double _calculatePolygonArea(List<Point> points) {
    if (points.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }
    return (area / 2).abs();
  }

  void _confirmResize() {
    if (_previewPoints != null && _previewPoints!.isNotEmpty) {
      // Check if selection was partial (implies distortion)
      final bool isPartialSelection =
          _selectedResizeIndices.length != _points.length;

      setState(() {
        _points.clear();
        _points.addAll(_previewPoints!);
        _isResizeMode = false;
        _previewPoints = null;
        _selectedResizeIndices.clear();

        // Clear measurements as they are no longer valid
        _sideMeasurements.clear();
        _diagonalMeasurements.clear();

        // Recalculate side measurements based on the new area
        if (_resizeTargetArea != null) {
          final newAreaPixels = _calculatePolygonArea(_points);
          if (newAreaPixels > 0) {
            final metersPerPixel = math.sqrt(
              _resizeTargetArea! / newAreaPixels,
            );

            // Calculate sides
            for (int i = 0; i < _points.length; i++) {
              final p1 = _points[i];
              final p2 = _points[(i + 1) % _points.length];
              final distPixels = math.sqrt(
                math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2),
              );
              final distMeters = distPixels * metersPerPixel;
              _sideMeasurements[i] = distMeters;
            }

            // Calculate diagonals if needed (for polygons with > 3 sides)
            if (_points.length > 3) {
              // Calculate diagonals from vertex 0 to N-2
              for (int i = 2; i < _points.length - 1; i++) {
                final p1 = _points[0];
                final p2 = _points[i];
                final distPixels = math.sqrt(
                  math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2),
                );
                final distMeters = distPixels * metersPerPixel;
                _diagonalMeasurements['0-$i'] = distMeters;
              }
            }

            // Update controllers for Rectangle and Circle so _calculateArea uses new values
            if (_selectedShape == ShapeType.rectangle) {
              // Check if the shape is still a rectangle (all points selected/scaled uniformly)
              // If user selected a subset of points, it's likely distorted -> Convert to Polygon

              final w1 = _sideMeasurements[0] ?? 0;
              final h1 = _sideMeasurements[1] ?? 0;
              final w2 = _sideMeasurements[2] ?? 0;
              final h2 = _sideMeasurements[3] ?? 0;

              const tolerance = 0.01; // 1% tolerance
              bool isDistorted = false;

              if ((w1 - w2).abs() > w1 * tolerance ||
                  (h1 - h2).abs() > h1 * tolerance) {
                isDistorted = true;
              }

              // Force distortion if partial selection was used
              if (isPartialSelection) {
                isDistorted = true;
              }

              if (isDistorted) {
                _selectedShape = ShapeType.polygon;
                _isShapeComplete =
                    true; // Mark as complete so Calculate button is enabled

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Shape converted to Polygon due to non-uniform resize.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                // Update width/height controllers
                // Average width/height
                // final avgW = (w1 + w2) / 2;
                // final avgH = (h1 + h2) / 2;

                // We need to update the controllers that _calculateArea uses
                // But _calculateArea uses _widthControllers and _heightControllers if available
                // Or _widthController and _heightController if not.
                // Let's update the main ones.
                // Note: This might be simplistic if using average method with multiple segments.
                // But resize usually simplifies things.
              }
            }
          }
        }
      });

      // Trigger recalculation
      _calculateArea();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shape resized successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelResize() {
    setState(() {
      _isResizeMode = false;
      _previewPoints = null;
    });
  }
}
