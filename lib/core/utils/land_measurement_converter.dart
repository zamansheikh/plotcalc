/// Legacy traditional-Bangladeshi land unit breakdown.
/// Backed by [LandUnitSystem] for canonical factors.
library;

import 'land_unit_system.dart';

class LandUnit {
  final int acres;
  final int bighas;
  final int kathas;
  final int shataks;
  final int chotaks;
  final double squareMeters; // remainder after chotak

  const LandUnit({
    required this.acres,
    required this.bighas,
    required this.kathas,
    required this.shataks,
    required this.chotaks,
    required this.squareMeters,
  });

  @override
  String toString() {
    final parts = <String>[];
    if (acres > 0) parts.add('$acres একর');
    if (bighas > 0) parts.add('$bighas বিঘা');
    if (kathas > 0) parts.add('$kathas কাঠা');
    if (shataks > 0) parts.add('$shataks শতাংশ');
    if (chotaks > 0) parts.add('$chotaks ছটাক');
    if (squareMeters > 0) {
      final m = squareMeters.toStringAsFixed(2);
      parts.add('$m বর্গমিটার');
    }
    return parts.isEmpty ? '0 বর্গমিটার' : parts.join(' ');
  }
}

class LandUnitConverter {
  static LandUnit fromSquareMeters(double sqm) =>
      _convert(sqm * LandUnitSystem.sqftPerSqMeter);

  static LandUnit fromSquareFeet(double sqft) => _convert(sqft);

  static LandUnit fromSquareMetersMymensingh(double sqm) =>
      _convertMymensingh(sqm * LandUnitSystem.sqftPerSqMeter);

  static LandUnit fromSquareFeetMymensingh(double sqft) =>
      _convertMymensingh(sqft);

  static LandUnit _convert(double totalSqft) {
    const eps = 1e-6;
    double sqft = totalSqft;

    final acres = ((sqft + eps) / LandUnitSystem.sqftPerAcre).floor();
    sqft -= acres * LandUnitSystem.sqftPerAcre;

    final bighas = ((sqft + eps) / LandUnitSystem.sqftPerBigha).floor();
    sqft -= bighas * LandUnitSystem.sqftPerBigha;

    final kathas = ((sqft + eps) / LandUnitSystem.sqftPerKatha).floor();
    sqft -= kathas * LandUnitSystem.sqftPerKatha;

    final shataks = ((sqft + eps) / LandUnitSystem.sqftPerShatak).floor();
    sqft -= shataks * LandUnitSystem.sqftPerShatak;

    final chotaks = ((sqft + eps) / LandUnitSystem.sqftPerChotak).floor();
    sqft -= chotaks * LandUnitSystem.sqftPerChotak;

    if (sqft < 0) sqft = 0;
    final sqmRemainder = sqft * LandUnitSystem.sqMeterPerSqft;
    final roundedSqm = (sqmRemainder * 100).round() / 100.0;

    return LandUnit(
      acres: acres,
      bighas: bighas,
      kathas: kathas,
      shataks: shataks,
      chotaks: chotaks,
      squareMeters: roundedSqm,
    );
  }

  static LandUnit _convertMymensingh(double totalSqft) {
    const eps = 1e-6;
    double sqft = totalSqft;

    final bighas =
        ((sqft + eps) / LandUnitSystem.sqftPerBighaMymensingh).floor();
    sqft -= bighas * LandUnitSystem.sqftPerBighaMymensingh;

    final kathas =
        ((sqft + eps) / LandUnitSystem.sqftPerKathaMymensingh).floor();
    sqft -= kathas * LandUnitSystem.sqftPerKathaMymensingh;

    final shataks = ((sqft + eps) / LandUnitSystem.sqftPerShatak).floor();
    sqft -= shataks * LandUnitSystem.sqftPerShatak;

    final chotaks = ((sqft + eps) / LandUnitSystem.sqftPerChotak).floor();
    sqft -= chotaks * LandUnitSystem.sqftPerChotak;

    if (sqft < 0) sqft = 0;
    final sqmRemainder = sqft * LandUnitSystem.sqMeterPerSqft;
    final roundedSqm = (sqmRemainder * 100).round() / 100.0;

    return LandUnit(
      acres: 0,
      bighas: bighas,
      kathas: kathas,
      shataks: shataks,
      chotaks: chotaks,
      squareMeters: roundedSqm,
    );
  }
}
