import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Right-side menu drawer. Each row pushes a top-level page (Settings,
/// About, …). New entries can be appended to [_items] without touching
/// the rest of the app.
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  static const _items = <_MenuItem>[
    _MenuItem(
      icon: Icons.pie_chart_outline,
      label: 'Khotiyan',
      sub: 'Calculate share by Ana, Gonda, Kora',
      route: AppRoutes.khotiyan,
    ),
    _MenuItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      sub: 'Theme, units, grid style',
      route: AppRoutes.settings,
    ),
    _MenuItem(
      icon: Icons.info_outline,
      label: 'About',
      sub: 'Version, credits, what PlotCalc does',
      route: AppRoutes.about,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Drawer(
      backgroundColor: AppColors.ink,
      width: size.width * 0.82,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            _Header(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _Tile(item: _items[i]),
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String sub;
  final String route;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.route,
  });
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu', style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  'Settings, info, and more',
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 22,
              color: AppColors.text,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final _MenuItem item;
  const _Tile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(); // Close drawer first.
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHi,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: AppColors.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: AppTypography.sans(
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sub,
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          const Icon(Icons.terrain, size: 14, color: AppColors.textFaint),
          const SizedBox(width: 6),
          Text(
            'PlotCalc · v1.0.0',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
