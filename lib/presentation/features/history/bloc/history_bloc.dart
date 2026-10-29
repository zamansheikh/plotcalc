import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/plot.dart';
import '../../../../domain/entities/plot_sheet.dart';
import '../../../../domain/usecases/clear_all_plots.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../../domain/usecases/get_sheets.dart';

/// Which list the History tab shows.
enum HistoryTab { plots, sheets }

class HistoryState extends Equatable {
  final List<Plot> plots;
  final List<PlotSheet> sheets;
  final HistoryTab tab;

  /// In the order the user picked them; a new sheet lists plots this way.
  final Set<String> selectedIds;
  final PlotTag? filter;
  final String query;
  final bool loading;

  const HistoryState({
    this.plots = const [],
    this.sheets = const [],
    this.tab = HistoryTab.plots,
    this.selectedIds = const {},
    this.filter,
    this.query = '',
    this.loading = true,
  });

  HistoryState copyWith({
    List<Plot>? plots,
    List<PlotSheet>? sheets,
    HistoryTab? tab,
    Set<String>? selectedIds,
    PlotTag? filter,
    bool clearFilter = false,
    String? query,
    bool? loading,
  }) => HistoryState(
    plots: plots ?? this.plots,
    sheets: sheets ?? this.sheets,
    tab: tab ?? this.tab,
    selectedIds: selectedIds ?? this.selectedIds,
    filter: clearFilter ? null : (filter ?? this.filter),
    query: query ?? this.query,
    loading: loading ?? this.loading,
  );

  List<Plot> get visible {
    return plots.where((p) {
      if (filter != null && p.tag != filter) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Selected plots that still exist, in selection order.
  List<Plot> get selectedPlots {
    final byId = {for (final p in plots) p.id: p};
    return [
      for (final id in selectedIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  List<Object?> get props => [
    plots,
    sheets,
    tab,
    selectedIds,
    filter,
    query,
    loading,
  ];
}

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

class _HistoryPlotsUpdated extends HistoryEvent {
  final List<Plot> plots;
  const _HistoryPlotsUpdated(this.plots);
  @override
  List<Object?> get props => [plots];
}

class _HistorySheetsUpdated extends HistoryEvent {
  final List<PlotSheet> sheets;
  const _HistorySheetsUpdated(this.sheets);
  @override
  List<Object?> get props => [sheets];
}

class HistoryTabChanged extends HistoryEvent {
  final HistoryTab tab;
  const HistoryTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

class HistorySelectionToggled extends HistoryEvent {
  final String id;
  const HistorySelectionToggled(this.id);
  @override
  List<Object?> get props => [id];
}

class HistoryFilterChanged extends HistoryEvent {
  final PlotTag? filter;
  const HistoryFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class HistoryQueryChanged extends HistoryEvent {
  final String query;
  const HistoryQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class HistorySelectionCleared extends HistoryEvent {
  const HistorySelectionCleared();
}

class HistoryClearAllRequested extends HistoryEvent {
  const HistoryClearAllRequested();
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetPlots _getPlots;
  final ClearAllPlots _clearAllPlots;
  final GetSheets _getSheets;
  StreamSubscription? _sub;
  StreamSubscription? _sheetSub;

  HistoryBloc(this._getPlots, this._clearAllPlots, this._getSheets)
    : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<_HistoryPlotsUpdated>((e, emit) {
      emit(state.copyWith(plots: e.plots, loading: false));
    });
    on<_HistorySheetsUpdated>(
      (e, emit) => emit(state.copyWith(sheets: e.sheets)),
    );
    on<HistoryTabChanged>((e, emit) => emit(state.copyWith(tab: e.tab)));
    // No cap: two plots can be compared, and any number summed into a sheet.
    on<HistorySelectionToggled>((e, emit) {
      final next = Set<String>.from(state.selectedIds);
      if (!next.remove(e.id)) next.add(e.id);
      emit(state.copyWith(selectedIds: next));
    });
    on<HistoryFilterChanged>((e, emit) {
      emit(state.copyWith(filter: e.filter, clearFilter: e.filter == null));
    });
    on<HistoryQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<HistorySelectionCleared>(
      (e, emit) => emit(state.copyWith(selectedIds: const {})),
    );
    on<HistoryClearAllRequested>((e, emit) async {
      await _clearAllPlots();
      emit(state.copyWith(selectedIds: const {}));
    });
    add(const HistoryStarted());
  }

  Future<void> _onStarted(HistoryStarted e, Emitter<HistoryState> emit) async {
    final initial = await _getPlots();
    emit(state.copyWith(plots: initial, loading: false));
    _sub?.cancel();
    _sub = _getPlots.watch().listen((plots) {
      add(_HistoryPlotsUpdated(plots));
    });
    _sheetSub?.cancel();
    _sheetSub = _getSheets.watch().listen((sheets) {
      add(_HistorySheetsUpdated(sheets));
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _sheetSub?.cancel();
    return super.close();
  }
}
