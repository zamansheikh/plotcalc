import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../settings/settings_bloc.dart';

enum TabKind { plots, history, subdivide, info }

extension TabKindX on TabKind {
  int get index => switch (this) {
        TabKind.plots => 0,
        TabKind.history => 1,
        TabKind.subdivide => 2,
        TabKind.info => 3,
      };

  static TabKind fromIndex(int i) => switch (i) {
        0 => TabKind.plots,
        1 => TabKind.history,
        2 => TabKind.subdivide,
        3 => TabKind.info,
        _ => TabKind.plots,
      };
}

class BottomTabBar extends StatelessWidget {
  final TabKind active;
  final ValueChanged<TabKind> onChanged;
  const BottomTabBar({
    super.key,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    final items = <_Item>[
      _Item(TabKind.plots, Icons.layers_outlined, 'Plots'),
      _Item(TabKind.history, Icons.history, 'History'),
      _Item(TabKind.subdivide, Icons.call_split, 'Subdivide'),
      _Item(TabKind.info, Icons.info_outline, 'Info'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final it in items)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: it.kind == active ? null : () => onChanged(it.kind),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: it.kind == active
                        ? AppColors.limeDim
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        it.icon,
                        size: 20,
                        color:
                            it.kind == active ? accent : AppColors.textDim,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        it.label,
                        style: AppTypography.mono(
                          size: 10,
                          color: it.kind == active
                              ? accent
                              : AppColors.textDim,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Item {
  final TabKind kind;
  final IconData icon;
  final String label;
  _Item(this.kind, this.icon, this.label);
}
