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
import '../../../../l10n/l10n.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late final TextEditingController _ctrl =
      TextEditingController(text: '1000');
  AreaUnit _from = AreaUnit.sqft;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_ctrl.text.replaceAll(',', '')) ?? 0;
  double get _sqm => _from.toSqm(_value);

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Header(),
            _InputCard(
              controller: _ctrl,
              from: _from,
              accent: accent,
              onValueChanged: () => setState(() {}),
              onUnitChanged: (u) => setState(() => _from = u),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Label(context.l10n.converterConvertsTo),
              ),
            ),
            Expanded(
              child: _Conversions(
                sqm: _sqm,
                from: _from,
                accent: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
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
                Text(context.l10n.converterTitle, style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  context.l10n.converterSubtitle,
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final AreaUnit from;
  final Color accent;
  final VoidCallback onValueChanged;
  final ValueChanged<AreaUnit> onUnitChanged;

  const _InputCard({
    required this.controller,
    required this.from,
    required this.accent,
    required this.onValueChanged,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              context.l10n.converterValue,
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    cursorColor: accent,
                    style: AppTypography.mono(
                      size: 36,
                      weight: FontWeight.w500,
                      color: accent,
                      letterSpacing: -0.7,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => onValueChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  from.labelOf(context.l10n),
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
                    active: u == from,
                    accent: accent,
                    onTap: () => onUnitChanged(u),
                  ),
              ],
            ),
          ],
        ),
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
          unit.labelOf(context.l10n),
          style: AppTypography.mono(
            size: 11,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _Conversions extends StatelessWidget {
  final double sqm;
  final AreaUnit from;
  final Color accent;
  const _Conversions({
    required this.sqm,
    required this.from,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final targets = AreaUnit.values.where((u) => u != from).toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: targets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final u = targets[i];
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.nameOf(context.l10n).toUpperCase(),
                      style: AppTypography.mono(
                        size: 9,
                        color: AppColors.textFaint,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u.labelOf(context.l10n),
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                u.format(sqm),
                style: AppTypography.mono(
                  size: 18,
                  weight: FontWeight.w500,
                  color: accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.mono(
        size: 11,
        color: AppColors.textFaint,
        letterSpacing: 1.32,
      ),
    );
  }
}
