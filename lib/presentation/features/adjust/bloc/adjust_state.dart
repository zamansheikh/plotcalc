import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/geometry/boundary_adjust.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/units/area_unit.dart';

/// How the plot is reshaped to hit the target.
enum AdjustMethod {
  /// Resize the whole outline.
  scale,

  /// Move chosen boundaries or corners, leaving the rest alone.
  boundary,
}

enum AdjustMode { uniform, horizontal, vertical }
enum AdjustAnchor { center, north, east, south, west }

class AdjustState extends Equatable {
  final List<Vertex> baseVertices;
  final double targetSqm;
  final AdjustMode mode;
  final AdjustAnchor anchor;

  final AdjustMethod method;

  /// Whether [selection] indexes sides or corners.
  final AdjustTargetKind targetKind;

  /// Sides (or corners) the user has picked to move.
  final Set<int> selection;

  /// Which of the two boundaries meeting at the chosen corner it slides
  /// along: the one running to the next corner, or to the previous one.
  final bool slideAlongNext;

  /// Unit the target is entered and read in. `null` follows the app setting.
  /// A plot is often discussed in katha even when the app is set to sq ft,
  /// so this is per-visit rather than a global change.
  final AreaUnit? displayUnit;

  const AdjustState({
    this.baseVertices = const [],
    this.targetSqm = 0,
    this.mode = AdjustMode.uniform,
    this.anchor = AdjustAnchor.center,
    this.method = AdjustMethod.scale,
    this.targetKind = AdjustTargetKind.side,
    this.selection = const {},
    this.displayUnit,
    this.slideAlongNext = true,
  });

  AdjustState copyWith({
    List<Vertex>? baseVertices,
    double? targetSqm,
    AdjustMode? mode,
    AdjustAnchor? anchor,
    AdjustMethod? method,
    AdjustTargetKind? targetKind,
    Set<int>? selection,
    AreaUnit? displayUnit,
    bool? slideAlongNext,
  }) =>
      AdjustState(
        baseVertices: baseVertices ?? this.baseVertices,
        targetSqm: targetSqm ?? this.targetSqm,
        mode: mode ?? this.mode,
        anchor: anchor ?? this.anchor,
        method: method ?? this.method,
        targetKind: targetKind ?? this.targetKind,
        selection: selection ?? this.selection,
        displayUnit: displayUnit ?? this.displayUnit,
        slideAlongNext: slideAlongNext ?? this.slideAlongNext,
      );

  double get baseSqm => Geometry.polygonArea(baseVertices);

  /// How far the chosen boundaries have to move, or null when nothing is
  /// selected or the plot/target cannot support an answer.
  ///
  /// Solving walks the offset outward step by step, so this is not free —
  /// callers should resolve it once per build and pass the result down
  /// rather than reading it repeatedly.
  BoundarySolution? solveBoundary() => BoundaryAdjust.solve(
    base: baseVertices,
    targetSqm: targetSqm,
    kind: targetKind,
    selection: selection,
    alongNext: slideAlongNext,
  );

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
  List<Object?> get props => [
    baseVertices,
    targetSqm,
    mode,
    anchor,
    method,
    targetKind,
    selection,
    displayUnit,
    slideAlongNext,
  ];
}
