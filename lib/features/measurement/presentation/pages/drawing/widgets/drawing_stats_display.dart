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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Points', '$pointsLength', Icons.place),
        if (selectedShape == ShapeType.rectangle)
          _buildStatItem('W × H', '$widthText × $heightText', Icons.straighten),
        if (selectedShape == ShapeType.circle)
          _buildStatItem('Radius', radiusText, Icons.circle_outlined),
        if ((selectedShape == ShapeType.polygon ||
                selectedShape == ShapeType.triangle) &&
            pointsLength >= 2)
          _buildStatItem(
            'Sides',
            '${pointsLength >= 3 ? pointsLength : pointsLength - 1}',
            Icons.timeline,
          ),
        if (sideMeasurementsLength > 0)
          _buildStatItem(
            'Measured',
            '$sideMeasurementsLength/${pointsLength >= 3 ? pointsLength : pointsLength - 1}',
            Icons.check_circle_outline,
          ),
      ],
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
}
