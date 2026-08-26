import 'dart:math' as math;

import 'vertex.dart';

enum ShapePreset {
  rectangle,
  square,
  triangle,
  trapezoid,
  pentagon,
  circle,
  freeform,
}

/// A circle is stored as its radius and drawn as a fine regular polygon, so
/// every painter and hit test keeps working unchanged.
///
/// The polygon is for drawing only: at 72 sides its area is about 0.13% under
/// the true circle, which is invisible on screen but would be wrong in a
/// figure. Anything the user reads comes from [Plot.areaSqm] /
/// [Plot.perimeterM], which use the exact formulae when a radius is known.
const int circleSegments = 72;

/// Radius of the circle offered by the shape picker.
const double circlePresetRadius = 22;

/// Vertices approximating a circle of [radius] metres, centred at origin.
List<Vertex> circleVertices(double radius) => List.generate(
  circleSegments,
  (i) {
    final a = -math.pi / 2 + i * 2 * math.pi / circleSegments;
    return Vertex(radius * math.cos(a), radius * math.sin(a));
  },
);

extension ShapePresetX on ShapePreset {
  // Display names are locale-dependent — see ShapePresetL10n.labelOf.

  /// Vertex preset in meters, centered at origin.
  List<Vertex> get vertices => switch (this) {
        ShapePreset.rectangle => const [
            Vertex(-25, -15),
            Vertex(25, -15),
            Vertex(25, 15),
            Vertex(-25, 15),
          ],
        ShapePreset.square => const [
            Vertex(-20, -20),
            Vertex(20, -20),
            Vertex(20, 20),
            Vertex(-20, 20),
          ],
        ShapePreset.triangle => const [
            Vertex(0, -25),
            Vertex(25, 18),
            Vertex(-25, 18),
          ],
        ShapePreset.trapezoid => const [
            Vertex(-15, -18),
            Vertex(15, -18),
            Vertex(28, 18),
            Vertex(-28, 18),
          ],
        ShapePreset.pentagon => List.generate(5, (i) {
            const r = 22.0;
            final a = -math.pi / 2 + i * 2 * math.pi / 5;
            return Vertex(r * math.cos(a), r * math.sin(a));
          }),
        ShapePreset.circle => circleVertices(circlePresetRadius),
        ShapePreset.freeform => const [
            Vertex(-22, -18),
            Vertex(18, -22),
            Vertex(26, 8),
            Vertex(4, 22),
            Vertex(-24, 14),
          ],
      };
}
