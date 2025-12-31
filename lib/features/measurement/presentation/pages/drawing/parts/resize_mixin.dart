part of '../drawing_page.dart';

mixin ResizeMixin on State<DrawingPage> {
  // State variables managed by this mixin
  bool _isResizeMode = false;
  double? _resizeTargetArea;
  double? _currentAreaMeters;
  final Set<int> _selectedResizeIndices = {};
  List<Point>? _previewPoints;
  ResizeConstraint _resizeConstraint = ResizeConstraint.none;

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
        // Reset constraint if not exactly one point selected
        if (_selectedResizeIndices.length != 1) {
          _resizeConstraint = ResizeConstraint.none;
        }
        _updateResizePreview();
      });
      return;
    }

    // 2. If no point tapped, check lines (sides)
    // This allows selecting/deselecting a whole side (2 points)
    // OR toggling constraints if points are already selected
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
      // Check if this side is a valid constraint for the current selection
      if (_selectedResizeIndices.isNotEmpty) {
        final n = _points.length;
        final sideIdx = tappedSideIndex;

        // Determine start and end of selection chain
        final sorted = List<int>.from(_selectedResizeIndices)..sort();
        int startIndex = sorted.first;
        int endIndex = sorted.last;

        // Wrap around check for contiguous selection
        bool isContiguous = true;
        if (sorted.length > 1) {
          int breaks = 0;
          for (int i = 0; i < sorted.length; i++) {
            final current = sorted[i];
            final next = sorted[(i + 1) % sorted.length];
            final dist = (next - current + n) % n;
            if (dist != 1) {
              breaks++;
              if (dist > 1) {
                endIndex = current;
                startIndex = next;
              }
            }
          }
          if (breaks > 1) isContiguous = false;
        }

        if (isContiguous) {
          // Check Previous Side
          final prevSideIdx = (startIndex - 1 + n) % n;
          if (sideIdx == prevSideIdx) {
            setState(() {
              if (_resizeConstraint == ResizeConstraint.previousSide) {
                // Toggle off
                _resizeConstraint = _selectedResizeIndices.length > 1
                    ? ResizeConstraint.rigid
                    : ResizeConstraint.none;
              } else if (_resizeConstraint == ResizeConstraint.nextSide) {
                // Add to existing
                _resizeConstraint = ResizeConstraint.bothSides;
              } else if (_resizeConstraint == ResizeConstraint.bothSides) {
                // Remove previous, keep next
                _resizeConstraint = ResizeConstraint.nextSide;
              } else {
                // Set new
                _resizeConstraint = ResizeConstraint.previousSide;
              }
              _updateResizePreview();
            });
            return;
          }

          // Check Next Side
          final nextSideIdx = endIndex;
          if (sideIdx == nextSideIdx) {
            setState(() {
              if (_resizeConstraint == ResizeConstraint.nextSide) {
                // Toggle off
                _resizeConstraint = _selectedResizeIndices.length > 1
                    ? ResizeConstraint.rigid
                    : ResizeConstraint.none;
              } else if (_resizeConstraint == ResizeConstraint.previousSide) {
                // Add to existing
                _resizeConstraint = ResizeConstraint.bothSides;
              } else if (_resizeConstraint == ResizeConstraint.bothSides) {
                // Remove next, keep previous
                _resizeConstraint = ResizeConstraint.previousSide;
              } else {
                // Set new
                _resizeConstraint = ResizeConstraint.nextSide;
              }
              _updateResizePreview();
            });
            return;
          }
        }
      }

      // Fallback: Select/Deselect points connected to the side
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
        // Reset constraint if selection changes
        if (_selectedResizeIndices.length > 1 && _isSelectionContiguous()) {
          _resizeConstraint = ResizeConstraint.rigid;
        } else {
          _resizeConstraint = ResizeConstraint.none;
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

    // Check for constrained resize (Single point selected + Constraint active)
    if (_selectedResizeIndices.length == 1 &&
        _resizeConstraint != ResizeConstraint.none &&
        _resizeConstraint != ResizeConstraint.rigid) {
      final movingIndex = _selectedResizeIndices.first;
      final constrainedPoints = _solveConstrainedResize(
        movingIndex,
        targetPixelArea,
        _resizeConstraint,
      );

      if (constrainedPoints != null) {
        _previewPoints = constrainedPoints;
        return;
      }
    }

    // Check for Rigid Resize (Multiple contiguous points + Rigid constraint)
    if (_selectedResizeIndices.length > 1 &&
        (_resizeConstraint == ResizeConstraint.rigid ||
            _resizeConstraint == ResizeConstraint.previousSide ||
            _resizeConstraint == ResizeConstraint.nextSide ||
            _resizeConstraint == ResizeConstraint.bothSides) &&
        _isSelectionContiguous()) {
      final rigidPoints = _solveRigidResize(targetPixelArea, _resizeConstraint);
      if (rigidPoints != null) {
        _previewPoints = rigidPoints;
        return;
      }
    }

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

  List<Point>? _solveConstrainedResize(
    int movingIndex,
    double targetAreaPixels,
    ResizeConstraint constraint,
  ) {
    final p = _points;
    final n = p.length;
    final k = movingIndex;
    final prev = (k - 1 + n) % n;
    final next = (k + 1) % n;

    final pOld = p[k];
    final pPrev = p[prev];
    final pNext = p[next];

    // Calculate current signed area
    final currentSignedArea = _calculateSignedPolygonArea(p);
    final sign = currentSignedArea >= 0 ? 1.0 : -1.0;
    final targetSignedArea = targetAreaPixels * sign;

    // Line equation: ax + by = c
    // 2 * A_target = S + x_k(y_next - y_prev) + y_k(x_prev - x_next)
    // c = 2 * A_target - S
    // S = 2 * A_current - (x_old(y_next - y_prev) + y_old(x_prev - x_next))

    final a = pNext.y - pPrev.y;
    final b = pPrev.x - pNext.x;

    final termOld = pOld.x * a + pOld.y * b;
    final c = 2 * targetSignedArea - (2 * currentSignedArea - termOld);

    // Line constraint (Fixed Orientation)
    // The point must move along the line defined by the fixed side.
    // This allows the side to change length (slide) but keeps it collinear.

    double dx, dy, x0, y0;

    if (constraint == ResizeConstraint.previousSide) {
      // Line through pPrev and pOld
      dx = pOld.x - pPrev.x;
      dy = pOld.y - pPrev.y;
      x0 = pPrev.x;
      y0 = pPrev.y;
    } else {
      // Line through pNext and pOld
      dx = pOld.x - pNext.x;
      dy = pOld.y - pNext.y;
      x0 = pNext.x;
      y0 = pNext.y;
    }

    // Line 2 equation (Side Line): -dy*x + dx*y = -dy*x0 + dx*y0
    // Let a2 = -dy, b2 = dx, c2 = -dy*x0 + dx*y0
    final a2 = -dy;
    final b2 = dx;
    final c2 = a2 * x0 + b2 * y0;

    // Line 1 equation (Area Line): a*x + b*y = c
    // Solve system:
    // a*x + b*y = c
    // a2*x + b2*y = c2

    final det = a * b2 - a2 * b;

    if (det.abs() < 1e-9) {
      // Lines are parallel. No solution (cannot change area by moving along this line).
      return null;
    }

    final x = (b2 * c - b * c2) / det;
    final y = (a * c2 - a2 * c) / det;

    final best = Point(x, y);

    final newPoints = List<Point>.from(p);
    newPoints[k] = best;
    return newPoints;
  }

  double _calculateSignedPolygonArea(List<Point> points) {
    if (points.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }
    return area / 2.0;
  }

  bool _isSelectionContiguous() {
    if (_selectedResizeIndices.isEmpty) return false;
    if (_selectedResizeIndices.length == 1) return true;
    if (_selectedResizeIndices.length == _points.length) return true;

    final sorted = List<int>.from(_selectedResizeIndices)..sort();
    int breaks = 0;
    final n = _points.length;

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final next = sorted[(i + 1) % sorted.length];

      // Calculate distance in forward direction
      final dist = (next - current + n) % n;

      if (dist != 1) {
        breaks++;
      }
    }

    // A contiguous selection should have exactly one "break" (the gap of unselected points)
    // If breaks == 0, it means all points are selected (handled above)
    return breaks == 1;
  }

  List<Point>? _solveRigidResize(
    double targetPixelArea,
    ResizeConstraint constraint,
  ) {
    if (_selectedResizeIndices.isEmpty) return null;

    final n = _points.length;
    final sorted = List<int>.from(_selectedResizeIndices)..sort();

    // Find the "break" to identify start and end of the chain
    int startIndex = sorted.first;
    int endIndex = sorted.last;

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

    final prevIndex = (startIndex - 1 + n) % n;
    final nextIndex = (endIndex + 1 + n) % n;

    final pStart = _points[startIndex];
    final pEnd = _points[endIndex];
    final pPrev = _points[prevIndex];
    final pNext = _points[nextIndex];

    final yCoeff = (pEnd.y - pStart.y) + (pNext.y - pPrev.y);
    final xCoeff = (pStart.x - pEnd.x) + (pPrev.x - pNext.x);

    final currentSignedArea = _calculateSignedPolygonArea(_points);
    final sign = currentSignedArea >= 0 ? 1.0 : -1.0;
    final targetSignedArea = targetPixelArea * sign;
    final areaDiff = targetSignedArea - currentSignedArea;

    // Equation: yCoeff * dx + xCoeff * dy = 2 * areaDiff
    final C = 2 * areaDiff;
    final A = yCoeff;
    final B = xCoeff;

    final normSq = A * A + B * B;
    if (normSq < 1e-9) return null;

    double dx, dy;

    if (constraint == ResizeConstraint.bothSides) {
      // Constrain both P_start and P_end to move along their respective lines.
      // This is generally impossible with pure translation unless lines are parallel.
      // Instead, we switch to SCALING relative to the intersection of the two lines.
      // The intersection of Line(P_prev -> P_start) and Line(P_next -> P_end).
      // In the typical case (contiguous selection), P_prev and P_next are the SAME point (the unselected corner).
      // Or they are different points if selection wraps around strangely, but let's assume standard case.

      // Find intersection of Line 1 (P_prev -> P_start) and Line 2 (P_next -> P_end)
      // Line 1: P_prev + t * (P_start - P_prev)
      // Line 2: P_next + u * (P_end - P_next)

      // If P_prev == P_next (single unselected point), that is the center.
      double cx, cy;

      if ((pPrev.x - pNext.x).abs() < 1e-5 &&
          (pPrev.y - pNext.y).abs() < 1e-5) {
        cx = pPrev.x;
        cy = pPrev.y;
      } else {
        // Calculate intersection
        final x1 = pPrev.x, y1 = pPrev.y;
        final x2 = pStart.x, y2 = pStart.y;
        final x3 = pNext.x, y3 = pNext.y;
        final x4 = pEnd.x, y4 = pEnd.y;

        final d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
        if (d.abs() < 1e-9) {
          // Parallel lines, fallback to free translation
          dx = (A * C) / normSq;
          dy = (B * C) / normSq;
          final newPoints = List<Point>.from(_points);
          for (final idx in _selectedResizeIndices) {
            newPoints[idx] = Point(_points[idx].x + dx, _points[idx].y + dy);
          }
          return newPoints;
        }

        cx =
            ((x1 * y2 - y1 * x2) * (x3 - x4) -
                (x1 - x2) * (x3 * y4 - y3 * x4)) /
            d;
        cy =
            ((x1 * y2 - y1 * x2) * (y3 - y4) -
                (y1 - y2) * (x3 * y4 - y3 * x4)) /
            d;
      }

      // Use scaling solver centered at (cx, cy)
      return _findCorrectScaleForMixedPoints(cx, cy, targetPixelArea);
    } else if (constraint == ResizeConstraint.previousSide) {
      // Constrain P_start to move along the line defined by P_prev -> P_start
      // This allows the side (P_prev -> P_start) to change length but keeps orientation.
      // Vector v = P_start - P_prev
      // Constraint: (dx, dy) must be parallel to v
      // -v.y * dx + v.x * dy = 0

      final vx = pStart.x - pPrev.x;
      final vy = pStart.y - pPrev.y;

      // Equation 2: a2*dx + b2*dy = 0
      final a2 = -vy;
      final b2 = vx;
      final c2 = 0.0;

      // Solve system:
      // A*dx + B*dy = C
      // a2*dx + b2*dy = c2

      final det = A * b2 - a2 * B;
      if (det.abs() < 1e-9) return null;

      dx = (b2 * C - B * c2) / det;
      dy = (A * c2 - a2 * C) / det;
    } else if (constraint == ResizeConstraint.nextSide) {
      // Constrain P_end to move along the line defined by P_next -> P_end
      // This allows the side (P_next -> P_end) to change length but keeps orientation.
      // Vector v = P_end - P_next
      // Constraint: (dx, dy) must be parallel to v

      final vx = pEnd.x - pNext.x;
      final vy = pEnd.y - pNext.y;

      final a2 = -vy;
      final b2 = vx;
      final c2 = 0.0;

      final det = A * b2 - a2 * B;
      if (det.abs() < 1e-9) return null;

      dx = (b2 * C - B * c2) / det;
      dy = (A * c2 - a2 * C) / det;
    } else {
      // Free rigid translation (minimal norm)
      dx = (A * C) / normSq;
      dy = (B * C) / normSq;
    }

    // Apply translation to all selected points
    final newPoints = List<Point>.from(_points);
    for (final idx in _selectedResizeIndices) {
      newPoints[idx] = Point(_points[idx].x + dx, _points[idx].y + dy);
    }

    return newPoints;
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
}
