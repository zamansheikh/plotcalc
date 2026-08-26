import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_event.dart';
import '../../../shared/widgets/area_breakdown_view.dart';
import '../../../shared/widgets/phone_chrome.dart';

/// Lets the user choose which units a compound reading is built from, and in
/// what order. A live sample sits at the top so the effect of a change is
/// visible without leaving the screen.
class BreakdownUnitsScreen extends StatelessWidget {
  const BreakdownUnitsScreen({super.key});

  /// One bigha — a familiar size that exercises most of the unit chain.
  static const _sampleSqm = 1337.803776;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final config = settings.breakdown;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: PhoneChrome(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _TopBar(),
              Expanded(
                child: ReorderableListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AreaBreakdownView(
                          sqm: _sampleSqm,
                          configurable: false,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.breakdownConfigHint,
                          style: AppTypography.sans(
                            size: 12,
                            color: AppColors.textDim,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.breakdownOf(
                            config.orderedEnabled.length,
                            config.order.length,
                          ),
                          style: AppTypography.monoLabel,
                        ),
                      ],
                    ),
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () =>
                          context.read<SettingsBloc>().add(
                            const BreakdownReset(),
                          ),
                      child: Text(
                        context.l10n.actionResetDefaults,
                        style: AppTypography.sans(
                          size: 13,
                          color: settings.accent,
                        ),
                      ),
                    ),
                  ),
                  onReorderItem: (oldIndex, newIndex) => context
                      .read<SettingsBloc>()
                      .add(BreakdownUnitsReordered(oldIndex, newIndex)),
                  children: [
                    for (var i = 0; i < config.order.length; i++)
                      _UnitTile(
                        key: ValueKey(config.order[i]),
                        index: i,
                        unit: config.order[i],
                        on: config.isOn(config.order[i]),
                        accent: settings.accent,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          SmallIconButton(
            icon: Icons.chevron_left,
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.breakdownConfigTitle,
                  style: AppTypography.sans(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.breakdownConfigSubtitle,
                  style: AppTypography.mono(size: 10, color: AppColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final int index;
  final AreaUnit unit;
  final bool on;
  final Color accent;
  const _UnitTile({
    super.key,
    required this.index,
    required this.unit,
    required this.on,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.read<SettingsBloc>().add(BreakdownUnitToggled(unit)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: on ? AppColors.surfaceHi : AppColors.surface,
              border: Border.all(color: on ? accent : AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  on ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: on ? accent : AppColors.textFaint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.nameOf(context.l10n),
                        style: AppTypography.sans(
                          size: 13,
                          weight: FontWeight.w500,
                          color: on ? AppColors.text : AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 ${unit.labelOf(context.l10n)} · '
                        '${AreaUnit.sqft.format(unit.sqmPerUnit)} '
                        '${AreaUnit.sqft.labelOf(context.l10n)}',
                        style: AppTypography.mono(
                          size: 10,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_handle,
                      size: 18,
                      color: AppColors.textFaint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
