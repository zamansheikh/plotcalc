import 'package:intl/intl.dart';

/// Exact square metres in one square foot. The international foot is defined
/// as exactly 0.3048 m, so 0.3048² is exact rather than an approximation.
const double sqmPerSqft = 0.09290304;

/// Square feet in one acre — exact by definition (1 acre = 10 sq chains).
const double _sqftPerAcre = 43560;

/// A shotok (decimal) is exactly one hundredth of an acre: 435.6 sq ft.
const double _sqftPerShotok = _sqftPerAcre / 100;

/// Bangladesh's standard katha, as used in Dhaka and in land deeds
/// generally: 720 sq ft. Twenty of them make a bigha, sixteen chatak make
/// one katha. Regional conventions differ — see the Mymensingh pair below.
const double _sqftPerKatha = 720;

/// Mymensingh's regional katha is 6.5 shotok rather than the standard
/// 1.65, and twenty of them still make one (much larger) bigha — so a
/// Mymensingh bigha is 130 shotok, or 1.3 acres.
const double _shotokPerKathaMymensingh = 6.5;
const double _sqftPerKathaMymensingh =
    _sqftPerShotok * _shotokPerKathaMymensingh;

const double _kathaPerBigha = 20;
const double _chatakPerKatha = 16;

/// Area units the app can display and convert between.
///
/// Each unit is declared by its size **in square feet**, because that is how
/// the Bangladeshi units are actually defined (a katha is 720 sq ft; a shotok
/// is 1/100 acre). Everything else is derived. Declaring a pre-divided
/// "units per square metre" constant instead is how `bigha` ended up an
/// order of magnitude wrong: a dropped zero in a long decimal is invisible,
/// whereas `20 * _sqftPerKatha` is self-evidently twenty katha.
enum AreaUnit {
  sqft(1, 0),
  sqm(1 / sqmPerSqft, 1),
  acre(_sqftPerAcre, 4),
  hectare(10000 / sqmPerSqft, 4),
  bigha(_kathaPerBigha * _sqftPerKatha, 4),
  katha(_sqftPerKatha, 3),
  chatak(_sqftPerKatha / _chatakPerKatha, 2),
  shotok(_sqftPerShotok, 3),
  bighaMymensingh(_kathaPerBigha * _sqftPerKathaMymensingh, 5),
  kathaMymensingh(_sqftPerKathaMymensingh, 3);

  /// How many square feet one of this unit covers.
  final double sqftPerUnit;

  /// Fraction digits used when displaying this unit.
  final int precision;

  // Unit names are locale-dependent — see AreaUnitL10n in l10n.dart.
  const AreaUnit(this.sqftPerUnit, this.precision);

  /// Square metres one of this unit covers.
  double get sqmPerUnit => sqftPerUnit * sqmPerSqft;

  /// How many of this unit fit in one square metre.
  double get factor => 1 / sqmPerUnit;

  /// Convert square meters to this unit.
  double fromSqm(double sqm) => sqm / sqmPerUnit;

  /// Convert this unit value back to square meters.
  double toSqm(double v) => v * sqmPerUnit;

  /// Format a square-meter value as a readable string in this unit.
  String format(double sqm) {
    final v = fromSqm(sqm);
    if (precision == 0) {
      return NumberFormat.decimalPattern().format(v.round());
    }
    final f = NumberFormat.decimalPattern();
    f.minimumFractionDigits = precision;
    f.maximumFractionDigits = precision;
    return f.format(v);
  }

  static AreaUnit fromKey(String key) {
    return AreaUnit.values.firstWhere(
      (u) => u.name == key,
      orElse: () => AreaUnit.sqft,
    );
  }
}
