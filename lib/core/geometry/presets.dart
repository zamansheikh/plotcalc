import 'dart:math' as math;

import 'vertex.dart';

enum ShapePreset {
  rectangle,
  square,
  triangle,
  trapezoid,
  pentagon,
  freeform,
}

extension ShapePresetX on ShapePreset {
  String get label => switch (this) {
        ShapePreset.rectangle => 'Rectangle',
        ShapePreset.square => 'Square',
        ShapePreset.triangle => 'Triangle',
        ShapePreset.trapezoid => 'Trapezoid',
        ShapePreset.pentagon => 'Pentagon',
        ShapePreset.freeform => 'Free-form',
      };

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
        ShapePreset.freeform => const [
            Vertex(-22, -18),
            Vertex(18, -22),
            Vertex(26, 8),
            Vertex(4, 22),
            Vertex(-24, 14),
          ],
      };
}
