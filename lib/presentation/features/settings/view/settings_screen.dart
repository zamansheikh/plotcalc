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
                    title: 'THEME',
                    child: _AccentRow(current: state.accent),
                  ),
                  _Section(
                    title: 'GRID STYLE',
                    child: _GridRow(current: state.gridStyle),
                  ),
                  _Section(
                    title: 'AREA UNIT',
                    child: _AreaList(current: state.areaUnit),
                  ),
                  _Section(
                    title: 'LENGTH UNIT',
                    child: _LengthRow(current: state.lengthUnit),
                  ),
                  _Section(
                    title: 'UNDERLAY',
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
                Text('Settings', style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  'Tweak the look, feel, and units',
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
          'Accent color',
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
      (GridStyle.dots, 'Dots'),
      (GridStyle.lines, 'Lines'),
      (GridStyle.blueprint, 'Blueprint'),
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
      (LengthUnit.ft, 'Feet'),
      (LengthUnit.m, 'Meters'),
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
                    unit.displayName,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w500,
                      color: active ? accent : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit.label,
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
                'Map underlay',
                style: AppTypography.sans(size: 13, weight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                'Show road & parcel hints behind the canvas',
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
