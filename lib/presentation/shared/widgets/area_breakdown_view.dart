import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/area_breakdown.dart';
import '../../../l10n/l10n.dart';
import '../settings/settings_bloc.dart';

/// An area written the way a deed reads it: "1 bigha · 5 katha · 3.00 chatak".
///
/// Takes its unit selection from settings, so the same plot reads differently
/// for someone who works in acres than for someone who works in katha.
class AreaBreakdownView extends StatelessWidget {
  final double sqm;

  /// Renders on a card of its own. Off when the caller already provides one.
  final bool framed;

  const AreaBreakdownView({super.key, required this.sqm, this.framed = true});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final breakdown = AreaBreakdown.of(sqm, settings.breakdown);

    final body = breakdown.isEmpty
        ? Text(
            settings.breakdown.orderedEnabled.isEmpty
                ? context.l10n.breakdownEmpty
                : context.l10n.breakdownNone,
            style: AppTypography.sans(size: 12, color: AppColors.textDim),
          )
        : Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < breakdown.parts.length; i++) ...[
                if (i > 0)
                  Text(
                    '·',
                    style: AppTypography.mono(
                      size: 13,
                      color: AppColors.textFaint,
                    ),
                  ),
                _Term(part: breakdown.parts[i], accent: accent),
              ],
            ],
          );

    if (!framed) return body;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.breakdownSectionLabel,
            style: AppTypography.monoLabel,
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  final BreakdownPart part;
  final Color accent;
  const _Term({required this.part, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          part.formatted,
          style: AppTypography.mono(
            size: 17,
            weight: FontWeight.w600,
            color: accent,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          part.unit.labelOf(context.l10n),
          style: AppTypography.sans(size: 12, color: AppColors.textDim),
        ),
      ],
    );
  }
}
