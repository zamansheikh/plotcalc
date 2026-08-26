import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/presets.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/input_method.dart';
import 'draw_event.dart';
import 'draw_state.dart';

class DrawBloc extends Bloc<DrawEvent, DrawState> {
  DrawBloc() : super(const DrawState()) {
    on<DrawInitialized>((e, emit) {
      switch (e.args.method) {
        case InputMethod.draw:
          emit(state.copyWith(
            vertices: List.of(e.args.preset.vertices),
            selectedIndex: 0,
            history: const [],
            inputMethod: InputMethod.draw,
            isPlacingTaps: false,
            awaitingTypeInput: false,
          ));
          break;
        case InputMethod.tap:
          emit(state.copyWith(
            vertices: const [],
            selectedIndex: 0,
            history: const [],
            inputMethod: InputMethod.tap,
            isPlacingTaps: true,
            awaitingTypeInput: false,
          ));
          break;
        case InputMethod.type:
          emit(state.copyWith(
            // Show the preset behind the modal so the user has visual context.
            vertices: List.of(e.args.preset.vertices),
            selectedIndex: 0,
            history: const [],
            inputMethod: InputMethod.type,
            isPlacingTaps: false,
            awaitingTypeInput: true,
          ));
          break;
      }
    });

    on<VertexSelected>((e, emit) {
      if (state.isPlacingTaps) return;
      emit(state.copyWith(selectedIndex: e.index));
    });

    on<VertexMoved>((e, emit) {
      if (state.isPlacingTaps) return;
      final next = List<Vertex>.from(state.vertices);
      next[e.index] = e.position;
      emit(state.copyWith(vertices: next, selectedIndex: e.index));
    });

    on<VertexInserted>((e, emit) {
      if (state.isPlacingTaps) return;
      final i = e.afterIndex;
      final n = state.vertices.length;
      final mid = Geometry.midpoint(
        state.vertices[i],
        state.vertices[(i + 1) % n],
      );
      final hist = [...state.history, List<Vertex>.from(state.vertices)];
      final next = List<Vertex>.from(state.vertices)..insert(i + 1, mid);
      emit(state.copyWith(
        vertices: next,
        selectedIndex: i + 1,
        history: hist,
      ));
    });

    on<VertexRemoved>((e, emit) {
      if (state.vertices.length <= 3) return;
      final hist = [...state.history, List<Vertex>.from(state.vertices)];
      final next = List<Vertex>.from(state.vertices)..removeAt(e.index);
      emit(state.copyWith(
        vertices: next,
        selectedIndex: 0,
        history: hist,
      ));
    });

    on<DrawUndone>((e, emit) {
      if (state.history.isEmpty) return;
      final hist = List<List<Vertex>>.from(state.history);
      final last = hist.removeLast();
      emit(state.copyWith(
        vertices: last,
        history: hist,
        selectedIndex: 0,
      ));
    });

    on<AnglesToggled>(
      (e, emit) => emit(state.copyWith(showAngles: !state.showAngles)),
    );

    on<DiagonalsToggled>(
      (e, emit) =>
          emit(state.copyWith(showDiagonals: !state.showDiagonals)),
    );

    on<DiagonalAdjusted>((e, emit) {
      if (state.isPlacingTaps) return;
      if (e.newLengthMeters <= 0) return;
      final n = state.vertices.length;
      if (e.fromIndex < 0 || e.fromIndex >= n) return;
      if (e.toIndex < 0 || e.toIndex >= n) return;
      // The fixed endpoint stays put; the other moves along the axis.
      final anchorIdx = e.moveTo ? e.fromIndex : e.toIndex;
      final movingIdx = e.moveTo ? e.toIndex : e.fromIndex;
      final anchor = state.vertices[anchorIdx];
      final moving = state.vertices[movingIdx];
      final currentLen = Geometry.sideLength(anchor, moving);
      if (currentLen == 0) return;
      final scale = e.newLengthMeters / currentLen;
      final newMoving = Vertex(
        anchor.x + (moving.x - anchor.x) * scale,
        anchor.y + (moving.y - anchor.y) * scale,
      );
      final hist = [...state.history, List<Vertex>.from(state.vertices)];
      final next = List<Vertex>.from(state.vertices)..[movingIdx] = newMoving;
      emit(state.copyWith(
        vertices: next,
        history: hist,
        selectedIndex: movingIdx,
      ));
    });

    on<TapVertexAdded>((e, emit) {
      if (!state.isPlacingTaps) return;
      final next = [...state.vertices, e.position];
      emit(state.copyWith(
        vertices: next,
        selectedIndex: next.length - 1,
      ));
    });

    on<TapPlacementCompleted>((e, emit) {
      if (state.vertices.length < 3) return;
      emit(state.copyWith(isPlacingTaps: false));
    });

    on<TypeShapeGenerated>((e, emit) {
      emit(state.copyWith(
        vertices: e.vertices,
        selectedIndex: 0,
        isPlacingTaps: false,
        awaitingTypeInput: false,
        history: const [],
      ));
    });

    on<TypeInputAcknowledged>(
      (e, emit) => emit(state.copyWith(awaitingTypeInput: false)),
    );
  }
}
