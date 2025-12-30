import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/measurement_result_bottom_sheet.dart';
import '../../domain/entities/measurement.dart';
import '../bloc/measurement_bloc.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Measurement> _cachedMeasurements = [];

  @override
  void initState() {
    super.initState();
    // Load measurements when page opens
    context.read<MeasurementBloc>().add(const LoadAllMeasurementsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.measurementHistory),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MeasurementBloc>().add(
                const LoadAllMeasurementsEvent(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MeasurementBloc, MeasurementState>(
        builder: (context, state) {
          // Update cache when measurements are loaded
          if (state is MeasurementsLoaded) {
            _cachedMeasurements = state.measurements;
          }

          if (state is MeasurementLoading) {
            // Show cached list with a loading indicator overlay if we have data
            if (_cachedMeasurements.isNotEmpty) {
              return Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cachedMeasurements.length,
                    itemBuilder: (context, index) {
                      final measurement = _cachedMeasurements[index];
                      return _buildMeasurementCard(context, measurement, loc);
                    },
                  ),
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          } else if (state is MeasurementsLoaded) {
            if (state.measurements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      loc.noMeasurements,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.startMeasuring,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.add),
                      label: Text(loc.newMeasurement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.measurements.length,
              itemBuilder: (context, index) {
                final measurement = state.measurements[index];
                return _buildMeasurementCard(context, measurement, loc);
              },
            );
          } else if (state is MeasurementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${loc.failedToCalculateArea}: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MeasurementBloc>().add(
                        const LoadAllMeasurementsEvent(),
                      );
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            );
          }

          // For any other state (Saved, Calculated, Initial, Deleted), trigger reload and show cache
          // This prevents the screen from going blank when returning from DrawingPage
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<MeasurementBloc>().add(
                const LoadAllMeasurementsEvent(),
              );
            }
          });

          // Show cached list while loading
          if (_cachedMeasurements.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cachedMeasurements.length,
              itemBuilder: (context, index) {
                final measurement = _cachedMeasurements[index];
                return _buildMeasurementCard(context, measurement, loc);
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildMeasurementCard(
    BuildContext context,
    Measurement measurement,
    AppLocalizations loc,
  ) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkTheme ? Colors.grey[900] : Colors.white,
      child: InkWell(
        onTap: () => _showMeasurementBottomSheet(context, measurement, loc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkTheme
                            ? [
                                AppTheme.primaryColor.withValues(alpha: 0.7),
                                AppTheme.primaryColor.withValues(alpha: 0.5),
                              ]
                            : [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withValues(alpha: 0.7),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getShapeIcon(measurement.shapeType),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          measurement.shapeType.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isDarkTheme
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(measurement.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkTheme
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkTheme
                      ? Colors.green.shade900.withValues(alpha: 0.35)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkTheme
                        ? Colors.green.shade800
                        : Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Area',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkTheme
                                ? Colors.grey[300]
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${measurement.area.toStringAsFixed(2)} m²',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme
                                ? Colors.lightGreen.shade300
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkTheme
                            ? AppTheme.primaryColor.withValues(alpha: 0.18)
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 16,
                            color: isDarkTheme
                                ? Colors.lightGreen.shade300
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${measurement.points.length} points',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkTheme
                                  ? Colors.lightGreen.shade300
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showMeasurementBottomSheet(context, measurement, loc),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(loc.view),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, measurement.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(loc.delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showMeasurementBottomSheet(
    BuildContext context,
    Measurement measurement,
    AppLocalizations loc,
  ) {
    // Capture the parent context to ensure we use a stable context for navigation
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => MeasurementResultBottomSheet(
        measurement: measurement,
        onViewShape: () => _viewShape(parentContext, measurement),
        onResizeRequest: (targetArea, unit, currentArea) async {
          // Navigate to drawing page with resize request
          // Use parentContext because sheetContext is disposed when sheet is closed
          await parentContext.push(
            '/drawing',
            extra: {
              'measurement': measurement,
              'resizeTargetArea': targetArea,
              'resizeTargetUnit': unit,
            },
          );

          // Refresh list when returning
          if (parentContext.mounted) {
            // Use addPostFrameCallback to ensure navigation is complete
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (parentContext.mounted) {
                parentContext.read<MeasurementBloc>().add(
                  const LoadAllMeasurementsEvent(),
                );
              }
            });
          }
        },
      ),
    );
  }

  void _viewShape(BuildContext context, Measurement measurement) async {
    // Navigate to drawing page with the measurement data
    await context.push('/drawing', extra: measurement);

    // Refresh list when returning
    if (context.mounted) {
      context.read<MeasurementBloc>().add(const LoadAllMeasurementsEvent());
    }
  }


  void _confirmDelete(BuildContext context, String id) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteMeasurement),
        content: Text(loc.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MeasurementBloc>().add(DeleteMeasurementEvent(id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.measurementDeleted),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}
