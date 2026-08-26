import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../settings/settings_bloc.dart';

/// The header every bottom-nav tab wears.
///
/// The four tabs had each grown their own: different padding, the subtitle
/// above the title on one and below it on the others, and the menu button
/// only on Plots — so the drawer was unreachable from three of the four.
class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Shown in place of the menu button, for tabs with their own action.
  final Widget? trailing;

  const TabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.mono(size: 11, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? MenuButton(accent: accent),
        ],
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final Color accent;
  const MenuButton({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Scaffold.of(context).openEndDrawer(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.menu, size: 18, color: accent),
        ),
      ),
    );
  }
}
