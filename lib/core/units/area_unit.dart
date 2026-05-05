import 'package:intl/intl.dart';

enum AreaUnit {
  sqft('sq ft', 10.7639, 0, 'Square feet'),
  sqm('m²', 1, 1, 'Square meters'),
  acre('acre', 0.000247105, 4, 'Acres'),
  hectare('hectare', 0.0001, 4, 'Hectares'),
  bigha('bigha', 0.00747384, 4, 'Bigha'),
  katha('katha', 0.014947, 3, 'Katha'),
  chatak('chatak', 0.239, 2, 'Chatak'),
  shotok('shotok', 0.0247105, 3, 'Shotok');

  final String label;
  final double factor;
  final int precision;
  final String displayName;

  const AreaUnit(this.label, this.factor, this.precision, this.displayName);

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
