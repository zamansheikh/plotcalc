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
    on<AdjustReset>((e, emit) {
      final base = Geometry.polygonArea(state.baseVertices);
      emit(state.copyWith(targetSqm: base));
    });
  }
}
