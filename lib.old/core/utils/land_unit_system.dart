import 'package:flutter/widgets.dart';
import '../localization/app_localizations.dart';

/// Single source of truth for all land-area conversions used by the app.
///
/// Every page that converts, displays, or breaks down land areas should use
/// these helpers. Do not duplicate the factors elsewhere — drift between
/// pages was a long-standing bug.
class LandUnitSystem {
  // sq.ft per unit. These are the canonical factors.
  static const double sqftPerSqMeter = 10.7639104167;
  static const double sqMeterPerSqft = 0.09290304;

  static const double sqftPerHectare = 107639.104167;
  static const double sqftPerAcre = 43560.0;
  static const double sqftPerBigha = 14520.0;
  static const double sqftPerKatha = 721.46;
  static const double sqftPerShatak = 435.6;
  static const double sqftPerChotak = 45.09;

  // Mymensingh region uses different bigha/katha sizes.
  // 1 Katha (Mymensingh) = 6.5 Shatak; 1 Bigha (Mymensingh) = 20 Katha (Mymensingh).
  static const double sqftPerKathaMymensingh = sqftPerShatak * 6.5; // 2831.4
  static const double sqftPerBighaMymensingh =
      sqftPerKathaMymensingh * 20; // 56628.0

  // Rounding epsilon for floor() to avoid losing units at boundaries
  // (e.g. 14519.999999 → 0 bighas instead of 1).
  static const double _epsilon = 1e-6;

  static const Map<LandUnitId, double> _sqftFactor = {
    LandUnitId.squareMeter: 1 / sqMeterPerSqft, // 10.76391...
    LandUnitId.squareFeet: 1.0,
    LandUnitId.hectare: sqftPerHectare,
    LandUnitId.acre: sqftPerAcre,
    LandUnitId.bigha: sqftPerBigha,
    LandUnitId.katha: sqftPerKatha,
    LandUnitId.shatak: sqftPerShatak,
    LandUnitId.chotak: sqftPerChotak,
    LandUnitId.bighaMymensingh: sqftPerBighaMymensingh,
    LandUnitId.kathaMymensingh: sqftPerKathaMymensingh,
  };

  static double sqftFactor(LandUnitId id) => _sqftFactor[id]!;

  /// Convert any unit value into square feet (the internal canonical unit).
  static double toSqft(double value, LandUnitId fromUnit) =>
      value * sqftFactor(fromUnit);

  /// Convert square feet into any unit.
  static double fromSqft(double sqft, LandUnitId toUnit) =>
      sqft / sqftFactor(toUnit);

  /// Convert between any two units.
  static double convert(double value, LandUnitId from, LandUnitId to) {
    if (from == to) return value;
    return toSqft(value, from) / sqftFactor(to);
  }

  /// Localized display name for a unit id.
  static String name(BuildContext context, LandUnitId id) {
    final loc = AppLocalizations.of(context);
    switch (id) {
      case LandUnitId.squareMeter:
        return loc.metersTitle;
      case LandUnitId.squareFeet:
        return loc.squareFeet;
      case LandUnitId.hectare:
        return loc.hectares;
      case LandUnitId.acre:
        return loc.acres;
      case LandUnitId.bigha:
        return loc.bighaStandard;
      case LandUnitId.katha:
        return loc.kathaStandard;
      case LandUnitId.shatak:
        return loc.shatak;
      case LandUnitId.chotak:
        return loc.chotak;
      case LandUnitId.bighaMymensingh:
        return loc.bighaMymensingh;
      case LandUnitId.kathaMymensingh:
        return loc.kathaMymensingh;
    }
  }

  /// Short label suitable for chips / dropdowns.
  static String shortName(BuildContext context, LandUnitId id) {
    final loc = AppLocalizations.of(context);
    switch (id) {
      case LandUnitId.squareMeter:
        return 'm²';
      case LandUnitId.squareFeet:
        return 'ft²';
      case LandUnitId.hectare:
        return 'ha';
      case LandUnitId.acre:
        return loc.acre;
      case LandUnitId.bigha:
        return loc.bigha;
      case LandUnitId.katha:
        return loc.katha;
      case LandUnitId.shatak:
        return loc.shatak;
      case LandUnitId.chotak:
        return loc.chotak;
      case LandUnitId.bighaMymensingh:
        return '${loc.bigha} (M)';
      case LandUnitId.kathaMymensingh:
        return '${loc.katha} (M)';
    }
  }

  /// Default ordering for breakdown (largest → smallest), with the
  /// region-specific Mymensingh units disabled by default.
  static List<LandUnitConfig> defaultBreakdownUnits() {
    return [
      LandUnitConfig(id: LandUnitId.bighaMymensingh, isEnabled: false),
      LandUnitConfig(id: LandUnitId.acre, isEnabled: true),
      LandUnitConfig(id: LandUnitId.bigha, isEnabled: true),
      LandUnitConfig(id: LandUnitId.kathaMymensingh, isEnabled: false),
      LandUnitConfig(id: LandUnitId.katha, isEnabled: true),
      LandUnitConfig(id: LandUnitId.shatak, isEnabled: true),
      LandUnitConfig(id: LandUnitId.chotak, isEnabled: true),
    ];
  }

  /// Full list of conversion display units (used by unit converter page).
  static const List<LandUnitId> allConversionUnits = [
    LandUnitId.squareMeter,
    LandUnitId.squareFeet,
    LandUnitId.hectare,
    LandUnitId.acre,
    LandUnitId.bigha,
    LandUnitId.katha,
    LandUnitId.shatak,
    LandUnitId.chotak,
    LandUnitId.bighaMymensingh,
    LandUnitId.kathaMymensingh,
  ];

  /// Convert square feet into a multi-unit breakdown using the given config.
  /// Larger units are extracted first (the order is taken from [units]).
  static LandBreakdown breakdown(double totalSqft, List<LandUnitConfig> units) {
    final entries = <LandBreakdownEntry>[];
    final perUnit = <LandUnitId, int>{};
    double remaining = totalSqft;
    LandUnitConfig? lastUsed;
    int lastUsedCount = 0;

    for (final config in units) {
      if (!config.isEnabled) continue;
      final factor = sqftFactor(config.id);
      // Add a tiny epsilon to avoid floating-point boundary loss.
      final count = ((remaining + _epsilon) / factor).floor();
      if (count > 0) {
        entries.add(LandBreakdownEntry(unitId: config.id, count: count));
        perUnit[config.id] = count;
        remaining -= count * factor;
        if (remaining < 0) remaining = 0; // clamp drift
        lastUsed = config;
        lastUsedCount = count;
      }
    }

    String? decimalLabel;
    LandUnitId? decimalUnit;
    double? decimalValue;
    if (lastUsed != null && remaining > 0.01) {
      final factor = sqftFactor(lastUsed.id);
      final total = lastUsedCount + remaining / factor;
      decimalUnit = lastUsed.id;
      decimalValue = total;
      decimalLabel = total.toStringAsFixed(2);
    } else if (entries.isEmpty && remaining > 0.01) {
      // Fall back to the smallest enabled unit.
      LandUnitConfig? smallest;
      for (final u in units) {
        if (u.isEnabled) smallest = u;
      }
      if (smallest != null) {
        final factor = sqftFactor(smallest.id);
        final total = totalSqft / factor;
        decimalUnit = smallest.id;
        decimalValue = total;
        decimalLabel = total.toStringAsFixed(2);
      }
    }

    return LandBreakdown(
      totalSqft: totalSqft,
      entries: entries,
      perUnit: perUnit,
      remainderSqft: remaining,
      decimalUnit: decimalUnit,
      decimalValue: decimalValue,
      decimalLabel: decimalLabel,
    );
  }

  /// Format a number in a human-friendly way.
  /// Large values keep 2 decimals; tiny values keep more precision.
  static String formatNumber(double value) {
    if (value == 0) return '0';
    final abs = value.abs();
    if (abs >= 100) return value.toStringAsFixed(2);
    if (abs >= 1) return value.toStringAsFixed(3);
    if (abs >= 0.001) return value.toStringAsFixed(5);
    return value.toStringAsExponential(3);
  }
}

/// Identifier for every supported land unit.
enum LandUnitId {
  squareMeter,
  squareFeet,
  hectare,
  acre,
  bigha,
  katha,
  shatak,
  chotak,
  bighaMymensingh,
  kathaMymensingh,
}

/// A unit + whether it participates in a multi-unit breakdown.
/// Mutable so the user can re-order and toggle units interactively.
class LandUnitConfig {
  final LandUnitId id;
  bool isEnabled;

  LandUnitConfig({required this.id, this.isEnabled = true});

  LandUnitConfig copy() => LandUnitConfig(id: id, isEnabled: isEnabled);
}

class LandBreakdownEntry {
  final LandUnitId unitId;
  final int count;
  const LandBreakdownEntry({required this.unitId, required this.count});
}

class LandBreakdown {
  final double totalSqft;
  final List<LandBreakdownEntry> entries;
  final Map<LandUnitId, int> perUnit;
  final double remainderSqft;
  final LandUnitId? decimalUnit;
  final double? decimalValue;
  final String? decimalLabel;

  const LandBreakdown({
    required this.totalSqft,
    required this.entries,
    required this.perUnit,
    required this.remainderSqft,
    this.decimalUnit,
    this.decimalValue,
    this.decimalLabel,
  });

  bool get isEmpty => entries.isEmpty && remainderSqft <= 0.01;
}
