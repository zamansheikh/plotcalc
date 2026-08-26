enum LengthUnit {
  ft(3.28084),
  m(1);

  final double factor;

  // Unit names are locale-dependent — see LengthUnitL10n in l10n.dart.
  const LengthUnit(this.factor);

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
