import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import '../../../core/units/area_breakdown.dart';
import '../../../core/units/area_unit.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const _localeKey = 'plotcalc.locale.v1';
  static const _breakdownOrderKey = 'plotcalc.breakdown.order.v1';
  static const _breakdownEnabledKey = 'plotcalc.breakdown.enabled.v1';

  SettingsBloc()
    : super(
        SettingsState(
          locale: _restoreLocale(),
          breakdown: _restoreBreakdown(),
        ),
      ) {
    on<AccentChanged>((e, emit) => emit(state.copyWith(accent: e.color)));
    on<GridStyleChanged>((e, emit) => emit(state.copyWith(gridStyle: e.style)));
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
    on<BreakdownUnitToggled>(
      (e, emit) => _saveBreakdown(emit, state.breakdown.toggled(e.unit)),
    );
    on<BreakdownUnitsReordered>(
      (e, emit) => _saveBreakdown(
        emit,
        state.breakdown.reordered(e.oldIndex, e.newIndex),
      ),
    );
    on<BreakdownReset>(
      (e, emit) => _saveBreakdown(emit, BreakdownConfig.defaults),
    );
  }

  void _saveBreakdown(Emitter<SettingsState> emit, BreakdownConfig config) {
    final prefs = sl<SharedPreferences>();
    prefs.setStringList(
      _breakdownOrderKey,
      config.order.map((u) => u.name).toList(),
    );
    prefs.setStringList(
      _breakdownEnabledKey,
      config.enabled.map((u) => u.name).toList(),
    );
    emit(state.copyWith(breakdown: config));
  }

  /// Reads the saved language, if the user ever picked one. Returning `null`
  /// leaves the app on the device language.
  static Locale? _restoreLocale() {
    final code = sl<SharedPreferences>().getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  static BreakdownConfig _restoreBreakdown() {
    final prefs = sl<SharedPreferences>();
    final savedOrder = prefs.getStringList(_breakdownOrderKey);
    final savedEnabled = prefs.getStringList(_breakdownEnabledKey);
    if (savedOrder == null || savedEnabled == null) {
      return BreakdownConfig.defaults;
    }

    final byName = {for (final u in AreaUnit.values) u.name: u};

    // Drop names that no longer exist, then append any unit added since the
    // preference was written so a new release can't leave it unreachable.
    final order = <AreaUnit>[
      for (final name in savedOrder)
        if (byName[name] != null) byName[name]!,
    ];
    for (final u in BreakdownConfig.defaults.order) {
      if (!order.contains(u)) order.add(u);
    }

    return BreakdownConfig(
      order: order,
      enabled: {
        for (final name in savedEnabled)
          if (byName[name] != null) byName[name]!,
      },
      // Stored preferences are just data: a file that enables both a standard
      // and a Mymensingh unit must not produce a mixed-convention reading.
    ).sanitized();
  }
}
