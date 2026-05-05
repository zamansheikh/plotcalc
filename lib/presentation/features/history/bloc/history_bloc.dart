import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/clear_all_plots.dart';
import '../../../../domain/usecases/get_plots.dart';

class HistoryState extends Equatable {
  final List<Plot> plots;
  final Set<String> selectedIds;
  final PlotTag? filter;
  final String query;
  final bool loading;

  const HistoryState({
    this.plots = const [],
    this.selectedIds = const {},
    this.filter,
    this.query = '',
    this.loading = true,
  });

  HistoryState copyWith({
    List<Plot>? plots,
    Set<String>? selectedIds,
    PlotTag? filter,
    bool clearFilter = false,
    String? query,
    bool? loading,
  }) =>
      HistoryState(
        plots: plots ?? this.plots,
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

  @override
  List<Object?> get props => [plots, selectedIds, filter, query, loading];
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
  StreamSubscription? _sub;

  HistoryBloc(this._getPlots, this._clearAllPlots)
      : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<_HistoryPlotsUpdated>((e, emit) {
      emit(state.copyWith(plots: e.plots, loading: false));
    });
    on<HistorySelectionToggled>((e, emit) {
      final next = Set<String>.from(state.selectedIds);
      if (next.contains(e.id)) {
        next.remove(e.id);
      } else {
        if (next.length >= 2) next.remove(next.first);
        next.add(e.id);
      }
      emit(state.copyWith(selectedIds: next));
    });
    on<HistoryFilterChanged>((e, emit) {
      emit(state.copyWith(
        filter: e.filter,
        clearFilter: e.filter == null,
      ));
    });
    on<HistoryQueryChanged>(
      (e, emit) => emit(state.copyWith(query: e.query)),
    );
    on<HistorySelectionCleared>(
      (e, emit) => emit(state.copyWith(selectedIds: const {})),
    );
    on<HistoryClearAllRequested>((e, emit) async {
      await _clearAllPlots();
      emit(state.copyWith(selectedIds: const {}));
    });
    add(const HistoryStarted());
  }

  Future<void> _onStarted(
    HistoryStarted e,
    Emitter<HistoryState> emit,
  ) async {
    final initial = await _getPlots();
    emit(state.copyWith(plots: initial, loading: false));
    _sub?.cancel();
    _sub = _getPlots.watch().listen((plots) {
      add(_HistoryPlotsUpdated(plots));
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
