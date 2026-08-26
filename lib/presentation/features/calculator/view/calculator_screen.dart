import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_breakdown.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/area_breakdown_view.dart';
import '../../../shared/widgets/unit_input.dart';

/// How the running total is being entered.
enum _Entry {
  /// One number in one unit.
  total,

  /// A value per unit — effectively an editable breakdown.
  parts,
}

/// Working surface for land arithmetic: hold a running total, read it as a
/// compound breakdown, and add to or subtract from it in any unit.
///
/// Distinct from the converter, which only restates one value in every unit.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  /// Square metres is the canonical store. Every field is a view of it, so
  /// switching units restates the same area rather than reinterpreting the
  /// digits the user typed.
  double _totalSqm = 0;
  AreaUnit _totalUnit = AreaUnit.katha;

  _Entry _entry = _Entry.total;

  final _totalCtrl = TextEditingController();
  final _parts = <AreaUnit, TextEditingController>{};

  /// Until the user picks an adjust unit explicitly, it follows the total's
  /// unit — adding to a total you are reading in katha almost always means
  /// adding katha, and one fewer decision is one fewer tap.
  AreaUnit? _adjustUnitOverride;
  final _adjustCtrl = TextEditingController();
  String? _adjustError;

  @override
  void dispose() {
    _totalCtrl.dispose();
    _adjustCtrl.dispose();
    for (final c in _parts.values) {
      c.dispose();
    }
    super.dispose();
  }

  AreaUnit get _adjustUnit => _adjustUnitOverride ?? _totalUnit;

  TextEditingController _partCtrl(AreaUnit u) =>
      _parts.putIfAbsent(u, TextEditingController.new);

  /// Trailing zeros make a running total hard to scan.
  String _pretty(double v) {
    if (v == 0) return '';
    if (v == v.roundToDouble() && v.abs() < 1e9) return v.toStringAsFixed(0);
    return v
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _setTotal(double sqm) {
    setState(() {
      _totalSqm = sqm < 0 ? 0 : sqm;
      _totalCtrl.text = _pretty(_totalUnit.fromSqm(_totalSqm));
    });
  }

  /// Fills the per-unit fields from the current total, so switching to
  /// "By unit" starts from what is already on screen instead of blank.
  void _seedParts(BreakdownConfig config) {
    final breakdown = AreaBreakdown.of(_totalSqm, config);
    final byUnit = {for (final p in breakdown.parts) p.unit: p.value};
    for (final u in config.orderedEnabled) {
      _partCtrl(u).text = _pretty(byUnit[u] ?? 0);
    }
  }

  void _recomputeFromParts(List<AreaUnit> units) {
    var sum = 0.0;
    for (final u in units) {
      final v = double.tryParse(_partCtrl(u).text.replaceAll(',', '').trim());
      if (v != null && v > 0) sum += u.toSqm(v);
    }
    setState(() {
      _totalSqm = sum;
      _totalCtrl.text = _pretty(_totalUnit.fromSqm(sum));
    });
  }

  void _applyAdjustment({required bool adds}) {
    final v = double.tryParse(_adjustCtrl.text.replaceAll(',', '').trim());
    if (v == null || v <= 0) return;
    final delta = _adjustUnit.toSqm(v);
    final next = adds ? _totalSqm + delta : _totalSqm - delta;
    if (next < 0) {
      setState(() => _adjustError = context.l10n.calcCannotGoNegative);
      return;
    }
    setState(() => _adjustError = null);
    _setTotal(next);
    _adjustCtrl.clear();
    if (_entry == _Entry.parts) {
      _seedParts(context.read<SettingsBloc>().state.breakdown);
    }
  }

  void _clear() {
    _adjustCtrl.clear();
    for (final c in _parts.values) {
      c.clear();
    }
    setState(() => _adjustError = null);
    _setTotal(0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final units = settings.breakdown.orderedEnabled;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ToolHeader(
              title: context.l10n.calcTitle,
              subtitle: context.l10n.calcSubtitle,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              trailing: _totalSqm > 0
                  ? _ClearButton(onTap: _clear)
                  : null,
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _entryCard(accent, units, settings.breakdown),
                  const SizedBox(height: 18),
                  // Framed, so the breakdown brings its own label plus the
                  // Copy and Units shortcuts — the same card the result
                  // screen shows.
                  if (_totalSqm > 0)
                    AreaBreakdownView(sqm: _totalSqm)
                  else ...[
                    _sectionLabel(context.l10n.calcResultLabel),
                    const SizedBox(height: 8),
                    _card(
                      child: Text(
                        context.l10n.calcEmpty,
                        style: AppTypography.sans(
                          size: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _sectionLabel(context.l10n.calcAdjustLabel),
                  const SizedBox(height: 8),
                  _adjustCard(accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: AppTypography.monoLabel);

  Widget _card({required Widget child, bool emphasised = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(
        color: emphasised ? AppColors.lineMid : AppColors.line,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _entryCard(
    Color accent,
    List<AreaUnit> units,
    BreakdownConfig config,
  ) {
    return _card(
      emphasised: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ModeTab(
                  label: context.l10n.calcModeTotal,
                  active: _entry == _Entry.total,
                  accent: accent,
                  onTap: () => setState(() => _entry = _Entry.total),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeTab(
                  label: context.l10n.calcModeParts,
                  active: _entry == _Entry.parts,
                  accent: accent,
                  onTap: () {
                    _seedParts(config);
                    setState(() => _entry = _Entry.parts);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_entry == _Entry.total) ...[
            Text(context.l10n.calcTotalLabel, style: AppTypography.monoLabel),
            const SizedBox(height: 8),
            BigNumberField(
              controller: _totalCtrl,
              accent: accent,
              suffix: _totalUnit.labelOf(context.l10n),
              onChanged: (raw) {
                final v = double.tryParse(raw.replaceAll(',', '').trim());
                setState(
                  () => _totalSqm =
                      (v == null || v < 0) ? 0 : _totalUnit.toSqm(v),
                );
              },
            ),
            const SizedBox(height: 14),
            UnitChipRow(
              units: AreaUnit.values,
              selected: _totalUnit,
              accent: accent,
              onChanged: (u) => setState(() {
                _totalUnit = u;
                _totalCtrl.text = _pretty(u.fromSqm(_totalSqm));
              }),
            ),
          ] else ...[
            for (var i = 0; i < units.length; i++) ...[
              if (i > 0) Divider(height: 18, color: AppColors.line),
              _PartRow(
                unit: units[i],
                controller: _partCtrl(units[i]),
                accent: accent,
                onChanged: (_) => _recomputeFromParts(units),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              context.l10n.calcPartsHint,
              style: AppTypography.sans(size: 11, color: AppColors.textFaint),
            ),
          ],
        ],
      ),
    );
  }

  Widget _adjustCard(Color accent) {
    final amount =
        double.tryParse(_adjustCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final ready = amount > 0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.calcAmountLabel, style: AppTypography.monoLabel),
          const SizedBox(height: 6),
          BigNumberField(
            controller: _adjustCtrl,
            accent: accent,
            size: 26,
            suffix: _adjustUnit.labelOf(context.l10n),
            onChanged: (_) => setState(() => _adjustError = null),
          ),
          const SizedBox(height: 12),
          UnitChipRow(
            units: AreaUnit.values,
            selected: _adjustUnit,
            accent: accent,
            onChanged: (u) => setState(() => _adjustUnitOverride = u),
          ),
          if (_adjustError != null) ...[
            const SizedBox(height: 10),
            Text(
              _adjustError!,
              style: AppTypography.sans(size: 11, color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 14),
          // One tap chooses the operation and performs it. An earlier version
          // had a mode toggle as well, which meant two controls labelled
          // "Add" doing different things.
          Row(
            children: [
              Expanded(
                child: WideButton(
                  label: context.l10n.calcSubtract,
                  icon: Icons.remove,
                  accent: AppColors.danger,
                  filled: false,
                  onTap: ready
                      ? () => _applyAdjustment(adds: false)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: WideButton(
                  label: context.l10n.calcAdd,
                  icon: Icons.add,
                  accent: accent,
                  onTap: ready ? () => _applyAdjustment(adds: true) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          context.l10n.calcClear,
          style: AppTypography.mono(size: 10, color: AppColors.textDim),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accent : AppColors.ink,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            size: 12,
            weight: FontWeight.w500,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );
  }
}

/// One unit's field in "By unit" mode, laid out like the converter's
/// result rows so the two screens read the same way.
class _PartRow extends StatelessWidget {
  final AreaUnit unit;
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  const _PartRow({
    required this.unit,
    required this.controller,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.nameOf(context.l10n).toUpperCase(),
                style: AppTypography.mono(
                  size: 9,
                  color: AppColors.textFaint,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit.labelOf(context.l10n),
                style: AppTypography.mono(size: 10, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 120,
          child: BigNumberField(
            controller: controller,
            accent: accent,
            size: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
