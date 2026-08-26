import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/area_breakdown_view.dart';
import '../../../shared/widgets/phone_chrome.dart';

/// Working surface for land arithmetic: hold a running total, read it as a
/// compound breakdown, add or subtract a quantity in any unit, or assemble a
/// total from several units at once.
///
/// Distinct from the converter, which only restates one value in every unit.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  /// Square metres is the canonical store; the text field is only ever a
  /// view of it in the currently selected unit.
  double _totalSqm = 0;
  AreaUnit _totalUnit = AreaUnit.katha;

  final _totalCtrl = TextEditingController();

  bool _adjustAdds = true;
  AreaUnit _adjustUnit = AreaUnit.katha;
  final _adjustCtrl = TextEditingController();
  String? _adjustError;

  final _combine = <AreaUnit, TextEditingController>{};

  bool _showAdjust = false;
  bool _showCombine = false;

  @override
  void dispose() {
    _totalCtrl.dispose();
    _adjustCtrl.dispose();
    for (final c in _combine.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _combineCtrl(AreaUnit u) =>
      _combine.putIfAbsent(u, TextEditingController.new);

  /// Trailing zeros make a running total hard to read, so trim them.
  String _pretty(double v) {
    if (v == 0) return '';
    if (v == v.roundToDouble() && v.abs() < 1e9) {
      return v.toStringAsFixed(0);
    }
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

  void _onTotalTyped(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '').trim());
    setState(() => _totalSqm = (v == null || v < 0) ? 0 : _totalUnit.toSqm(v));
  }

  void _changeTotalUnit(AreaUnit u) {
    // Keep the area itself fixed and restate it in the new unit.
    setState(() {
      _totalUnit = u;
      _totalCtrl.text = _pretty(u.fromSqm(_totalSqm));
    });
  }

  void _applyAdjustment() {
    final v = double.tryParse(_adjustCtrl.text.replaceAll(',', '').trim());
    if (v == null || v <= 0) return;
    final delta = _adjustUnit.toSqm(v);
    final next = _adjustAdds ? _totalSqm + delta : _totalSqm - delta;
    if (next < 0) {
      setState(() => _adjustError = context.l10n.calcCannotGoNegative);
      return;
    }
    setState(() => _adjustError = null);
    _setTotal(next);
    _adjustCtrl.clear();
  }

  double get _combineSqm {
    var sum = 0.0;
    _combine.forEach((unit, ctrl) {
      final v = double.tryParse(ctrl.text.replaceAll(',', '').trim());
      if (v != null && v > 0) sum += unit.toSqm(v);
    });
    return sum;
  }

  void _applyCombine() {
    final sqm = _combineSqm;
    if (sqm <= 0) return;
    _setTotal(sqm);
    setState(() => _showCombine = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: PhoneChrome(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _TopBar(onClear: () {
                _adjustCtrl.clear();
                for (final c in _combine.values) {
                  c.clear();
                }
                setState(() => _adjustError = null);
                _setTotal(0);
              }),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _totalCard(accent),
                    const SizedBox(height: 12),
                    if (_totalSqm > 0)
                      AreaBreakdownView(sqm: _totalSqm)
                    else
                      _hint(context.l10n.calcEmpty),
                    const SizedBox(height: 12),
                    _adjustCard(accent),
                    const SizedBox(height: 10),
                    _combineCard(accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: AppTypography.sans(size: 12, color: AppColors.textDim),
    ),
  );

  Widget _totalCard(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.lineMid),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.calcTotalLabel, style: AppTypography.monoLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  controller: _totalCtrl,
                  accent: accent,
                  big: true,
                  onChanged: _onTotalTyped,
                ),
              ),
              const SizedBox(width: 10),
              _UnitPicker(
                current: _totalUnit,
                accent: accent,
                onChanged: _changeTotalUnit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adjustCard(Color accent) {
    return _Expandable(
      icon: Icons.tune,
      title: context.l10n.calcAdjustTitle,
      subtitle: context.l10n.calcAdjustSub,
      expanded: _showAdjust,
      accent: accent,
      onToggle: () => setState(() => _showAdjust = !_showAdjust),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Segment(
                  label: context.l10n.calcAdd,
                  icon: Icons.add,
                  selected: _adjustAdds,
                  accent: accent,
                  onTap: () => setState(() => _adjustAdds = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Segment(
                  label: context.l10n.calcSubtract,
                  icon: Icons.remove,
                  selected: !_adjustAdds,
                  accent: AppColors.danger,
                  onTap: () => setState(() => _adjustAdds = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  controller: _adjustCtrl,
                  accent: accent,
                  onChanged: (_) => setState(() => _adjustError = null),
                ),
              ),
              const SizedBox(width: 8),
              _UnitPicker(
                current: _adjustUnit,
                accent: accent,
                onChanged: (u) => setState(() => _adjustUnit = u),
              ),
            ],
          ),
          if (_adjustError != null) ...[
            const SizedBox(height: 8),
            Text(
              _adjustError!,
              style: AppTypography.sans(size: 11, color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 10),
          _PrimaryButton(
            label: context.l10n.calcApply,
            accent: accent,
            onTap: _applyAdjustment,
          ),
        ],
      ),
    );
  }

  Widget _combineCard(Color accent) {
    final units = context.watch<SettingsBloc>().state.breakdown.orderedEnabled;
    final sum = _combineSqm;
    return _Expandable(
      icon: Icons.calculate_outlined,
      title: context.l10n.calcCombineTitle,
      subtitle: context.l10n.calcCombineSub,
      expanded: _showCombine,
      accent: accent,
      onToggle: () => setState(() => _showCombine = !_showCombine),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final u in units) ...[
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    u.labelOf(context.l10n),
                    style: AppTypography.sans(
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _NumberInput(
                    controller: _combineCtrl(u),
                    accent: accent,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 2),
          Text(
            context.l10n.calcCombineRunning(
              _totalUnit.format(sum),
              _totalUnit.labelOf(context.l10n),
            ),
            style: AppTypography.mono(size: 11, color: AppColors.textDim),
          ),
          const SizedBox(height: 10),
          _PrimaryButton(
            label: context.l10n.calcCombineApply,
            accent: accent,
            onTap: sum > 0 ? _applyCombine : null,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClear;
  const _TopBar({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          SmallIconButton(
            icon: Icons.chevron_left,
            onTap: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.calcTitle,
                  style: AppTypography.sans(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.calcSubtitle,
                  style: AppTypography.mono(size: 10, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(
              context.l10n.calcClear,
              style: AppTypography.mono(size: 10, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  final bool big;
  const _NumberInput({
    required this.controller,
    required this.accent,
    required this.onChanged,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: AppTypography.mono(
        size: big ? 26 : 15,
        weight: FontWeight.w600,
        color: big ? accent : AppColors.text,
      ),
      cursorColor: accent,
      decoration: InputDecoration(
        isDense: true,
        hintText: '0',
        hintStyle: AppTypography.mono(
          size: big ? 26 : 15,
          color: AppColors.textFaint,
        ),
        filled: true,
        fillColor: AppColors.surfaceHi,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent),
        ),
      ),
    );
  }
}

class _UnitPicker extends StatelessWidget {
  final AreaUnit current;
  final Color accent;
  final ValueChanged<AreaUnit> onChanged;
  const _UnitPicker({
    required this.current,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AreaUnit>(
      onSelected: onChanged,
      color: AppColors.surfaceHi,
      itemBuilder: (_) => [
        for (final u in AreaUnit.values)
          PopupMenuItem(
            value: u,
            child: Text(
              u.nameOf(context.l10n),
              style: AppTypography.sans(
                size: 13,
                color: u == current ? accent : AppColors.text,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.labelOf(context.l10n),
              style: AppTypography.sans(
                size: 13,
                weight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.limeDim : Colors.transparent,
            border: Border.all(color: selected ? accent : AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? accent : AppColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: selected ? accent : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  const _PrimaryButton({
    required this.label,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? accent : AppColors.surfaceHi,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? accent : AppColors.line),
          ),
          child: Text(
            label,
            style: AppTypography.sans(
              size: 13,
              weight: FontWeight.w600,
              color: on ? AppColors.ink : AppColors.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _Expandable extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final Color accent;
  final VoidCallback onToggle;
  final Widget child;
  const _Expandable({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.accent,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.sans(
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.sans(
                              size: 11,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: AppColors.textDim,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}
