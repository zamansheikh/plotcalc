import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../features/settings/view/settings_drawer.dart';
import 'bottom_tab_bar.dart';

/// Persistent scaffold for the four bottom-nav tabs (Plots, History,
/// Subdivide, Info). The tab content swaps inside [navigationShell] without
/// rebuilding the bar, and the right-side menu drawer hangs off this
/// scaffold so it can be opened from any tab.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      endDrawer: const SettingsDrawer(),
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomTabBar(
          active: TabKindX.fromIndex(navigationShell.currentIndex),
          onChanged: (kind) => navigationShell.goBranch(
            kind.index,
            initialLocation: kind.index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

extension ShellNavigation on BuildContext {
  /// Switches the shell to [tab], keeping that branch's own navigation stack.
  ///
  /// Always use this to reach a bottom-nav destination. The tab paths are
  /// branches of the [StatefulShellRoute], so `push`ing one instead stacks
  /// that screen on top of whichever branch is *currently* active: the bar
  /// keeps highlighting the old tab, and — because the bar ignores taps on
  /// the already-active tab — the user is left with no way back.
  void goTab(TabKind tab) =>
      StatefulNavigationShell.of(this).goBranch(tab.index);
}
