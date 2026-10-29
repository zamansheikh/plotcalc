import 'package:intl/intl.dart';

import '../../domain/entities/plot.dart';
import '../../domain/entities/plot_sheet.dart';
import '../../l10n/l10n.dart';
import '../geometry/geometry.dart';
import '../geometry/vertex.dart';
import '../units/area_breakdown.dart';
import '../units/area_unit.dart';

/// One plot as a line of a sheet.
class SheetRow {
  final String plotId;
  final String name;
  final PlotTag tag;
  final List<Vertex> vertices;
  final int colorValue;
  final double areaSqm;

  const SheetRow({
    required this.plotId,
    required this.name,
    required this.tag,
    required this.vertices,
    required this.colorValue,
    required this.areaSqm,
  });

  factory SheetRow.of(Plot p) => SheetRow(
    plotId: p.id,
    name: p.name,
    tag: p.tag,
    vertices: p.vertices,
    colorValue: p.colorValue,
    areaSqm: Geometry.polygonArea(p.vertices),
  );
}

/// A sheet with its plots looked up and its totals worked out, so the
/// screen, the shared text and the PDF all show the same numbers.
class SheetSummary {
  final String name;
  final List<SheetRow> rows;

  /// Every row and the total are read in this one unit, so the column adds
  /// up by eye. A plot's own preferred unit is ignored here on purpose.
  final AreaUnit unit;
  final AreaBreakdown breakdown;

  final double? pricePerUnit;
  final AreaUnit priceUnit;

  /// Plots the sheet still names but which have since been deleted.
  final int missing;

  const SheetSummary({
    required this.name,
    required this.rows,
    required this.unit,
    required this.breakdown,
    required this.priceUnit,
    this.pricePerUnit,
    this.missing = 0,
  });

  /// Looks up [sheet]'s plots in [plots], keeping the sheet's order and
  /// skipping any that no longer exist.
  factory SheetSummary.of(
    PlotSheet sheet,
    List<Plot> plots, {
    required AreaUnit fallbackUnit,
    required BreakdownConfig breakdown,
  }) {
    final byId = {for (final p in plots) p.id: p};
    final rows = <SheetRow>[];
    var missing = 0;
    for (final id in sheet.plotIds) {
      final p = byId[id];
      if (p == null) {
        missing++;
      } else {
        rows.add(SheetRow.of(p));
      }
    }
    final total = rows.fold<double>(0, (sum, r) => sum + r.areaSqm);
    return SheetSummary(
      name: sheet.name,
      rows: rows,
      unit: sheet.unit ?? fallbackUnit,
      breakdown: AreaBreakdown.of(total, breakdown),
      pricePerUnit: sheet.pricePerUnit,
      priceUnit: sheet.priceUnit,
      missing: missing,
    );
  }

  double get totalSqm => rows.fold<double>(0, (sum, r) => sum + r.areaSqm);

  bool get hasPrice => pricePerUnit != null && pricePerUnit! > 0;

  /// Price of [sqm] of land at the sheet's rate, or null with no rate set.
  double? valueOf(double sqm) =>
      hasPrice ? priceUnit.fromSqm(sqm) * pricePerUnit! : null;

  double? get totalValue => valueOf(totalSqm);

  /// Fraction of the total, 0..1. Zero for an empty sheet.
  double shareOf(SheetRow r) => totalSqm == 0 ? 0 : r.areaSqm / totalSqm;

  /// "1 bigha · 5 katha · 3.00 chatak", or empty with no breakdown units.
  String breakdownLine(AppLocalizations t) => breakdown.parts
      .map((p) => '${p.formatted} ${p.unit.labelOf(t)}')
      .join(' · ');

  String area(double sqm, AppLocalizations t) =>
      '${unit.format(sqm)} ${unit.labelOf(t)}';

  /// Taka, whole, grouped in the active locale's digits.
  static String money(double v) =>
      '৳ ${NumberFormat.decimalPattern().format(v.round())}';

  /// Share as a percentage, e.g. "32.5%".
  static String percent(double fraction) {
    final f = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    return '${f.format(fraction * 100)}%';
  }

  /// Reads a typed amount. Takes Bengali digits as well as ASCII, and
  /// ignores grouping commas, since both come from ordinary keyboards.
  static double? parseAmount(String raw) {
    const bengali = '০১২৩৪৫৬৭৮৯';
    var s = raw.trim().replaceAll(',', '').replaceAll('٫', '.');
    for (var i = 0; i < bengali.length; i++) {
      s = s.replaceAll(bengali[i], '$i');
    }
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// "৳ 50,000 / shotok".
  String rateLine(AppLocalizations t) =>
      '${money(pricePerUnit ?? 0)} / ${priceUnit.labelOf(t)}';

  /// Plain-text sheet for the clipboard or a share sheet.
  String asText(AppLocalizations t) {
    final lines = <String>[name, ''];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final value = valueOf(r.areaSqm);
      lines.add(
        '${NumberFormat.decimalPattern().format(i + 1)}. ${r.name} — '
        '${area(r.areaSqm, t)}'
        '${value == null ? '' : ' — ${money(value)}'}',
      );
    }
    lines
      ..add('')
      ..add('${t.sheetTotalArea(rows.length)}: ${area(totalSqm, t)}');
    final chain = breakdownLine(t);
    if (chain.isNotEmpty) lines.add('= $chain');
    if (hasPrice) {
      lines
        ..add('${t.sheetRate}: ${rateLine(t)}')
        ..add('${t.sheetTotalValue}: ${money(totalValue!)}');
    }
    lines
      ..add('')
      ..add(t.appName);
    return lines.join('\n');
  }
}
