import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/export/plot_pdf.dart';
import 'package:plotcalc/core/export/plot_summary.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';

import 'export_test.dart' show l10nFor;

/// A PDF carries its own fonts. Before the face was bundled it was fetched at
/// export time, so a Bengali document built offline came out with no Bengali
/// in it at all — and Bengali is the language the app opens in. Nothing here
/// touches the network.
void main() {
  setUp(PlotPdf.resetFontCacheForTest);

  PlotSummary summary(String name) {
    final sqm = AreaUnit.katha.toSqm(5);
    return PlotSummary(
      name: name,
      areaSqm: sqm,
      perimeterM: 100,
      sides: 4,
      unit: AreaUnit.katha,
      breakdown: AreaBreakdown.of(sqm, BreakdownConfig.defaults),
    );
  }

  testWidgets('a Bengali document embeds the bundled Bengali face', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('bn'));
    final bytes = await PlotPdf.build(summary('উত্তরের জমি'), t);
    expect(
      latin1.decode(bytes, allowInvalid: true),
      contains('NotoSansBengali'),
      reason: 'without an embedded face the Bengali text cannot render',
    );
  });

  testWidgets('an English document does not pay for the Bengali face', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('en'));
    final bytes = await PlotPdf.build(summary('North field'), t);
    expect(latin1.decode(bytes, allowInvalid: true), isNot(contains('NotoSansBengali')));
  });

  testWidgets('the Bengali document carries the extra glyphs, not just the '
      'font name', (tester) async {
    final bn = await l10nFor(tester, const Locale('bn'));
    final bengali = await PlotPdf.build(summary('উত্তরের জমি'), bn);
    PlotPdf.resetFontCacheForTest();
    final en = await l10nFor(tester, const Locale('en'));
    final latin = await PlotPdf.build(summary('North field'), en);
    // Both embed a subset of the Latin face, so the gap is only the Bengali
    // glyphs actually used — a few kilobytes, not a whole font.
    expect(bengali.length, greaterThan(latin.length));
  });

  testWidgets('both documents still build and are valid PDFs', (tester) async {
    for (final locale in [const Locale('en'), const Locale('bn')]) {
      PlotPdf.resetFontCacheForTest();
      final t = await l10nFor(tester, locale);
      final bytes = await PlotPdf.build(summary('জমি / field'), t);
      expect(bytes.length, greaterThan(1000), reason: locale.languageCode);
      expect(
        latin1.decode(bytes.sublist(0, 5)),
        '%PDF-',
        reason: locale.languageCode,
      );
    }
  });
}
