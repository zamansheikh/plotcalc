import 'package:equatable/equatable.dart';

import '../../../../core/geometry/vertex.dart';
import '../../../../core/input_method.dart';

class DrawState extends Equatable {
  final List<Vertex> vertices;
  final int selectedIndex;
  final List<List<Vertex>> history;
  final bool showAngles;
  final bool showDiagonals;
  final InputMethod inputMethod;

  /// True while the user is in the initial tap-to-place phase. While true,
  /// canvas taps add new vertices instead of inserting at edges; drag is
  /// disabled. Set to false once the user finalizes ("Done").
  final bool isPlacingTaps;

  /// True while a Type-mode dialog is expected to be open. The view layer
  /// uses this to know it should prompt for dimensions on entry.
  final bool awaitingTypeInput;

  const DrawState({
    this.vertices = const [],
    this.selectedIndex = 0,
    this.history = const [],
    this.showAngles = true,
    this.showDiagonals = false,
    this.inputMethod = InputMethod.draw,
    this.isPlacingTaps = false,
    this.awaitingTypeInput = false,
  });

  DrawState copyWith({
    List<Vertex>? vertices,
    int? selectedIndex,
    List<List<Vertex>>? history,
    bool? showAngles,
    bool? showDiagonals,
    InputMethod? inputMethod,
    bool? isPlacingTaps,
    bool? awaitingTypeInput,
  }) =>
      DrawState(
        vertices: vertices ?? this.vertices,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        history: history ?? this.history,
        showAngles: showAngles ?? this.showAngles,
        showDiagonals: showDiagonals ?? this.showDiagonals,
        inputMethod: inputMethod ?? this.inputMethod,
        isPlacingTaps: isPlacingTaps ?? this.isPlacingTaps,
        awaitingTypeInput: awaitingTypeInput ?? this.awaitingTypeInput,
      );

  @override
  List<Object?> get props => [
        vertices,
        selectedIndex,
        history,
        showAngles,
        showDiagonals,
        inputMethod,
        isPlacingTaps,
        awaitingTypeInput,
      ];
}
