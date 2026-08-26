import '../../l10n/l10n.dart';
import '../units/area_breakdown.dart';
import '../units/area_unit.dart';

/// Everything needed to describe a measured plot in text, a PDF, or a
/// clipboard entry — assembled once so the three exports can't disagree.
class PlotSummary {
  final String name;
  final double areaSqm;
  final double perimeterM;
  final int sides;
  final AreaUnit unit;
  final AreaBreakdown breakdown;

  const PlotSummary({
    required this.name,
    required this.areaSqm,
    required this.perimeterM,
    required this.sides,
    required this.unit,
    required this.breakdown,
  });

  /// The compound reading, e.g. "1 bigha · 5 katha · 3.00 chatak".
  /// Empty when no units are enabled for a breakdown.
  String breakdownLine(AppLocalizations t) => breakdown.parts
      .map((p) => '${p.formatted} ${p.unit.labelOf(t)}')
      .join(' · ');

  /// Plain-text summary for the clipboard or a share sheet.
  ///
  /// Deliberately not localised into a single template string: the shape is
  /// a list of "label: value" lines, and building it here keeps the same
  /// text flowing into every export.
  String asText(AppLocalizations t) {
    final lines = <String>[
      name,
      '',
      '${t.drawArea}: ${unit.format(areaSqm)} ${unit.labelOf(t)}',
    ];

    final chain = breakdownLine(t);
    if (chain.isNotEmpty) {
      lines.add('${t.calcResultLabel}: $chain');
    }

    lines
      ..add('${t.drawPerimeter}: ${perimeterM.toStringAsFixed(1)} '
          '${t.unitMeterShort}')
      ..add('${t.drawSides}: $sides')
      ..add('')
      ..add(t.appName);

    return lines.join('\n');
  }

  /// Plain-text comparison of two plots, for the Compare screen's share.
  ///
  /// Built from the labels the screen itself shows, so what leaves the app
  /// reads the way the screen did. The difference and ratio are quoted in
  /// A's unit — B's is only used for its own line.
  static String comparisonText(
    PlotSummary a,
    PlotSummary b,
    AppLocalizations t,
  ) {
    String line(String tag, PlotSummary s) {
      final area = '${s.unit.format(s.areaSqm)} ${s.unit.labelOf(t)}';
      final chain = s.breakdownLine(t);
      return chain.isEmpty
          ? '$tag — ${s.name}: $area'
          : '$tag — ${s.name}: $area  ($chain)';
    }

    final unit = a.unit;
    final ratio = b.areaSqm == 0 ? null : a.areaSqm / b.areaSqm;

    return [
      t.compareTitle,
      '',
      line(t.comparePlotA, a),
      line(t.comparePlotB, b),
      '',
      '${t.compareDelta}: '
          '${unit.format(a.areaSqm - b.areaSqm)} ${unit.labelOf(t)}',
      if (ratio != null) '${t.compareRatio}: ${ratio.toStringAsFixed(2)}',
      '',
      t.appName,
    ].join('\n');
  }

  /// The unit table used by the PDF, so a reader can convert without the app.
  List<(String, String)> conversions(AppLocalizations t) => [
    for (final u in AreaUnit.values)
      (u.nameOf(t), '${u.format(areaSqm)} ${u.labelOf(t)}'),
  ];
}
