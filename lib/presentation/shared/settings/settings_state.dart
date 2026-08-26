import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/units/area_breakdown.dart';
import '../../../core/units/area_unit.dart';
import '../../../core/units/length_unit.dart';

enum GridStyle { dots, lines, blueprint }

class SettingsState extends Equatable {
  /// `null` means "follow the device language" — [MaterialApp] then resolves
  /// against `supportedLocales`, so a Bengali phone opens in Bengali without
  /// the user picking anything. Set once the user chooses explicitly.
  final Locale? locale;

  final Color accent;
  final GridStyle gridStyle;
  final AreaUnit areaUnit;
  final LengthUnit lengthUnit;
  final bool mapUnderlay;

  /// Which units make up a compound area reading, and in what order.
  final BreakdownConfig breakdown;

  const SettingsState({
    this.locale,
    this.accent = AppColors.lime,
    this.gridStyle = GridStyle.blueprint,
    this.areaUnit = AreaUnit.sqft,
    this.lengthUnit = LengthUnit.ft,
    this.mapUnderlay = false,
    this.breakdown = BreakdownConfig.defaults,
  });

  SettingsState copyWith({
    Locale? locale,
    bool resetLocale = false,
    Color? accent,
    GridStyle? gridStyle,
    AreaUnit? areaUnit,
    LengthUnit? lengthUnit,
    bool? mapUnderlay,
    BreakdownConfig? breakdown,
  }) =>
      SettingsState(
        locale: resetLocale ? null : (locale ?? this.locale),
        accent: accent ?? this.accent,
        gridStyle: gridStyle ?? this.gridStyle,
        areaUnit: areaUnit ?? this.areaUnit,
        lengthUnit: lengthUnit ?? this.lengthUnit,
        mapUnderlay: mapUnderlay ?? this.mapUnderlay,
        breakdown: breakdown ?? this.breakdown,
      );

  @override
  List<Object?> get props =>
      [
        locale,
        accent,
        gridStyle,
        areaUnit,
        lengthUnit,
        mapUnderlay,
        breakdown.order,
        breakdown.enabled,
      ];
}
