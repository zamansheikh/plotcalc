import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';

/// The way into measuring from a mouza map photo, shown on Home and on the
/// "measure a plot" screen.
class MouzaEntryCard extends StatelessWidget {
  final Color accent;
  const MouzaEntryCard({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return InkWell(
      onTap: () => context.push(AppRoutes.mouza),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.map_outlined, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.mouzaEntryTitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.mouzaEntrySub,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      size: 12,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: accent),
          ],
        ),
      ),
    );
  }
}
