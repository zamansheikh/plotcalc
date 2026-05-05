import 'geometry/presets.dart';

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

extension InputMethodX on InputMethod {
  String get label => switch (this) {
        InputMethod.draw => 'Draw',
        InputMethod.tap => 'Tap',
        InputMethod.type => 'Type',
      };
}

/// Bundle passed from the picker to the draw screen.
class DrawArgs {
  final InputMethod method;
  final ShapePreset preset;
  const DrawArgs({required this.method, required this.preset});
}
