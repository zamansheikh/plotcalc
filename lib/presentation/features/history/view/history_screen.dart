import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/clear_all_plots.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../../../domain/usecases/delete_plot.dart';
import '../../../../domain/usecases/save_plot.dart';
import '../../result/view/result_screen.dart' show ResultArgs;
import '../bloc/history_bloc.dart';
import 'filter_sheet.dart';
import 'plot_actions_sheet.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryBloc(sl<GetPlots>(), sl<ClearAllPlots>()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return SafeArea(
      child: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          final visible = state.visible;
          final totalSqm = state.plots.fold<double>(
            0,
            (acc, p) => acc + Geometry.polygonArea(p.vertices),
          );
          return Column(
            children: [
              const SizedBox(height: 8),
              _Header(count: state.plots.length, totalSqm: totalSqm),
              _Search(query: state.query, accent: accent),
              _FilterChips(filter: state.filter, accent: accent),
              _SelectionRow(count: state.selectedIds.length, accent: accent),
              Expanded(
                child: _List(plots: visible, state: state),
              ),
              _CompareCta(
                accent: accent,
                enabled: state.selectedIds.length == 2,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final double totalSqm;
  const _Header({required this.count, required this.totalSqm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  '$count plots · ${AreaUnit.acre.format(totalSqm)} acre total',
                  style: AppTypography.mono(size: 11, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          if (count > 0)
            SmallIconButton(
              icon: Icons.delete_outline,
              onTap: () => _confirmClearAll(context),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final bloc = context.read<HistoryBloc>();
    final ok = await showClearAllConfirm(context, count: count);
    if (ok) bloc.add(const HistoryClearAllRequested());
  }
}

class _Search extends StatelessWidget {
  final String query;
  final Color accent;
  const _Search({required this.query, required this.accent});

  Future<void> _openFilterSheet(BuildContext context) async {
    final bloc = context.read<HistoryBloc>();
    final state = bloc.state;
    final counts = <PlotTag?, int>{null: state.plots.length};
    for (final tag in PlotTag.values) {
      counts[tag] = state.plots.where((p) => p.tag == tag).length;
    }
    final result = await showFilterSheet(
      context,
      current: state.filter,
      counts: counts,
      accent: accent,
    );
    if (result != null) {
      bloc.add(HistoryFilterChanged(result.tag));
    }
  }

  @override
  Widget build(BuildContext context) {
    const rowHeight = 52.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        cursorColor: accent,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Search plots…',
                          hintStyle: AppTypography.sans(
                            size: 14,
                            color: AppColors.textDim,
                          ),
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTypography.sans(size: 14),
                        onChanged: (v) => context.read<HistoryBloc>().add(
                          HistoryQueryChanged(v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openFilterSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Filter',
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final PlotTag? filter;
  final Color accent;
  const _FilterChips({required this.filter, required this.accent});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final tags = [null, ...PlotTag.values];
        final counts = <PlotTag?, int>{};
        counts[null] = state.plots.length;
        for (final tag in PlotTag.values) {
          counts[tag] = state.plots.where((p) => p.tag == tag).length;
        }
        return SizedBox(
          height: 28,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final tag = tags[i];
              final active = tag == filter;
              final label = tag == null ? 'All' : tag.label;
              return InkWell(
                onTap: () =>
                    context.read<HistoryBloc>().add(HistoryFilterChanged(tag)),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? accent : AppColors.surface,
                    border: active ? null : Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$label · ${counts[tag]}',
                    style: AppTypography.mono(
                      size: 11,
                      color: active ? AppColors.ink : AppColors.textDim,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SelectionRow extends StatelessWidget {
  final int count;
  final Color accent;
  const _SelectionRow({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count SELECTED FOR COMPARE',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          GestureDetector(
            onTap: () => context.read<HistoryBloc>().add(
              const HistorySelectionCleared(),
            ),
            child: Text(
              'CLEAR',
              style: AppTypography.mono(
                size: 10,
                color: accent,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  final List<Plot> plots;
  final HistoryState state;
  const _List({required this.plots, required this.state});

  @override
  Widget build(BuildContext context) {
    if (plots.isEmpty) {
      final filtered = state.filter != null || state.query.isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            filtered
                ? 'No plots match this filter.\nTap "All" to clear.'
                : 'No plots yet — measure one from Home.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyDim,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      itemCount: plots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _Tile(
        plot: plots[i],
        selected: state.selectedIds.contains(plots[i].id),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Plot plot;
  final bool selected;
  const _Tile({required this.plot, required this.selected});

  Future<void> _openActions(BuildContext context, Color accent) async {
    final action = await showPlotActionsSheet(
      context,
      plot: plot,
      accent: accent,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case PlotAction.rename:
        final newName = await showRenameDialog(
          context,
          currentName: plot.name,
          accent: accent,
        );
        if (newName != null && newName != plot.name) {
          await sl<SavePlot>()(plot.copyWith(name: newName));
        }
        break;
      case PlotAction.delete:
        final ok = await showDeleteConfirm(context, name: plot.name);
        if (ok) await sl<DeletePlot>()(plot.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    final color = Color(plot.colorValue);
    final areaSqm = Geometry.polygonArea(plot.vertices);
    return InkWell(
      onTap: () => context.push(
        AppRoutes.result,
        extra: ResultArgs(name: plot.name, vertices: plot.vertices),
      ),
      onLongPress: () =>
          context.read<HistoryBloc>().add(HistorySelectionToggled(plot.id)),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: selected ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Thumbnail with selection check overlaid on top-left
            // (replaces the corner-of-tile check that used to overlap
            // with the 3-dot menu).
            SizedBox(
              width: 60,
              height: 54,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? accent : AppColors.line,
                      ),
                    ),
                    child:
                        PlotThumbnail(vertices: plot.vertices, color: color),
                  ),
                  if (selected)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.ink,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 11,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot.name,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${AreaUnit.sqft.format(areaSqm)} sq ft',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(size: 10, color: color),
                        ),
                      ),
                      Text(
                        ' · ${plot.vertices.length} sides · ${_when(plot.createdAt)}',
                        style: AppTypography.mono(
                          size: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      plot.tag.label.toUpperCase(),
                      style: AppTypography.mono(
                        size: 9,
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _openActions(context, accent),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _when(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(t.year, t.month, t.day);
    final diff = today.difference(created).inDays;
    if (diff == 0) {
      return 'Today · ${DateFormat('HH:mm').format(t)}';
    }
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEE').format(t);
    return DateFormat('MMM d').format(t);
  }
}

class _CompareCta extends StatelessWidget {
  final Color accent;
  final bool enabled;
  const _CompareCta({required this.accent, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? () => context.push(AppRoutes.compare) : null,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            disabledBackgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            disabledForegroundColor: AppColors.textDim,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.compare_arrows,
                size: 16,
                color: enabled ? AppColors.ink : AppColors.textDim,
              ),
              const SizedBox(width: 8),
              Text(
                'Compare 2 plots',
                style: AppTypography.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: enabled ? AppColors.ink : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
