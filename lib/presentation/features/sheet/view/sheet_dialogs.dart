import 'package:flutter/material.dart';

import '../../../../core/geometry/geometry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/entities/plot_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../history/view/plot_actions_sheet.dart';

enum SheetAction { shareText, pdf, rename, delete }

ShapeBorder get _sheetShape => const RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
);

Widget _grabber() => Center(
  child: Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.line,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

/// Share, rename and delete for one sheet.
Future<SheetAction?> showSheetActions(
  BuildContext context, {
  required PlotSheet sheet,
}) {
  return showModalBottomSheet<SheetAction>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: _sheetShape,
    builder: (c) {
      final t = c.l10n;
      Widget row(IconData icon, String label, SheetAction a, {Color? color}) =>
          InkWell(
            onTap: () => Navigator.of(c).pop(a),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color ?? AppColors.text),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: AppTypography.sans(
                      size: 14,
                      weight: FontWeight.w500,
                      color: color ?? AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          );
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              const SizedBox(height: 14),
              Text(
                sheet.name,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(size: 16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              row(Icons.ios_share, t.resultShare, SheetAction.shareText),
              const Divider(height: 1, color: AppColors.line),
              row(
                Icons.picture_as_pdf_outlined,
                t.resultExportPdf,
                SheetAction.pdf,
              ),
              const Divider(height: 1, color: AppColors.line),
              row(
                Icons.drive_file_rename_outline,
                t.actionRename,
                SheetAction.rename,
              ),
              const Divider(height: 1, color: AppColors.line),
              row(
                Icons.delete_outline,
                t.actionDelete,
                SheetAction.delete,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Picks an area unit. Returns null when dismissed; `(unit: null)` means
/// "follow the app setting", offered only when [allowFollow] is set.
Future<({AreaUnit? unit})?> showUnitPicker(
  BuildContext context, {
  required String title,
  required AreaUnit? current,
  required Color accent,
  bool allowFollow = false,
}) {
  return showModalBottomSheet<({AreaUnit? unit})>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    shape: _sheetShape,
    builder: (c) {
      final t = c.l10n;
      Widget option(String label, AreaUnit? u, {String? trailing}) {
        final active = current == u;
        return InkWell(
          onTap: () => Navigator.of(c).pop((unit: u)),
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
                    trailing,
                    style: AppTypography.mono(
                      size: 11,
                      color: AppColors.textFaint,
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTypography.sans(size: 16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (allowFollow) ...[
                        option(t.plotUnitFollowsSettings, null),
                        const Divider(height: 1, color: AppColors.line),
                      ],
                      for (final u in AreaUnit.values) ...[
                        option(u.nameOf(t), u, trailing: u.labelOf(t)),
                        if (u != AreaUnit.values.last)
                          const Divider(height: 1, color: AppColors.line),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Lets the user tick saved plots to add. Returns their ids, or null.
Future<List<String>?> showAddPlotsSheet(
  BuildContext context, {
  required List<Plot> candidates,
  required AreaUnit unit,
  required Color accent,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    shape: _sheetShape,
    builder: (_) =>
        _AddPlots(candidates: candidates, unit: unit, accent: accent),
  );
}

class _AddPlots extends StatefulWidget {
  final List<Plot> candidates;
  final AreaUnit unit;
  final Color accent;
  const _AddPlots({
    required this.candidates,
    required this.unit,
    required this.accent,
  });

  @override
  State<_AddPlots> createState() => _AddPlotsState();
}

class _AddPlotsState extends State<_AddPlots> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final accent = widget.accent;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            const SizedBox(height: 14),
            Text(
              t.sheetAddPlots,
              style: AppTypography.sans(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (widget.candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(t.sheetAllAdded, style: AppTypography.bodyDim),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.candidates.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.line),
                  itemBuilder: (_, i) {
                    final p = widget.candidates[i];
                    final on = _picked.contains(p.id);
                    final sqm = Geometry.polygonArea(p.vertices);
                    return InkWell(
                      onTap: () => setState(() {
                        if (!_picked.remove(p.id)) _picked.add(p.id);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              on
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: on ? accent : AppColors.textFaint,
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 36,
                              height: 30,
                              child: PlotThumbnail(
                                vertices: p.vertices,
                                color: Color(p.colorValue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sans(size: 13),
                              ),
                            ),
                            Text(
                              '${widget.unit.format(sqm)} '
                              '${widget.unit.labelOf(t)}',
                              style: AppTypography.mono(
                                size: 11,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_picked.toList()),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.ink,
                  disabledBackgroundColor: AppColors.surfaceHi,
                  disabledForegroundColor: AppColors.textDim,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _picked.isEmpty
                      ? t.sheetAddPlots
                      : '${t.sheetAddPlots} · ${_picked.length}',
                  style: AppTypography.sans(size: 14, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a sheet name, prefilled with [initial].
Future<String?> showSheetNameDialog(
  BuildContext context, {
  required String initial,
  required Color accent,
}) => showRenameDialog(
  context,
  currentName: initial,
  accent: accent,
  title: context.l10n.sheetNameTitle,
);
