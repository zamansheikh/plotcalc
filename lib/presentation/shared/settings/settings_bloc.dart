import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<AccentChanged>((e, emit) => emit(state.copyWith(accent: e.color)));
    on<GridStyleChanged>(
      (e, emit) => emit(state.copyWith(gridStyle: e.style)),
    );
    on<AreaUnitChanged>((e, emit) => emit(state.copyWith(areaUnit: e.unit)));
    on<LengthUnitChanged>(
      (e, emit) => emit(state.copyWith(lengthUnit: e.unit)),
    );
    on<MapUnderlayToggled>(
      (e, emit) => emit(state.copyWith(mapUnderlay: e.enabled)),
    );
  }
}
