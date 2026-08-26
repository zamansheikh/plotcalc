import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../l10n/l10n.dart';

class FilterSheetResult {
  final PlotTag? tag; // null = "All"
  const FilterSheetResult(this.tag);
}

Future<FilterSheetResult?> showFilterSheet(
  BuildContext context, {
  required PlotTag? current,
  required Map<PlotTag?, int> counts,
  required Color accent,
}) {
  return showModalBottomSheet<FilterSheetResult>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => _FilterSheet(
      current: current,
      counts: counts,
      accent: accent,
    ),
  );
}

class _FilterSheet extends StatelessWidget {
  final PlotTag? current;
  final Map<PlotTag?, int> counts;
  final Color accent;
  const _FilterSheet({
    required this.current,
    required this.counts,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.filterTitle,
              style: AppTypography.sans(size: 18, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _Row(
              label: context.l10n.filterAllPlots,
              count: counts[null] ?? 0,
              active: current == null,
              accent: accent,
              onTap: () =>
                  Navigator.of(context).pop(const FilterSheetResult(null)),
            ),
            const Divider(height: 1, color: AppColors.line),
            for (var i = 0; i < PlotTag.values.length; i++) ...[
              _Row(
                label: PlotTag.values[i].labelOf(context.l10n),
                count: counts[PlotTag.values[i]] ?? 0,
                active: PlotTag.values[i] == current,
                accent: accent,
                onTap: () => Navigator.of(context).pop(
                  FilterSheetResult(PlotTag.values[i]),
                ),
              ),
              if (i < PlotTag.values.length - 1)
                const Divider(height: 1, color: AppColors.line),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _Row({
    required this.label,
    required this.count,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.sans(
                  size: 14,
                  weight: FontWeight.w500,
                  color: active ? accent : AppColors.text,
                ),
              ),
            ),
            Text(
              '$count',
              style: AppTypography.mono(
                size: 12,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              active ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: active ? accent : AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
