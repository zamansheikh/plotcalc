import 'package:equatable/equatable.dart';

import '../../../../domain/entities/plot.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class HomePlotsUpdated extends HomeEvent {
  final List<Plot> plots;
  const HomePlotsUpdated(this.plots);
  @override
  List<Object?> get props => [plots];
}
