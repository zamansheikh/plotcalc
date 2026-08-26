import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../l10n/l10n.dart';

enum PlotAction { rename, unit, delete }

Future<PlotAction?> showPlotActionsSheet(
  BuildContext context, {
  required Plot plot,
  required Color accent,
}) {
  return showModalBottomSheet<PlotAction>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => _ActionsSheet(plot: plot, accent: accent),
  );
}

class _ActionsSheet extends StatelessWidget {
  final Plot plot;
  final Color accent;
  const _ActionsSheet({required this.plot, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
              plot.name,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.plotTagSides(plot.tag.labelOf(context.l10n), plot.vertices.length),
              style: AppTypography.mono(
                size: 11,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 14),
            _ActionRow(
              icon: Icons.drive_file_rename_outline,
              label: context.l10n.actionRename,
              color: AppColors.text,
              onTap: () => Navigator.of(context).pop(PlotAction.rename),
            ),
            const Divider(height: 1, color: AppColors.line),
            _ActionRow(
              icon: Icons.straighten,
              label: context.l10n.plotDisplayUnit,
              color: AppColors.text,
              // Shows the override, or the app setting it currently follows.
              trailing: plot.preferredUnit?.labelOf(context.l10n) ??
                  context.l10n.plotUnitFollowsSettings,
              onTap: () => Navigator.of(context).pop(PlotAction.unit),
            ),
            const Divider(height: 1, color: AppColors.line),
            _ActionRow(
              icon: Icons.delete_outline,
              label: context.l10n.actionDelete,
              color: AppColors.danger,
              onTap: () => Navigator.of(context).pop(PlotAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? trailing;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.sans(
                  size: 14,
                  weight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.mono(
                  size: 11,
                  color: AppColors.textDim,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Picks the unit a saved plot is read in. `null` restores "follow the app
/// setting", which is what plots use until someone chooses otherwise.
Future<AreaUnit?> showPlotUnitSheet(
  BuildContext context, {
  required Plot plot,
  required Color accent,
}) {
  return showModalBottomSheet<AreaUnit?>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
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
              sheetContext.l10n.plotUnitTitle,
              style: AppTypography.sans(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _UnitOption(
              label: sheetContext.l10n.plotUnitFollowsSettings,
              active: plot.preferredUnit == null,
              accent: accent,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            const Divider(height: 1, color: AppColors.line),
            for (final u in AreaUnit.values) ...[
              _UnitOption(
                label: u.nameOf(sheetContext.l10n),
                trailing: u.labelOf(sheetContext.l10n),
                active: plot.preferredUnit == u,
                accent: accent,
                onTap: () => Navigator.of(sheetContext).pop(u),
              ),
              if (u != AreaUnit.values.last)
                const Divider(height: 1, color: AppColors.line),
            ],
          ],
        ),
      ),
    ),
  );
}

class _UnitOption extends StatelessWidget {
  final String label;
  final String? trailing;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _UnitOption({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: active ? accent : AppColors.textFaint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.sans(
                  size: 13,
                  color: active ? AppColors.text : AppColors.textDim,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.mono(size: 11, color: AppColors.textFaint),
              ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showRenameDialog(
  BuildContext context, {
  required String currentName,
  required Color accent,
}) {
  final controller = TextEditingController(text: currentName);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Text(
        context.l10n.plotRenameTitle,
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.ink,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: accent,
          textAlignVertical: TextAlignVertical.center,
          style: AppTypography.sans(size: 14),
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isNotEmpty) Navigator.of(dialogContext).pop(t);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            context.l10n.actionCancel,
            style: AppTypography.sans(size: 13, color: AppColors.textDim),
          ),
        ),
        FilledButton(
          onPressed: () {
            final t = controller.text.trim();
            if (t.isNotEmpty) Navigator.of(dialogContext).pop(t);
          },
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: AppColors.ink,
          ),
          child: Text(
            context.l10n.actionSave,
            style: AppTypography.sans(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool> showDeleteConfirm(
  BuildContext context, {
  required String name,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Text(
        context.l10n.plotDeleteTitle,
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Text(
        context.l10n.plotDeleteBody(name),
        style: AppTypography.sans(size: 13, color: AppColors.textDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            context.l10n.actionCancel,
            style: AppTypography.sans(size: 13, color: AppColors.textDim),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.text,
          ),
          child: Text(
            context.l10n.actionDelete,
            style: AppTypography.sans(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showClearAllConfirm(
  BuildContext context, {
  required int count,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Text(
        context.l10n.plotClearAllTitle,
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Text(
        context.l10n.plotClearAllBody(count),
        style: AppTypography.sans(
          size: 13,
          color: AppColors.textDim,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            context.l10n.actionCancel,
            style: AppTypography.sans(size: 13, color: AppColors.textDim),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.text,
          ),
          child: Text(
            context.l10n.plotClearAll,
            style: AppTypography.sans(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
