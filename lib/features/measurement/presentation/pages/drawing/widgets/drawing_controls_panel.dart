import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/land_area_breakdown.dart';
import 'drawing_stats_display.dart';

class DrawingControlsPanel extends StatelessWidget {
  final ShapeType selectedShape;
  final bool isShapeComplete;
  final bool isResizeMode;
  final bool isAdjustMode;
  final int pointsLength;
  final String widthText;
  final String heightText;
  final String radiusText;
  final int sideMeasurementsLength;
  final bool isLoading;
  final double? adjustCurrentArea;
  final double? adjustTargetArea;
  final VoidCallback onUndo;
  final VoidCallback onCalculate;
  final VoidCallback onClear;
  final VoidCallback? onCompletePolygon;
  final VoidCallback? onCancelResize;
  final VoidCallback? onApplyResize;
  final VoidCallback? onToggleAdjustMode;
  final VoidCallback? onDoneAdjusting;
  final VoidCallback? onCancelAdjusting;
  final VoidCallback? onSetTargetArea;
  final ValueChanged<String>? onWidthChanged;
  final ValueChanged<String>? onHeightChanged;
  final ValueChanged<String>? onRadiusChanged;

  const DrawingControlsPanel({
    super.key,
    required this.selectedShape,
    required this.isShapeComplete,
    required this.isResizeMode,
    this.isAdjustMode = false,
    required this.pointsLength,
    required this.widthText,
    required this.heightText,
    required this.radiusText,
    required this.sideMeasurementsLength,
    required this.isLoading,
    this.adjustCurrentArea,
    this.adjustTargetArea,
    required this.onUndo,
    required this.onCalculate,
    required this.onClear,
    this.onCompletePolygon,
    this.onCancelResize,
    this.onApplyResize,
    this.onToggleAdjustMode,
    this.onDoneAdjusting,
    this.onCancelAdjusting,
    this.onSetTargetArea,
    this.onWidthChanged,
    this.onHeightChanged,
    this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Stats Row
          DrawingStatsDisplay(
            pointsLength: pointsLength,
            selectedShape: selectedShape,
            widthText: widthText,
            heightText: heightText,
            radiusText: radiusText,
            sideMeasurementsLength: sideMeasurementsLength,
          ),
          const SizedBox(height: 14),

          // Action Buttons
          if (isResizeMode)
            _buildResizeModeButtons(loc)
          else if (isAdjustMode)
            _buildAdjustModeButtons(loc)
          else
            _buildNormalModeButtons(loc),
        ],
      ),
    );
  }

  Widget _buildAdjustModeButtons(AppLocalizations loc) {
    return Builder(
      builder: (context) => Column(
        children: [
          // Area progress tracker
          if (adjustCurrentArea != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current area (clickable)
                  InkWell(
                    onTap: () => _showAreaDetailsPopup(
                      context,
                      loc,
                      adjustCurrentArea!,
                      loc.currentArea,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.square_foot,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${loc.currentArea}: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatAreaShatak(adjustCurrentArea!),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Target area & progress
                  if (adjustTargetArea != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showAreaDetailsPopup(
                        context,
                        loc,
                        adjustTargetArea!,
                        loc.targetArea,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${loc.targetArea}: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatAreaShatak(adjustTargetArea!),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (adjustCurrentArea! / adjustTargetArea!).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Difference text
                    Text(
                      _getDifferenceText(loc),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getProgressColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Instruction
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.deepPurple[700],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.tapPointToMove,
                    style: TextStyle(
                      color: Colors.deepPurple[800],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          // Row 1: Set Target Area (full width)
          OutlinedButton.icon(
            onPressed: onSetTargetArea,
            icon: Icon(
              Icons.track_changes,
              size: 18,
              color: adjustTargetArea != null
                  ? Colors.orange[700]
                  : Colors.grey[600],
            ),
            label: Text(
              adjustTargetArea != null ? loc.targetArea : loc.setTargetArea,
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[700],
              side: BorderSide(color: Colors.orange.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Cancel & Done Adjusting
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancelAdjusting,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.red[600],
                  ),
                  label: Text(loc.cancel, style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Done button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onDoneAdjusting,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(loc.adjustDone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const double _shatakSqFt = 435.6;

  String _formatAreaShatak(double sqMeters) {
    final sqFt = sqMeters * AppConstants.sqMeterToSqFeet;
    final shatak = sqFt / _shatakSqFt;
    return '${shatak.toStringAsFixed(2)} Shatak';
  }

  void _showAreaDetailsPopup(
    BuildContext context,
    AppLocalizations loc,
    double sqMeters,
    String title,
  ) {
    final sqFt = sqMeters * AppConstants.sqMeterToSqFeet;
    bool useMymensingh = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final units = <LandUnitDef>[
            if (useMymensingh) ...[
              LandUnitDef(
                id: 'bighaMymensingh',
                name: 'Bigha (Mymensingh)',
                sqftFactor: 56628.0,
              ),
              LandUnitDef(
                id: 'kathaMymensingh',
                name: 'Katha (Mymensingh)',
                sqftFactor: 2831.4,
              ),
            ] else ...[
              LandUnitDef(id: 'acre', name: 'Acre', sqftFactor: 43560.0),
              LandUnitDef(
                id: 'bigha',
                name: 'Bigha (Standard)',
                sqftFactor: 14520.0,
              ),
              LandUnitDef(
                id: 'katha',
                name: 'Katha (Standard)',
                sqftFactor: 721.46,
              ),
            ],
            LandUnitDef(id: 'shatak', name: 'Shatak', sqftFactor: 435.6),
            LandUnitDef(id: 'chotak', name: 'Chotak', sqftFactor: 45.09),
          ];
          final result = LandAreaCalculator.calculate(sqFt, units);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary Shatak value
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatAreaShatak(sqMeters),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),

                // Mymensingh toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setStateDialog(() {
                            useMymensingh = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !useMymensingh
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              loc.standardUnits,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !useMymensingh
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setStateDialog(() {
                            useMymensingh = true;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: useMymensingh
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              loc.mymensinghUnits,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: useMymensingh
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
                const SizedBox(height: 14),

                // Breakdown chips
                if (result.breakdown.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: result.breakdown.map((part) {
                      return Chip(
                        label: Text(
                          part,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: useMymensingh
                                ? Colors.deepPurple.shade900
                                : Colors.blue.shade900,
                          ),
                        ),
                        backgroundColor: useMymensingh
                            ? Colors.deepPurple.shade50
                            : Colors.blue.shade50,
                        elevation: 0,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  ),

                if (result.remainderSqFt > 0.01) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${result.remainderSqFt.toStringAsFixed(2)} sq.ft remainder',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],

                if (result.lastUnitDecimal != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '≈ ${result.lastUnitDecimal}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: useMymensingh
                          ? Colors.deepPurple[800]
                          : Colors.blue[800],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Sq ft / m² info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sqFt.toStringAsFixed(1)} sq ft  •  ${sqMeters.toStringAsFixed(2)} m²',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.ok),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getProgressColor() {
    if (adjustTargetArea == null || adjustCurrentArea == null) {
      return Colors.grey;
    }
    final ratio = adjustCurrentArea! / adjustTargetArea!;
    if (ratio >= 0.99 && ratio <= 1.01) return Colors.green;
    if (ratio >= 0.95 && ratio <= 1.05) return Colors.orange;
    return Colors.red;
  }

  String _getDifferenceText(AppLocalizations loc) {
    if (adjustTargetArea == null || adjustCurrentArea == null) return '';
    final diff = adjustTargetArea! - adjustCurrentArea!;
    final absDiff = diff.abs();
    final displayDiff = _formatAreaShatak(absDiff);

    if (diff.abs() / adjustTargetArea! < 0.01) {
      return '✓ ${loc.targetReached}';
    } else if (diff > 0) {
      return '${loc.remaining}: $displayDiff';
    } else {
      return '${loc.exceeded}: $displayDiff';
    }
  }

  Widget _buildResizeModeButtons(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelResize,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(loc.applyResize),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalModeButtons(AppLocalizations loc) {
    return Column(
      children: [
        // Primary Action Row
        Row(
          children: [
            // Undo Button
            _buildIconButton(
              icon: Icons.undo_rounded,
              onPressed: pointsLength > 0 ? onUndo : null,
              tooltip: loc.undo,
            ),
            const SizedBox(width: 8),
            // Calculate Area Button (Primary)
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ||
                        (selectedShape == ShapeType.polygon && !isShapeComplete)
                    ? null
                    : onCalculate,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate_rounded, size: 20),
                label: Text(loc.calculate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Clear Button
            _buildIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: pointsLength > 0 ? onClear : null,
              color: Colors.red,
              tooltip: loc.clear,
            ),
          ],
        ),

        // Complete Polygon Button (if needed)
        if (selectedShape == ShapeType.polygon &&
            pointsLength >= 3 &&
            !isShapeComplete &&
            onCompletePolygon != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCompletePolygon,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(loc.completePolygon),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // Adjust Land Button (for completed shapes)
        if (isShapeComplete &&
            pointsLength >= 3 &&
            onToggleAdjustMode != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onToggleAdjustMode,
              icon: const Icon(Icons.open_with_rounded, size: 20),
              label: Text(loc.adjustMode),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple[700],
                side: BorderSide(color: Colors.deepPurple.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    String? tooltip,
  }) {
    return SizedBox(
      height: 48,
      width: 48,
      child: IconButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: color ?? Colors.grey[700],
          side: BorderSide(
            color: onPressed != null
                ? (color?.withValues(alpha: 0.3) ?? Colors.grey.shade300)
                : Colors.grey.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        tooltip: tooltip,
      ),
    );
  }
}
