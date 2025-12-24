import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/land_measurement_converter.dart';
import '../widgets/measurement_result_bottom_sheet.dart';
import '../../../settings/presentation/bloc/measurement_unit_bloc.dart';
import '../../domain/entities/measurement.dart';
import '../bloc/measurement_bloc.dart';

class DrawingPage extends StatefulWidget {
  final Measurement? measurement; // Optional measurement to restore
  final double? resizeTargetArea;
  final MeasurementUnit? resizeTargetUnit;

  const DrawingPage({
    super.key,
    this.measurement,
    this.resizeTargetArea,
    this.resizeTargetUnit,
  });

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<Point> _points = [];
  final Map<int, double> _sideMeasurements =
      {}; // Index -> measurement in meters
  final Map<String, double> _diagonalMeasurements =
      {}; // "0-2" -> measurement (from point 0 to point 2)
  ShapeType _selectedShape = ShapeType.polygon;
  bool _isShapeComplete = false; // Track if shape is closed/complete
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  // Rectangle Average Method State
  int _widthSegmentCount = 1;
  int _heightSegmentCount = 1;
  final List<TextEditingController> _widthControllers = [];
  final List<TextEditingController> _heightControllers = [];

  // Zoom/Pan control
  final TransformationController _transformationController =
      TransformationController();
  Size _viewportSize = Size.zero;

  // Resize Mode State
  bool _isResizeMode = false;
  double? _resizeTargetArea;
  double? _currentAreaMeters; // Store current area in meters for scaling
  final Set<int> _selectedResizeIndices = {};
  List<Point>? _previewPoints;

  @override
  void initState() {
    super.initState();
    // Load measurement data if provided
    if (widget.measurement != null) {
      _loadMeasurement(widget.measurement!);

      // Apply resize if requested
      if (widget.resizeTargetArea != null && widget.resizeTargetUnit != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyResize(
            widget.resizeTargetArea!,
            widget.resizeTargetUnit!,
            widget.measurement!.area,
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _zoomToFit();
        });
      }
    }
  }

  void _loadMeasurement(Measurement measurement) {
    setState(() {
      _selectedShape = measurement.shapeType;
      _points.clear();
      _points.addAll(measurement.points);
      _isShapeComplete = measurement.points.length >= 3;

      // Load dimensions for rectangles and circles
      if (measurement.dimensions != null) {
        if (measurement.dimensions!.containsKey('width')) {
          _widthController.text = measurement.dimensions!['width'].toString();
        }
        if (measurement.dimensions!.containsKey('height')) {
          _heightController.text = measurement.dimensions!['height'].toString();
        }
        if (measurement.dimensions!.containsKey('radius')) {
          _radiusController.text = measurement.dimensions!['radius'].toString();
        }

        // Load average method data if available
        if (measurement.dimensions!.containsKey('width_count')) {
          _widthSegmentCount = measurement.dimensions!['width_count']!.toInt();
          _widthControllers.clear();
          for (int i = 0; i < _widthSegmentCount; i++) {
            final val = measurement.dimensions!['width_$i'] ?? 0.0;
            _widthControllers.add(TextEditingController(text: val.toString()));
          }
        }
        if (measurement.dimensions!.containsKey('height_count')) {
          _heightSegmentCount = measurement.dimensions!['height_count']!
              .toInt();
          _heightControllers.clear();
          for (int i = 0; i < _heightSegmentCount; i++) {
            final val = measurement.dimensions!['height_$i'] ?? 0.0;
            _heightControllers.add(TextEditingController(text: val.toString()));
          }
        }
      }

      // Load side measurements for polygons
      if (measurement.sideMeasurements != null) {
        _sideMeasurements.clear();
        _sideMeasurements.addAll(measurement.sideMeasurements!);
      }

      // Load diagonal measurements for polygons
      if (measurement.diagonalMeasurements != null) {
        _diagonalMeasurements.clear();
        _diagonalMeasurements.addAll(measurement.diagonalMeasurements!);
      }
    });
  }

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
    }
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
      // Get current input unit for converting back
      final inputUnit = context.read<MeasurementUnitBloc>().state.unit;

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
              _sideMeasurements[i] = inputUnit.fromMeters(distMeters);
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
                _diagonalMeasurements['0-$i'] = inputUnit.fromMeters(
                  distMeters,
                );
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

  void _zoomToFit() {
    if (_points.isEmpty || _viewportSize == Size.zero) return;

    // 1. Calculate bounding box of points
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var p in _points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }

    // Add some padding
    double padding = 50.0;

    if (_selectedShape == ShapeType.circle) {
      // For circle, we need to account for the fixed visual radius
      // defined in ShapePainter (80.0) plus the label
      const double circleVisualRadius = 80.0;
      minX -= circleVisualRadius;
      maxX += circleVisualRadius;
      minY -= circleVisualRadius;
      maxY += circleVisualRadius;

      // Add extra padding for the label which extends to the right
      maxX += 50.0;
    }

    final width = maxX - minX + padding * 2;
    final height = maxY - minY + padding * 2;
    final centerX = minX + (maxX - minX) / 2;
    final centerY = minY + (maxY - minY) / 2;

    // 2. Calculate scale to fit
    final scaleX = _viewportSize.width / width;
    final scaleY = _viewportSize.height / height;
    final scale = math.min(scaleX, scaleY).clamp(0.1, 5.0);

    // 3. Calculate translation to center
    final tx = (_viewportSize.width / 2) - scale * centerX;
    final ty = (_viewportSize.height / 2) - scale * centerY;

    final matrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);

    _transformationController.value = matrix;
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _radiusController.dispose();
    for (var c in _widthControllers) {
      c.dispose();
    }
    for (var c in _heightControllers) {
      c.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _addPoint(Offset position) async {
    // Don't add points if shape is already complete
    if (_isShapeComplete) return;

    setState(() {
      _points.add(Point(position.dx, position.dy));
    });

    // If we have at least 2 points, ask for measurement of the new side
    if (_points.length >= 2 &&
        (_selectedShape == ShapeType.polygon ||
            _selectedShape == ShapeType.triangle)) {
      // Ask for the side that was just created (from previous point to this point)
      await _askForSideMeasurement(_points.length - 2);

      // For triangle, complete the shape after 3rd point
      if (_selectedShape == ShapeType.triangle && _points.length == 3) {
        await _askForSideMeasurement(_points.length - 1); // The closing side
        setState(() {
          _isShapeComplete = true;
        });
      }
    }
  }

  void _completePolygon() async {
    final loc = AppLocalizations.of(context);
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.addThreePoints),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ask for the closing side measurement
    await _askForSideMeasurement(_points.length - 1);

    setState(() {
      _isShapeComplete = true;
    });
  }

  Future<void> _askForSideMeasurement(int sideIndex) async {
    debugPrint(
      'DEBUG: _askForSideMeasurement called with sideIndex: $sideIndex',
    );
    final loc = AppLocalizations.of(context);
    final measurementUnitState = context.read<MeasurementUnitBloc>().state;
    final unitSymbol = measurementUnitState.unit.symbol;
    final inputUnit = measurementUnitState.unit;

    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${loc.enterMeasurement} ${sideIndex + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Side length in $unitSymbol',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '${loc.enterMeasurement} ($unitSymbol)',
                border: const OutlineInputBorder(),
                suffixText: unitSymbol,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(loc.skip),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: Text(loc.ok),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      // Convert to meters before storing
      final valueInMeters = inputUnit.toMeters(result);
      setState(() {
        _sideMeasurements[sideIndex] = valueInMeters;
        debugPrint(
          'DEBUG: Stored measurement - sideMeasurements: $_sideMeasurements',
        );
      });
    }
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        // Remove the measurement for the last side
        if (_points.length >= 2) {
          _sideMeasurements.remove(_points.length - 2);
        }
        _points.removeLast();
        _isShapeComplete = false; // Allow adding points again
      });
    }
  }

  void _clearAll() {
    setState(() {
      _points.clear();
      _sideMeasurements.clear();
      _diagonalMeasurements.clear();
      _isShapeComplete = false;
      _widthController.clear();
      _heightController.clear();
      _radiusController.clear();
    });
  }

  void _calculateArea() {
    final loc = AppLocalizations.of(context);
    final measurementUnitState = context.read<MeasurementUnitBloc>().state;
    final inputUnit = measurementUnitState.unit;

    Map<String, double>? dimensions;

    // For specific shapes, we need dimensions
    if (_selectedShape == ShapeType.rectangle) {
      // Calculate average width
      double totalWidth = 0;
      int validWidths = 0;
      final widthValues = <String, double>{};

      for (int i = 0; i < _widthControllers.length; i++) {
        final val = double.tryParse(_widthControllers[i].text);
        if (val != null) {
          totalWidth += val;
          validWidths++;
          widthValues['width_$i'] = val;
        }
      }

      // Calculate average height
      double totalHeight = 0;
      int validHeights = 0;
      final heightValues = <String, double>{};

      for (int i = 0; i < _heightControllers.length; i++) {
        final val = double.tryParse(_heightControllers[i].text);
        if (val != null) {
          totalHeight += val;
          validHeights++;
          heightValues['height_$i'] = val;
        }
      }

      if (validWidths == 0 || validHeights == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.enterValidWidthHeight),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final avgWidth = totalWidth / validWidths;
      final avgHeight = totalHeight / validHeights;

      // Convert to meters before calculation
      final widthInMeters = inputUnit.toMeters(avgWidth);
      final heightInMeters = inputUnit.toMeters(avgHeight);

      dimensions = {
        'width': widthInMeters,
        'height': heightInMeters,
        'width_count': _widthSegmentCount.toDouble(),
        'height_count': _heightSegmentCount.toDouble(),
        ...widthValues,
        ...heightValues,
      };

      // Populate side measurements for visualization
      _sideMeasurements.clear();
      _sideMeasurements[0] = widthInMeters;
      _sideMeasurements[1] = heightInMeters;
      _sideMeasurements[2] = widthInMeters;
      _sideMeasurements[3] = heightInMeters;

      // Create 4 points for rectangle visualization
      if (_points.isEmpty) {
        setState(() {
          _points.addAll([
            const Point(50, 50),
            Point(50 + avgWidth * 10, 50),
            Point(50 + avgWidth * 10, 50 + avgHeight * 10),
            Point(50, 50 + avgHeight * 10),
          ]);
        });
      }
    } else if (_selectedShape == ShapeType.circle) {
      final radius = double.tryParse(_radiusController.text);

      if (radius == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.enterValidRadius),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Convert to meters before calculation
      final radiusInMeters = inputUnit.toMeters(radius);

      dimensions = {'radius': radiusInMeters};
      // Create center point if empty
      if (_points.isEmpty) {
        setState(() {
          _points.add(const Point(200, 200));
        });
      }
    } else {
      // For polygon and triangle, check points
      if (_points.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.addThreePoints),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // IMPORTANT: For accuracy, require ALL side measurements
      if (_sideMeasurements.length != _points.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please measure ALL ${_points.length} sides for accurate calculation. You have measured ${_sideMeasurements.length}.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // NEW: For polygons with 4+ sides, require diagonals for exact calculation
      if (_points.length >= 4) {
        // Formula: For N-sided polygon, need (N-3) diagonals to triangulate
        // 4-sided: 1 diagonal, 5-sided: 2 diagonals, 6-sided: 3 diagonals, etc.
        int requiredDiagonals = _points.length - 3;

        if (_diagonalMeasurements.length < requiredDiagonals) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'For a ${_points.length}-sided polygon, you need $requiredDiagonals diagonal(s) for exact calculation. You have measured ${_diagonalMeasurements.length}.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          // Open diagonal measurement dialog
          _showDiagonalInput();
          return;
        }
      }
    }

    // Calculate area
    // Convert side measurements and diagonal measurements to meters
    final sideMeasurementsInMeters = _sideMeasurements.map(
      (key, value) => MapEntry(key, inputUnit.toMeters(value)),
    );
    final diagonalMeasurementsInMeters = _diagonalMeasurements.map(
      (key, value) => MapEntry(key, inputUnit.toMeters(value)),
    );

    // Auto-fix shape geometry for Polygons and Triangles
    if (_selectedShape == ShapeType.polygon ||
        _selectedShape == ShapeType.triangle) {
      _fixShapeGeometry(sideMeasurementsInMeters, diagonalMeasurementsInMeters);
    }

    debugPrint(
      'DEBUG: _calculateArea - sideMeasurements being sent: $sideMeasurementsInMeters',
    );
    debugPrint(
      'DEBUG: _calculateArea - diagonalMeasurements being sent: $diagonalMeasurementsInMeters',
    );
    context.read<MeasurementBloc>().add(
      CalculateAreaEvent(
        points: _points,
        dimensions: dimensions,
        sideMeasurements: sideMeasurementsInMeters,
        diagonalMeasurements: diagonalMeasurementsInMeters,
      ),
    );
  }

  void _fixShapeGeometry(
    Map<int, double> sides,
    Map<String, double> diagonals,
  ) {
    if (_points.length < 3) return;

    // We need all sides to be measured
    if (sides.length != _points.length) return;

    // For N > 3, we need N-3 diagonals.
    // We assume diagonals are from point 0 to i (i=2..N-2)
    // If the user hasn't provided enough diagonals, we can't fix the shape fully.
    // But we can try to fix what we can.
    // For a triangle (N=3), we don't need diagonals.

    try {
      // 1. Establish coordinate system based on P0 and P1
      // P0 is at (0,0) in our local metric space
      // P1 is at (Side0, 0)
      final List<Offset> vPoints = [];
      vPoints.add(const Offset(0, 0)); // V0

      final double side0 = sides[0]!;
      vPoints.add(Offset(side0, 0)); // V1

      // 2. Calculate subsequent points V2, V3...
      for (int i = 2; i < _points.length; i++) {
        // To find Vi, we need distance from Vi-1 (which is Side(i-1))
        // and distance from V0 (which is Diagonal(0-i) OR Side(N-1) if i is last point)

        final double rPrev = sides[i - 1]!; // Distance from V(i-1)
        double rZero;

        if (i == _points.length - 1) {
          // Last point connects back to V0 via the last side
          rZero = sides[_points.length - 1]!;
        } else {
          // Intermediate point needs a diagonal from V0
          final diagKey = '0-$i';
          if (!diagonals.containsKey(diagKey)) {
            // Cannot triangulate further without this diagonal
            return;
          }
          rZero = diagonals[diagKey]!;
        }

        // Find intersection of Circle(V(i-1), rPrev) and Circle(V0, rZero)
        final intersection = _findIntersection(
          vPoints[i - 1],
          rPrev,
          const Offset(0, 0),
          rZero,
          i,
        );

        if (intersection == null) {
          // Impossible geometry
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible geometry! Check your measurements.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        vPoints.add(intersection);
      }

      // 3. Transform V points back to screen space
      // We want to map V0 -> P0 and V1 -> P1 (preserving P0->P1 direction)
      // Scale S = dist(P0, P1) / dist(V0, V1)
      // But dist(V0, V1) is side0.
      // So S = dist(P0, P1) / side0.
      // Actually, we want to KEEP the screen scale roughly what it is.
      // So we use the drawn length of the first side to determine scale.

      final p0 = Offset(_points[0].x, _points[0].y);
      final p1 = Offset(_points[1].x, _points[1].y);
      final currentDist = (p1 - p0).distance;
      final scale = currentDist / side0;

      final rotation = math.atan2(p1.dy - p0.dy, p1.dx - p0.dx);

      setState(() {
        for (int i = 0; i < _points.length; i++) {
          final v = vPoints[i];
          // Rotate
          final xRot = v.dx * math.cos(rotation) - v.dy * math.sin(rotation);
          final yRot = v.dx * math.sin(rotation) + v.dy * math.cos(rotation);
          // Scale and Translate
          final xFinal = p0.dx + xRot * scale;
          final yFinal = p0.dy + yRot * scale;

          // Update point
          // We create a new list to trigger state change if needed, but here we modify _points
          // Since we are inside setState, it's fine.
          _points[i] = Point(xFinal, yFinal);
        }
      });
    } catch (e) {
      debugPrint('Error fixing shape: $e');
    }
  }

  Offset? _findIntersection(
    Offset center1,
    double r1,
    Offset center2,
    double r2,
    int pointIndex,
  ) {
    // Find intersection of two circles
    // d = distance between centers
    final d = (center1 - center2).distance;

    // Check for solvability
    // Using a small epsilon for float comparison
    if (d > r1 + r2 + 0.001 || d < (r1 - r2).abs() - 0.001 || d == 0) {
      return null;
    }

    // a = distance from center1 to the line joining intersection points
    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);

    // h = distance from the line joining centers to the intersection points
    final h = math.sqrt(math.max(0, r1 * r1 - a * a));

    // P2 = point on the line joining centers
    final x2 = center1.dx + a * (center2.dx - center1.dx) / d;
    final y2 = center1.dy + a * (center2.dy - center1.dy) / d;

    // Two intersection points
    final sol1 = Offset(
      x2 + h * (center2.dy - center1.dy) / d,
      y2 - h * (center2.dx - center1.dx) / d,
    );
    final sol2 = Offset(
      x2 - h * (center2.dy - center1.dy) / d,
      y2 + h * (center2.dx - center1.dx) / d,
    );

    // To pick the correct solution, we compare with the original drawing.
    // We transform both solutions to screen space (using current P0, P1 alignment)
    // and see which one is closer to the user's drawn point P[pointIndex].

    // Note: In _fixShapeGeometry we calculated scale based on measured side0.
    // Here we just need a relative comparison, so using current screen P0-P1 is fine
    // assuming V0=(0,0) and V1=(side0,0) maps to P0, P1.
    // Wait, we need the scale relative to the V coordinates we are using.
    // V1.dx is the measured length.
    // So scale = (P1-P0).distance / V1.dx.
    // But we don't have V1.dx passed here easily.
    // Let's just use the calculated scale from _fixShapeGeometry logic:
    // We can pass P0, P1, and V1.dx to this function, or just do the check in _fixShapeGeometry.
    // But _fixShapeGeometry calls this.
    // Let's return both and let caller decide? No, simpler to decide here if we have context.

    // Let's approximate:
    // The "winding" or "side" of the line P0-P(i-1) should be preserved.
    // Or simply, closest to original point.

    // We need to reconstruct the transform to check.
    // Let's assume the caller handles the selection?
    // No, let's do a simple heuristic:
    // Check cross product (signed area) of (Vi-1 - V0) x (Vi - V0).
    // Compare with (Pi-1 - P0) x (Pi - P0).
    // They should have the same sign.

    final v0 = center2; // center2 is V0 (0,0) passed from caller
    final vPrev = center1; // center1 is V(i-1)

    // Original points
    final pOriginal = Offset(_points[pointIndex].x, _points[pointIndex].y);
    final pPrev = Offset(_points[pointIndex - 1].x, _points[pointIndex - 1].y);
    final pZero = Offset(_points[0].x, _points[0].y);

    // Cross product of solution 2
    // final cp2 = (vPrev.dx - v0.dx) * (sol2.dy - v0.dy) - (vPrev.dy - v0.dy) * (sol2.dx - v0.dx);

    // If signs match, pick sol1, else sol2
    // Note: Screen Y is down, Math Y is up usually, but cross product sign consistency holds.
    // However, if the points are collinear, CP is 0.
    // Also, if the user drew it "inside out" or "twisted", this might be tricky.
    // But "closest to original" is usually the best UX for "snapping".

    // Let's try "closest to original" approach by roughly transforming sol1/sol2.
    // We need scale and rotation.
    // Scale ~ (pPrev - pZero).distance / (vPrev - v0).distance
    // Rotation ~ angle(pPrev - pZero) - angle(vPrev - v0)
    // This is local transformation based on the previous segment.

    final distV = (vPrev - v0).distance;
    if (distV < 0.001) return sol1; // Should not happen

    final distP = (pPrev - pZero).distance;
    final scale = distP / distV;
    final angleP = math.atan2(pPrev.dy - pZero.dy, pPrev.dx - pZero.dx);
    final angleV = math.atan2(vPrev.dy - v0.dy, vPrev.dx - v0.dx);
    final rotation = angleP - angleV;

    Offset transform(Offset v) {
      final dx = v.dx - v0.dx;
      final dy = v.dy - v0.dy;
      final xRot = dx * math.cos(rotation) - dy * math.sin(rotation);
      final yRot = dx * math.sin(rotation) + dy * math.cos(rotation);
      return Offset(pZero.dx + xRot * scale, pZero.dy + yRot * scale);
    }

    final tSol1 = transform(sol1);
    final tSol2 = transform(sol2);

    if ((tSol1 - pOriginal).distance < (tSol2 - pOriginal).distance) {
      return sol1;
    } else {
      return sol2;
    }
  }

  void _showShapeOptions() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.selectShape,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ShapeType.values.map(
              (shape) => ListTile(
                leading: Icon(
                  _getShapeIcon(shape),
                  color: _selectedShape == shape
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
                title: Text(shape.displayName),
                trailing: _selectedShape == shape
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedShape = shape;
                    _clearAll();
                  });
                  Navigator.pop(context);

                  // Show dimension input for shapes that need it
                  if (shape == ShapeType.rectangle ||
                      shape == ShapeType.circle) {
                    _showDimensionInput();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDimensionInput() {
    final loc = AppLocalizations.of(context);

    // Initialize controllers if empty
    if (_widthControllers.isEmpty) {
      _widthControllers.add(TextEditingController(text: _widthController.text));
    }
    if (_heightControllers.isEmpty) {
      _heightControllers.add(
        TextEditingController(text: _heightController.text),
      );
    }

    showDialog(
      context: context,
      builder: (context) => BlocBuilder<MeasurementUnitBloc, MeasurementUnitState>(
        builder: (context, state) {
          final unitSymbol = state.unit.symbol;

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(
                  '${loc.enterMeasurement} ${_selectedShape.displayName}',
                ),
                content: SingleChildScrollView(
                  child: _selectedShape == ShapeType.rectangle
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Width Section
                            Text(
                              '${loc.width} Measurements',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Text('Count:'),
                                Expanded(
                                  child: Slider(
                                    value: _widthSegmentCount.toDouble(),
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: _widthSegmentCount.toString(),
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        _widthSegmentCount = value.toInt();
                                        // Adjust controllers
                                        while (_widthControllers.length <
                                            _widthSegmentCount) {
                                          _widthControllers.add(
                                            TextEditingController(),
                                          );
                                        }
                                        while (_widthControllers.length >
                                            _widthSegmentCount) {
                                          _widthControllers.last.dispose();
                                          _widthControllers.removeLast();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                Text('$_widthSegmentCount'),
                              ],
                            ),
                            ...List.generate(_widthSegmentCount, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: TextField(
                                  controller: _widthControllers[index],
                                  decoration: InputDecoration(
                                    labelText:
                                        '${loc.width} ${index + 1} ($unitSymbol)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              );
                            }),
                            const SizedBox(height: 16),

                            // Height Section
                            Text(
                              '${loc.height} Measurements',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Text('Count:'),
                                Expanded(
                                  child: Slider(
                                    value: _heightSegmentCount.toDouble(),
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: _heightSegmentCount.toString(),
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        _heightSegmentCount = value.toInt();
                                        // Adjust controllers
                                        while (_heightControllers.length <
                                            _heightSegmentCount) {
                                          _heightControllers.add(
                                            TextEditingController(),
                                          );
                                        }
                                        while (_heightControllers.length >
                                            _heightSegmentCount) {
                                          _heightControllers.last.dispose();
                                          _heightControllers.removeLast();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                Text('$_heightSegmentCount'),
                              ],
                            ),
                            ...List.generate(_heightSegmentCount, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: TextField(
                                  controller: _heightControllers[index],
                                  decoration: InputDecoration(
                                    labelText:
                                        '${loc.height} ${index + 1} ($unitSymbol)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              );
                            }),
                          ],
                        )
                      : TextField(
                          controller: _radiusController,
                          decoration: InputDecoration(
                            labelText: '${loc.radius} ($unitSymbol)',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger redraw when dimensions are entered
                      setState(() {
                        if (_selectedShape == ShapeType.circle) {
                          if (_points.isEmpty) {
                            _points.add(const Point(200, 200));
                          }
                        } else if (_selectedShape == ShapeType.rectangle) {
                          // Update main controllers with average for backward compatibility/display
                          double totalWidth = 0;
                          int validWidths = 0;
                          for (var c in _widthControllers) {
                            final val = double.tryParse(c.text);
                            if (val != null) {
                              totalWidth += val;
                              validWidths++;
                            }
                          }
                          if (validWidths > 0) {
                            _widthController.text = (totalWidth / validWidths)
                                .toString();
                          }

                          double totalHeight = 0;
                          int validHeights = 0;
                          for (var c in _heightControllers) {
                            final val = double.tryParse(c.text);
                            if (val != null) {
                              totalHeight += val;
                              validHeights++;
                            }
                          }
                          if (validHeights > 0) {
                            _heightController.text =
                                (totalHeight / validHeights).toString();
                          }

                          if (_points.isEmpty) {
                            _points.add(const Point(100, 150));
                            _points.add(const Point(300, 150));
                            _points.add(const Point(300, 350));
                            _points.add(const Point(100, 350));
                          }

                          // Update side measurements immediately for visualization
                          final inputUnit = context
                              .read<MeasurementUnitBloc>()
                              .state
                              .unit;
                          final w = double.tryParse(_widthController.text) ?? 0;
                          final h =
                              double.tryParse(_heightController.text) ?? 0;

                          if (w > 0 && h > 0) {
                            final wMeters = inputUnit.toMeters(w);
                            final hMeters = inputUnit.toMeters(h);
                            _sideMeasurements[0] = wMeters;
                            _sideMeasurements[1] = hMeters;
                            _sideMeasurements[2] = wMeters;
                            _sideMeasurements[3] = hMeters;
                          }
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(loc.ok),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _getShapeIcon(ShapeType shape) {
    switch (shape) {
      case ShapeType.rectangle:
        return Icons.rectangle_outlined;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.triangle:
        return Icons.change_history;
      case ShapeType.polygon:
        return Icons.pentagon_outlined;
    }
  }

  void _showSideMeasurements() {
    final loc = AppLocalizations.of(context);
    // Calculate total number of sides
    final totalSides = _points.length >= 3
        ? _points.length
        : _points.length - 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.editSideMeasurements),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_points.length < 2) Text(loc.addAtLeast2Points),
              for (int i = 0; i < totalSides; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Side ${i + 1}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: '0.0',
                            suffixText: 'm',
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: TextEditingController(
                            text: _sideMeasurements[i]?.toString() ?? '',
                          ),
                          onChanged: (value) {
                            final measurement = double.tryParse(value);
                            if (measurement != null && measurement > 0) {
                              setState(() {
                                _sideMeasurements[i] = measurement;
                              });
                            } else {
                              setState(() {
                                _sideMeasurements.remove(i);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Refresh to show updated measurements
              Navigator.pop(context);
            },
            child: Text(loc.done),
          ),
        ],
      ),
    );
  }

  void _showDiagonalInput() {
    // Formula: For N-sided polygon, need (N-3) diagonals to triangulate
    int requiredDiagonals = _points.length - 3;

    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(
            '${loc.diagonalMeasurementsTitle} (${loc.diagonalMeasurementsRequired}: $requiredDiagonals)',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'For a ${_points.length}-sided polygon, measure $requiredDiagonals diagonal(s) to calculate exact area:',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                // Generate diagonal input fields
                ..._generateDiagonalInputs(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (_diagonalMeasurements.length >= requiredDiagonals) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter all $requiredDiagonals diagonals. You have entered ${_diagonalMeasurements.length}.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text(loc.done),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _generateDiagonalInputs() {
    final widgets = <Widget>[];
    final measurementUnitState = context.read<MeasurementUnitBloc>().state;
    final unitSymbol = measurementUnitState.unit.symbol;
    final inputUnit = measurementUnitState.unit;

    // Formula: For N-sided polygon, need (N-3) diagonals to triangulate
    int requiredDiagonals = _points.length - 3;

    // For a polygon with N sides, suggest diagonals
    // For simplicity, suggest diagonals from point 0 to points 2, 3, 4, etc.
    for (int i = 0; i < requiredDiagonals; i++) {
      final fromPoint = 0;
      final toPoint = i + 2;
      final diagonalKey = '$fromPoint-$toPoint';

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Point $fromPoint to Point $toPoint:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: '0.0',
                    suffixText: unitSymbol,
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  controller: TextEditingController(
                    text: _diagonalMeasurements[diagonalKey] != null
                        ? inputUnit
                              .fromMeters(_diagonalMeasurements[diagonalKey]!)
                              .toStringAsFixed(2)
                        : '',
                  ),
                  onChanged: (value) {
                    final measurement = double.tryParse(value);
                    if (measurement != null && measurement > 0) {
                      // Convert to meters before storing
                      final valueInMeters = inputUnit.toMeters(measurement);
                      setState(() {
                        _diagonalMeasurements[diagonalKey] = valueInMeters;
                      });
                    } else {
                      setState(() {
                        _diagonalMeasurements.remove(diagonalKey);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedShape.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _showShapeOptions,
            tooltip: loc.selectShape,
          ),
          if (_selectedShape == ShapeType.rectangle ||
              _selectedShape == ShapeType.circle)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showDimensionInput,
              tooltip: loc.enterMeasurement,
            ),
          if ((_selectedShape == ShapeType.polygon ||
                  _selectedShape == ShapeType.triangle) &&
              _points.length >= 2)
            IconButton(
              icon: const Icon(Icons.straighten),
              onPressed: _showSideMeasurements,
              tooltip: loc.enterMeasurement,
            ),
        ],
      ),
      body: BlocConsumer<MeasurementBloc, MeasurementState>(
        listener: (context, state) {
          if (state is MeasurementCalculated) {
            // Show result bottom sheet instead of dialog
            _showResultBottomSheet(state.measurement);
          } else if (state is MeasurementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Instruction Banner
              if (!_isResizeMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getInstructionText(loc),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isResizeMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.aspect_ratio, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resize Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                Text(
                                  'Select points to move. Unselected points will stay fixed.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _cancelResize,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _confirmResize,
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Canvas Area
              Expanded(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.1,
                          maxScale: 5.0,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          child: GestureDetector(
                            onTapDown: (details) {
                              if (_isResizeMode) {
                                _handleResizeTap(details.localPosition);
                              } else if (_selectedShape == ShapeType.polygon ||
                                  _selectedShape == ShapeType.triangle) {
                                _addPoint(details.localPosition);
                              }
                            },
                            child: Container(
                              color: Colors.grey[200],
                              child: CustomPaint(
                                painter: ShapePainter(
                                  _points,
                                  _selectedShape,
                                  _radiusController.text.isEmpty
                                      ? null
                                      : double.tryParse(_radiusController.text),
                                  _sideMeasurements,
                                  _diagonalMeasurements,
                                  previewPoints: _previewPoints ?? [],
                                  selectedIndices: _selectedResizeIndices,
                                  isResizeMode: _isResizeMode,
                                ),
                                child: Container(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_fit',
                        onPressed: _zoomToFit,
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Points',
                          '${_points.length}',
                          Icons.place,
                        ),
                        if (_selectedShape == ShapeType.rectangle)
                          _buildStatItem(
                            'W × H',
                            '${_widthController.text} × ${_heightController.text}',
                            Icons.straighten,
                          ),
                        if (_selectedShape == ShapeType.circle)
                          _buildStatItem(
                            'Radius',
                            _radiusController.text,
                            Icons.circle_outlined,
                          ),
                        if ((_selectedShape == ShapeType.polygon ||
                                _selectedShape == ShapeType.triangle) &&
                            _points.length >= 2)
                          _buildStatItem(
                            'Sides',
                            '${_points.length >= 3 ? _points.length : _points.length - 1}',
                            Icons.timeline,
                          ),
                        if (_sideMeasurements.isNotEmpty)
                          _buildStatItem(
                            'Measured',
                            '${_sideMeasurements.length}/${_points.length >= 3 ? _points.length : _points.length - 1}',
                            Icons.check_circle_outline,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons - Organized Layout
                    if (_isResizeMode)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isResizeMode = false;
                                  _previewPoints = [];
                                  _selectedResizeIndices.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _confirmResize,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Apply Resize'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        spacing: 12,
                        children: [
                          // Primary Action Row
                          Row(
                            children: [
                              // Undo Button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _points.isNotEmpty
                                      ? _undoLastPoint
                                      : null,
                                  child: const Icon(Icons.undo),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Calculate Area Button (Primary)
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed:
                                      state is MeasurementLoading ||
                                          (_selectedShape ==
                                                  ShapeType.polygon &&
                                              !_isShapeComplete)
                                      ? null
                                      : _calculateArea,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: state is MeasurementLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(loc.calculate),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Clear Button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _points.isNotEmpty
                                      ? _clearAll
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Icon(Icons.clear),
                                ),
                              ),
                            ],
                          ),
                          // Secondary Action Row - Complete Button (if needed)
                          if (_selectedShape == ShapeType.polygon &&
                              _points.length >= 3 &&
                              !_isShapeComplete)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _completePolygon,
                                icon: const Icon(Icons.check_circle),
                                label: Text(loc.completePolygon),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _getInstructionText(AppLocalizations loc) {
    switch (_selectedShape) {
      case ShapeType.rectangle:
        return '${loc.width} & ${loc.height} ${loc.sideLengthInMeters}';
      case ShapeType.circle:
        return '${loc.radius} ${loc.sideLengthInMeters}';
      case ShapeType.triangle:
        if (_isShapeComplete) {
          return '${loc.triangle} ${loc.complete}! ${loc.calculate}';
        }
        return 'Tap to add 3 points for ${loc.triangle}';
      case ShapeType.polygon:
        if (_isShapeComplete) {
          return '${loc.polygon} ${loc.complete}! ${loc.calculate}';
        } else if (_points.length >= 3) {
          return 'Tap "${loc.complete}" to close the ${loc.polygon}, or keep adding points';
        }
        return 'Tap to add points (minimum 3)';
    }
  }

  void _showResultBottomSheet(Measurement measurement) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MeasurementResultBottomSheet(
        measurement: measurement,
        onResizeRequest: (targetArea, unit, currentArea) {
          // Sheet is already closed by the widget
          _applyResize(targetArea, unit, currentArea);
        },
        onSave: () {
          context.read<MeasurementBloc>().add(
            SaveMeasurementEvent(measurement),
          );
          context.pop(); // Go back to home
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.measurementSaved),
              backgroundColor: AppTheme.successColor,
            ),
          );
        },
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final List<Point> points;
  final ShapeType shapeType;
  final double? radius;
  final Map<int, double> sideMeasurements;
  final Map<String, double> diagonalMeasurements;
  final List<Point> previewPoints;
  final Set<int> selectedIndices;
  final bool isResizeMode;

  ShapePainter(
    this.points,
    this.shapeType,
    this.radius,
    this.sideMeasurements,
    this.diagonalMeasurements, {
    this.previewPoints = const [],
    this.selectedIndices = const {},
    this.isResizeMode = false,
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
      final labelText = '${radius!.toStringAsFixed(1)}m';

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
        ? '${sideMeasurements[sideIndex]!.toStringAsFixed(1)}m'
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

          // Draw the diagonal line
          canvas.drawLine(fromPoint, toPoint, diagonalPaint);

          // Draw label at midpoint
          final midpoint = Offset(
            (fromPoint.dx + toPoint.dx) / 2,
            (fromPoint.dy + toPoint.dy) / 2,
          );

          final measurement = diagonalMeasurements[diagonalKey]!;
          final labelText = '${measurement.toStringAsFixed(1)}m';

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

          // Draw label background
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

          // Draw text
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
  bool shouldRepaint(ShapePainter oldDelegate) => true;
}
