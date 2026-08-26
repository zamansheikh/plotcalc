import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/unit_input.dart';
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
            ToolHeader(
              title: context.l10n.converterTitle,
              subtitle: context.l10n.converterSubtitle,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.home),
            ),
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
            BigNumberField(
              controller: controller,
              accent: accent,
              suffix: from.labelOf(context.l10n),
              onChanged: (_) => onValueChanged(),
            ),
            const SizedBox(height: 14),
            UnitChipRow(
              units: AreaUnit.values,
              selected: from,
              accent: accent,
              onChanged: onUnitChanged,
            ),
          ],
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
