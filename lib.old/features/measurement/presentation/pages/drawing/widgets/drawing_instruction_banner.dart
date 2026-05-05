import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/theme/app_theme.dart';

class DrawingInstructionBanner extends StatelessWidget {
  final ShapeType selectedShape;
  final bool isShapeComplete;
  final int pointsLength;

  const DrawingInstructionBanner({
    super.key,
    required this.selectedShape,
    required this.isShapeComplete,
    required this.pointsLength,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
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
    );
  }

  String _getInstructionText(AppLocalizations loc) {
    switch (selectedShape) {
      case ShapeType.rectangle:
        return '${loc.width} & ${loc.height} ${loc.sideLengthInMeters}';
      case ShapeType.circle:
        return '${loc.radius} ${loc.sideLengthInMeters}';
      case ShapeType.triangle:
        if (isShapeComplete) {
          return '${loc.triangle} ${loc.complete}! ${loc.calculate}';
        }
        return '${loc.tapToAdd3Points} ${loc.triangle}';
      case ShapeType.polygon:
        if (isShapeComplete) {
          return '${loc.polygon} ${loc.complete}! ${loc.calculate}';
        } else if (pointsLength >= 3) {
          return loc.tapCompleteToClose;
        }
        return loc.tapToAddPointsMin3;
    }
  }
}
