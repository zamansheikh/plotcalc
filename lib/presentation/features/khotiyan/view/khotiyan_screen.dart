import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';

/// Khotiyan share calculator. The user picks a fractional share in the
/// traditional Bengali land hierarchy (Ana / Gonda / Kora / Kranti / Til),
/// types the total plot area, and gets their portion broken down across
/// every supported area unit.
class KhotiyanScreen extends StatefulWidget {
  const KhotiyanScreen({super.key});

  @override
  State<KhotiyanScreen> createState() => _KhotiyanScreenState();
}

class _KhotiyanScreenState extends State<KhotiyanScreen> {
  // 16 Ana = 1; 20 Gonda = 1 Ana; 4 Kora = 1 Gonda;
  // 3 Kranti = 1 Kora; 20 Til = 1 Kranti.
  static const int _tilPerKranti = 20;
  static const int _krantiPerKora = 3;
  static const int _koraPerGonda = 4;
  static const int _gondaPerAna = 20;
  static const int _anaPerWhole = 16;
  static const int _totalTil = _anaPerWhole *
      _gondaPerAna *
      _koraPerGonda *
      _krantiPerKora *
      _tilPerKranti;

  int _ana = 0;
  int _gonda = 0;
  int _kora = 0;
  int _kranti = 0;
  int _til = 0;

  final TextEditingController _totalCtrl = TextEditingController();
  AreaUnit _unit = AreaUnit.shotok;

  @override
  void initState() {
    super.initState();
    _totalCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    super.dispose();
  }

  int get _selectedTil {
    var t = _til;
    t += _kranti * _tilPerKranti;
    t += _kora * _krantiPerKora * _tilPerKranti;
    t += _gonda * _koraPerGonda * _krantiPerKora * _tilPerKranti;
    t += _ana * _gondaPerAna * _koraPerGonda * _krantiPerKora * _tilPerKranti;
    return t;
  }

  double get _share => _selectedTil / _totalTil;

  double get _totalSqm {
    final v = double.tryParse(_totalCtrl.text.replaceAll(',', ''));
    if (v == null || v <= 0) return 0;
    return _unit.toSqm(v);
  }

  double get _userSqm => _totalSqm * _share;

  void _reset() {
    setState(() {
      _ana = 0;
      _gonda = 0;
      _kora = 0;
      _kranti = 0;
      _til = 0;
      _totalCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Header(onReset: _reset),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _ShareCard(
                    accent: accent,
                    share: _share,
                    selectedTil: _selectedTil,
                    totalTil: _totalTil,
                  ),
                  const SizedBox(height: 14),
                  _SelectorCard(
                    accent: accent,
                    ana: _ana,
                    gonda: _gonda,
                    kora: _kora,
                    kranti: _kranti,
                    til: _til,
                    onAna: (v) => setState(() => _ana = v),
                    onGonda: (v) => setState(() => _gonda = v),
                    onKora: (v) => setState(() => _kora = v),
                    onKranti: (v) => setState(() => _kranti = v),
                    onTil: (v) => setState(() => _til = v),
                  ),
                  const SizedBox(height: 14),
                  _TotalLandCard(
                    accent: accent,
                    controller: _totalCtrl,
                    unit: _unit,
                    onUnitChanged: (u) => setState(() => _unit = u),
                  ),
                  if (_share > 0 && _userSqm > 0) ...[
                    const SizedBox(height: 14),
                    _ResultsCard(accent: accent, sqm: _userSqm),
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

class _Header extends StatelessWidget {
  final VoidCallback onReset;
  const _Header({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SmallIconButton(
              icon: Icons.chevron_left,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khotiyan', style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  'Share calculator · Ana · Gonda · Kora',
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SmallIconButton(
              icon: Icons.refresh,
              onTap: onReset,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final Color accent;
  final double share;
  final int selectedTil;
  final int totalTil;
  const _ShareCard({
    required this.accent,
    required this.share,
    required this.selectedTil,
    required this.totalTil,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (share * 100).toStringAsFixed(4);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.limeDim,
                  border: Border.all(color: accent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pie_chart_outline, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'HISSYA',
                style: AppTypography.mono(
                  size: 10,
                  color: AppColors.textFaint,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                share.toStringAsFixed(6),
                style: AppTypography.mono(
                  size: 32,
                  weight: FontWeight.w500,
                  color: accent,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '$pct%',
                  style: AppTypography.mono(
                    size: 12,
                    color: AppColors.textDim,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceHi,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$selectedTil / $totalTil til',
            style: AppTypography.mono(
              size: 11,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final Color accent;
  final int ana;
  final int gonda;
  final int kora;
  final int kranti;
  final int til;
  final ValueChanged<int> onAna;
  final ValueChanged<int> onGonda;
  final ValueChanged<int> onKora;
  final ValueChanged<int> onKranti;
  final ValueChanged<int> onTil;

  const _SelectorCard({
    required this.accent,
    required this.ana,
    required this.gonda,
    required this.kora,
    required this.kranti,
    required this.til,
    required this.onAna,
    required this.onGonda,
    required this.onKora,
    required this.onKranti,
    required this.onTil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.lineMid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SELECT UNITS',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _StepperRow(
            label: 'Ana',
            sub: '/16',
            value: ana,
            max: 16,
            accent: accent,
            onChanged: onAna,
          ),
          _StepperRow(
            label: 'Gonda',
            sub: '/20',
            value: gonda,
            max: 19,
            accent: accent,
            onChanged: onGonda,
          ),
          _StepperRow(
            label: 'Kora',
            sub: '/4',
            value: kora,
            max: 3,
            accent: accent,
            onChanged: onKora,
          ),
          _StepperRow(
            label: 'Kranti',
            sub: '/3',
            value: kranti,
            max: 2,
            accent: accent,
            onChanged: onKranti,
          ),
          _StepperRow(
            label: 'Til',
            sub: '/20',
            value: til,
            max: 19,
            accent: accent,
            onChanged: onTil,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String sub;
  final int value;
  final int max;
  final Color accent;
  final ValueChanged<int> onChanged;
  final bool isLast;

  const _StepperRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.max,
    required this.accent,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  label,
                  style: AppTypography.sans(
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sub,
                  style: AppTypography.mono(
                    size: 10,
                    color: AppColors.textFaint,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          _StepperBtn(
            icon: Icons.remove,
            accent: accent,
            enabled: value > 0,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 56,
            child: Center(
              child: Text(
                '$value',
                style: AppTypography.mono(
                  size: 18,
                  weight: FontWeight.w500,
                  color: accent,
                ),
              ),
            ),
          ),
          _StepperBtn(
            icon: Icons.add,
            accent: accent,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperBtn({
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.limeDim : AppColors.surfaceHi,
          border: Border.all(
            color: enabled ? accent : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? accent : AppColors.textFaint,
        ),
      ),
    );
  }
}

class _TotalLandCard extends StatelessWidget {
  final Color accent;
  final TextEditingController controller;
  final AreaUnit unit;
  final ValueChanged<AreaUnit> onUnitChanged;

  const _TotalLandCard({
    required this.accent,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.lineMid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL LAND',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  cursorColor: accent,
                  style: AppTypography.mono(
                    size: 32,
                    weight: FontWeight.w500,
                    color: accent,
                    letterSpacing: -0.7,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: AppTypography.mono(
                      size: 32,
                      weight: FontWeight.w500,
                      color: AppColors.textFaint,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit.label,
                style: AppTypography.mono(
                  size: 14,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final u in AreaUnit.values)
                _UnitChip(
                  unit: u,
                  active: u == unit,
                  accent: accent,
                  onTap: () => onUnitChanged(u),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final AreaUnit unit;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _UnitChip({
    required this.unit,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent : AppColors.ink,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          unit.label,
          style: AppTypography.mono(
            size: 11,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final Color accent;
  final double sqm;

  const _ResultsCard({required this.accent, required this.sqm});

  @override
  Widget build(BuildContext context) {
    final units = AreaUnit.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'YOUR LAND',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < units.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i < units.length - 1
                        ? const Border(
                            bottom: BorderSide(color: AppColors.line),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              units[i].displayName.toUpperCase(),
                              style: AppTypography.mono(
                                size: 9,
                                color: AppColors.textFaint,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              units[i].label,
                              style: AppTypography.mono(
                                size: 10,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        units[i].format(sqm),
                        style: AppTypography.mono(
                          size: 16,
                          weight: FontWeight.w500,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
