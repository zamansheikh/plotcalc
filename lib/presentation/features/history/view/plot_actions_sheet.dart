import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/plot.dart';

enum PlotAction { rename, delete }

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
              '${plot.tag.label} · ${plot.vertices.length} sides',
              style: AppTypography.mono(
                size: 11,
                color: AppColors.textDim,
              ),
            ),
            const SizedBox(height: 14),
            _ActionRow(
              icon: Icons.drive_file_rename_outline,
              label: 'Rename',
              color: AppColors.text,
              onTap: () => Navigator.of(context).pop(PlotAction.rename),
            ),
            const Divider(height: 1, color: AppColors.line),
            _ActionRow(
              icon: Icons.delete_outline,
              label: 'Delete',
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
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
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
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.sans(
                size: 14,
                weight: FontWeight.w500,
                color: color,
              ),
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
        'Rename plot',
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
            'Cancel',
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
            'Save',
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
        'Delete plot?',
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Text(
        '"$name" will be removed permanently.',
        style: AppTypography.sans(size: 13, color: AppColors.textDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancel',
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
            'Delete',
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
        'Clear all history?',
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Text(
        'All $count saved plot${count == 1 ? '' : 's'} will be removed '
        'permanently. This can\'t be undone.',
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
            'Cancel',
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
            'Clear all',
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
