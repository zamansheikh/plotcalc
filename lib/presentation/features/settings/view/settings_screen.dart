import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../core/units/length_unit.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_event.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../../l10n/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsBloc>().state;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _Header(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _Section(
                    title: context.l10n.settingsLanguage,
                    child: _LanguageRow(current: Localizations.localeOf(context)),
                  ),
                  _Section(
                    title: context.l10n.settingsTheme,
                    child: _AccentRow(current: state.accent),
                  ),
                  _Section(
                    title: context.l10n.settingsGridStyle,
                    child: _GridRow(current: state.gridStyle),
                  ),
                  _Section(
                    title: context.l10n.settingsBreakdown,
                    child: _BreakdownRow(
                      count: state.breakdown.orderedEnabled.length,
                      total: state.breakdown.order.length,
                    ),
                  ),
                  _Section(
                    title: context.l10n.settingsAreaUnit,
                    child: _AreaList(current: state.areaUnit),
                  ),
                  _Section(
                    title: context.l10n.settingsLengthUnit,
                    child: _LengthRow(current: state.lengthUnit),
                  ),
                  _Section(
                    title: context.l10n.settingsUnderlay,
                    child: _UnderlayToggle(value: state.mapUnderlay),
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
  const _Header();
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
                Text(context.l10n.settingsTitle, style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  context.l10n.settingsSubtitle,
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: AppTypography.mono(
                size: 10,
                color: AppColors.textFaint,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AccentRow extends StatelessWidget {
  final Color current;
  const _AccentRow({required this.current});

  @override
  Widget build(BuildContext context) {
    const swatches = [
      AppColors.lime,
      AppColors.sky,
      AppColors.amber,
      AppColors.rose,
      AppColors.violet,
      AppColors.emerald,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.settingsAccent,
          style: AppTypography.sans(size: 13, weight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final c in swatches)
              GestureDetector(
                onTap: () =>
                    context.read<SettingsBloc>().add(AccentChanged(c)),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.toARGB32() == current.toARGB32()
                          ? AppColors.text
                          : AppColors.line,
                      width: c.toARGB32() == current.toARGB32() ? 2 : 1,
                    ),
                  ),
                  child: c.toARGB32() == current.toARGB32()
                      ? const Icon(Icons.check,
                          size: 18, color: AppColors.ink)
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GridRow extends StatelessWidget {
  final GridStyle current;
  const _GridRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    final options = [
      (GridStyle.dots, context.l10n.settingsGridDots),
      (GridStyle.lines, context.l10n.settingsGridLines),
      (GridStyle.blueprint, context.l10n.settingsGridBlueprint),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _Pill(
              label: options[i].$2,
              active: options[i].$1 == current,
              accent: accent,
              onTap: () => context
                  .read<SettingsBloc>()
                  .add(GridStyleChanged(options[i].$1)),
            ),
          ),
        ],
      ],
    );
  }
}

class _LengthRow extends StatelessWidget {
  final LengthUnit current;
  const _LengthRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    final options = [
      (LengthUnit.ft, context.l10n.unitFeet),
      (LengthUnit.m, context.l10n.unitMeters),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _Pill(
              label: options[i].$2,
              active: options[i].$1 == current,
              accent: accent,
              onTap: () => context
                  .read<SettingsBloc>()
                  .add(LengthUnitChanged(options[i].$1)),
            ),
          ),
        ],
      ],
    );
  }
}

class _AreaList extends StatelessWidget {
  final AreaUnit current;
  const _AreaList({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Column(
      children: [
        for (var i = 0; i < AreaUnit.values.length; i++) ...[
          if (i > 0) Divider(height: 1, color: AppColors.line),
          _UnitRow(
            unit: AreaUnit.values[i],
            active: AreaUnit.values[i] == current,
            accent: accent,
          ),
        ],
      ],
    );
  }
}

class _UnitRow extends StatelessWidget {
  final AreaUnit unit;
  final bool active;
  final Color accent;
  const _UnitRow({
    required this.unit,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.read<SettingsBloc>().add(AreaUnitChanged(unit)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.nameOf(context.l10n),
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w500,
                      color: active ? accent : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit.labelOf(context.l10n),
                    style: AppTypography.mono(
                      size: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check, size: 16, color: accent)
            else
              const Icon(
                Icons.circle_outlined,
                size: 16,
                color: AppColors.textFaint,
              ),
          ],
        ),
      ),
    );
  }
}

class _UnderlayToggle extends StatelessWidget {
  final bool value;
  const _UnderlayToggle({required this.value});
  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.settingsMapUnderlay,
                style: AppTypography.sans(size: 13, weight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.settingsMapUnderlaySub,
                style: AppTypography.mono(
                  size: 10,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: AppColors.ink,
          activeTrackColor: accent,
          inactiveThumbColor: AppColors.textDim,
          inactiveTrackColor: AppColors.surfaceHi,
          onChanged: (v) =>
              context.read<SettingsBloc>().add(MapUnderlayToggled(v)),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _Pill({
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

/// Language picker. The active row is driven by [Localizations.localeOf]
/// rather than the stored preference, so before the user ever chooses one
/// it correctly highlights whichever language the device resolved to.
class _LanguageRow extends StatelessWidget {
  final Locale current;
  const _LanguageRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    final options = [
      (const Locale('en'), context.l10n.settingsLanguageEnglish),
      (const Locale('bn'), context.l10n.settingsLanguageBengali),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _Pill(
              label: options[i].$2,
              active: options[i].$1.languageCode == current.languageCode,
              accent: accent,
              onTap: () => context
                  .read<SettingsBloc>()
                  .add(LocaleChanged(options[i].$1)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Entry point into the breakdown-unit editor. Shows the current selection
/// inline so the common case (checking what's on) needs no navigation.
class _BreakdownRow extends StatelessWidget {
  final int count;
  final int total;
  const _BreakdownRow({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.breakdownUnits),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.settingsBreakdownSub,
                      style: AppTypography.sans(size: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.breakdownOf(count, total),
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
