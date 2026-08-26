import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:plotcalc/app.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/units/area_unit.dart';
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

  testWidgets('an English device still opens in Bengali', (tester) async {
    // The device language is deliberately not consulted: most of this app's
    // users carry English-locale phones and want a Bengali app.
    expect((await localeUnder(tester, const Locale('en'))).languageCode, 'bn');
  });

  testWidgets('any other device language opens in Bengali too', (
    tester,
  ) async {
    expect((await localeUnder(tester, const Locale('fr'))).languageCode, 'bn');
    expect((await localeUnder(tester, const Locale('hi'))).languageCode, 'bn');
  });

  testWidgets('the app sets intl to the UI locale, so digits agree', (
    tester,
  ) async {
    await localeUnder(tester, const Locale('bn'));
    expect(Intl.defaultLocale, startsWith('bn'));
    // Areas must use the same digits as the localized counts around them.
    expect(AreaUnit.katha.format(1337.803776), '২০.০০০');
  });

  testWidgets('choosing English switches the whole app over', (tester) async {
    SharedPreferences.setMockInitialValues({'plotcalc.locale.v1': 'en'});
    await GetIt.I.reset();
    await configureDependencies();
    await InfoContent.load();

    expect((await localeUnder(tester, const Locale('bn'))).languageCode, 'en',
        reason: 'a saved choice beats the app default');
    expect(Intl.defaultLocale, startsWith('en'));
    expect(AreaUnit.katha.format(1337.803776), '20.000');
  });
}
