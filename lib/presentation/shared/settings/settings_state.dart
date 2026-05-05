import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/units/area_unit.dart';
import '../../../core/units/length_unit.dart';

enum GridStyle { dots, lines, blueprint }

class SettingsState extends Equatable {
  final Color accent;
  final GridStyle gridStyle;
  final AreaUnit areaUnit;
  final LengthUnit lengthUnit;
  final bool mapUnderlay;

  const SettingsState({
    this.accent = AppColors.lime,
    this.gridStyle = GridStyle.blueprint,
    this.areaUnit = AreaUnit.sqft,
    this.lengthUnit = LengthUnit.ft,
    this.mapUnderlay = false,
  });

  SettingsState copyWith({
    Color? accent,
    GridStyle? gridStyle,
    AreaUnit? areaUnit,
    LengthUnit? lengthUnit,
    bool? mapUnderlay,
  }) =>
      SettingsState(
        accent: accent ?? this.accent,
        gridStyle: gridStyle ?? this.gridStyle,
        areaUnit: areaUnit ?? this.areaUnit,
        lengthUnit: lengthUnit ?? this.lengthUnit,
        mapUnderlay: mapUnderlay ?? this.mapUnderlay,
      );

  @override
  List<Object?> get props =>
      [accent, gridStyle, areaUnit, lengthUnit, mapUnderlay];
}
