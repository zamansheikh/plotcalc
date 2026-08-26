import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/app.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/info/data/land_info_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises the real [PlotCalcApp] rather than a stand-in MaterialApp.
/// A previous version of this suite built its own MaterialApp and so did not
/// notice that app.dart was missing its localeResolutionCallback entirely.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    // Boot the real dependency graph — the app's first screen needs it.
    await configureDependencies();
    await InfoContent.load();
    Intl.defaultLocale = null;
  });

  Future<Locale> localeUnder(WidgetTester tester, Locale device) async {
    tester.platformDispatcher.localesTestValue = [device];
    await tester.pumpWidget(const PlotCalcApp());
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Navigator).first);
    return Localizations.localeOf(ctx);
  }

  tearDown(() {
    Intl.defaultLocale = null;
  });

  testWidgets('a Bengali device opens the real app in Bengali', (tester) async {
    expect((await localeUnder(tester, const Locale('bn'))).languageCode, 'bn');
  });

  testWidgets('an English device opens in English', (tester) async {
    expect((await localeUnder(tester, const Locale('en'))).languageCode, 'en');
  });

  testWidgets('an unsupported device language falls back to English', (
    tester,
  ) async {
    // Without localeResolutionCallback this resolved to Bengali, because the
    // generated supportedLocales list is alphabetical.
    expect((await localeUnder(tester, const Locale('fr'))).languageCode, 'en');
    expect((await localeUnder(tester, const Locale('hi'))).languageCode, 'en');
  });

  testWidgets('the app sets intl to the UI locale, so digits agree', (
    tester,
  ) async {
    await localeUnder(tester, const Locale('bn'));
    expect(Intl.defaultLocale, startsWith('bn'));
    // Areas must use the same digits as the localized counts around them.
    expect(AreaUnit.katha.format(1337.803776), '২০.০০০');

    await localeUnder(tester, const Locale('en'));
    expect(Intl.defaultLocale, startsWith('en'));
    expect(AreaUnit.katha.format(1337.803776), '20.000');
  });
}
