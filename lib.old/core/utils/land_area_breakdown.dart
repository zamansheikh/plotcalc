import 'land_unit_system.dart';

/// Legacy data shapes kept for back-compat with drawing/resize pages.
/// New code should use [LandUnitSystem] directly.
class LandUnitDef {
  final String id;
  final String name;
  final double sqftFactor;
  bool isEnabled;

  LandUnitDef({
    required this.id,
    required this.name,
    required this.sqftFactor,
    this.isEnabled = true,
  });
}

class LandAreaResult {
  final List<String> breakdown;
  final Map<String, int> unitValues;
  final double remainderSqFt;
  final String? lastUnitDecimal;

  LandAreaResult({
    required this.breakdown,
    required this.unitValues,
    required this.remainderSqFt,
    this.lastUnitDecimal,
  });
}

/// Thin wrapper that delegates conversion math to [LandUnitSystem] so every
/// caller (calculator, drawing, resize) shares the same canonical factors.
class LandAreaCalculator {
  static LandUnitDef _def(LandUnitId id, String name, {bool enabled = true}) {
    return LandUnitDef(
      id: _legacyId(id),
      name: name,
      sqftFactor: LandUnitSystem.sqftFactor(id),
      isEnabled: enabled,
    );
  }

  static String _legacyId(LandUnitId id) {
    switch (id) {
      case LandUnitId.bighaMymensingh:
        return 'bighaMymensingh';
      case LandUnitId.kathaMymensingh:
        return 'kathaMymensingh';
      case LandUnitId.acre:
        return 'acre';
      case LandUnitId.bigha:
        return 'bigha';
      case LandUnitId.katha:
        return 'katha';
      case LandUnitId.shatak:
        return 'shatak';
      case LandUnitId.chotak:
        return 'chotak';
      case LandUnitId.squareMeter:
        return 'squareMeters';
      case LandUnitId.squareFeet:
        return 'squareFeet';
      case LandUnitId.hectare:
        return 'hectares';
    }
  }

  static List<LandUnitDef> getDefaultUnits() {
    return [
      _def(LandUnitId.bighaMymensingh, 'Bigha (Mymensingh)', enabled: false),
      _def(LandUnitId.acre, 'Acre'),
      _def(LandUnitId.bigha, 'Bigha (Standard)'),
      _def(LandUnitId.kathaMymensingh, 'Katha (Mymensingh)', enabled: false),
      _def(LandUnitId.katha, 'Katha (Standard)'),
      _def(LandUnitId.shatak, 'Shatak'),
      _def(LandUnitId.chotak, 'Chotak'),
    ];
  }

  static LandAreaResult calculate(double totalSqFt, List<LandUnitDef> units) {
    const epsilon = 1e-6;
    final results = <String>[];
    final unitValues = <String, int>{};
    double currentArea = totalSqFt;
    LandUnitDef? lastUsedUnit;
    int lastUsedUnitCount = 0;

    for (final unit in units) {
      if (unit.isEnabled && currentArea + epsilon >= unit.sqftFactor) {
        final count = ((currentArea + epsilon) / unit.sqftFactor).floor();
        if (count > 0) {
          results.add('$count ${unit.name}');
          unitValues[unit.id] = count;
          currentArea -= count * unit.sqftFactor;
          if (currentArea < 0) currentArea = 0;
          lastUsedUnit = unit;
          lastUsedUnitCount = count;
        }
      }
    }

    String? decimalStr;
    if (lastUsedUnit != null && currentArea > 0.01) {
      final decimalPart = currentArea / lastUsedUnit.sqftFactor;
      final totalDecimal = lastUsedUnitCount + decimalPart;
      decimalStr = '${totalDecimal.toStringAsFixed(2)} ${lastUsedUnit.name}';
    } else if (results.isEmpty && currentArea > 0.01) {
      try {
        final smallestUnit = units.lastWhere((u) => u.isEnabled);
        final val = totalSqFt / smallestUnit.sqftFactor;
        decimalStr = '${val.toStringAsFixed(2)} ${smallestUnit.name}';
      } catch (_) {
        // No units enabled
      }
    }

    return LandAreaResult(
      breakdown: results,
      unitValues: unitValues,
      remainderSqFt: currentArea,
      lastUnitDecimal: decimalStr,
    );
  }
}
