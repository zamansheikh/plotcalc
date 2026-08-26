import 'package:equatable/equatable.dart';

import '../../../../core/geometry/vertex.dart';
import '../../../../core/geometry/boundary_adjust.dart';
import 'adjust_state.dart';

sealed class AdjustEvent extends Equatable {
  const AdjustEvent();
  @override
  List<Object?> get props => [];
}

class AdjustInitialized extends AdjustEvent {
  final List<Vertex> base;
  /// The target starts at the plot's own area, so the field opens showing
  /// what it measures now and the user edits it to what they want — 5.2
  /// becomes 5.5. Anything else would put a number there they never asked
  /// for.
  final double initialMultiplier;
  const AdjustInitialized({required this.base, this.initialMultiplier = 1});
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

class MethodChanged extends AdjustEvent {
  final AdjustMethod method;
  const MethodChanged(this.method);
  @override
  List<Object?> get props => [method];
}

class TargetKindChanged extends AdjustEvent {
  final AdjustTargetKind kind;
  const TargetKindChanged(this.kind);
  @override
  List<Object?> get props => [kind];
}

/// Taps a side or corner on the canvas.
class SelectionToggled extends AdjustEvent {
  final int index;
  const SelectionToggled(this.index);
  @override
  List<Object?> get props => [index];
}

class SelectionCleared extends AdjustEvent {
  const SelectionCleared();
}
