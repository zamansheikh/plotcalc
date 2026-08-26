import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/export/plot_summary.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';

import 'export_test.dart' show l10nFor;

/// The Compare screen's share button used to be `onTap: () {}`. These cover
/// the text it now produces, and guard against another dead control.
void main() {
  PlotSummary summary(String name, double kathas) {
    final sqm = AreaUnit.katha.toSqm(kathas);
    return PlotSummary(
      name: name,
      areaSqm: sqm,
      perimeterM: 100,
      sides: 4,
      unit: AreaUnit.katha,
      breakdown: AreaBreakdown.of(sqm, BreakdownConfig.defaults),
    );
  }

  testWidgets('the comparison names both plots and quotes both areas', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('en'));
    final text = PlotSummary.comparisonText(
      summary('North field', 5),
      summary('South field', 2),
      t,
    );
    expect(text, contains('North field'));
    expect(text, contains('South field'));
    expect(text, contains(t.comparePlotA));
    expect(text, contains(t.comparePlotB));
    expect(text, startsWith(t.compareTitle));
    expect(text, endsWith(t.appName));
  });

  testWidgets('the difference is signed, so B larger than A reads negative', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('en'));
    final aBigger = PlotSummary.comparisonText(
      summary('A', 5),
      summary('B', 2),
      t,
    );
    final bBigger = PlotSummary.comparisonText(
      summary('A', 2),
      summary('B', 5),
      t,
    );
    expect(aBigger, contains('${t.compareDelta}: 3'));
    expect(bBigger, contains('${t.compareDelta}: -3'));
  });

  testWidgets('the ratio is A over B', (tester) async {
    final t = await l10nFor(tester, const Locale('en'));
    final text = PlotSummary.comparisonText(
      summary('A', 6),
      summary('B', 3),
      t,
    );
    expect(text, contains('${t.compareRatio}: 2.00'));
  });

  testWidgets('an empty plot B cannot divide by zero', (tester) async {
    final t = await l10nFor(tester, const Locale('en'));
    final text = PlotSummary.comparisonText(
      summary('A', 5),
      summary('B', 0),
      t,
    );
    expect(text, isNot(contains(t.compareRatio)));
    expect(text, isNot(contains('Infinity')));
    expect(text, isNot(contains('NaN')));
  });

  testWidgets('the Bengali share carries Bengali labels and digits', (
    tester,
  ) async {
    final t = await l10nFor(tester, const Locale('bn'));
    final text = PlotSummary.comparisonText(
      summary('উত্তরের জমি', 5),
      summary('দক্ষিণের জমি', 2),
      t,
    );
    expect(text, contains('উত্তরের জমি'));
    expect(text, startsWith(t.compareTitle));
    expect(
      text,
      matches(RegExp('[০-৯]')),
      reason: 'figures follow the UI locale',
    );
  });

  test('no screen ships a control that does nothing', () {
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].replaceAll(' ', '');
        if (line.contains('onTap:(){}') ||
            line.contains('onPressed:(){}') ||
            line.contains('onTap:()=>{}') ||
            line.contains('onPressed:()=>{}')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'a button that looks live and does nothing is worse than none',
    );
  });
}
