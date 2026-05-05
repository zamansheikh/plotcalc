part of '../drawing_page.dart';

mixin ResizeMixin on State<DrawingPage> {
  // State variables managed by this mixin
  bool _isResizeMode = false;
  bool _isAdjustMode = false;
  double? _resizeTargetArea;
  double? _currentAreaMeters;
  double? _adjustTargetArea; // target area in sq meters (optional)
  double? _adjustCurrentArea; // current area in sq meters
  double? _adjustTargetSqFt; // target stored in sq ft for compound unit display
  List<Point>? _originalAdjustPoints; // original shape before adjusting
  Map<int, double>?
  _originalAdjustSideMeasurements; // original side measurements
  final Set<int> _selectedResizeIndices = {};
  final Set<int> _lockedSideIndices = {};
  int? _compensationSideIndex;
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

  void _enterAdjustMode() {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 3 points to adjust.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate current real-world area
    final currentArea = _calculateRealAreaFromPoints();

    setState(() {
      _isAdjustMode = true;
      _isResizeMode = false;
      _previewPoints = null;
      _compensationSideIndex = null;
      _adjustCurrentArea = currentArea;
      // Save original shape for overlay comparison
      _originalAdjustPoints = List<Point>.from(_points);
      _originalAdjustSideMeasurements = Map<int, double>.from(
        _sideMeasurements,
      );
    });
  }

  void _exitAdjustMode() {
    setState(() {
      _isAdjustMode = false;
      _adjustTargetArea = null;
      _adjustTargetSqFt = null;
      _originalAdjustPoints = null;
      _originalAdjustSideMeasurements = null;
    });
  }

  void _cancelAdjustMode() {
    if (_originalAdjustPoints != null) {
      setState(() {
        // Restore original points and side measurements
        _points.clear();
        _points.addAll(_originalAdjustPoints!);
        _sideMeasurements.clear();
        if (_originalAdjustSideMeasurements != null) {
          _sideMeasurements.addAll(_originalAdjustSideMeasurements!);
        }
        _diagonalMeasurements.clear();
        _isAdjustMode = false;
        _adjustTargetArea = null;
        _adjustTargetSqFt = null;
        _originalAdjustPoints = null;
        _originalAdjustSideMeasurements = null;
      });
    } else {
      _exitAdjustMode();
    }
  }

  double? _getPixelsPerMeter() {
    if (_sideMeasurements.isEmpty) return null;
    final n = _points.length;
    for (final entry in _sideMeasurements.entries) {
      final si = entry.key;
      final meters = entry.value;
      if (meters > 0 && si < n) {
        final sp1 = _points[si];
        final sp2 = _points[(si + 1) % n];
        final distPx = math.sqrt(
          math.pow(sp1.x - sp2.x, 2) + math.pow(sp1.y - sp2.y, 2),
        );
        return distPx / meters;
      }
    }
    return null;
  }

  double? _calculateRealAreaFromPoints() {
    if (_points.length < 3) return null;
    final ppm = _getPixelsPerMeter();
    if (ppm == null || ppm <= 0) return null;
    final pixelArea = _calculatePolygonArea(_points);
    return pixelArea / (ppm * ppm); // convert pixel² to meter²
  }

  void _handleAdjustTap(Offset localPosition) {
    // Tap a POINT to move it
    const double touchRadius = 30.0;
    int? tappedIndex;

    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final distance = (Offset(point.x, point.y) - localPosition).distance;
      if (distance <= touchRadius) {
        tappedIndex = i;
        break;
      }
    }

    if (tappedIndex != null) {
      _showMovePointDialog(tappedIndex);
    }
  }

  void _showMovePointDialog(int pointIndex) {
    final loc = AppLocalizations.of(context);
    final measurementUnitState = context.read<MeasurementUnitBloc>().state;
    final inputUnit = measurementUnitState.unit;

    int selectedDirection = -1; // -1 = none selected
    final distController = TextEditingController();

    // Direction vectors (screen coords: Y increases downward)
    // Index: 0=Up, 1=UpRight, 2=Right, 3=DownRight, 4=Down, 5=DownLeft, 6=Left, 7=UpLeft
    final directionVectors = [
      const Offset(0, -1), // Up
      Offset(1 / math.sqrt(2), -1 / math.sqrt(2)), // Up-Right
      const Offset(1, 0), // Right
      Offset(1 / math.sqrt(2), 1 / math.sqrt(2)), // Down-Right
      const Offset(0, 1), // Down
      Offset(-1 / math.sqrt(2), 1 / math.sqrt(2)), // Down-Left
      const Offset(-1, 0), // Left
      Offset(-1 / math.sqrt(2), -1 / math.sqrt(2)), // Up-Left
    ];

    final directionLabels = [
      loc.up,
      loc.upRight,
      loc.right,
      loc.downRight,
      loc.down,
      loc.downLeft,
      loc.left,
      loc.upLeft,
    ];

    final directionIcons = [
      Icons.arrow_upward,
      Icons.north_east,
      Icons.arrow_forward,
      Icons.south_east,
      Icons.arrow_downward,
      Icons.south_west,
      Icons.arrow_back,
      Icons.north_west,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // Calculate preview area if direction and distance are set
          String? previewAreaText;
          if (selectedDirection >= 0 && distController.text.isNotEmpty) {
            final dist = double.tryParse(distController.text);
            if (dist != null && dist > 0) {
              final ppm = _getPixelsPerMeter();
              if (ppm != null) {
                final distInMeters = inputUnit.toMeters(dist);
                final pixelDist = distInMeters * ppm;
                final dir = directionVectors[selectedDirection];
                final dx = dir.dx * pixelDist;
                final dy = dir.dy * pixelDist;
                final testPoints = List<Point>.from(_points);
                testPoints[pointIndex] = Point(
                  _points[pointIndex].x + dx,
                  _points[pointIndex].y + dy,
                );
                final newPixelArea = _calculatePolygonArea(testPoints);
                final newRealArea = newPixelArea / (ppm * ppm);

                // Format area for display in Shatak
                final previewSqFt = newRealArea * AppConstants.sqMeterToSqFeet;
                final previewShatak = previewSqFt / _shatakSqFt;
                previewAreaText = '${previewShatak.toStringAsFixed(2)} Shatak';
              }
            }
          }

          final bool canAutoAdjust =
              selectedDirection >= 0 && _adjustTargetArea != null;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.open_with_rounded,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${loc.movePoint} ${pointIndex + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Direction label
                    Text(
                      loc.direction,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Compass grid (3x3)
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dirBtn(
                                7,
                                directionIcons[7],
                                directionLabels[7],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                              _dirBtn(
                                0,
                                directionIcons[0],
                                directionLabels[0],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                              _dirBtn(
                                1,
                                directionIcons[1],
                                directionLabels[1],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dirBtn(
                                6,
                                directionIcons[6],
                                directionLabels[6],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2E7D32,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'P${pointIndex + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              _dirBtn(
                                2,
                                directionIcons[2],
                                directionLabels[2],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dirBtn(
                                5,
                                directionIcons[5],
                                directionLabels[5],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                              _dirBtn(
                                4,
                                directionIcons[4],
                                directionLabels[4],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                              _dirBtn(
                                3,
                                directionIcons[3],
                                directionLabels[3],
                                selectedDirection,
                                setStateDialog,
                                (d) => selectedDirection = d,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Divider(color: Colors.grey[200], height: 1),
                    const SizedBox(height: 16),

                    // Manual distance input
                    Text(
                      loc.distance,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: distController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: false,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        suffixText: inputUnit.symbol,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    // Preview area
                    if (previewAreaText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.preview,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'New area: $previewAreaText',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Apply manual move button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            selectedDirection >= 0 &&
                                distController.text.isNotEmpty &&
                                (double.tryParse(distController.text) ?? 0) > 0
                            ? () {
                                final dist = double.tryParse(
                                  distController.text,
                                )!;
                                final distMeters = inputUnit.toMeters(dist);
                                Navigator.pop(context);
                                _applyPointMove(
                                  pointIndex,
                                  directionVectors[selectedDirection],
                                  distMeters,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.moving, size: 18),
                        label: Text(loc.apply),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Auto-adjust section
                    if (canAutoAdjust) ...[
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey[200], height: 1),
                      const SizedBox(height: 12),

                      // Auto-adjust info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_fix_high,
                                  size: 16,
                                  color: Colors.orange[800],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.autoComplete,
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Auto-move this point to reach target area exactly',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _autoCompletePoint(
                                    pointIndex,
                                    directionVectors[selectedDirection],
                                  );
                                },
                                icon: const Icon(Icons.auto_fix_high, size: 18),
                                label: Text(loc.autoComplete),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dirBtn(
    int index,
    IconData icon,
    String label,
    int selectedDirection,
    StateSetter setStateDialog,
    void Function(int) onSelect,
  ) {
    final isSelected = selectedDirection == index;
    return GestureDetector(
      onTap: () => setStateDialog(() => onSelect(index)),
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPointMove(int pointIndex, Offset direction, double distMeters) {
    final ppm = _getPixelsPerMeter();
    if (ppm == null || ppm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot determine scale. Please measure sides first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pixelDist = distMeters * ppm;
    final dx = direction.dx * pixelDist;
    final dy = direction.dy * pixelDist;
    final n = _points.length;

    setState(() {
      // Move the single point
      _points[pointIndex] = Point(
        _points[pointIndex].x + dx,
        _points[pointIndex].y + dy,
      );

      // Recalculate all side measurements from new point positions
      for (int i = 0; i < n; i++) {
        final sp1 = _points[i];
        final sp2 = _points[(i + 1) % n];
        final dist = math.sqrt(
          math.pow(sp2.x - sp1.x, 2) + math.pow(sp2.y - sp1.y, 2),
        );
        _sideMeasurements[i] = dist / ppm;
      }

      // Clear diagonals
      _diagonalMeasurements.clear();

      // Update current area
      _adjustCurrentArea = _calculateRealAreaFromPoints();

      // Convert rectangle to polygon if shape was distorted
      if (_selectedShape == ShapeType.rectangle) {
        _selectedShape = ShapeType.polygon;
        _isShapeComplete = true;
      }
    });

    final loc = AppLocalizations.of(context);

    // Check if target reached (within 1% tolerance)
    if (_adjustTargetArea != null && _adjustCurrentArea != null) {
      final ratio = _adjustCurrentArea! / _adjustTargetArea!;
      if (ratio >= 0.99 && ratio <= 1.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.targetReached),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.pointMoved),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  static const double _shatakSqFt = 435.6;

  void _showSetTargetAreaDialog() {
    final loc = AppLocalizations.of(context);
    final shatakController = TextEditingController();
    bool useBreakdown = false;

    // Pre-fill with existing target or current area in Shatak
    if (_adjustTargetSqFt != null && _adjustTargetSqFt! > 0) {
      shatakController.text = (_adjustTargetSqFt! / _shatakSqFt)
          .toStringAsFixed(2);
    } else if (_adjustCurrentArea != null) {
      final currentSqFt = _adjustCurrentArea! * AppConstants.sqMeterToSqFeet;
      shatakController.text = (currentSqFt / _shatakSqFt).toStringAsFixed(2);
    }

    // Current area in Shatak
    final currentShatak = _adjustCurrentArea != null
        ? (_adjustCurrentArea! * AppConstants.sqMeterToSqFeet) / _shatakSqFt
        : 0.0;

    // Breakdown controllers - standard units
    final bighaCtrl = TextEditingController();
    final kathaCtrl = TextEditingController();
    final shatakPartCtrl = TextEditingController();
    final chotakCtrl = TextEditingController();

    double calcBreakdownSqFt() {
      final bigha = double.tryParse(bighaCtrl.text) ?? 0;
      final katha = double.tryParse(kathaCtrl.text) ?? 0;
      final shatak = double.tryParse(shatakPartCtrl.text) ?? 0;
      final chotak = double.tryParse(chotakCtrl.text) ?? 0;
      return bigha * 14520.0 + katha * 721.46 + shatak * 435.6 + chotak * 45.09;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final breakdownTotalSqFt = calcBreakdownSqFt();
          final breakdownShatak = breakdownTotalSqFt / _shatakSqFt;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.setTargetArea)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current area display
                  if (_adjustCurrentArea != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${loc.currentArea}: ${currentShatak.toStringAsFixed(2)} Shatak',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Toggle: Shatak / Breakdown
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setStateDialog(() => useBreakdown = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !useBreakdown
                                    ? Colors.orange[700]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Shatak',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: !useBreakdown
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setStateDialog(() => useBreakdown = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: useBreakdown
                                    ? Colors.orange[700]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                loc.breakdownInput,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: useBreakdown
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!useBreakdown) ...[
                    // Shatak input with info button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: shatakController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: loc.enterShatakValue,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixText: 'Shatak',
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final val = double.tryParse(shatakController.text);
                            if (val != null && val > 0) {
                              final sqFt = val * _shatakSqFt;
                              final units = <LandUnitDef>[
                                LandUnitDef(
                                  id: 'bigha',
                                  name: 'Bigha',
                                  sqftFactor: 14520.0,
                                ),
                                LandUnitDef(
                                  id: 'katha',
                                  name: 'Katha',
                                  sqftFactor: 721.46,
                                ),
                                LandUnitDef(
                                  id: 'shatak',
                                  name: 'Shatak',
                                  sqftFactor: 435.6,
                                ),
                                LandUnitDef(
                                  id: 'chotak',
                                  name: 'Chotak',
                                  sqftFactor: 45.09,
                                ),
                              ];
                              final result = LandAreaCalculator.calculate(
                                sqFt,
                                units,
                              );
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(loc.areaDetails),
                                  content: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: result.breakdown.map((part) {
                                      return Chip(
                                        label: Text(
                                          part,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue.shade50,
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(loc.ok),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                          ),
                          tooltip: loc.areaDetails,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Breakdown inputs
                    _buildBreakdownField('Bigha', bighaCtrl, setStateDialog),
                    const SizedBox(height: 8),
                    _buildBreakdownField('Katha', kathaCtrl, setStateDialog),
                    const SizedBox(height: 8),
                    _buildBreakdownField(
                      'Shatak',
                      shatakPartCtrl,
                      setStateDialog,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownField('Chotak', chotakCtrl, setStateDialog),
                    const SizedBox(height: 12),
                    // Total in Shatak
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.functions,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '= ${breakdownShatak.toStringAsFixed(2)} Shatak',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _adjustTargetArea = null;
                    _adjustTargetSqFt = null;
                  });
                  Navigator.pop(context);
                },
                child: Text(loc.clear),
              ),
              ElevatedButton(
                onPressed: () {
                  double? totalSqFt;
                  if (useBreakdown) {
                    final sqFt = calcBreakdownSqFt();
                    if (sqFt > 0) totalSqFt = sqFt;
                  } else {
                    final val = double.tryParse(shatakController.text);
                    if (val != null && val > 0) {
                      totalSqFt = val * _shatakSqFt;
                    }
                  }
                  if (totalSqFt != null) {
                    final sqMeters = totalSqFt / AppConstants.sqMeterToSqFeet;
                    setState(() {
                      _adjustTargetArea = sqMeters;
                      _adjustTargetSqFt = totalSqFt;
                    });
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(loc.ok),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBreakdownField(
    String label,
    TextEditingController ctrl,
    StateSetter setStateDialog,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setStateDialog(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixText: label,
        filled: true,
        fillColor: Colors.grey[50],
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  void _autoCompletePoint(int pointIndex, Offset direction) {
    final ppm = _getPixelsPerMeter();
    if (ppm == null || ppm <= 0) return;
    if (_adjustTargetArea == null) return;

    final n = _points.length;
    if (n < 3) return;

    final targetPixelArea = _adjustTargetArea! * ppm * ppm;

    // The shoelace formula gives signed area that changes LINEARLY with t
    // when we move point[k] by (dx*t, dy*t).
    //
    // signedArea(t) = signedArea(0) + t * C
    // where C = (dy*(x_{k-1} - x_{k+1}) + dx*(y_{k+1} - y_{k-1})) / 2
    //
    // We want |signedArea(t)| = targetPixelArea, solve for t exactly.

    // Compute current signed area (without abs)
    double signedArea = 0;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      signedArea += _points[i].x * _points[j].y;
      signedArea -= _points[j].x * _points[i].y;
    }
    signedArea /= 2;

    // Linear coefficient of t
    final prevIdx = (pointIndex - 1 + n) % n;
    final nextIdx = (pointIndex + 1) % n;
    final dCoeff =
        (direction.dy * (_points[prevIdx].x - _points[nextIdx].x) +
            direction.dx * (_points[nextIdx].y - _points[prevIdx].y)) /
        2;

    if (dCoeff.abs() < 1e-10) {
      // Direction is parallel to adjacent edges — can't change area
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot adjust in this direction. Try a different direction.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Solve: signedArea + t * dCoeff = ±targetPixelArea
    // Use the same sign as current signed area to preserve winding order
    final targetSigned = signedArea >= 0 ? targetPixelArea : -targetPixelArea;
    final t = (targetSigned - signedArea) / dCoeff;

    // Apply the move
    final p = _points[pointIndex];
    final moveX = direction.dx * t;
    final moveY = direction.dy * t;

    setState(() {
      _points[pointIndex] = Point(p.x + moveX, p.y + moveY);

      for (int i = 0; i < n; i++) {
        final sp1 = _points[i];
        final sp2 = _points[(i + 1) % n];
        final dist = math.sqrt(
          math.pow(sp2.x - sp1.x, 2) + math.pow(sp2.y - sp1.y, 2),
        );
        _sideMeasurements[i] = dist / ppm;
      }

      _diagonalMeasurements.clear();
      _adjustCurrentArea = _calculateRealAreaFromPoints();

      if (_selectedShape == ShapeType.rectangle) {
        _selectedShape = ShapeType.polygon;
        _isShapeComplete = true;
      }
    });

    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.targetReached),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleAdjustMode() {
    if (_isAdjustMode) {
      _exitAdjustMode();
    } else {
      _enterAdjustMode();
    }
  }
}
