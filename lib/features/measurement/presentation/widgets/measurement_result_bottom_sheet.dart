import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/land_area_breakdown.dart';
import '../../../../core/utils/land_measurement_converter.dart';
import '../../domain/entities/measurement.dart';
import '../bloc/measurement_bloc.dart';
import 'land_area_breakdown_widget.dart';

class MeasurementResultBottomSheet extends StatefulWidget {
  final Measurement measurement;
  final VoidCallback? onViewShape;
  final VoidCallback? onSave;
  final Function(double targetArea, MeasurementUnit unit)? onResizeRequest;

  const MeasurementResultBottomSheet({
    super.key,
    required this.measurement,
    this.onViewShape,
    this.onSave,
    this.onResizeRequest,
  });

  @override
  State<MeasurementResultBottomSheet> createState() =>
      _MeasurementResultBottomSheetState();
}

class _MeasurementResultBottomSheetState
    extends State<MeasurementResultBottomSheet> {
  late List<LandUnitDef> _units;
  late LandAreaResult _breakdownResult;
  bool _showConfiguration = false;

  // For Resize Feature
  final TextEditingController _targetAreaController = TextEditingController();
  MeasurementUnit _targetAreaUnit = MeasurementUnit.acres;

  @override
  void initState() {
    super.initState();
    _units = LandAreaCalculator.getDefaultUnits();
    _calculateBreakdown();
  }

  @override
  void dispose() {
    _targetAreaController.dispose();
    super.dispose();
  }

  void _calculateBreakdown() {
    final totalSqFt = widget.measurement.getAreaIn(MeasurementUnit.squareFeet);
    setState(() {
      _breakdownResult = LandAreaCalculator.calculate(totalSqFt, _units);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final LandUnitDef item = _units.removeAt(oldIndex);
      _units.insert(newIndex, item);
      _calculateBreakdown();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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

  void _showResizeDialog() {
    final units = LandAreaCalculator.getDefaultUnits();
    final controllers = <String, TextEditingController>{};
    for (var unit in units) {
      controllers[unit.id] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Resize Area'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter target area (combine multiple units if needed):',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ...units.map((unit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                unit.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: controllers[unit.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  hintText: '0',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  double totalSqFt = 0;
                  bool hasInput = false;

                  for (var unit in units) {
                    final text = controllers[unit.id]?.text;
                    if (text != null && text.isNotEmpty) {
                      final value = double.tryParse(text);
                      if (value != null) {
                        totalSqFt += value * unit.sqftFactor;
                        hasInput = true;
                      }
                    }
                  }

                  if (hasInput && totalSqFt > 0) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close bottom sheet
                    if (widget.onResizeRequest != null) {
                      widget.onResizeRequest!(
                        totalSqFt,
                        MeasurementUnit.squareFeet,
                      );
                    }
                  }
                },
                child: const Text('Resize'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getShapeIcon(widget.measurement.shapeType),
                  color: primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.measurement.shapeType.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${loc.created}: ${_formatDate(widget.measurement.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detailed Breakdown
            LandAreaBreakdownWidget(result: _breakdownResult),

            const SizedBox(height: 16),

            // Unit Configuration Toggle
            InkWell(
              onTap: () {
                setState(() {
                  _showConfiguration = !_showConfiguration;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Unit Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showConfiguration
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            // Unit Configuration List
            if (_showConfiguration) ...[
              const SizedBox(height: 8),
              Text(
                'Drag to reorder. Uncheck to hide.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _units.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final unit = _units[index];
                      return CheckboxListTile(
                        key: ValueKey(unit.id),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        dense: true,
                        title: Text(
                          unit.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: unit.isEnabled,
                        activeColor: primaryColor,
                        secondary: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle, size: 20),
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            unit.isEnabled = value ?? false;
                            _calculateBreakdown();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Resize / Target Area Feature
            if (widget.onResizeRequest != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryColor.withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.aspect_ratio, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Target Area Adjustment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjust shape to a specific area (e.g., 1 Acre).',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showResizeDialog,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Expand/Shrink to Target Area'),
                      ),
                    ),
                  ],
                ),
              ),

            // Standard Units Table
            Text(
              'Standard Units',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: MeasurementUnit.values.map((unit) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(unit.symbol, style: const TextStyle(fontSize: 15)),
                        Text(
                          widget.measurement.getAreaIn(unit).toStringAsFixed(4),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                if (widget.onViewShape != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onViewShape!();
                      },
                      icon: const Icon(Icons.visibility),
                      label: Text(loc.viewShape),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.onSave != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSave!();
                      },
                      icon: const Icon(Icons.save),
                      label: Text(loc.save),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(loc.close),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
