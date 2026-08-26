import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/bottom_tab_bar.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../result/view/result_screen.dart' show ResultArgs;
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../../../../l10n/l10n.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(sl<GetPlots>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;

    return SafeArea(
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final totalSqm = state.plots.fold<double>(
            0,
            (acc, p) => acc + p.areaSqm,
          );
          return Column(
            children: [
              const SizedBox(height: 12),
              _Header(accent: accent),
              _HeroCard(
                accent: accent,
                gridStyle: settings.gridStyle,
                totalSqm: totalSqm,
                count: state.plots.length,
              ),
              _QuickActions(accent: accent),
              _RecentHeader(count: state.plots.length, accent: accent),
              Expanded(
                child: _RecentList(plots: state.plots, accent: accent),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Color accent;
  const _Header({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeBuildBy,
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textFaint,
                    letterSpacing: 1.32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(context.l10n.homeTitle, style: AppTypography.heroTitle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MenuButton(accent: accent),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final Color accent;
  const _MenuButton({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Scaffold.of(context).openEndDrawer(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.menu, size: 20, color: accent),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Color accent;
  final GridStyle gridStyle;
  final double totalSqm;
  final int count;

  const _HeroCard({
    required this.accent,
    required this.gridStyle,
    required this.totalSqm,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final acres = AreaUnit.acre.format(totalSqm);
    final bigha = AreaUnit.bigha.format(totalSqm);
    final sqm = AreaUnit.sqm.format(totalSqm);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            GridBackground(style: gridStyle),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.homeThisMonth,
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
                      Text(
                        acres,
                        style: AppTypography.mono(
                          size: 38,
                          weight: FontWeight.w500,
                          color: accent,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'acre',
                        style: AppTypography.mono(
                          size: 14,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '+$count plots',
                        style: AppTypography.mono(size: 11, color: accent),
                      ),
                      const _Dot(),
                      Text(
                        '$bigha ${AreaUnit.bigha.labelOf(context.l10n)}',
                        style: AppTypography.mono(
                          size: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                      const _Dot(),
                      Text(
                        '$sqm ${AreaUnit.sqm.labelOf(context.l10n)}',
                        style: AppTypography.mono(
                          size: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: CustomPaint(
                      painter: _SparkPainter(accent),
                      size: Size.infinite,
                    ),
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

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: AppTypography.mono(size: 11, color: AppColors.textFaint),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color accent;
  _SparkPainter(this.accent);

  static const _points = <Offset>[
    Offset(0, 28),
    Offset(0.107, 22),
    Offset(0.214, 25),
    Offset(0.321, 18),
    Offset(0.429, 20),
    Offset(0.536, 12),
    Offset(0.643, 16),
    Offset(0.75, 8),
    Offset(0.857, 14),
    Offset(1, 4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pts = _points
        .map((p) => Offset(p.dx * size.width, p.dy / 36 * size.height))
        .toList();
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = accent.withValues(alpha: 0.08));
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.accent != accent;
}

class _QuickActions extends StatelessWidget {
  final Color accent;
  const _QuickActions({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.add,
              label: context.l10n.homeMeasurePlot,
              sub: context.l10n.homeMeasureSub,
              tag: context.l10n.homeBadgeNew,
              filled: true,
              accent: accent,
              onTap: () => context.push(AppRoutes.picker),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionTile(
              icon: Icons.swap_horiz,
              label: context.l10n.converterTitle,
              sub: context.l10n.homeAllUnits,
              tag: context.l10n.homeToolLabel,
              filled: false,
              accent: accent,
              onTap: () => context.push(AppRoutes.converter),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final String tag;
  final bool filled;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.tag,
    required this.filled,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.ink : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? accent : AppColors.surface,
          border: filled ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: filled ? AppColors.ink : accent),
                Text(
                  tag,
                  style: AppTypography.mono(
                    size: 10,
                    color: filled
                        ? AppColors.ink.withValues(alpha: 0.6)
                        : AppColors.textFaint,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: AppTypography.sans(
                size: 15,
                weight: FontWeight.w600,
                color: fg,
              ),
            ),
            Text(
              sub,
              style: AppTypography.sans(
                size: 11,
                color: filled
                    ? AppColors.ink.withValues(alpha: 0.7)
                    : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  final int count;
  final Color accent;
  const _RecentHeader({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.homeRecent(count), style: AppTypography.monoCaption),
          GestureDetector(
            onTap: () => context.goTab(TabKind.history),
            child: Text(
              context.l10n.homeSeeAll,
              style: AppTypography.sans(
                size: 12,
                weight: FontWeight.w500,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<Plot> plots;
  final Color accent;
  const _RecentList({required this.plots, required this.accent});

  @override
  Widget build(BuildContext context) {
    final visible = plots.take(5).toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = visible[i];
        final color = Color(p.colorValue);
        final areaSqm = p.areaSqm;
        final unit =
            p.preferredUnit ?? context.watch<SettingsBloc>().state.areaUnit;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(
              AppRoutes.result,
              extra: ResultArgs(
                name: p.name,
                vertices: p.vertices,
                unit: p.preferredUnit,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: PlotThumbnail(vertices: p.vertices, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTypography.sans(
                            size: 14,
                            weight: FontWeight.w500,
                            letterSpacing: -0.14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${unit.format(areaSqm)} ${unit.labelOf(context.l10n)}',
                              style: AppTypography.mono(size: 11, color: color),
                            ),
                            Text(
                              context.l10n.homeSides(p.vertices.length),
                              style: AppTypography.mono(
                                size: 11,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.tag.labelOf(context.l10n).toUpperCase(),
                      style: AppTypography.mono(
                        size: 9,
                        color: AppColors.textDim,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
