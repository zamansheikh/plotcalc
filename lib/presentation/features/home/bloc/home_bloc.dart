import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/usecases/get_plots.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPlots _getPlots;
  StreamSubscription? _sub;

  HomeBloc(this._getPlots) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomePlotsUpdated>(_onPlotsUpdated);
    add(const HomeStarted());
  }

  Future<void> _onStarted(HomeStarted e, Emitter<HomeState> emit) async {
    final initial = await _getPlots();
    emit(state.copyWith(plots: initial, loading: false));
    _sub?.cancel();
    _sub = _getPlots.watch().listen((plots) {
      add(HomePlotsUpdated(plots));
    });
  }

  void _onPlotsUpdated(HomePlotsUpdated e, Emitter<HomeState> emit) {
    emit(state.copyWith(plots: e.plots, loading: false));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
