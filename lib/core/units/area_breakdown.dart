import 'area_unit.dart';

/// Which units take part in a compound breakdown, and in what order.
///
/// Order is the user's, not ours: the breakdown walks it top to bottom taking
/// whole units at each step, so listing largest-to-smallest is what produces
/// the familiar "1 bigha, 5 katha, 3 chatak" reading.
class BreakdownConfig {
  final List<AreaUnit> order;
  final Set<AreaUnit> enabled;

  const BreakdownConfig({required this.order, required this.enabled});

  /// The default arrangement. The Mymensingh units are present but off, so
  /// the ordering is already correct for anyone who switches them on.
  static const defaults = BreakdownConfig(
    order: [
      AreaUnit.bighaMymensingh,
      AreaUnit.acre,
      AreaUnit.bigha,
      AreaUnit.kathaMymensingh,
      AreaUnit.katha,
      AreaUnit.shotok,
      AreaUnit.chatak,
    ],
    enabled: {
      AreaUnit.acre,
      AreaUnit.bigha,
      AreaUnit.katha,
      AreaUnit.shotok,
      AreaUnit.chatak,
    },
  );

  List<AreaUnit> get orderedEnabled =>
      order.where(enabled.contains).toList(growable: false);

  bool isOn(AreaUnit u) => enabled.contains(u);

  BreakdownConfig copyWith({List<AreaUnit>? order, Set<AreaUnit>? enabled}) =>
      BreakdownConfig(
        order: order ?? this.order,
        enabled: enabled ?? this.enabled,
      );

  BreakdownConfig toggled(AreaUnit u) {
    final next = Set<AreaUnit>.from(enabled);
    next.contains(u) ? next.remove(u) : next.add(u);
    return copyWith(enabled: next);
  }

  /// [newIndex] is the destination *after* the item has been lifted out, which
  /// is what `ReorderableListView.onReorderItem` already accounts for. Do not
  /// re-apply the `newIndex > oldIndex ? newIndex - 1` correction here — that
  /// belongs to the deprecated `onReorder` callback and double-correcting
  /// drops downward drags one slot short.
  BreakdownConfig reordered(int oldIndex, int newIndex) {
    final next = List<AreaUnit>.from(order);
    next.insert(newIndex, next.removeAt(oldIndex));
    return copyWith(order: next);
  }
}

/// One term of a breakdown, e.g. "5 katha".
class BreakdownPart {
  final AreaUnit unit;

  /// Value in [unit]. Whole for every part except the last, which carries
  /// the remainder as a fraction so nothing is lost.
  final double value;

  final bool isRemainder;

  const BreakdownPart(this.unit, this.value, {required this.isRemainder});

  double get sqm => unit.toSqm(value);

  String get formatted =>
      isRemainder ? unit.formatValue(value) : unit.formatWhole(value);
}

/// An area expressed as a chain of traditional units.
class AreaBreakdown {
  final double totalSqm;

  /// Non-zero terms, in configured order. Zero terms are dropped, so a plot
  /// of one bigha reads "1 bigha" rather than "1 bigha, 0 katha, 0 chatak".
  final List<BreakdownPart> parts;

  const AreaBreakdown({required this.totalSqm, required this.parts});

  bool get isEmpty => parts.isEmpty;

  /// Sum of the parts. Equal to [totalSqm] up to floating-point error — the
  /// breakdown is lossless because the final part keeps the fraction.
  double get accountedSqm =>
      parts.fold(0.0, (sum, p) => sum + p.sqm);

  /// Flooring `remaining / sqmPerUnit` is unsafe on its own: exactly twenty
  /// katha can land on 19.999999999999996 and lose a whole unit. Nudging the
  /// quotient before flooring costs nothing and removes that cliff.
  static const double _quotientEpsilon = 1e-9;

  /// Values below this (in the final unit) are floating-point dust, not a
  /// real remainder, and are dropped.
  static const double _dust = 1e-9;

  static AreaBreakdown of(double totalSqm, BreakdownConfig config) {
    final units = config.orderedEnabled;
    if (units.isEmpty || !totalSqm.isFinite || totalSqm <= 0) {
      return AreaBreakdown(totalSqm: totalSqm, parts: const []);
    }

    final parts = <BreakdownPart>[];
    var remaining = totalSqm;

    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (i == units.length - 1) {
        // Smallest enabled unit carries whatever is left, as a fraction.
        final value = remaining / unit.sqmPerUnit;
        if (value > _dust) {
          parts.add(BreakdownPart(unit, value, isRemainder: true));
        }
      } else {
        final count =
            (remaining / unit.sqmPerUnit + _quotientEpsilon).floorToDouble();
        if (count > 0) {
          parts.add(BreakdownPart(unit, count, isRemainder: false));
          remaining -= count * unit.sqmPerUnit;
          if (remaining < 0) remaining = 0;
        }
      }
    }

    return AreaBreakdown(totalSqm: totalSqm, parts: parts);
  }
}
