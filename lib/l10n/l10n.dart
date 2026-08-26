import 'package:flutter/widgets.dart';

import '../core/geometry/presets.dart';
import '../core/input_method.dart';
import '../core/units/area_unit.dart';
import '../core/units/length_unit.dart';
import '../domain/entities/plot.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Picks the locale the app runs in.
///
/// Generated [AppLocalizations.supportedLocales] is alphabetical, so Bengali
/// sits first and Flutter's default resolution would hand a French or Hindi
/// phone a Bengali UI. Match on language code, otherwise fall back to English.
Locale resolveAppLocale(Locale? device, Iterable<Locale> supported) {
  if (device != null) {
    for (final locale in supported) {
      if (locale.languageCode == device.languageCode) return locale;
    }
  }
  return const Locale('en');
}

extension L10nContext on BuildContext {
  /// Shorthand for the current translations: `context.l10n.actionSave`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Enum display names live here rather than on the enums themselves: the
/// enums are `const` and know nothing about a [BuildContext], while every
/// label has to change with the active locale.
extension AreaUnitL10n on AreaUnit {
  /// Short symbol shown next to a number ("sq ft", "বর্গফুট").
  String labelOf(AppLocalizations t) => switch (this) {
    AreaUnit.sqft => t.unitSqftLabel,
    AreaUnit.sqm => t.unitSqmLabel,
    AreaUnit.acre => t.unitAcreLabel,
    AreaUnit.hectare => t.unitHectareLabel,
    AreaUnit.bigha => t.unitBighaLabel,
    AreaUnit.katha => t.unitKathaLabel,
    AreaUnit.chatak => t.unitChatakLabel,
    AreaUnit.shotok => t.unitShotokLabel,
    AreaUnit.bighaMymensingh => t.unitBighaMymensinghLabel,
    AreaUnit.kathaMymensingh => t.unitKathaMymensinghLabel,
  };

  /// Full name used in pickers and lists ("Square feet").
  String nameOf(AppLocalizations t) => switch (this) {
    AreaUnit.sqft => t.unitSqftName,
    AreaUnit.sqm => t.unitSqmName,
    AreaUnit.acre => t.unitAcreName,
    AreaUnit.hectare => t.unitHectareName,
    AreaUnit.bigha => t.unitBighaName,
    AreaUnit.katha => t.unitKathaName,
    AreaUnit.chatak => t.unitChatakName,
    AreaUnit.shotok => t.unitShotokName,
    AreaUnit.bighaMymensingh => t.unitBighaMymensinghName,
    AreaUnit.kathaMymensingh => t.unitKathaMymensinghName,
  };
}

extension LengthUnitL10n on LengthUnit {
  String labelOf(AppLocalizations t) => switch (this) {
    LengthUnit.ft => t.unitFeetShort,
    LengthUnit.m => t.unitMeterShort,
  };

  String nameOf(AppLocalizations t) => switch (this) {
    LengthUnit.ft => t.unitFeet,
    LengthUnit.m => t.unitMeters,
  };
}

extension PlotTagL10n on PlotTag {
  String labelOf(AppLocalizations t) => switch (this) {
    PlotTag.agricultural => t.tagAgricultural,
    PlotTag.residential => t.tagResidential,
    PlotTag.commercial => t.tagCommercial,
    PlotTag.forest => t.tagForest,
    PlotTag.other => t.tagOther,
  };
}

extension ShapePresetL10n on ShapePreset {
  String labelOf(AppLocalizations t) => switch (this) {
    ShapePreset.rectangle => t.presetRectangle,
    ShapePreset.square => t.presetSquare,
    ShapePreset.triangle => t.presetTriangle,
    ShapePreset.trapezoid => t.presetTrapezoid,
    ShapePreset.pentagon => t.presetPentagon,
    ShapePreset.freeform => t.presetFreeform,
  };
}

extension InputMethodL10n on InputMethod {
  String labelOf(AppLocalizations t) => switch (this) {
    InputMethod.draw => t.methodDraw,
    InputMethod.tap => t.methodTap,
    InputMethod.type => t.methodType,
  };

  String subtitleOf(AppLocalizations t) => switch (this) {
    InputMethod.draw => t.methodDrawSub,
    InputMethod.tap => t.methodTapSub,
    InputMethod.type => t.methodTypeSub,
  };
}
