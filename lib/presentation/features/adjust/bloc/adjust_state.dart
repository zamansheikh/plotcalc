import 'package:equatable/equatable.dart';

import '../../../../core/geometry/vertex.dart';

enum AdjustMode { uniform, horizontal, vertical }
enum AdjustAnchor { center, north, east, south, west }

class AdjustState extends Equatable {
  final List<Vertex> baseVertices;
  final double targetSqm;
  final AdjustMode mode;
  final AdjustAnchor anchor;

  const AdjustState({
    this.baseVertices = const [],
    this.targetSqm = 0,
    this.mode = AdjustMode.uniform,
    this.anchor = AdjustAnchor.center,
  });

  AdjustState copyWith({
    List<Vertex>? baseVertices,
    double? targetSqm,
    AdjustMode? mode,
    AdjustAnchor? anchor,
  }) =>
      AdjustState(
        baseVertices: baseVertices ?? this.baseVertices,
        targetSqm: targetSqm ?? this.targetSqm,
        mode: mode ?? this.mode,
        anchor: anchor ?? this.anchor,
      );

  @override
  List<Object?> get props => [baseVertices, targetSqm, mode, anchor];
}
