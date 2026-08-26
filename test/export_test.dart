import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/export/plot_export.dart';
import 'package:plotcalc/core/export/plot_pdf.dart';
import 'package:plotcalc/core/export/plot_summary.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/l10n/l10n.dart';

Future<AppLocalizations> l10nFor(WidgetTester tester, Locale locale) async {
  late AppLocalizations t;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Mirrors app.dart: number formatting follows the UI locale, so the
      // exported text uses the same digits as the screen it came from.
      localeResolutionCallback: (device, supported) {
        final resolved = resolveAppLocale(device, supported);
        Intl.defaultLocale = resolved.toLanguageTag();
        return resolved;
      },
      home: Builder(
        builder: (context) {
          t = context.l10n;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return t;
}

/// One bigha, five katha — a value whose breakdown is easy to read by eye.
PlotSummary summaryOf({String name = 'North field', AreaUnit? unit}) {
  final sqm = AreaUnit.bigha.toSqm(1) + AreaUnit.katha.toSqm(5);
  return PlotSummary(
    name: name,
    areaSqm: sqm,
    perimeterM: 148.25,
    sides: 5,
    unit: unit ?? AreaUnit.katha,
    breakdown: AreaBreakdown.of(sqm, BreakdownConfig.defaults),
  );
}

void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('summary text', () {
    testWidgets('carries the name, area, breakdown, perimeter and sides', (
      tester,
    ) async {
      final t = await l10nFor(tester, const Locale('en'));
      final text = summaryOf().asText(t);

      expect(text, startsWith('North field'));
      expect(text, contains('25.000 katha'));
      expect(text, contains('1 bigha'));
      expect(text, contains('5 katha'));
      expect(text, contains('148.3'));  // 148.25 rounds up
      expect(text, contains('5'));
      expect(text, contains('PlotCalc'));
    });

    testWidgets('follows the locale', (tester) async {
      final bn = await l10nFor(tester, const Locale('bn'));
      final text = summaryOf().asText(bn);
      expect(text, contains('কাঠা'));
      expect(text, contains('প্লটক্যালক'));
      expect(RegExp(r'[০-৯]').hasMatch(text), isTrue,
          reason: 'Bengali numerals, matching the rest of the UI');
    });

    testWidgets('the breakdown line matches what the UI shows', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      expect(summaryOf().breakdownLine(t), '1 bigha · 5 katha');
    });

    testWidgets('survives a plot with no breakdown units enabled', (
      tester,
    ) async {
      final t = await l10nFor(tester, const Locale('en'));
      final s = PlotSummary(
        name: 'Bare',
        areaSqm: 100,
        perimeterM: 40,
        sides: 4,
        unit: AreaUnit.sqm,
        breakdown: AreaBreakdown.of(
          100,
          const BreakdownConfig(order: [], enabled: {}),
        ),
      );
      expect(s.breakdownLine(t), isEmpty);
      expect(s.asText(t), contains('Bare'));  // no crash, no empty line noise
    });

    testWidgets('lists every unit in the conversion table', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      expect(summaryOf().conversions(t).length, AreaUnit.values.length);
    });
  });

  group('pdf', () {
    testWidgets('produces a valid, non-trivial PDF', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final bytes = await PlotPdf.build(summaryOf(), t);

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      // %%EOF terminates a well-formed document.
      expect(String.fromCharCodes(bytes.skip(bytes.length - 8)),
          contains('EOF'));
    });

    testWidgets('embeds the plot image when one is supplied', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final plain = await PlotPdf.build(summaryOf(), t);
      final png = _png1x1;
      final withArt = await PlotPdf.build(summaryOf(), t, plotImage: png);
      expect(withArt.length, greaterThan(plain.length));
    });

    testWidgets('a long plot name does not break generation', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      final bytes = await PlotPdf.build(
        summaryOf(name: 'A' * 300),
        t,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('clipboard', () {
    testWidgets('copy puts the summary on the clipboard', (tester) async {
      final t = await l10nFor(tester, const Locale('en'));
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await PlotExport.copy(summaryOf(), t);
      expect(copied, isNotNull);
      expect(copied, contains('North field'));
      expect(copied, contains('1 bigha'));
    });
  });
}

/// A literal 1x1 PNG. Rendering one via PictureRecorder.toImage() hangs
/// under `flutter test` on this toolchain, and the bytes are all the PDF
/// needs anyway.
final Uint8List _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);
