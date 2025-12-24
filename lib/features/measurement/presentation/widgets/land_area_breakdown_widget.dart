import 'package:flutter/material.dart';
import '../../../../core/utils/land_area_breakdown.dart';

class LandAreaBreakdownWidget extends StatelessWidget {
  final LandAreaResult result;

  const LandAreaBreakdownWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    if (result.breakdown.isEmpty && result.remainderSqFt <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkTheme
              ? [Colors.green.shade900, Colors.teal.shade900]
              : [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme ? Colors.green.shade800 : Colors.green.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Calculation Result',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkTheme
                  ? Colors.green.shade100
                  : Colors.green.shade800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
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
                      color: isDarkTheme ? Colors.white : Colors.green.shade900,
                    ),
                  ),
                  backgroundColor: isDarkTheme
                      ? Colors.green.shade800
                      : Colors.white,
                  elevation: 0,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          if (result.remainderSqFt > 0.01) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkTheme ? Colors.black26 : Colors.white54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+ ${result.remainderSqFt.toStringAsFixed(2)} sq.ft remainder',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkTheme
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
          if (result.lastUnitDecimal != null) ...[
            const SizedBox(height: 12),
            Text(
              'OR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkTheme
                    ? Colors.green.shade200
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '≈ ${result.lastUnitDecimal}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.green.shade900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
