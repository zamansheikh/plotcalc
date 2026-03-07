import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_constants.dart';

class DrawingStatsDisplay extends StatelessWidget {
  final int pointsLength;
  final ShapeType selectedShape;
  final String widthText;
  final String heightText;
  final String radiusText;
  final int sideMeasurementsLength;

  const DrawingStatsDisplay({
    super.key,
    required this.pointsLength,
    required this.selectedShape,
    required this.widthText,
    required this.heightText,
    required this.radiusText,
    required this.sideMeasurementsLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(
            Icons.place_rounded,
            '$pointsLength',
            'Points',
            const Color(0xFF2E7D32),
          ),
          if (selectedShape == ShapeType.rectangle)
            _buildStatChip(
              Icons.straighten_rounded,
              '$widthText × $heightText',
              'W × H',
              const Color(0xFF1976D2),
            ),
          if (selectedShape == ShapeType.circle)
            _buildStatChip(
              Icons.circle_outlined,
              radiusText,
              'Radius',
              const Color(0xFF1976D2),
            ),
          if ((selectedShape == ShapeType.polygon ||
                  selectedShape == ShapeType.triangle) &&
              pointsLength >= 2)
            _buildStatChip(
              Icons.timeline_rounded,
              '${pointsLength >= 3 ? pointsLength : pointsLength - 1}',
              'Sides',
              const Color(0xFF1976D2),
            ),
          if (sideMeasurementsLength > 0)
            _buildStatChip(
              Icons.check_circle_outline_rounded,
              '$sideMeasurementsLength/${pointsLength >= 3 ? pointsLength : pointsLength - 1}',
              'Measured',
              sideMeasurementsLength >=
                      (pointsLength >= 3 ? pointsLength : pointsLength - 1)
                  ? const Color(0xFF388E3C)
                  : const Color(0xFFEF6C00),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
