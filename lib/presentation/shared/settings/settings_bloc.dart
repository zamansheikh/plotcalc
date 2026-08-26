import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const _localeKey = 'plotcalc.locale.v1';

  SettingsBloc() : super(SettingsState(locale: _restoreLocale())) {
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
    on<LocaleChanged>((e, emit) {
      sl<SharedPreferences>().setString(_localeKey, e.locale.languageCode);
      emit(state.copyWith(locale: e.locale));
    });
  }

  /// Reads the saved language, if the user ever picked one. Returning `null`
  /// leaves the app on the device language.
  static Locale? _restoreLocale() {
    final code = sl<SharedPreferences>().getString(_localeKey);
    return code == null ? null : Locale(code);
  }
}
