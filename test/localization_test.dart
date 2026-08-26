import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/presets.dart';
import 'package:plotcalc/core/input_method.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/core/units/length_unit.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/l10n/l10n.dart';

/// Pumps [child] under the given locale and hands back its BuildContext.
Future<BuildContext> _contextFor(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveAppLocale,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  group('ARB files', () {
    final en = json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final bn = json.decode(File('lib/l10n/app_bn.arb').readAsStringSync())
        as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> m) =>
        m.keys.where((k) => !k.startsWith('@')).toSet();

    test('both locales define exactly the same keys', () {
      expect(keys(bn), equals(keys(en)));
      expect(keys(en).length, greaterThan(200));
    });

    test('every Bengali value is non-empty', () {
      for (final k in keys(bn)) {
        expect((bn[k] as String).trim(), isNotEmpty, reason: k);
      }
    });

    test('placeholders match between locales', () {
      final ph = RegExp(r'\{(\w+)\}');
      for (final k in keys(en)) {
        final a = ph.allMatches(en[k] as String).map((m) => m[1]).toSet();
        final b = ph.allMatches(bn[k] as String).map((m) => m[1]).toSet();
        expect(b, equals(a), reason: 'placeholder mismatch in "$k"');
      }
    });

    test('no Bengali value was left as untouched English prose', () {
      // Values that are legitimately identical: a pure format string and the
      // two language names, which are always shown in their own language.
      const allowed = {
        'historyChip',
        'settingsLanguageEnglish',
        'settingsLanguageBengali',
      };
      final bengali = RegExp(r'[ঀ-৿]');
      for (final k in keys(bn)) {
        if (allowed.contains(k)) continue;
        final v = bn[k] as String;
        // Anything with letters should carry Bengali script.
        if (!RegExp(r'[A-Za-z]{3,}').hasMatch(en[k] as String)) continue;
        expect(bengali.hasMatch(v), isTrue, reason: '"$k" is still English: $v');
      }
    });
  });

  group('AppLocalizations', () {
    testWidgets('resolves English and Bengali', (tester) async {
      var ctx = await _contextFor(tester, const Locale('en'));
      expect(ctx.l10n.tabHistory, 'History');
      expect(ctx.l10n.settingsTitle, 'Settings');

      ctx = await _contextFor(tester, const Locale('bn'));
      expect(ctx.l10n.tabHistory, 'ইতিহাস');
      expect(ctx.l10n.settingsTitle, 'সেটিংস');
    });

    testWidgets('placeholders and plurals render', (tester) async {
      final en = await _contextFor(tester, const Locale('en'));
      expect(en.l10n.drawVertexOf(2, 5), 'Vertex 2 of 5');
      expect(en.l10n.plotClearAllBody(1), contains('All 1 saved plot will'));
      expect(en.l10n.plotClearAllBody(4), contains('All 4 saved plots will'));

      final bn = await _contextFor(tester, const Locale('bn'));
      expect(bn.l10n.drawVertexOf(2, 5), contains('কোণ'));
      expect(bn.l10n.plotClearAllBody(3), contains('৩টি'));
    });

    testWidgets('an unsupported locale falls back to the app default', (
      tester,
    ) async {
      // Bangla, not English: this is a Bangladeshi app and that is the
      // language it is meant to open in.
      final ctx = await _contextFor(tester, const Locale('fr'));
      expect(ctx.l10n.tabHistory, 'ইতিহাস');
    });

    test('resolution honours a supported request, else the app default', () {
      const supported = [Locale('bn'), Locale('en')];
      expect(resolveAppLocale(const Locale('bn'), supported).languageCode, 'bn');
      expect(resolveAppLocale(const Locale('en'), supported).languageCode, 'en');
      expect(resolveAppLocale(const Locale('fr'), supported).languageCode, 'bn');
      expect(resolveAppLocale(null, supported).languageCode, 'bn');
      expect(appDefaultLocale.languageCode, 'bn');
      // A regional variant still matches its language.
      expect(
        resolveAppLocale(const Locale('bn', 'BD'), supported).languageCode,
        'bn',
      );
    });
  });

  group('enum labels follow the locale', () {
    testWidgets('every enum value resolves in both languages', (tester) async {
      for (final locale in [const Locale('en'), const Locale('bn')]) {
        final ctx = await _contextFor(tester, locale);
        final t = ctx.l10n;
        for (final u in AreaUnit.values) {
          expect(u.labelOf(t), isNotEmpty, reason: '${u.name} @$locale');
          expect(u.nameOf(t), isNotEmpty, reason: '${u.name} @$locale');
        }
        for (final u in LengthUnit.values) {
          expect(u.labelOf(t), isNotEmpty);
          expect(u.nameOf(t), isNotEmpty);
        }
        for (final v in PlotTag.values) {
          expect(v.labelOf(t), isNotEmpty);
        }
        for (final v in ShapePreset.values) {
          expect(v.labelOf(t), isNotEmpty);
        }
        for (final v in InputMethod.values) {
          expect(v.labelOf(t), isNotEmpty);
          expect(v.subtitleOf(t), isNotEmpty);
        }
      }
    });

    testWidgets('Bengali labels actually differ from English', (tester) async {
      final en = (await _contextFor(tester, const Locale('en'))).l10n;
      expect(AreaUnit.bigha.labelOf(en), 'bigha');
      expect(PlotTag.agricultural.labelOf(en), 'Agricultural');

      final bn = (await _contextFor(tester, const Locale('bn'))).l10n;
      expect(AreaUnit.bigha.labelOf(bn), 'বিঘা');
      expect(PlotTag.agricultural.labelOf(bn), 'কৃষি');
    });
  });
}
