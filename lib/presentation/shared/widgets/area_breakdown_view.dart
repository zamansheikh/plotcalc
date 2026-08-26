import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Shows a copy affordance next to the section label. Only meaningful
  /// when [framed], since that is what draws the label.
  final bool copyable;

  const AreaBreakdownView({
    super.key,
    required this.sqm,
    this.framed = true,
    this.copyable = true,
  });

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
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.breakdownSectionLabel,
                  style: AppTypography.monoLabel,
                ),
              ),
              if (copyable && !breakdown.isEmpty)
                _CopyButton(
                  text: breakdown.parts
                      .map((p) => '${p.formatted} ${p.unit.labelOf(context.l10n)}')
                      .join(' · '),
                  accent: accent,
                ),
            ],
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

/// Copies the compound reading. Handy in the calculator, where the number
/// is usually on its way into a message or a deed.
class _CopyButton extends StatelessWidget {
  final String text;
  final Color accent;
  const _CopyButton({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final copied = context.l10n.copiedToClipboard;
        await Clipboard.setData(ClipboardData(text: text));
        messenger.showSnackBar(SnackBar(content: Text(copied)));
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_all_outlined, size: 13, color: accent),
            const SizedBox(width: 5),
            Text(
              context.l10n.actionCopy,
              style: AppTypography.mono(size: 10, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
