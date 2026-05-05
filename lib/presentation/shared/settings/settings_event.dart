import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/units/area_unit.dart';
import '../../../core/units/length_unit.dart';
import 'settings_state.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class AccentChanged extends SettingsEvent {
  final Color color;
  const AccentChanged(this.color);
  @override
  List<Object?> get props => [color];
}

class GridStyleChanged extends SettingsEvent {
  final GridStyle style;
  const GridStyleChanged(this.style);
  @override
  List<Object?> get props => [style];
}

class AreaUnitChanged extends SettingsEvent {
  final AreaUnit unit;
  const AreaUnitChanged(this.unit);
  @override
  List<Object?> get props => [unit];
}

class LengthUnitChanged extends SettingsEvent {
  final LengthUnit unit;
  const LengthUnitChanged(this.unit);
  @override
  List<Object?> get props => [unit];
}

class MapUnderlayToggled extends SettingsEvent {
  final bool enabled;
  const MapUnderlayToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}
