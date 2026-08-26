import 'package:equatable/equatable.dart';

import '../../../../core/geometry/vertex.dart';
import '../../../../core/input_method.dart';

sealed class DrawEvent extends Equatable {
  const DrawEvent();
  @override
  List<Object?> get props => [];
}

class DrawInitialized extends DrawEvent {
  final DrawArgs args;
  const DrawInitialized(this.args);
  @override
  List<Object?> get props => [args.method, args.preset];
}

class VertexSelected extends DrawEvent {
  final int index;
  const VertexSelected(this.index);
  @override
  List<Object?> get props => [index];
}

class VertexMoved extends DrawEvent {
  final int index;
  final Vertex position;
  const VertexMoved({required this.index, required this.position});
  @override
  List<Object?> get props => [index, position];
}

class VertexInserted extends DrawEvent {
  final int afterIndex;
  const VertexInserted(this.afterIndex);
  @override
  List<Object?> get props => [afterIndex];
}

class VertexRemoved extends DrawEvent {
  final int index;
  const VertexRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class DrawUndone extends DrawEvent {
  const DrawUndone();
}

class AnglesToggled extends DrawEvent {
  const AnglesToggled();
}

class DiagonalsToggled extends DrawEvent {
  const DiagonalsToggled();
}

/// Set the length of the diagonal between two vertices by moving one of its
/// endpoints along the diagonal axis. The other endpoint and all unrelated
/// vertices stay in place.
class DiagonalAdjusted extends DrawEvent {
  final int fromIndex;
  final int toIndex;
  final double newLengthMeters;
  final bool moveTo; // true = move toIndex, false = move fromIndex
  const DiagonalAdjusted({
    required this.fromIndex,
    required this.toIndex,
    required this.newLengthMeters,
    required this.moveTo,
  });
  @override
  List<Object?> get props =>
      [fromIndex, toIndex, newLengthMeters, moveTo];
}

/// Tap mode: append a vertex at the given world position.
class TapVertexAdded extends DrawEvent {
  final Vertex position;
  const TapVertexAdded(this.position);
  @override
  List<Object?> get props => [position];
}

/// Tap mode: finalize the polygon and switch to drag editing.
class TapPlacementCompleted extends DrawEvent {
  const TapPlacementCompleted();
}

/// Type mode: replace the polygon with a freshly-generated vertex list.
class TypeShapeGenerated extends DrawEvent {
  final List<Vertex> vertices;

  /// Set when the generated shape is a circle, so the plot can be saved as
  /// one rather than as a 72-sided polygon.
  final double? circleRadiusM;

  const TypeShapeGenerated(this.vertices, {this.circleRadiusM});
  @override
  List<Object?> get props => [vertices, circleRadiusM];
}

/// View signals that the type-input sheet has been shown — clears the flag
/// so it doesn't auto-open again on rebuild.
class TypeInputAcknowledged extends DrawEvent {
  const TypeInputAcknowledged();
}

/// Drags a circle's rim handle. Resizes it rather than turning it into a
/// polygon, which is what moving one of its 72 vertices would do.
class CircleRadiusChanged extends DrawEvent {
  final double radiusM;
  const CircleRadiusChanged(this.radiusM);
  @override
  List<Object?> get props => [radiusM];
}
