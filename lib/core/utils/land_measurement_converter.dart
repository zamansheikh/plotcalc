/// Land Measurement Converter Utility
/// Converts square meters to various land measurement units
/// Primarily used for South Asian land measurements
library;

class LandMeasurementConverter {
  // Square meter to other units conversion factors
  static const double sqMeterToSqYard = 1.196;
  static const double sqMeterToSqFeet = 10.76;
  static const double sqMeterToSqInch = 1550;
  static const double sqYardToSqMeter = 1.0 / 1.196; // = ~0.8361

  // Land unit definitions (in square meters)
  // Calculated: sqYards × sqYardToSqMeter for precise conversion
  static const double sqMeterPerAcre = 4046.856; // 4840 sq yards
  static const double sqMeterPerBigha = 1348.929; // 1613 sq yards
  static const double sqMeterPerKatha = 67.076; // 80.16 sq yards
  static const double sqMeterPerShatak = 40.469; // 48.40 sq yards
  static const double sqMeterPerShotok = 4.187; // 5.01 sq yards
  static const double sqMeterPerHectare = 10000;

  // Land unit definitions in square yards (for reference)
  // Using exact values from user's specifications
  static const double sqYardsPerAcre = 4840.0;
  static const double sqYardsPerBigha = 1613.0;
  static const double sqYardsPerKatha = 80.16;
  static const double sqYardsPerShatak = 48.40; // 1/100 of acre
  static const double sqYardsPerShotok = 5.01; // 1/16 of katha

  /// Converts square meters to various land measurements
  /// Returns a map with both primary and fractional units
  /// Uses square yards as intermediate unit for better accuracy
  static Map<String, dynamic> convertToLandUnits(double sqMeters) {
    final result = <String, dynamic>{};

    // Convert to square yards first for calculations (maintains accuracy)
    double remainingQty = sqMeters * sqMeterToSqYard;

    // ===== ACRES =====
    int acres = (remainingQty / sqYardsPerAcre).floor();
    remainingQty = remainingQty - (acres * sqYardsPerAcre);

    if (acres > 0) {
      result['acres'] = acres;
      if (remainingQty > 0) {
        result['acresFraction'] = (remainingQty / sqYardsPerAcre)
            .toStringAsFixed(4);
      }
    }

    // ===== BIGHAS =====
    int bighas = (remainingQty / sqYardsPerBigha).floor();
    remainingQty = remainingQty - (bighas * sqYardsPerBigha);

    if (bighas > 0 ||
        (acres == 0 && (sqMeters * sqMeterToSqYard) >= sqYardsPerBigha)) {
      result['bighas'] = bighas;
      if (remainingQty > 0) {
        result['bighasFraction'] = (remainingQty / sqYardsPerBigha)
            .toStringAsFixed(4);
      }
    }

    // ===== KATHAS =====
    int kathas = (remainingQty / sqYardsPerKatha).floor();
    remainingQty = remainingQty - (kathas * sqYardsPerKatha);

    if (kathas > 0) {
      result['kathas'] = kathas;
      if (remainingQty > 0) {
        result['kathasFraction'] = (remainingQty / sqYardsPerKatha)
            .toStringAsFixed(4);
      }
    }

    // ===== SHATAKS (Percent) =====
    int shataks = (remainingQty / sqYardsPerShatak).floor();
    remainingQty = remainingQty - (shataks * sqYardsPerShatak);

    if (shataks > 0) {
      result['shataks'] = shataks;
      if (remainingQty > 0) {
        result['shataksFraction'] = (remainingQty / sqYardsPerShatak)
            .toStringAsFixed(4);
      }
    }

    // ===== SHOTOKS (Chotak) =====
    int shotoks = (remainingQty / sqYardsPerShotok).floor();
    remainingQty = remainingQty - (shotoks * sqYardsPerShotok);

    if (shotoks > 0) {
      result['shotoks'] = shotoks;
      if (remainingQty > 0) {
        result['shotoksFraction'] = (remainingQty / sqYardsPerShotok)
            .toStringAsFixed(4);
      }
    }

    // Always include square meters
    result['sqMeters'] = sqMeters.toStringAsFixed(2);
    result['sqYards'] = (sqMeters * sqMeterToSqYard).toStringAsFixed(2);

    return result;
  }

  /// Formats the land measurement into a human-readable string
  static String formatLandMeasurement(double sqMeters) {
    final measurements = convertToLandUnits(sqMeters);

    final parts = <String>[];

    if (measurements.containsKey('acres') && measurements['acres'] > 0) {
      parts.add(
        '${measurements['acres']} acre${measurements['acres'] > 1 ? 's' : ''}',
      );
    }

    if (measurements.containsKey('bighas') && measurements['bighas'] > 0) {
      parts.add(
        '${measurements['bighas']} bigha${measurements['bighas'] > 1 ? 's' : ''}',
      );
    }

    if (measurements.containsKey('kathas') && measurements['kathas'] > 0) {
      parts.add(
        '${measurements['kathas']} katha${measurements['kathas'] > 1 ? 's' : ''}',
      );
    }

    if (measurements.containsKey('shataks') && measurements['shataks'] > 0) {
      parts.add(
        '${measurements['shataks']} shatak${measurements['shataks'] > 1 ? 's' : ''}',
      );
    }

    if (measurements.containsKey('shotoks') && measurements['shotoks'] > 0) {
      parts.add(
        '${measurements['shotoks']} shotok${measurements['shotoks'] > 1 ? 's' : ''}',
      );
    }

    // If no major units, show meters
    if (parts.isEmpty) {
      return '${measurements['sqMeters']} sq meters';
    }

    return parts.join(', ');
  }

  /// Converts square meters to square yards
  static double sqMetersToSqYards(double sqMeters) {
    return sqMeters * sqMeterToSqYard;
  }

  /// Converts square meters to square feet
  static double sqMetersToSqFeet(double sqMeters) {
    return sqMeters * sqMeterToSqFeet;
  }

  /// Converts square meters to acres
  static double sqMetersToAcres(double sqMeters) {
    return sqMeters / sqMeterPerAcre;
  }

  /// Converts square meters to bighas
  static double sqMetersToBighas(double sqMeters) {
    return sqMeters / sqMeterPerBigha;
  }

  /// Converts square meters to kathas
  static double sqMetersToKathas(double sqMeters) {
    return sqMeters / sqMeterPerKatha;
  }

  /// Converts square meters to hectares
  static double sqMetersToHectares(double sqMeters) {
    return sqMeters / sqMeterPerHectare;
  }

  /// Detailed breakdown showing all units
  static String getDetailedBreakdown(double sqMeters) {
    final measurements = convertToLandUnits(sqMeters);

    final buffer = StringBuffer();
    buffer.writeln('=== Land Measurement Breakdown ===\n');

    if (measurements.containsKey('acres') && measurements['acres'] > 0) {
      buffer.writeln('Acres: ${measurements['acres']}');
      if (measurements.containsKey('acresFraction')) {
        buffer.writeln('  (${measurements['acresFraction']} of an acre)');
      }
    }

    if (measurements.containsKey('bighas') && measurements['bighas'] > 0) {
      buffer.writeln('Bighas: ${measurements['bighas']}');
      if (measurements.containsKey('bighasFraction')) {
        buffer.writeln('  (${measurements['bighasFraction']} of a bigha)');
      }
    }

    if (measurements.containsKey('kathas') && measurements['kathas'] > 0) {
      buffer.writeln('Kathas: ${measurements['kathas']}');
      if (measurements.containsKey('kathasFraction')) {
        buffer.writeln('  (${measurements['kathasFraction']} of a katha)');
      }
    }

    if (measurements.containsKey('shataks') && measurements['shataks'] > 0) {
      buffer.writeln('Shataks: ${measurements['shataks']}');
      if (measurements.containsKey('shataksFraction')) {
        buffer.writeln('  (${measurements['shataksFraction']} of a shatak)');
      }
    }

    if (measurements.containsKey('shotoks') && measurements['shotoks'] > 0) {
      buffer.writeln('Shotoks: ${measurements['shotoks']}');
      if (measurements.containsKey('shotoksFraction')) {
        buffer.writeln('  (${measurements['shotoksFraction']} of a shotok)');
      }
    }

    buffer.writeln('\n--- Standard Units ---');
    buffer.writeln('Square Meters: ${measurements['sqMeters']}');
    buffer.writeln('Square Yards: ${measurements['sqYards']}');
    buffer.writeln(
      'Square Feet: ${sqMetersToSqFeet(sqMeters).toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Hectares: ${sqMetersToHectares(sqMeters).toStringAsFixed(4)}',
    );

    return buffer.toString();
  }

  /// Verify calculation: calculates back to square meters from components
  static double verifyCalculation(
    int acres,
    int bighas,
    int kathas,
    int shataks,
    int shotoks,
  ) {
    double sqYards = 0.0;
    sqYards += acres * sqYardsPerAcre;
    sqYards += bighas * sqYardsPerBigha;
    sqYards += kathas * sqYardsPerKatha;
    sqYards += shataks * sqYardsPerShatak;
    sqYards += shotoks * sqYardsPerShotok;

    return sqYards * sqYardToSqMeter;
  }
}
