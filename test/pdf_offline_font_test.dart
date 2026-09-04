import 'dart:convert';

import 'package:bangla_pdf/extract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/export/plot_pdf.dart';
import 'package:plotcalc/core/export/plot_summary.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';

import 'export_test.dart' show l10nFor;

/// A PDF carries its own fonts and its own text layer, and package:pdf does
/// neither for Bengali: it embeds no Bengali face and lays code points out in
/// order, which breaks conjuncts and misplaces vowel signs. Bengali is the
/// language the app opens in, so both matter. Nothing here touches the
/// network — an export has to work in a field with no signal.
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

  Future<String> textOf(WidgetTester tester, String name, Locale locale) async {
    final t = await l10nFor(tester, locale);
    final bytes = await PlotPdf.build(summary(name), t);
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    return BanglaPdfExtractor.extract(bytes).text;
  }

  testWidgets('the plot name comes back out of the document as typed', (
    tester,
  ) async {
    // Not "does it render" but "is the text really there": a reader can
    // search the PDF, and a screen reader can speak it.
    expect(
      await textOf(tester, 'উত্তরের জমি', const Locale('bn')),
      contains('উত্তরের জমি'),
    );
  });

  testWidgets('conjuncts survive the round trip', (tester) async {
    // These ligate. Unshaped they come out as a base plus a stray hasanta.
    for (final word in ['ক্ষেত', 'পশ্চিম', 'দক্ষিণ']) {
      PlotPdf.resetFontCacheForTest();
      expect(
        await textOf(tester, word, const Locale('bn')),
        contains(word),
        reason: word,
      );
    }
  });

  testWidgets('a name with reph exports at all', (tester) async {
    // Reph used to throw a RangeError out of pdf.save(), losing the export
    // outright rather than merely looking wrong.
    for (final word in ['কর্ম', 'পূর্ব', 'উত্তর-পূর্ব কোণ']) {
      PlotPdf.resetFontCacheForTest();
      expect(
        await textOf(tester, word, const Locale('bn')),
        contains(word),
        reason: word,
      );
    }
  });

  testWidgets('the document reads as Unicode, not Bijoy mojibake', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('bn'));
    final bytes = await PlotPdf.build(summary('উত্তরের জমি'), t);
    final result = BanglaPdfExtractor.extract(bytes);
    expect(result.encodingDetected, BanglaTextEncoding.unicode);
    expect(result.text, isNot(contains('Avgvi')));
  });

  testWidgets('Bengali digits are preserved, not silently latinised', (
    tester,
  ) async {
    final text = await textOf(tester, 'জমি', const Locale('bn'));
    expect(
      text,
      matches(RegExp('[০-৯]')),
      reason: 'the figures follow the UI locale',
    );
  });

  testWidgets('an English document keeps the Latin face and its bold', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('en'));
    final bytes = await PlotPdf.build(summary('North field'), t);
    final raw = latin1.decode(bytes, allowInvalid: true);
    expect(raw, contains('NotoSans'));
    expect(raw, contains('NotoSans-Bold'));
  });

  testWidgets('a mixed name keeps both scripts', (tester) async {
    expect(
      await textOf(tester, 'Plot 12 — উত্তরের জমি', const Locale('bn')),
      contains('উত্তরের জমি'),
    );
  });
}
