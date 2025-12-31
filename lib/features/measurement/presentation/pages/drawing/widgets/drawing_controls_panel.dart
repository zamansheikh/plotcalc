import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/theme/app_theme.dart';
import 'drawing_stats_display.dart';

class DrawingControlsPanel extends StatelessWidget {
  final ShapeType selectedShape;
  final bool isShapeComplete;
  final bool isResizeMode;
  final bool isMoveMode;
  final int pointsLength;
  final String widthText;
  final String heightText;
  final String radiusText;
  final int sideMeasurementsLength;
  final bool isLoading;
  final VoidCallback onUndo;
  final VoidCallback onCalculate;
  final VoidCallback onClear;
  final VoidCallback? onCompletePolygon;
  final VoidCallback? onCancelResize;
  final VoidCallback? onApplyResize;
  final VoidCallback? onToggleResizeMode;
  final VoidCallback? onToggleMoveMode;
  final ValueChanged<String>? onWidthChanged;
  final ValueChanged<String>? onHeightChanged;
  final ValueChanged<String>? onRadiusChanged;
  final VoidCallback? onConfirmMove;
  final VoidCallback? onCancelMove;
  final VoidCallback? onConfigureMove;
  final double moveX;
  final double moveY;
  final double moveRange;
  final ValueChanged<double>? onMoveXChanged;
  final ValueChanged<double>? onMoveYChanged;
  final ValueChanged<double>? onMoveRangeChanged;
  final Set<int> selectedResizeIndices;
  final ValueChanged<int>? onTogglePointSelection;

  const DrawingControlsPanel({
    super.key,
    required this.selectedShape,
    required this.isShapeComplete,
    required this.isResizeMode,
    this.isMoveMode = false,
    required this.pointsLength,
    required this.widthText,
    required this.heightText,
    required this.radiusText,
    required this.sideMeasurementsLength,
    required this.isLoading,
    required this.onUndo,
    required this.onCalculate,
    required this.onClear,
    this.onCompletePolygon,
    this.onCancelResize,
    this.onApplyResize,
    this.onToggleResizeMode,
    this.onToggleMoveMode,
    this.onWidthChanged,
    this.onHeightChanged,
    this.onRadiusChanged,
    this.onConfirmMove,
    this.onCancelMove,
    this.onConfigureMove,
    this.moveX = 0.0,
    this.moveY = 0.0,
    this.moveRange = 5.0,
    this.onMoveXChanged,
    this.onMoveYChanged,
    this.onMoveRangeChanged,
    this.selectedResizeIndices = const {},
    this.onTogglePointSelection,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
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
          DrawingStatsDisplay(
            pointsLength: pointsLength,
            selectedShape: selectedShape,
            widthText: widthText,
            heightText: heightText,
            radiusText: radiusText,
            sideMeasurementsLength: sideMeasurementsLength,
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (isResizeMode)
            _buildResizeModeButtons(loc)
          else if (isMoveMode)
            _buildMoveModeButtons(loc)
          else
            _buildNormalModeButtons(loc),
        ],
      ),
    );
  }

  Widget _buildMoveModeButtons(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Point Selection Chips
        Text(
          loc.selectCornerToMove,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(pointsLength, (index) {
              final isSelected = selectedResizeIndices.contains(index);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${index + 1}'),
                  selected: isSelected,
                  onSelected: (_) => onTogglePointSelection?.call(index),
                  selectedColor: Colors.green.withValues(alpha: 0.3),
                  checkmarkColor: Colors.green,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.green[900] : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Range Selector
        Row(
          children: [
            Text(
              loc.range,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            ...[1.0, 5.0, 10.0].map((range) {
              final isSelected = moveRange == range;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${range.toInt()}m'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onMoveRangeChanged?.call(range);
                  },
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  backgroundColor: Colors.grey[200],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),

        // X Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.horizontal),
            Text(
              '${moveX.toStringAsFixed(2)} m',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: moveX,
          min: -moveRange,
          max: moveRange,
          onChanged: onMoveXChanged,
          label: moveX.toStringAsFixed(2),
          activeColor: Colors.blue,
        ),

        // Y Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.vertical),
            Text(
              '${moveY.toStringAsFixed(2)} m',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: moveY,
          min: -moveRange,
          max: moveRange,
          onChanged: onMoveYChanged,
          label: moveY.toStringAsFixed(2),
          activeColor: Colors.blue,
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancelMove,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: Text(loc.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onConfirmMove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(loc.applyMove),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResizeModeButtons(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelResize,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onApplyResize,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(loc.applyResize),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalModeButtons(AppLocalizations loc) {
    return Column(
      spacing: 12,
      children: [
        // Primary Action Row
        Row(
          children: [
            // Undo Button
            Expanded(
              child: OutlinedButton(
                onPressed: pointsLength > 0 ? onUndo : null,
                child: const Icon(Icons.undo),
              ),
            ),
            const SizedBox(width: 8),
            // Calculate Area Button (Primary)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    isLoading ||
                        (selectedShape == ShapeType.polygon && !isShapeComplete)
                    ? null
                    : onCalculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isLoading
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
                onPressed: pointsLength > 0 ? onClear : null,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Icon(Icons.clear),
              ),
            ),
          ],
        ),
        // Complete Polygon Button (if needed)
        if (selectedShape == ShapeType.polygon &&
            pointsLength >= 3 &&
            !isShapeComplete &&
            onCompletePolygon != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCompletePolygon,
              icon: const Icon(Icons.check_circle),
              label: Text(loc.completePolygon),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }
}
