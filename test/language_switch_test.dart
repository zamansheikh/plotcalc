import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:plotcalc/presentation/shared/settings/settings_event.dart';
import 'package:plotcalc/presentation/shared/settings/settings_state.dart';
import 'package:plotcalc/presentation/shared/widgets/bottom_tab_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });

  test('starts on the device language and remembers an explicit choice', () async {
    // Nothing saved yet -> null, i.e. follow the device.
    expect(SettingsBloc().state.locale, isNull);

    final bloc = SettingsBloc()..add(const LocaleChanged(Locale('bn')));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.locale?.languageCode, 'bn');

    // A fresh bloc (i.e. next app launch) restores it.
    expect(SettingsBloc().state.locale?.languageCode, 'bn');
  });

  testWidgets('switching language re-renders the UI in Bengali', (
    tester,
  ) async {
    final bloc = SettingsBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) => MaterialApp(
            locale: state.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: resolveAppLocale,
            home: Scaffold(
              body: BottomTabBar(
                active: TabKind.plots,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('ইতিহাস'), findsNothing);

    bloc.add(const LocaleChanged(Locale('bn')));
    await tester.pumpAndSettle();

    expect(find.text('ইতিহাস'), findsOneWidget);
    expect(find.text('History'), findsNothing);

    bloc.add(const LocaleChanged(Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
  });
}
