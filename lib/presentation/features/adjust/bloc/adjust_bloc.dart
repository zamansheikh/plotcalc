import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/geometry/geometry.dart';
import 'adjust_event.dart';
import 'adjust_state.dart';

class AdjustBloc extends Bloc<AdjustEvent, AdjustState> {
  AdjustBloc() : super(const AdjustState()) {
    on<AdjustInitialized>((e, emit) {
      final base = Geometry.polygonArea(e.base);
      emit(state.copyWith(
        baseVertices: e.base,
        targetSqm: base * e.initialMultiplier,
      ));
    });
    on<TargetChanged>((e, emit) {
      emit(state.copyWith(targetSqm: e.sqm < 0 ? 0 : e.sqm));
    });
    on<ModeChanged>((e, emit) => emit(state.copyWith(mode: e.mode)));
    on<AnchorChanged>((e, emit) => emit(state.copyWith(anchor: e.anchor)));
    on<DisplayUnitChanged>(
      (e, emit) => emit(state.copyWith(displayUnit: e.unit)),
    );
    on<MethodChanged>((e, emit) => emit(state.copyWith(method: e.method)));
    on<TargetKindChanged>((e, emit) {
      // Side 2 and corner 2 are different things, so the selection cannot
      // carry across.
      emit(state.copyWith(targetKind: e.kind, selection: const {}));
    });
    on<SelectionToggled>((e, emit) {
      final next = Set<int>.from(state.selection);
      next.contains(e.index) ? next.remove(e.index) : next.add(e.index);
      emit(state.copyWith(selection: next));
    });
    on<SlideDirectionToggled>(
      (e, emit) => emit(state.copyWith(slideAlongNext: !state.slideAlongNext)),
    );
    on<SelectionCleared>(
      (e, emit) => emit(state.copyWith(selection: const {})),
    );
    on<AdjustReset>((e, emit) {
      final base = Geometry.polygonArea(state.baseVertices);
      emit(state.copyWith(targetSqm: base));
    });
  }
}
