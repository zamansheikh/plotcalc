import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'measurement_unit_event.dart';
part 'measurement_unit_state.dart';

enum InputUnit {
  meters,
  feet;

  String get displayName {
    switch (this) {
      case InputUnit.meters:
        return 'Meters (m)';
      case InputUnit.feet:
        return 'Feet (ft)';
    }
  }

  String get symbol {
    switch (this) {
      case InputUnit.meters:
        return 'm';
      case InputUnit.feet:
        return 'ft';
    }
  }

  // Conversion factor to meters
  double toMeters(double value) {
    switch (this) {
      case InputUnit.meters:
        return value;
      case InputUnit.feet:
        return value * 0.3048; // 1 foot = 0.3048 meters
    }
  }

  // Conversion factor from meters
  double fromMeters(double meters) {
    switch (this) {
      case InputUnit.meters:
        return meters;
      case InputUnit.feet:
        return meters / 0.3048; // meters to feet
    }
  }
}

class MeasurementUnitBloc
    extends Bloc<MeasurementUnitEvent, MeasurementUnitState> {
  static const String _key = 'measurement_unit_preference';

  MeasurementUnitBloc() : super(const MeasurementUnitState(InputUnit.meters)) {
    on<LoadMeasurementUnitEvent>(_onLoadMeasurementUnit);
    on<ChangeMeasurementUnitEvent>(_onChangeMeasurementUnit);
  }

  Future<void> _onLoadMeasurementUnit(
    LoadMeasurementUnitEvent event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitName = prefs.getString(_key) ?? 'meters';
      final unit = InputUnit.values.firstWhere(
        (e) => e.name == unitName,
        orElse: () => InputUnit.meters,
      );
      emit(MeasurementUnitState(unit));
    } catch (e) {
      // If SharedPreferences fails, use default
      print('Error loading measurement unit preference: $e');
      emit(const MeasurementUnitState(InputUnit.meters));
    }
  }

  Future<void> _onChangeMeasurementUnit(
    ChangeMeasurementUnitEvent event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, event.unit.name);
      emit(MeasurementUnitState(event.unit));
    } catch (e) {
      // If SharedPreferences fails, still update the state
      print('Error saving measurement unit preference: $e');
      emit(MeasurementUnitState(event.unit));
    }
  }
}
