import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/theme/app_theme.dart';
import 'drawing_stats_display.dart';

class DrawingControlsPanel extends StatelessWidget {
  final ShapeType selectedShape;
  final bool isShapeComplete;
  final bool isResizeMode;
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

  const DrawingControlsPanel({
    super.key,
    required this.selectedShape,
    required this.isShapeComplete,
    required this.isResizeMode,
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
          else
            _buildNormalModeButtons(loc),
        ],
      ),
    );
  }

  Widget _buildResizeModeButtons(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelResize,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
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
            child: const Text('Apply Resize'),
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
