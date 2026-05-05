import 'package:equatable/equatable.dart';

import '../../../../core/geometry/vertex.dart';
import 'adjust_state.dart';

sealed class AdjustEvent extends Equatable {
  const AdjustEvent();
  @override
  List<Object?> get props => [];
}

class AdjustInitialized extends AdjustEvent {
  final List<Vertex> base;
  final double initialMultiplier;
  const AdjustInitialized({required this.base, this.initialMultiplier = 1.2});
  @override
  List<Object?> get props => [base, initialMultiplier];
}

class TargetChanged extends AdjustEvent {
  final double sqm;
  const TargetChanged(this.sqm);
  @override
  List<Object?> get props => [sqm];
}

class ModeChanged extends AdjustEvent {
  final AdjustMode mode;
  const ModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class AnchorChanged extends AdjustEvent {
  final AdjustAnchor anchor;
  const AnchorChanged(this.anchor);
  @override
  List<Object?> get props => [anchor];
}

class AdjustReset extends AdjustEvent {
  const AdjustReset();
}
