import 'package:intl/intl.dart';

enum AreaUnit {
  sqft(10.7639, 0),
  sqm(1, 1),
  acre(0.000247105, 4),
  hectare(0.0001, 4),
  bigha(0.00747384, 4),
  katha(0.014947, 3),
  chatak(0.239, 2),
  shotok(0.0247105, 3);

  final double factor;
  final int precision;

  // Unit names are locale-dependent — see AreaUnitL10n in l10n.dart.
  const AreaUnit(this.factor, this.precision);

  /// Convert square meters to this unit.
  double fromSqm(double sqm) => sqm * factor;

  /// Convert this unit value back to square meters.
  double toSqm(double v) => v / factor;

  /// Format a square-meter value as a readable string in this unit.
  String format(double sqm) {
    final v = sqm * factor;
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
