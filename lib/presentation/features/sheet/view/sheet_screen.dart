import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/export/plot_export.dart';
import '../../../../core/export/sheet_summary.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/entities/plot_sheet.dart';
import '../../../../domain/usecases/delete_sheet.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../../domain/usecases/get_sheets.dart';
import '../../../../domain/usecases/save_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/area_breakdown_view.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../result/view/result_screen.dart' show ResultArgs;
import 'sheet_canvas.dart';
import 'sheet_dialogs.dart';

/// Asks for a name, saves a new sheet holding [plotIds] and opens it.
/// Returns false if the user cancelled.
Future<bool> createSheet(BuildContext context, List<String> plotIds) async {
  final accent = context.read<SettingsBloc>().state.accent;
  final t = context.l10n;
  final count = (await sl<GetSheets>()()).length;
  if (!context.mounted) return false;
  final name = await showSheetNameDialog(
    context,
    initial: t.sheetDefaultName(
      NumberFormat.decimalPattern().format(count + 1),
    ),
    accent: accent,
  );
  if (name == null || !context.mounted) return false;
  final sheet = PlotSheet(
    id: const Uuid().v4(),
    name: name,
    plotIds: plotIds,
    createdAt: DateTime.now(),
  );
  await sl<SaveSheet>()(sheet);
  if (context.mounted) context.push(AppRoutes.sheet, extra: sheet.id);
  return true;
}

/// Runs a sheet action picked from its menu. Shared by this screen and the
/// sheet list in History. Returns true when the sheet was deleted.
Future<bool> runSheetAction(
  BuildContext context,
  SheetAction action,
  PlotSheet sheet,
) async {
  final t = context.l10n;
  final settings = context.read<SettingsBloc>().state;
  final messenger = ScaffoldMessenger.of(context);
  switch (action) {
    case SheetAction.shareText:
    case SheetAction.pdf:
      try {
        final summary = SheetSummary.of(
          sheet,
          await sl<GetPlots>()(),
          fallbackUnit: settings.areaUnit,
          breakdown: settings.breakdown,
        );
        if (action == SheetAction.pdf) {
          await PlotExport.shareSheetPdf(
            summary,
            t,
            layout: sheet.layout,
            lengthUnit: settings.lengthUnit,
          );
        } else {
          await PlotExport.shareSheet(summary, t);
        }
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(t.exportFailed)));
      }
      return false;
    case SheetAction.rename:
      final name = await showSheetNameDialog(
        context,
        initial: sheet.name,
        accent: settings.accent,
      );
      if (name != null && name != sheet.name) {
        await sl<SaveSheet>()(sheet.copyWith(name: name));
      }
      return false;
    case SheetAction.delete:
      final ok = await _confirmDelete(context, sheet.name);
      if (ok) await sl<DeleteSheet>()(sheet.id);
      return ok;
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final t = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        t.sheetDeleteTitle,
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Text(
        t.sheetDeleteBody(name),
        style: AppTypography.sans(size: 13, color: AppColors.textDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: Text(
            t.actionCancel,
            style: AppTypography.sans(size: 13, color: AppColors.textDim),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(c).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.text,
          ),
          child: Text(
            t.actionDelete,
            style: AppTypography.sans(size: 13, weight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A group of saved plots with their total area and, once a price is
/// entered, their total value.
class SheetScreen extends StatefulWidget {
  final String sheetId;
  const SheetScreen({super.key, required this.sheetId});

  @override
  State<SheetScreen> createState() => _SheetScreenState();
}

class _SheetScreenState extends State<SheetScreen> {
  PlotSheet? _sheet;
  List<Plot>? _plots;
  bool _gone = false;
  StreamSubscription? _sheetSub;
  StreamSubscription? _plotSub;
  final _price = TextEditingController();
  bool _priceFilled = false;

  @override
  void initState() {
    super.initState();
    _sheetSub = sl<GetSheets>().watch().listen((all) {
      final s = all.where((s) => s.id == widget.sheetId).firstOrNull;
      if (!mounted || _gone) return;
      if (s == null) {
        // Deleted, from this screen's menu or from History: leave once.
        _gone = true;
        if (context.canPop()) context.pop();
        return;
      }
      setState(() => _sheet = s);
      // Filled once: rewriting it on every save would move the cursor
      // while the user is typing.
      if (!_priceFilled) {
        _priceFilled = true;
        final p = s.pricePerUnit;
        _price.text = p == null
            ? ''
            : (p == p.roundToDouble() ? p.toStringAsFixed(0) : '$p');
      }
    });
    _plotSub = sl<GetPlots>().watch().listen((all) {
      if (mounted) setState(() => _plots = all);
    });
  }

  @override
  void dispose() {
    _sheetSub?.cancel();
    _plotSub?.cancel();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save(PlotSheet next) => sl<SaveSheet>()(next);

  void _onPriceChanged(String raw) {
    final sheet = _sheet;
    if (sheet == null) return;
    final v = SheetSummary.parseAmount(raw);
    _save(
      v == null || v <= 0
          ? sheet.copyWith(clearPrice: true)
          : sheet.copyWith(pricePerUnit: v),
    );
  }

  Future<void> _pickUnit() async {
    final sheet = _sheet!;
    final picked = await showUnitPicker(
      context,
      title: context.l10n.sheetUnitTitle,
      current: sheet.unit,
      accent: context.read<SettingsBloc>().state.accent,
      allowFollow: true,
    );
    if (picked == null) return;
    await _save(
      picked.unit == null
          ? sheet.copyWith(clearUnit: true)
          : sheet.copyWith(unit: picked.unit),
    );
  }

  Future<void> _pickPriceUnit() async {
    final sheet = _sheet!;
    final picked = await showUnitPicker(
      context,
      title: context.l10n.sheetPriceUnitTitle,
      current: sheet.priceUnit,
      accent: context.read<SettingsBloc>().state.accent,
    );
    if (picked?.unit == null) return;
    await _save(sheet.copyWith(priceUnit: picked!.unit));
  }

  Future<void> _addPlots(SheetSummary summary) async {
    final sheet = _sheet!;
    final inSheet = sheet.plotIds.toSet();
    final ids = await showAddPlotsSheet(
      context,
      candidates: [
        for (final p in _plots ?? const <Plot>[])
          if (!inSheet.contains(p.id)) p,
      ],
      unit: summary.unit,
      accent: context.read<SettingsBloc>().state.accent,
    );
    if (ids == null || ids.isEmpty) return;
    await _save(sheet.copyWith(plotIds: [...sheet.plotIds, ...ids]));
  }

  Future<void> _remove(SheetRow row) async {
    final before = _sheet!;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.l10n;
    await _save(
      before.copyWith(plotIds: [...before.plotIds]..remove(row.plotId)),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(t.sheetPlotRemoved(row.name)),
          action: SnackBarAction(
            label: t.actionUndo,
            onPressed: () {
              // Put it back where it was, on top of any other edits since.
              final now = _sheet;
              if (now == null || now.plotIds.contains(row.plotId)) return;
              final at = before.plotIds.indexOf(row.plotId);
              final ids = [...now.plotIds]
                ..insert(at.clamp(0, now.plotIds.length), row.plotId);
              _save(now.copyWith(plotIds: ids));
            },
          ),
        ),
      );
  }

  Future<void> _menu() async {
    final sheet = _sheet;
    if (sheet == null) return;
    final action = await showSheetActions(context, sheet: sheet);
    if (action == null || !mounted) return;
    // A delete closes this screen through the sheet listener.
    await runSheetAction(context, action, sheet);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final sheet = _sheet;
    final plots = _plots;

    if (sheet == null || plots == null) {
      return const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(child: CircularProgressIndicator(color: AppColors.lime)),
      );
    }

    final t = context.l10n;
    final s = SheetSummary.of(
      sheet,
      plots,
      fallbackUnit: settings.areaUnit,
      breakdown: settings.breakdown,
    );

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Row(
                children: [
                  SmallIconButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.sheetTitle.toUpperCase(),
                          style: AppTypography.mono(
                            size: 9,
                            color: AppColors.textFaint,
                            letterSpacing: 1.3,
                          ),
                        ),
                        Text(
                          sheet.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            size: 15,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SmallIconButton(
                    icon: Icons.picture_as_pdf_outlined,
                    onTap: () =>
                        runSheetAction(context, SheetAction.pdf, sheet),
                  ),
                  const SizedBox(width: 6),
                  SmallIconButton(icon: Icons.more_horiz, onTap: _menu),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _TotalCard(summary: s, accent: accent, onUnit: _pickUnit),
                  const SizedBox(height: 8),
                  AreaBreakdownView(sqm: s.totalSqm),
                  const SizedBox(height: 8),
                  _PriceCard(
                    summary: s,
                    controller: _price,
                    accent: accent,
                    onChanged: _onPriceChanged,
                    onUnit: _pickPriceUnit,
                  ),
                  if (s.rows.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LayoutCard(
                      items: canvasItemsOf(s, sheet.layout, t),
                      accent: accent,
                      onOpen: () {
                        // Otherwise the price field takes focus back, and
                        // opens the keyboard, on return.
                        FocusScope.of(context).unfocus();
                        context.push(AppRoutes.sheetArrange, extra: sheet.id);
                      },
                    ),
                  ],
                  if (s.missing > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      t.sheetMissing(s.missing),
                      style: AppTypography.sans(
                        size: 12,
                        color: AppColors.amber,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.sheetPlotsHeader,
                          style: AppTypography.monoLabel,
                        ),
                      ),
                      InkWell(
                        onTap: () => _addPlots(s),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 15, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                t.sheetAddPlots,
                                style: AppTypography.mono(
                                  size: 11,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (s.rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        t.sheetEmpty,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyDim,
                      ),
                    ),
                  for (var i = 0; i < s.rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _RowTile(
                      index: i,
                      row: s.rows[i],
                      summary: s,
                      accent: accent,
                      onRemove: () => _remove(s.rows[i]),
                      onOpen: () {
                        FocusScope.of(context).unfocus();
                        final plot = plots.firstWhere(
                          (p) => p.id == s.rows[i].plotId,
                        );
                        context.push(
                          AppRoutes.result,
                          extra: ResultArgs(
                            name: plot.name,
                            vertices: plot.vertices,
                            unit: plot.preferredUnit,
                            plotId: plot.id,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final SheetSummary summary;
  final Color accent;
  final VoidCallback onUnit;
  const _TotalCard({
    required this.summary,
    required this.accent,
    required this.onUnit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final s = summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.lineMid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.sheetTotalLabel, style: AppTypography.monoLabel),
              ),
              Text(
                t.sheetCount(s.rows.length),
                style: AppTypography.mono(size: 10, color: AppColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.unit.format(s.totalSqm),
                    style: AppTypography.mono(
                      size: 34,
                      weight: FontWeight.w600,
                      color: accent,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onUnit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lineMid),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.unit.labelOf(t),
                        style: AppTypography.sans(size: 13),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: AppColors.textDim,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (s.hasPrice) ...[
            const SizedBox(height: 10),
            Text(
              '${t.sheetTotalValue}: ${SheetSummary.money(s.totalValue!)}',
              style: AppTypography.sans(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The arrangement at a glance, with the way into the canvas editor.
class _LayoutCard extends StatelessWidget {
  final List<CanvasItem> items;
  final Color accent;
  final VoidCallback onOpen;
  const _LayoutCard({
    required this.items,
    required this.accent,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                    t.sheetLayoutHeader,
                    style: AppTypography.monoLabel,
                  ),
                ),
                Icon(Icons.open_with, size: 14, color: accent),
                const SizedBox(width: 5),
                Text(
                  t.sheetArrange,
                  style: AppTypography.mono(size: 11, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 180,
                color: AppColors.ink,
                child: SheetLayoutPreview(
                  items: items,
                  accent: accent,
                  meterLabel: t.unitMeterShort,
                  lengthUnit: settings.lengthUnit,
                  lengthLabel: settings.lengthUnit.labelOf(t),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final SheetSummary summary;
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  final VoidCallback onUnit;
  const _PriceCard({
    required this.summary,
    required this.controller,
    required this.accent,
    required this.onChanged,
    required this.onUnit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final s = summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.sheetPriceLabel, style: AppTypography.monoLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '৳',
                style: AppTypography.sans(size: 20, color: AppColors.textDim),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.,]')),
                  ],
                  cursorColor: accent,
                  style: AppTypography.mono(
                    size: 22,
                    weight: FontWeight.w500,
                    color: accent,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: AppTypography.mono(
                      size: 22,
                      color: AppColors.textFaint,
                    ),
                  ),
                  onChanged: onChanged,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
              InkWell(
                onTap: onUnit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lineMid),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.sheetPricePer(s.priceUnit.labelOf(t)),
                        style: AppTypography.sans(size: 12),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: AppColors.textDim,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final int index;
  final SheetRow row;
  final SheetSummary summary;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onOpen;
  const _RowTile({
    required this.index,
    required this.row,
    required this.summary,
    required this.accent,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final s = summary;
    final color = Color(row.colorValue);
    final share = s.shareOf(row);
    final value = s.valueOf(row.areaSqm);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: PlotThumbnail(vertices: row.vertices, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.area(row.areaSqm, t)} · '
                    '${SheetSummary.percent(share)}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(size: 11, color: color),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      SheetSummary.money(value),
                      style: AppTypography.mono(
                        size: 11,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Share of the total, as a bar.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 3,
                      backgroundColor: AppColors.line,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.actionRemove,
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16, color: AppColors.textDim),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in History's Sheets tab.
class SheetTile extends StatelessWidget {
  final PlotSheet sheet;
  final List<Plot> plots;
  const SheetTile({super.key, required this.sheet, required this.plots});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final t = context.l10n;
    final s = SheetSummary.of(
      sheet,
      plots,
      fallbackUnit: settings.areaUnit,
      breakdown: settings.breakdown,
    );
    return InkWell(
      onTap: () => context.push(AppRoutes.sheet, extra: sheet.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _Stack(rows: s.rows),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheet.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.area(s.totalSqm, t),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(size: 11, color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      t.sheetCount(s.rows.length),
                      if (s.hasPrice) SheetSummary.money(s.totalValue!),
                    ].join(' · '),
                    style: AppTypography.mono(
                      size: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                final action = await showSheetActions(context, sheet: sheet);
                if (action != null && context.mounted) {
                  await runSheetAction(context, action, sheet);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three plot outlines, overlapped like a fanned stack of papers.
class _Stack extends StatelessWidget {
  final List<SheetRow> rows;
  const _Stack({required this.rows});

  @override
  Widget build(BuildContext context) {
    final shown = rows.take(3).toList();
    return SizedBox(
      width: 60,
      height: 54,
      child: Stack(
        children: [
          if (shown.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: const Center(
                child: Icon(
                  Icons.layers_outlined,
                  size: 18,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: i * 6.0,
              top: i * 5.0,
              right: (shown.length - 1 - i) * 6.0,
              bottom: (shown.length - 1 - i) * 5.0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.lineMid),
                ),
                child: PlotThumbnail(
                  vertices: shown[i].vertices,
                  color: Color(shown[i].colorValue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
