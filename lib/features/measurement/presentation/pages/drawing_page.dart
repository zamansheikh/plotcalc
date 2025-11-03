import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/land_measurement_converter.dart';
import '../../domain/entities/measurement.dart';
import '../bloc/measurement_bloc.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<Point> _points = [];
  final Map<int, double> _sideMeasurements =
      {}; // Index -> measurement in meters
  ShapeType _selectedShape = ShapeType.polygon;
  bool _isShapeComplete = false; // Track if shape is closed/complete
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

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
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 3 points before completing the polygon'),
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
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Side ${sideIndex + 1} Length'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the length of side ${sideIndex + 1} in meters',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Length (meters)',
                border: OutlineInputBorder(),
                suffixText: 'm',
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
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        _sideMeasurements[sideIndex] = result;
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
      _isShapeComplete = false;
      _widthController.clear();
      _heightController.clear();
      _radiusController.clear();
    });
  }

  void _calculateArea() {
    Map<String, double>? dimensions;

    // For specific shapes, we need dimensions
    if (_selectedShape == ShapeType.rectangle) {
      final width = double.tryParse(_widthController.text);
      final height = double.tryParse(_heightController.text);

      if (width == null || height == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid width and height'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      dimensions = {'width': width, 'height': height};
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
          const SnackBar(
            content: Text('Please enter valid radius'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      dimensions = {'radius': radius};
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
          const SnackBar(
            content: Text('Please add at least 3 points'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Calculate area
    print(
      'DEBUG: _calculateArea - sideMeasurements being sent: $_sideMeasurements',
    );
    context.read<MeasurementBloc>().add(
      CalculateAreaEvent(
        points: _points,
        dimensions: dimensions,
        sideMeasurements: _sideMeasurements,
      ),
    );
  }

  void _showShapeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Shape Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${_selectedShape.displayName} Dimensions'),
        content: _selectedShape == ShapeType.rectangle
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Width (meters)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (meters)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              )
            : TextField(
                controller: _radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('OK'),
          ),
        ],
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
    // Calculate total number of sides
    final totalSides = _points.length >= 3
        ? _points.length
        : _points.length - 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Side Measurements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_points.length < 2)
                const Text('Add at least 2 points to see sides'),
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Change Shape',
          ),
          if (_selectedShape == ShapeType.rectangle ||
              _selectedShape == ShapeType.circle)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showDimensionInput,
              tooltip: 'Edit Dimensions',
            ),
          if ((_selectedShape == ShapeType.polygon ||
                  _selectedShape == ShapeType.triangle) &&
              _points.length >= 2)
            IconButton(
              icon: const Icon(Icons.straighten),
              onPressed: _showSideMeasurements,
              tooltip: 'Edit Side Measurements',
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
                        _getInstructionText(),
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
                                    : const Text('Calculate'),
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
                              label: const Text('Complete Polygon'),
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

  String _getInstructionText() {
    switch (_selectedShape) {
      case ShapeType.rectangle:
        return 'Enter width and height in meters';
      case ShapeType.circle:
        return 'Enter radius in meters';
      case ShapeType.triangle:
        if (_isShapeComplete) {
          return 'Triangle complete! You can now calculate the area';
        }
        return 'Tap to add 3 points for triangle';
      case ShapeType.polygon:
        if (_isShapeComplete) {
          return 'Polygon complete! You can now calculate the area';
        } else if (_points.length >= 3) {
          return 'Tap "Complete" to close the polygon, or keep adding points';
        }
        return 'Tap to add points (minimum 3)';
    }
  }

  void _showResultDialog(Measurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successColor),
            const SizedBox(width: 8),
            const Text('Area Calculated'),
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
              const Text(
                'Area in Standard Units:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Area in Land Units:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                LandMeasurementConverter.formatLandMeasurement(
                  measurement.getAreaIn(MeasurementUnit.squareMeters),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.green),
              ),
              const SizedBox(height: 12),
              Text(
                'Details:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ..._buildLandMeasurementDetails(
                measurement.getAreaIn(MeasurementUnit.squareMeters),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Go back to home
            },
            child: const Text('Discard'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MeasurementBloc>().add(
                SaveMeasurementEvent(measurement),
              );
              Navigator.pop(context);
              context.pop(); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement saved successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper function to build land measurement detail rows
  List<Widget> _buildLandMeasurementDetails(double sqMeters) {
    final measurements = LandMeasurementConverter.convertToLandUnits(sqMeters);
    final details = <Widget>[];

    if (measurements.containsKey('acres')) {
      details.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Acres:', style: TextStyle(fontSize: 12)),
              Text(
                '${measurements['acres']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (measurements.containsKey('bighas')) {
      details.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bighas:', style: TextStyle(fontSize: 12)),
              Text(
                '${measurements['bighas']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (measurements.containsKey('kathas')) {
      details.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kathas:', style: TextStyle(fontSize: 12)),
              Text(
                '${measurements['kathas']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (measurements.containsKey('shataks')) {
      details.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shataks:', style: TextStyle(fontSize: 12)),
              Text(
                '${measurements['shataks']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (measurements.containsKey('shotoks')) {
      details.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shotoks:', style: TextStyle(fontSize: 12)),
              Text(
                '${measurements['shotoks']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (details.isEmpty) {
      details.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Text('Less than 1 shotok', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    return details;
  }
}

class ShapePainter extends CustomPainter {
  final List<Point> points;
  final ShapeType shapeType;
  final double? radius;
  final Map<int, double> sideMeasurements;

  ShapePainter(this.points, this.shapeType, this.radius, this.sideMeasurements);

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
      // Draw circle
      final center = Offset(points.first.x, points.first.y);
      canvas.drawCircle(center, radius! * 10, fillPaint);
      canvas.drawCircle(center, radius! * 10, paint);
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

    canvas.drawCircle(midpoint, 12, bgPaint);
    canvas.drawCircle(
      midpoint,
      12,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: hasMeasurement
            ? '${sideMeasurements[sideIndex]!.toStringAsFixed(1)}m'
            : '${sideIndex + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) => true;
}
