import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/land_measurement_converter.dart';
import '../../../settings/presentation/bloc/measurement_unit_bloc.dart';
import '../../domain/entities/measurement.dart';
import '../bloc/measurement_bloc.dart';

class DrawingPage extends StatefulWidget {
  final Measurement? measurement; // Optional measurement to restore
  
  const DrawingPage({super.key, this.measurement});

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

  @override
  void initState() {
    super.initState();
    // Load measurement data if provided
    if (widget.measurement != null) {
      _loadMeasurement(widget.measurement!);
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

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _radiusController.dispose();
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
    print('DEBUG: _askForSideMeasurement called with sideIndex: $sideIndex');
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
        print(
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
      final width = double.tryParse(_widthController.text);
      final height = double.tryParse(_heightController.text);

      if (width == null || height == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.enterValidWidthHeight),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Convert to meters before calculation
      final widthInMeters = inputUnit.toMeters(width);
      final heightInMeters = inputUnit.toMeters(height);
      
      dimensions = {'width': widthInMeters, 'height': heightInMeters};
      // Create 4 points for rectangle visualization
      if (_points.isEmpty) {
        setState(() {
          _points.addAll([
            const Point(50, 50),
            Point(50 + width * 10, 50),
            Point(50 + width * 10, 50 + height * 10),
            Point(50, 50 + height * 10),
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
    
    print(
      'DEBUG: _calculateArea - sideMeasurements being sent: $sideMeasurementsInMeters',
    );
    print(
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
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<MeasurementUnitBloc, MeasurementUnitState>(
        builder: (context, state) {
          final unitSymbol = state.unit.symbol;
          
          return AlertDialog(
            title: Text('${loc.enterMeasurement} ${_selectedShape.displayName}'),
            content: _selectedShape == ShapeType.rectangle
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _widthController,
                        decoration: InputDecoration(
                          labelText: '${loc.width} ($unitSymbol)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: '${loc.height} ($unitSymbol)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
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
                      if (_points.isEmpty) {
                        _points.add(const Point(100, 150));
                        _points.add(const Point(300, 150));
                        _points.add(const Point(300, 350));
                        _points.add(const Point(100, 350));
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
    final loc = AppLocalizations.of(context);

    // Formula: For N-sided polygon, need (N-3) diagonals to triangulate
    int requiredDiagonals = _points.length - 3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Diagonal Measurements (Required: $requiredDiagonals)'),
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
      ),
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
                        ? inputUnit.fromMeters(_diagonalMeasurements[diagonalKey]!).toStringAsFixed(2)
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
            // Show result dialog instead of navigating
            _showResultDialog(state.measurement);
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

              // Canvas Area
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    if (_selectedShape == ShapeType.polygon ||
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
                      ),
                      child: Container(),
                    ),
                  ),
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
                                        (_selectedShape == ShapeType.polygon &&
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

  void _showResultDialog(Measurement measurement) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Text(loc.area),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shape: ${measurement.shapeType.displayName}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Area in Standard Units:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...MeasurementUnit.values.map(
                (unit) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${unit.symbol}:'),
                      Text(
                        measurement.getAreaIn(unit).toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area in Land Units (Standard):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LandUnitConverter.fromSquareMeters(measurement.area).toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Area in Land Units (Mymensingh):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LandUnitConverter.fromSquareMetersMymensingh(measurement.area).toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              // context.pop(); // Go back to home
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(loc.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MeasurementBloc>().add(
                SaveMeasurementEvent(measurement),
              );
              Navigator.pop(context);
              context.pop(); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.measurementSaved),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: Text(loc.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
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

  ShapePainter(
    this.points,
    this.shapeType,
    this.radius,
    this.sideMeasurements,
    this.diagonalMeasurements,
  );

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

    // Draw shape based on type
    if (shapeType == ShapeType.circle && radius != null && points.isNotEmpty) {
      // Draw circle with fixed size, centered on canvas
      // The radius value is only used for area calculation, not for visual scaling
      final center = Offset(size.width / 2, size.height / 2);
      const double fixedRadiusPixels = 80; // Fixed visual size
      
      canvas.drawCircle(center, fixedRadiusPixels, fillPaint);
      canvas.drawCircle(center, fixedRadiusPixels, paint);
      canvas.drawCircle(center, 6, pointPaint);
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
      for (var point in points) {
        canvas.drawCircle(Offset(point.x, point.y), 6, pointPaint);
        canvas.drawCircle(
          Offset(point.x, point.y),
          6,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
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
      for (var point in points) {
        canvas.drawCircle(Offset(point.x, point.y), 6, pointPaint);
        // Draw point border
        canvas.drawCircle(
          Offset(point.x, point.y),
          6,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
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
      canvas.drawCircle(Offset(points.first.x, points.first.y), 8, pointPaint);
      canvas.drawCircle(
        Offset(points.first.x, points.first.y),
        8,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
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
