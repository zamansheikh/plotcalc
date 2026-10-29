import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/export/division_pdf.dart';
import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/division_plan.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/lot_division.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/entities/plot_sheet.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../../domain/usecases/get_sheets.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../../shared/widgets/tab_header.dart';
import '../division_store.dart';
import 'division_canvas.dart';

/// One owner's row: its text fields outlive rebuilds, and its key outlives
/// reordering.
class _OwnerRow {
  final int key;
  final TextEditingController name;
  final TextEditingController amount;
  _OwnerRow(this.key, String name, String amount)
    : name = TextEditingController(text: name),
      amount = TextEditingController(text: amount);

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// Divide a plot among owners — equally, by share, or by area — with every
/// lot facing a chosen side, a common road kept out first if needed, each
/// lot's boundaries worked out, and the whole saved as a sheet that can be
/// opened and changed again.
///
/// The drawing is always the live result; the three tabs below it each ask
/// one plain question: who gets what, which side and road, and what bounds
/// each lot.
class SubdivideScreen extends StatefulWidget {
  /// A saved division to open again, by its sheet's id.
  final String? editSheetId;

  const SubdivideScreen({super.key, this.editSheetId});

  @override
  State<SubdivideScreen> createState() => _SubdivideScreenState();
}

class _SubdivideScreenState extends State<SubdivideScreen> {
  Plot? _plot;
  DivisionSpec? _spec;
  final List<_OwnerRow> _rows = [];
  int _nextKey = 0;
  int _tab = 0;
  PlotSheet? _editing;
  bool _loading = false;
  String? _error;
  bool _busy = false;
  bool _slid = false;

  @override
  void initState() {
    super.initState();
    if (widget.editSheetId != null) _loadEdit(widget.editSheetId!);
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEdit(String sheetId) async {
    setState(() => _loading = true);
    final sheet = await sl<GetSheets>().byId(sheetId);
    final spec = sheet?.division;
    final plots = await sl<GetPlots>()();
    if (!mounted) return;
    final t = context.l10n;
    final parent = spec == null
        ? null
        : plots.where((p) => p.id == spec.parentPlotId).firstOrNull;
    setState(() {
      _loading = false;
      if (sheet == null || spec == null || parent == null) {
        _error = t.divisionParentGone;
        return;
      }
      _editing = sheet;
      _start(parent, spec: spec);
    });
  }

  void _start(Plot p, {DivisionSpec? spec}) {
    for (final r in _rows) {
      r.dispose();
    }
    _rows.clear();
    _plot = p;
    _spec =
        spec ??
        DivisionSpec(
          parentPlotId: p.id,
          owners: const [DivisionOwner(), DivisionOwner()],
        );
    for (final o in _spec!.owners) {
      _rows.add(_newRow(o.name, o.amount));
    }
    _tab = 0;
    _slid = false;
  }

  _OwnerRow _newRow(String name, String amount) {
    final row = _OwnerRow(_nextKey++, name, amount);
    row.name.addListener(_sync);
    row.amount.addListener(_sync);
    return row;
  }

  /// Text fields are the source of truth for owners; this copies them into
  /// the spec whenever one changes.
  void _sync() {
    final spec = _spec;
    if (spec == null) return;
    final owners = [
      for (final r in _rows)
        DivisionOwner(name: r.name.text, amount: r.amount.text),
    ];
    setState(() => _spec = spec.copyWith(owners: owners));
  }

  void _update(DivisionSpec next) => setState(() => _spec = next);

  /// Owners added, removed or reordered: the dividers between them are new,
  /// so any turned by hand go back to following the front side.
  void _ownersChanged() {
    _spec = _spec!.copyWith(angles: const []);
    _sync();
  }

  void _addOwner({String amount = ''}) {
    _rows.add(_newRow('', amount));
    _ownersChanged();
  }

  void _removeOwner(int i) {
    if (_rows.length <= 1) return;
    _rows.removeAt(i).dispose();
    _ownersChanged();
  }

  void _reorder(int from, int to) {
    final row = _rows.removeAt(from);
    _rows.insert(to, row);
    _ownersChanged();
  }

  void _setMode(DivisionMode m) {
    final spec = _spec!;
    if (m == spec.mode) return;
    // A share means nothing as an area and the other way round.
    for (final r in _rows) {
      r.amount.removeListener(_sync);
      r.amount.text = '';
      r.amount.addListener(_sync);
    }
    _update(spec.copyWith(mode: m));
    _sync();
  }

  void _setAreaUnit(AreaUnit u) {
    final spec = _spec!;
    for (final r in _rows) {
      final v = ShareParser.number(r.amount.text);
      if (v == null) continue;
      r.amount.removeListener(_sync);
      r.amount.text = _plain(u.fromSqm(spec.areaUnit.toSqm(v)));
      r.amount.addListener(_sync);
    }
    _update(spec.copyWith(areaUnit: u));
    _sync();
  }

  void _tapSide(int side) {
    final spec = _spec!;
    HapticFeedback.selectionClick();
    _update(
      spec.frontSide == side
          ? spec.copyWith(clearFront: true, roadWidthM: 0, angles: const [])
          : spec.copyWith(frontSide: side, angles: const []),
    );
  }

  void _pivot(DivisionResult r, int index, bool firstEnd, Vertex to) {
    if (index >= r.cuts.length) return;
    final fixed = firstEnd ? r.cuts[index].b : r.cuts[index].a;
    final angle = LotDivision.angleAfterDrag(fixed, to);
    final spec = _spec!;
    final angles = List<double?>.of(spec.angles);
    while (angles.length <= index) {
      angles.add(null);
    }
    angles[index] = angle;
    _update(spec.copyWith(angles: angles));
  }

  void _slide(DivisionResult r, int index, Vertex to) {
    final spec = _spec!;
    final amounts = DivisionPlan.areasAfterSlide(spec, r, index, to);
    if (spec.mode != DivisionMode.areas) _slid = true;
    for (var i = 0; i < _rows.length && i < amounts.length; i++) {
      _rows[i].amount.removeListener(_sync);
      _rows[i].amount.text = amounts[i];
      _rows[i].amount.addListener(_sync);
    }
    _spec = spec.copyWith(mode: DivisionMode.areas);
    _sync();
  }

  void _dragEnded() {
    if (!_slid) return;
    _slid = false;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.divisionSlid)));
  }

  /// Gives the unassigned rest to a new owner.
  void _giveRest(DivisionResult r) {
    final spec = _spec!;
    if (spec.mode == DivisionMode.shares) {
      final used = spec.owners.fold<double>(
        0,
        (s, o) => s + (ShareParser.parse(o.amount)?.value ?? 0),
      );
      _addOwner(amount: _fraction(1 - used));
    } else {
      _addOwner();
    }
    setState(() => _tab = 0);
  }

  Future<void> _save(DivisionResult r) async {
    final plot = _plot, spec = _spec;
    if (plot == null || spec == null || _busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final t = context.l10n;
    final router = GoRouter.maybeOf(context);
    try {
      final sheet = await DivisionStore.save(
        parent: plot,
        spec: spec,
        result: r,
        t: t,
        existing: _editing,
      );
      if (!mounted) return;
      setState(() {
        _editing = sheet;
        _spec = sheet.division;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.divisionSaved),
            // Opened from its sheet, the sheet is right behind this screen.
            action: widget.editSheetId != null || router == null
                ? null
                : SnackBarAction(
                    label: t.divisionOpenSheet,
                    onPressed: () =>
                        router.push(AppRoutes.sheet, extra: sheet.id),
                  ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pdf(DivisionResult r) async {
    final plot = _plot, spec = _spec;
    if (plot == null || spec == null || _busy) return;
    final t = context.l10n;
    final settings = context.read<SettingsBloc>().state;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final names = DivisionNames(spec, t);
      final bytes = await DivisionPdf.build(
        t: t,
        plotName: plot.name,
        parent: plot.vertices,
        spec: spec,
        result: r,
        nameOf: names.of,
        areaUnit: plot.preferredUnit ?? settings.areaUnit,
        lengthUnit: settings.lengthUnit,
        breakdown: settings.breakdown,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'division.pdf');
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.exportFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _plain(double v) =>
      v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  /// A leftover share as people write it: a simple fraction when it is
  /// one, a decimal otherwise.
  static String _fraction(double v) {
    for (final d in const [2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 48, 64]) {
      final k = (v * d).round();
      if (k > 0 && (k / d - v).abs() < 1e-6) {
        final n = NumberFormat.decimalPattern();
        return '${n.format(k)}/${n.format(d)}';
      }
    }
    return v.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final edit = widget.editSheetId != null;
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    }
    if (_error != null) {
      return SafeArea(
        child: Column(
          children: [
            _EditBar(title: t.subdivideTitle),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyDim,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final plot = _plot;
    final spec = _spec;
    if (plot == null || spec == null) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Header(title: t.subdivideTitle, subtitle: t.subdivideSubtitle),
            Expanded(
              child: _PlotPicker(onSelect: (p) => setState(() => _start(p))),
            ),
          ],
        ),
      );
    }

    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final result = DivisionPlan.compute(spec, plot.vertices);
    final names = DivisionNames(spec, t);
    final areaUnit = plot.preferredUnit ?? settings.areaUnit;
    final canSave = result.ok && result.lots.isNotEmpty && !_busy;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => Column(
          children: [
            if (edit)
              _EditBar(
                title: t.subdivideTitle,
                subtitle: t.divisionPeople(plot.name, spec.owners.length),
              )
            else ...[
              const SizedBox(height: 8),
              _SelectedHeader(
                plot: plot,
                owners: spec.owners.length,
                onChange: () => setState(() {
                  _plot = null;
                  _spec = null;
                  _editing = null;
                }),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: math.min(300, box.maxHeight * 0.38),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DivisionCanvas(
                    parent: plot.vertices,
                    result: result,
                    frontSide: spec.frontSide,
                    nameOf: names.of,
                    lengthUnit: settings.lengthUnit,
                    lengthLabel: settings.lengthUnit.labelOf(t),
                    frontLabel: t.divisionFront,
                    northLabel: t.divisionNorth,
                    accent: accent,
                    onTapSide: _tapSide,
                    onPivot: (i, a, to) => _pivot(result, i, a, to),
                    onSlide: (i, to) => _slide(result, i, to),
                    onDragEnd: _dragEnded,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                t.divisionDragHint,
                maxLines: 2,
                style: AppTypography.sans(size: 11, color: AppColors.textFaint),
              ),
            ),
            _Tabs(
              index: _tab,
              accent: accent,
              labels: [
                t.divisionOwnersTab,
                t.divisionSidesTab,
                t.divisionBoundsTab,
              ],
              warn: [!result.ok || result.rest != null, false, false],
              onTap: (i) => setState(() => _tab = i),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _OwnersTab(
                  rows: _rows,
                  spec: spec,
                  result: result,
                  areaUnit: areaUnit,
                  accent: accent,
                  onMode: _setMode,
                  onAreaUnit: _setAreaUnit,
                  onAdd: () => _addOwner(),
                  onRemove: _removeOwner,
                  onReorder: _reorder,
                  onGiveRest: () => _giveRest(result),
                ),
                1 => _SidesTab(
                  parent: plot.vertices,
                  spec: spec,
                  accent: accent,
                  lengthUnit: settings.lengthUnit,
                  onFront: (s) => s == null
                      ? _update(
                          spec.copyWith(
                            clearFront: true,
                            roadWidthM: 0,
                            angles: const [],
                          ),
                        )
                      : _update(spec.copyWith(frontSide: s, angles: const [])),
                  onRoad: (w) => _update(spec.copyWith(roadWidthM: w)),
                  onStraighten: () => _update(spec.copyWith(angles: const [])),
                ),
                _ => _BoundsTab(
                  result: result,
                  names: names,
                  areaUnit: areaUnit,
                  lengthUnit: settings.lengthUnit,
                ),
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: canSave ? () => _pdf(result) : null,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(
                      t.resultExportPdf,
                      style: AppTypography.sans(size: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      disabledForegroundColor: AppColors.textFaint,
                      side: const BorderSide(color: AppColors.lineMid),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSave ? () => _save(result) : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.ink,
                        disabledBackgroundColor: AppColors.surface,
                        disabledForegroundColor: AppColors.textDim,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t.subdivideSaveAction,
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: canSave ? AppColors.ink : AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) =>
      TabHeader(title: title, subtitle: subtitle);
}

/// Header for the pushed "change a saved division" screen.
class _EditBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _EditBar({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    child: Row(
      children: [
        SmallIconButton(
          icon: Icons.chevron_left,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.sans(size: 15, weight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(size: 12, color: AppColors.textDim),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SelectedHeader extends StatelessWidget {
  final Plot plot;
  final int owners;
  final VoidCallback onChange;
  const _SelectedHeader({
    required this.plot,
    required this.owners,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      title: context.l10n.subdivideTitle,
      subtitle: context.l10n.divisionPeople(plot.name, owners),
      trailing: OutlinedButton.icon(
        onPressed: onChange,
        icon: const Icon(Icons.swap_horiz, size: 14),
        label: Text(
          context.l10n.actionChange,
          style: AppTypography.sans(size: 12, weight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final Color accent;
  final List<String> labels;
  final List<bool> warn;
  final ValueChanged<int> onTap;
  const _Tabs({
    required this.index,
    required this.accent,
    required this.labels,
    required this.warn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          labels[i],
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: index == i
                                ? AppColors.ink
                                : AppColors.textDim,
                          ),
                        ),
                      ),
                      if (warn[i]) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------ owners tab

String _issueText(AppLocalizations t, DivisionIssue i) => switch (i) {
  DivisionIssue.sharesOver => t.divisionIssueSharesOver,
  DivisionIssue.sharesMixed => t.divisionIssueSharesMixed,
  DivisionIssue.shareUnreadable => t.divisionIssueShareUnreadable,
  DivisionIssue.areasOver => t.divisionIssueAreasOver,
  DivisionIssue.areaUnreadable => t.divisionIssueAreaUnreadable,
  DivisionIssue.roadTooWide => t.divisionIssueRoadTooWide,
};

class _OwnersTab extends StatelessWidget {
  final List<_OwnerRow> rows;
  final DivisionSpec spec;
  final DivisionResult result;
  final AreaUnit areaUnit;
  final Color accent;
  final ValueChanged<DivisionMode> onMode;
  final ValueChanged<AreaUnit> onAreaUnit;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onReorder;
  final VoidCallback onGiveRest;

  const _OwnersTab({
    required this.rows,
    required this.spec,
    required this.result,
    required this.areaUnit,
    required this.accent,
    required this.onMode,
    required this.onAreaUnit,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    required this.onGiveRest,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final landSqm = Geometry.polygonArea(result.land);
    final modes = [
      (DivisionMode.equal, t.divisionModeEqual),
      (DivisionMode.shares, t.divisionModeShares),
      (DivisionMode.areas, t.divisionModeAreas),
    ];
    final header = Column(
      key: const ValueKey('owners-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.divisionHowLabel, style: AppTypography.monoLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final (m, label) in modes) ...[
              Expanded(
                child: ChoiceChip(
                  key: ValueKey('mode-${m.name}'),
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(label, textAlign: TextAlign.center),
                  ),
                  selected: spec.mode == m,
                  onSelected: (_) => onMode(m),
                  showCheckmark: false,
                  labelStyle: AppTypography.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: spec.mode == m ? AppColors.ink : AppColors.text,
                  ),
                  selectedColor: accent,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: spec.mode == m ? accent : AppColors.lineMid,
                  ),
                ),
              ),
              if (m != DivisionMode.areas) const SizedBox(width: 6),
            ],
          ],
        ),
        if (spec.mode != DivisionMode.equal) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  spec.mode == DivisionMode.shares
                      ? t.divisionShareHelp
                      : t.divisionAreaHelp,
                  style: AppTypography.sans(size: 12, color: AppColors.textDim),
                ),
              ),
              if (spec.mode == DivisionMode.areas)
                PopupMenuButton<AreaUnit>(
                  tooltip: t.settingsAreaUnit,
                  initialValue: spec.areaUnit,
                  onSelected: onAreaUnit,
                  color: AppColors.surface,
                  itemBuilder: (_) => [
                    for (final u in AreaUnit.values)
                      PopupMenuItem(value: u, child: Text(u.nameOf(t))),
                  ],
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
                          spec.areaUnit.labelOf(t),
                          style: AppTypography.sans(size: 12),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        for (final issue in result.issues)
          _Banner(text: _issueText(t, issue), colour: AppColors.danger),
        if (result.rest != null)
          _Banner(
            text: t.divisionRestNote(
              '${areaUnit.format(result.rest!.areaSqm)} ${areaUnit.labelOf(t)}',
            ),
            colour: AppColors.amber,
            action: t.divisionGiveRest,
            onAction: onGiveRest,
          ),
        const SizedBox(height: 8),
      ],
    );

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      buildDefaultDragHandles: false,
      header: header,
      footer: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TextButton.icon(
          key: const ValueKey('add-owner'),
          onPressed: onAdd,
          icon: Icon(Icons.person_add_alt_1_outlined, size: 18, color: accent),
          label: Text(
            t.divisionAddOwner,
            style: AppTypography.sans(
              size: 14,
              weight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
      ),
      itemCount: rows.length,
      onReorderItem: onReorder,
      itemBuilder: (context, i) {
        final row = rows[i];
        final piece = result.ofOwner(i);
        final colour = ownerColour(i);
        final summary = piece == null
            ? '—'
            : '${areaUnit.format(piece.areaSqm)} ${areaUnit.labelOf(t)} · '
                  '${SheetSummary.percent(landSqm == 0 ? 0 : piece.areaSqm / landSqm)}';
        return Padding(
          key: ValueKey('owner-${row.key}'),
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: AppColors.textFaint,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colour,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: ValueKey('owner-name-$i'),
                        controller: row.name,
                        cursorColor: accent,
                        textCapitalization: TextCapitalization.words,
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: t.subdivideLot(i + 1),
                          hintStyle: AppTypography.sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.textFaint,
                          ),
                        ),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: AppTypography.mono(size: 11, color: colour),
                      ),
                    ],
                  ),
                ),
                if (spec.mode != DivisionMode.equal)
                  SizedBox(
                    width: 112,
                    child: TextField(
                      key: ValueKey('owner-amount-$i'),
                      controller: row.amount,
                      textAlign: TextAlign.right,
                      cursorColor: accent,
                      keyboardType: spec.mode == DivisionMode.areas
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      style: AppTypography.mono(
                        size: 14,
                        weight: FontWeight.w600,
                        color: accent,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: spec.mode == DivisionMode.areas
                            ? t.divisionAreaHint
                            : t.divisionShareHint,
                        hintStyle: AppTypography.mono(
                          size: 11,
                          color: AppColors.textFaint,
                        ),
                        suffixText: spec.mode == DivisionMode.areas
                            ? spec.areaUnit.labelOf(t)
                            : null,
                        suffixStyle: AppTypography.mono(
                          size: 10,
                          color: AppColors.textFaint,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        filled: true,
                        fillColor: AppColors.ink,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accent),
                        ),
                      ),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                IconButton(
                  tooltip: t.subdivideRemoveLot,
                  onPressed: rows.length > 1 ? () => onRemove(i) : null,
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: rows.length > 1 ? AppColors.textDim : AppColors.line,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color colour;
  final String? action;
  final VoidCallback? onAction;
  const _Banner({
    required this.text,
    required this.colour,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        border: Border.all(color: colour.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colour),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.sans(size: 12, color: AppColors.text),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: AppTypography.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: colour,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------ sides tab

class _SidesTab extends StatefulWidget {
  final List<Vertex> parent;
  final DivisionSpec spec;
  final Color accent;
  final LengthUnit lengthUnit;
  final ValueChanged<int?> onFront;
  final ValueChanged<double> onRoad;
  final VoidCallback onStraighten;

  const _SidesTab({
    required this.parent,
    required this.spec,
    required this.accent,
    required this.lengthUnit,
    required this.onFront,
    required this.onRoad,
    required this.onStraighten,
  });

  @override
  State<_SidesTab> createState() => _SidesTabState();
}

class _SidesTabState extends State<_SidesTab> {
  late final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Widget _chip(String label, bool on, VoidCallback? onTap, {Key? key}) =>
      ChoiceChip(
        key: key,
        label: Text(label),
        selected: on,
        onSelected: onTap == null ? null : (_) => onTap(),
        showCheckmark: false,
        labelStyle: AppTypography.sans(
          size: 13,
          weight: FontWeight.w600,
          color: onTap == null
              ? AppColors.textFaint
              : (on ? AppColors.ink : AppColors.text),
        ),
        selectedColor: widget.accent,
        backgroundColor: AppColors.surface,
        disabledColor: AppColors.surface,
        side: BorderSide(color: on ? widget.accent : AppColors.lineMid),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final spec = widget.spec;
    final unit = widget.lengthUnit;
    final n = NumberFormat.decimalPattern();
    final p = widget.parent;
    final hasFront = spec.frontSide != null;
    final roadSteps = unit == LengthUnit.ft
        ? const <double>[4, 6, 8, 10, 12, 16]
        : const <double>[1, 1.5, 2, 2.5, 3, 4];
    final roadIn = unit.fromMeters(spec.roadWidthM);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(t.divisionFrontTitle, style: AppTypography.monoLabel),
        const SizedBox(height: 4),
        Text(
          t.divisionFrontHint,
          style: AppTypography.sans(size: 12, color: AppColors.textDim),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _chip(t.divisionFrontAny, !hasFront, () => widget.onFront(null)),
            for (var i = 0; i < p.length; i++)
              _chip(
                t.divisionSideN(
                  n.format(i + 1),
                  '${unit.format(Geometry.sideLength(p[i], p[(i + 1) % p.length]))} '
                  '${unit.labelOf(t)}',
                ),
                spec.frontSide == i,
                () => widget.onFront(i),
                key: ValueKey('side-$i'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(t.divisionRoadTitle, style: AppTypography.monoLabel),
        const SizedBox(height: 4),
        Text(
          hasFront ? t.divisionRoadHint : t.divisionRoadNeedsFront,
          style: AppTypography.sans(size: 12, color: AppColors.textDim),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _chip(
              t.divisionRoadNone,
              spec.roadWidthM == 0,
              hasFront ? () => widget.onRoad(0) : null,
            ),
            for (final w in roadSteps)
              _chip(
                '${n.format(w)} ${unit.labelOf(t)}',
                (roadIn - w).abs() < 1e-6,
                hasFront ? () => widget.onRoad(unit.toMeters(w)) : null,
                key: ValueKey('road-$w'),
              ),
            SizedBox(
              width: 90,
              child: TextField(
                key: const ValueKey('road-custom'),
                controller: _custom,
                enabled: hasFront,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                cursorColor: widget.accent,
                style: AppTypography.mono(size: 13, color: widget.accent),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: t.overlaySurveyOther,
                  suffixText: unit.labelOf(t),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onChanged: (raw) {
                  final v = ShareParser.number(raw);
                  if (v != null && v >= 0) widget.onRoad(unit.toMeters(v));
                },
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
          ],
        ),
        if (spec.angles.any((a) => a != null)) ...[
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: widget.onStraighten,
              icon: const Icon(Icons.straighten, size: 16),
              label: Text(t.divisionStraighten),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.lineMid),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ bounds tab

class _BoundsTab extends StatelessWidget {
  final DivisionResult result;
  final DivisionNames names;
  final AreaUnit areaUnit;
  final LengthUnit lengthUnit;
  const _BoundsTab({
    required this.result,
    required this.names,
    required this.areaUnit,
    required this.lengthUnit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final pieces = result.pieces;
    final polys = [for (final p in pieces) p.vertices];
    final lots = [
      for (var i = 0; i < pieces.length; i++)
        if (pieces[i].kind != PieceKind.road) i,
    ];
    if (lots.isEmpty) {
      return Center(
        child: Text(t.divisionBoundsEmpty, style: AppTypography.bodyDim),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: lots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, k) {
        final i = lots[k];
        final piece = pieces[i];
        final colour = pieceColour(piece);
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colour,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      names.of(piece),
                      style: AppTypography.sans(
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${areaUnit.format(piece.areaSqm)} ${areaUnit.labelOf(t)}',
                    style: AppTypography.mono(size: 12, color: colour),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final s in Chouhoddi.of(polys, i))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          DivisionPdf.cardinal(t, s.side),
                          style: AppTypography.sans(
                            size: 13,
                            color: AppColors.textDim,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: Text(
                          '${lengthUnit.format(s.lengthM)} ${lengthUnit.labelOf(t)}',
                          style: AppTypography.mono(size: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.neighbour == null
                              ? t.divisionOutside
                              : names.of(pieces[s.neighbour!]),
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            size: 13,
                            color: s.neighbour == null
                                ? AppColors.textFaint
                                : AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------ plot picker

class _PlotPicker extends StatefulWidget {
  final ValueChanged<Plot> onSelect;
  const _PlotPicker({required this.onSelect});

  @override
  State<_PlotPicker> createState() => _PlotPickerState();
}

class _PlotPickerState extends State<_PlotPicker> {
  late final Future<List<Plot>> _future = sl<GetPlots>()();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plot>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.lime),
          );
        }
        final plots = snap.data ?? const [];
        if (plots.isEmpty) {
          return _EmptyState();
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: plots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _PlotPickerTile(plot: plots[i], onTap: widget.onSelect),
        );
      },
    );
  }
}

class _PlotPickerTile extends StatelessWidget {
  final Plot plot;
  final ValueChanged<Plot> onTap;
  const _PlotPickerTile({required this.plot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(plot.colorValue);
    final areaSqm = Geometry.polygonArea(plot.vertices);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(plot),
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
              Container(
                width: 60,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: PlotThumbnail(vertices: plot.vertices, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.name,
                      style: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.subdivideMeta(
                        AreaUnit.sqft.format(areaSqm),
                        AreaUnit.sqft.labelOf(context.l10n),
                        plot.vertices.length,
                      ),
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        plot.tag.labelOf(context.l10n).toUpperCase(),
                        style: AppTypography.mono(
                          size: 9,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeDim,
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.call_split, size: 28, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.subdivideEmpty,
              style: AppTypography.sans(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.subdivideEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyDim,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.subdivideGoHome,
                style: AppTypography.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
