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
  final Map<String, int> unitValues; // Map of unit ID to integer count
  final double remainderSqFt;
  final String? lastUnitDecimal;

  LandAreaResult({
    required this.breakdown,
    required this.unitValues,
    required this.remainderSqFt,
    this.lastUnitDecimal,
  });
}

class LandAreaCalculator {
  static List<LandUnitDef> getDefaultUnits() {
    return [
      LandUnitDef(
        id: 'bighaMymensingh',
        name: 'Bigha (Mymensingh)',
        sqftFactor: 56628.0,
        isEnabled: false,
      ),
      LandUnitDef(id: 'acre', name: 'Acre', sqftFactor: 43560.0),
      LandUnitDef(id: 'bigha', name: 'Bigha (Standard)', sqftFactor: 14520.0),
      LandUnitDef(
        id: 'kathaMymensingh',
        name: 'Katha (Mymensingh)',
        sqftFactor: 2831.4,
        isEnabled: false,
      ),
      LandUnitDef(id: 'katha', name: 'Katha (Standard)', sqftFactor: 721.46),
      LandUnitDef(id: 'shatak', name: 'Shatak', sqftFactor: 435.6),
      LandUnitDef(id: 'chotak', name: 'Chotak', sqftFactor: 45.09),
    ];
  }

  static LandAreaResult calculate(double totalSqFt, List<LandUnitDef> units) {
    List<String> results = [];
    Map<String, int> unitValues = {};
    double currentArea = totalSqFt;
    LandUnitDef? lastUsedUnit;
    int lastUsedUnitCount = 0;

    for (var unit in units) {
      if (unit.isEnabled && currentArea >= unit.sqftFactor) {
        int count = (currentArea / unit.sqftFactor).floor();
        if (count > 0) {
          results.add('$count ${unit.name}');
          unitValues[unit.id] = count;
          currentArea -= count * unit.sqftFactor;
          lastUsedUnit = unit;
          lastUsedUnitCount = count;
        }
      }
    }

    String? decimalStr;
    if (lastUsedUnit != null && currentArea > 0.01) {
      double decimalPart = currentArea / lastUsedUnit.sqftFactor;
      double totalDecimal = lastUsedUnitCount + decimalPart;
      decimalStr = '${totalDecimal.toStringAsFixed(2)} ${lastUsedUnit.name}';
    } else if (results.isEmpty && currentArea > 0.01) {
      try {
        final smallestUnit = units.lastWhere((u) => u.isEnabled);
        double val = totalSqFt / smallestUnit.sqftFactor;
        decimalStr = '${val.toStringAsFixed(2)} ${smallestUnit.name}';
      } catch (e) {
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
