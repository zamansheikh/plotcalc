import 'package:equatable/equatable.dart';

import '../../../../domain/entities/plot.dart';

class HomeState extends Equatable {
  final List<Plot> plots;
  final bool loading;

  const HomeState({this.plots = const [], this.loading = true});

  HomeState copyWith({List<Plot>? plots, bool? loading}) =>
      HomeState(plots: plots ?? this.plots, loading: loading ?? this.loading);

  @override
  List<Object?> get props => [plots, loading];
}
