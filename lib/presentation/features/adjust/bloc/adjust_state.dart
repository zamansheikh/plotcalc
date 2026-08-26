import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/geometry/geometry.dart';
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

  double get baseSqm => Geometry.polygonArea(baseVertices);

  /// The plot resized to [targetSqm].
  ///
  /// Scaling about a fixed point is affine, so the area scales by exactly
  /// sx*sy regardless of which anchor is used: uniform takes the square root
  /// of the ratio in both axes, the single-axis modes take all of it in one.
  List<Vertex> get adjustedVertices {
    final base = baseSqm;
    // A degenerate plot has no area to scale, so there is nothing to do
    // beyond handing back what we were given.
    if (baseVertices.length < 3 || base <= 0) return baseVertices;
    if (!targetSqm.isFinite || targetSqm <= 0) return baseVertices;

    final ratio = targetSqm / base;
    var sx = 1.0, sy = 1.0;
    switch (mode) {
      case AdjustMode.uniform:
        sx = sy = math.sqrt(ratio);
      case AdjustMode.horizontal:
        sx = ratio;
      case AdjustMode.vertical:
        sy = ratio;
    }

    final (minX, minY, maxX, maxY) = Geometry.bbox(baseVertices);
    var ax = (minX + maxX) / 2;
    var ay = (minY + maxY) / 2;
    switch (anchor) {
      case AdjustAnchor.west:
        ax = minX;
      case AdjustAnchor.east:
        ax = maxX;
      case AdjustAnchor.north:
        ay = minY;
      case AdjustAnchor.south:
        ay = maxY;
      case AdjustAnchor.center:
        break;
    }

    return [
      for (final v in baseVertices)
        Vertex(ax + (v.x - ax) * sx, ay + (v.y - ay) * sy),
    ];
  }

  double get adjustedSqm => Geometry.polygonArea(adjustedVertices);

  @override
  List<Object?> get props => [baseVertices, targetSqm, mode, anchor];
}
