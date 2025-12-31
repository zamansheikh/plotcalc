import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../widgets/measurement_result_bottom_sheet.dart';
import '../../../../settings/presentation/bloc/measurement_unit_bloc.dart';
import '../../../domain/entities/measurement.dart';
import '../../bloc/measurement_bloc.dart';
import 'widgets/drawing_instruction_banner.dart';
import 'models/resize_constraint.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/drawing_controls_panel.dart';

part 'parts/resize_mixin.dart';
part 'parts/geometry_mixin.dart';

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

class _DrawingPageState extends State<DrawingPage>
    with ResizeMixin, GeometryMixin {
  @override
  final List<Point> _points = [];
  @override
  final Map<int, double> _sideMeasurements = {}; // Index -> measurement in meters
  @override
  final Map<String, double> _diagonalMeasurements = {}; // "0-2" -> measurement (from point 0 to point 2)
  @override
  ShapeType _selectedShape = ShapeType.polygon;
  @override
  bool _isShapeComplete = false; // Track if shape is closed/complete
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  @override
  final TextEditingController _radiusController = TextEditingController();

  // Compound Unit Toggle
  bool _useCompoundUnits = false;

  // Rectangle Average Method State
  int _widthSegmentCount = 1;
  int _heightSegmentCount = 1;
  final List<TextEditingController> _widthControllers = [];
  final List<TextEditingController> _heightControllers = [];

  // Zoom/Pan control
  final TransformationController _transformationController =
      TransformationController();
  Size _viewportSize = Size.zero;

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
    final inputUnit = context.read<MeasurementUnitBloc>().state.unit;

    setState(() {
      _selectedShape = measurement.shapeType;
      _points.clear();
      _points.addAll(measurement.points);
      _isShapeComplete = measurement.points.length >= 3;

      // Load dimensions for rectangles and circles
      if (measurement.dimensions != null) {
        if (measurement.dimensions!.containsKey('width')) {
          _widthController.text = inputUnit
              .fromMeters(measurement.dimensions!['width']!)
              .toStringAsFixed(2);
        }
        if (measurement.dimensions!.containsKey('height')) {
          _heightController.text = inputUnit
              .fromMeters(measurement.dimensions!['height']!)
              .toStringAsFixed(2);
        }
        if (measurement.dimensions!.containsKey('radius')) {
          _radiusController.text = inputUnit
              .fromMeters(measurement.dimensions!['radius']!)
              .toStringAsFixed(2);
        }

        // Load average method data if available
        if (measurement.dimensions!.containsKey('width_count')) {
          _widthSegmentCount = measurement.dimensions!['width_count']!.toInt();
          _widthControllers.clear();
          for (int i = 0; i < _widthSegmentCount; i++) {
            final val = measurement.dimensions!['width_$i'] ?? 0.0;
            _widthControllers.add(
              TextEditingController(
                text: inputUnit.fromMeters(val).toStringAsFixed(2),
              ),
            );
          }
        }
        if (measurement.dimensions!.containsKey('height_count')) {
          _heightSegmentCount = measurement.dimensions!['height_count']!
              .toInt();
          _heightControllers.clear();
          for (int i = 0; i < _heightSegmentCount; i++) {
            final val = measurement.dimensions!['height_$i'] ?? 0.0;
            _heightControllers.add(
              TextEditingController(
                text: inputUnit.fromMeters(val).toStringAsFixed(2),
              ),
            );
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

  // _applyResize moved to ResizeMixin

  // _handleResizeTap moved to ResizeMixin

  // _distToSegment moved to ResizeMixin

  // _updateResizePreview moved to ResizeMixin

  // _findCorrectScaleForMixedPoints moved to ResizeMixin

  // _calculatePolygonArea moved to ResizeMixin

  // _confirmResize moved to ResizeMixin

  // _cancelResize moved to ResizeMixin

  @override
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
      ..multiply(Matrix4.translationValues(tx, ty, 0.0))
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));

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

  void _handleSideTap(Offset localPosition) {
    const double touchRadius = 20.0;
    int? tappedSideIndex;

    for (int i = 0; i < _points.length; i++) {
      final p1 = _points[i];
      final p2 = _points[(i + 1) % _points.length];

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
      _askForSideMeasurement(tappedSideIndex);
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
            _MeasurementInputRow(
              label: loc.enterMeasurement,
              unit: inputUnit,
              useCompound: _useCompoundUnits,
              controller: controller,
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

  @override
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
          widthValues['width_$i'] = inputUnit.toMeters(val);
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
          heightValues['height_$i'] = inputUnit.toMeters(val);
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
    // Side measurements and diagonal measurements are already stored in meters
    final sideMeasurementsInMeters = Map<int, double>.from(_sideMeasurements);
    final diagonalMeasurementsInMeters = Map<String, double>.from(
      _diagonalMeasurements,
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

  // _fixShapeGeometry moved to GeometryMixin

  // _findIntersection moved to GeometryMixin

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
          final inputUnit = state.unit;

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
                              '${loc.width} ${loc.measurements}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text('${loc.count}:'),
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
                                child: _MeasurementInputRow(
                                  label: '${loc.width} ${index + 1}',
                                  unit: inputUnit,
                                  useCompound: _useCompoundUnits,
                                  controller: _widthControllers[index],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),

                            // Height Section
                            Text(
                              '${loc.height} ${loc.measurements}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text('${loc.count}:'),
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
                                child: _MeasurementInputRow(
                                  label: '${loc.height} ${index + 1}',
                                  unit: inputUnit,
                                  useCompound: _useCompoundUnits,
                                  controller: _heightControllers[index],
                                ),
                              );
                            }),
                          ],
                        )
                      : _MeasurementInputRow(
                          label: loc.radius,
                          unit: inputUnit,
                          useCompound: _useCompoundUnits,
                          controller: _radiusController,
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
    final measurementUnitState = context.read<MeasurementUnitBloc>().state;
    final inputUnit = measurementUnitState.unit;
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
                        width: 200,
                        child: _MeasurementInputRow(
                          label: '',
                          unit: inputUnit,
                          useCompound: _useCompoundUnits,
                          controller: TextEditingController(
                            text: _sideMeasurements[i] != null
                                ? inputUnit
                                      .fromMeters(_sideMeasurements[i]!)
                                      .toStringAsFixed(2)
                                : '',
                          ),
                          onChanged: (value) {
                            final measurement = double.tryParse(value);
                            if (measurement != null && measurement > 0) {
                              setState(() {
                                _sideMeasurements[i] = inputUnit.toMeters(
                                  measurement,
                                );
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
    final loc = AppLocalizations.of(context);
    final measurementUnitState = context.read<MeasurementUnitBloc>().state;
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
                  '${loc.point} $fromPoint ${loc.to} ${loc.point} $toPoint:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                width: 200,
                child: _MeasurementInputRow(
                  label: '',
                  unit: inputUnit,
                  useCompound: _useCompoundUnits,
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
          if (!_isResizeMode) ...[
            IconButton(
              icon: Icon(_useCompoundUnits ? Icons.grid_4x4 : Icons.numbers),
              onPressed: () {
                setState(() {
                  _useCompoundUnits = !_useCompoundUnits;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _useCompoundUnits
                          ? loc.switchedToCompound
                          : loc.switchedToDecimal,
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: loc.toggleUnitFormat,
            ),
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
            if (_selectedShape == ShapeType.polygon && _points.length >= 4)
              IconButton(
                icon: const Icon(Icons.border_style),
                onPressed: _showDiagonalInput,
                tooltip: loc.diagonalMeasurementsTitle,
              ),
            // Move Button
            if (_selectedShape == ShapeType.polygon ||
                _selectedShape == ShapeType.rectangle)
              IconButton(
                icon: const Icon(Icons.open_with),
                onPressed: _enterMoveMode,
                tooltip: 'Move Points/Sides',
              ),
          ],
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
              if (!_isResizeMode && !_isMoveMode)
                DrawingInstructionBanner(
                  selectedShape: _selectedShape,
                  isShapeComplete: _isShapeComplete,
                  pointsLength: _points.length,
                ),

              if (_isMoveMode)
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select points/sides to move, then click Configure.',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // Canvas Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _viewportSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return DrawingCanvas(
                      points: _points,
                      selectedShape: _selectedShape,
                      radiusText: _radiusController.text,
                      sideMeasurements: _sideMeasurements,
                      diagonalMeasurements: _diagonalMeasurements,
                      previewPoints: _previewPoints ?? [],
                      selectedIndices: _selectedResizeIndices,
                      isResizeMode: _isResizeMode || _isMoveMode,
                      inputUnit: context
                          .watch<MeasurementUnitBloc>()
                          .state
                          .unit,
                      useCompoundUnits: _useCompoundUnits,
                      transformationController: _transformationController,
                      viewportSize: _viewportSize,
                      onTapDown: (localPosition) {
                        if (_isMoveMode) {
                          _handleMoveTap(localPosition);
                        } else if (_isResizeMode) {
                          // Only allow interaction if shape is not Circle
                          // For Circle, resize is handled via slider/input only
                          if (_selectedShape != ShapeType.circle) {
                            _handleResizeTap(localPosition);
                          }
                        } else if (_selectedShape == ShapeType.polygon ||
                            _selectedShape == ShapeType.triangle) {
                          if (_isShapeComplete) {
                            _handleSideTap(localPosition);
                          } else {
                            _addPoint(localPosition);
                          }
                        }
                      },
                      onZoomToFit: _zoomToFit,
                      resizeConstraint: _resizeConstraint,
                      compensationSideIndex: _compensationSideIndex,
                      lockedSideIndices: _lockedSideIndices,
                    );
                  },
                ),
              ),

              // Controls
              DrawingControlsPanel(
                selectedShape: _selectedShape,
                isShapeComplete: _isShapeComplete,
                isResizeMode: _isResizeMode,
                isMoveMode: _isMoveMode,
                pointsLength: _points.length,
                widthText: _widthController.text,
                heightText: _heightController.text,
                radiusText: _radiusController.text,
                sideMeasurementsLength: _sideMeasurements.length,
                isLoading: state is MeasurementLoading,
                onUndo: _undoLastPoint,
                onCalculate: _calculateArea,
                onClear: _clearAll,
                onCompletePolygon:
                    (_selectedShape == ShapeType.polygon &&
                        _points.length >= 3 &&
                        !_isShapeComplete)
                    ? _completePolygon
                    : null,
                onCancelResize: _isResizeMode
                    ? () {
                        setState(() {
                          _isResizeMode = false;
                          _previewPoints = [];
                          _selectedResizeIndices.clear();
                        });
                      }
                    : null,
                onApplyResize: _isResizeMode ? _confirmResize : null,
                onApplyMove: _isMoveMode ? _confirmMove : null,
                onCancelMove: _isMoveMode
                    ? () {
                        setState(() {
                          _isMoveMode = false;
                          _previewPoints = null;
                          _selectedResizeIndices.clear();
                        });
                      }
                    : null,
                moveXValue: _moveX,
                moveYValue: _moveY,
                moveRange: _moveRange,
                onMoveXChanged: _isMoveMode ? _setMoveX : null,
                onMoveYChanged: _isMoveMode ? _setMoveY : null,
                onMoveRangeChanged: _isMoveMode ? _setMoveRange : null,
              ),
            ],
          );
        },
      ),
    );
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

class _MeasurementInputRow extends StatefulWidget {
  final String label;
  final InputUnit unit;
  final bool useCompound;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const _MeasurementInputRow({
    required this.label,
    required this.unit,
    required this.useCompound,
    required this.controller,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  State<_MeasurementInputRow> createState() => _MeasurementInputRowState();
}

class _MeasurementInputRowState extends State<_MeasurementInputRow> {
  late TextEditingController _mainController;
  late TextEditingController _smallController;

  @override
  void initState() {
    super.initState();
    _mainController = TextEditingController();
    _smallController = TextEditingController();
    _syncFromDecimal();

    _mainController.addListener(_onCompoundChanged);
    _smallController.addListener(_onCompoundChanged);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _smallController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MeasurementInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useCompound != widget.useCompound) {
      _syncFromDecimal();
    }
  }

  void _syncFromDecimal() {
    if (!widget.useCompound) return;

    double? val = double.tryParse(widget.controller.text);
    if (val == null) {
      _mainController.text = "";
      _smallController.text = "";
      return;
    }

    if (widget.unit == InputUnit.feet) {
      int feet = val.floor();
      int inches = ((val - feet) * 12).round();
      _mainController.text = feet.toString();
      _smallController.text = inches.toString();
    } else {
      int meters = val.floor();
      int cm = ((val - meters) * 100).round();
      _mainController.text = meters.toString();
      _smallController.text = cm.toString();
    }
  }

  void _onCompoundChanged() {
    if (!widget.useCompound) return;

    double main = double.tryParse(_mainController.text) ?? 0;
    double small = double.tryParse(_smallController.text) ?? 0;

    double decimal;
    if (widget.unit == InputUnit.feet) {
      decimal = main + (small / 12.0);
    } else {
      decimal = main + (small / 100.0);
    }

    String newText = decimal == 0 ? "" : decimal.toString();
    // Avoid infinite loop if we were listening to widget.controller
    if (widget.controller.text != newText) {
      widget.controller.text = newText;
      widget.onChanged?.call(newText);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useCompound) {
      return TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: '${widget.label} (${widget.unit.symbol})',
          border: const OutlineInputBorder(),
          suffixText: widget.unit.symbol,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
      );
    }

    final loc = AppLocalizations.of(context);
    String mainLabel = widget.unit == InputUnit.feet ? loc.feet : loc.meters;
    String smallLabel = widget.unit == InputUnit.feet ? loc.inches : loc.cm;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _mainController,
            decoration: InputDecoration(
              labelText: mainLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            autofocus: widget.autofocus,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _smallController,
            decoration: InputDecoration(
              labelText: smallLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
