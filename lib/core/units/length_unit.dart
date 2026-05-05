enum LengthUnit {
  ft('ft', 3.28084),
  m('m', 1);

  final String label;
  final double factor;

  const LengthUnit(this.label, this.factor);

  double fromMeters(double meters) => meters * factor;

  /// Convert a value expressed in this unit back to meters.
  double toMeters(double value) => value / factor;

  String format(double meters) => fromMeters(meters).toStringAsFixed(1);

  static LengthUnit fromKey(String key) {
    return LengthUnit.values.firstWhere(
      (u) => u.name == key,
      orElse: () => LengthUnit.ft,
    );
  }
}
