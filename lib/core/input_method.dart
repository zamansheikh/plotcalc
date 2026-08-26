import 'geometry/presets.dart';
import 'geometry/vertex.dart';

/// Way the user wants to start a new plot.
enum InputMethod {
  /// Start with the chosen preset and drag vertices to fine-tune.
  draw,

  /// Start with an empty canvas and tap to drop each vertex.
  tap,

  /// Type side lengths (and angles where relevant) numerically; a polygon
  /// is generated from those values, then can be tweaked.
  type,
}

/// Bundle passed from the picker to the draw screen.
class DrawArgs {
  final InputMethod method;
  final ShapePreset preset;

  /// An existing outline to edit. When set, the canvas opens on this shape
  /// instead of the preset — that is what re-editing a saved plot means.
  final List<Vertex>? vertices;

  /// The saved plot being edited, so the result can be written back to it
  /// rather than saved as a new one.
  final String? plotId;

  /// Name to keep on the plot when saving an edit.
  final String? name;

  const DrawArgs({
    required this.method,
    required this.preset,
    this.vertices,
    this.plotId,
    this.name,
  });
}
