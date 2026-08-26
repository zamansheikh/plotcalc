import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:plotcalc/presentation/shared/settings/settings_event.dart';
import 'package:plotcalc/presentation/shared/widgets/area_breakdown_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  await GetIt.I.reset();
  sl.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
}

Future<void> _settle(Bloc b) => Future<void>.delayed(Duration.zero);

void main() {
  group('persistence', () {
    test('starts on the defaults', () async {
      await _boot();
      final s = SettingsBloc().state.breakdown;
      expect(s.order, BreakdownConfig.defaults.order);
      expect(s.enabled, BreakdownConfig.defaults.enabled);
    });

    test('a toggle survives a restart', () async {
      await _boot();
      final bloc = SettingsBloc()
        ..add(const BreakdownUnitToggled(AreaUnit.bighaMymensingh));
      await _settle(bloc);
      expect(bloc.state.breakdown.isOn(AreaUnit.bighaMymensingh), isTrue);

      expect(SettingsBloc().state.breakdown.isOn(AreaUnit.bighaMymensingh),
          isTrue);
    });

    test('a reorder survives a restart', () async {
      await _boot();
      final bloc = SettingsBloc()..add(const BreakdownUnitsReordered(0, 3));
      await _settle(bloc);
      final saved = bloc.state.breakdown.order;
      expect(SettingsBloc().state.breakdown.order, saved);
      expect(saved, isNot(BreakdownConfig.defaults.order));
    });

    test('reset restores the defaults and persists that', () async {
      await _boot();
      final bloc = SettingsBloc()
        ..add(const BreakdownUnitToggled(AreaUnit.katha))
        ..add(const BreakdownReset());
      await _settle(bloc);
      expect(bloc.state.breakdown.enabled, BreakdownConfig.defaults.enabled);
      expect(SettingsBloc().state.breakdown.enabled,
          BreakdownConfig.defaults.enabled);
    });
  });

  group('migration of stored preferences', () {
    test('a unit added in a later release is appended, not lost', () async {
      // Simulates a preference written before the Mymensingh units existed.
      await _boot({
        'plotcalc.breakdown.order.v1': ['acre', 'bigha', 'katha'],
        'plotcalc.breakdown.enabled.v1': ['bigha', 'katha'],
      });
      final cfg = SettingsBloc().state.breakdown;
      expect(cfg.order.take(3), [AreaUnit.acre, AreaUnit.bigha, AreaUnit.katha]);
      expect(cfg.order, contains(AreaUnit.bighaMymensingh));
      expect(cfg.order.toSet().length, cfg.order.length, reason: 'no dupes');
      // The user's own choices are untouched.
      expect(cfg.enabled, {AreaUnit.bigha, AreaUnit.katha});
    });

    test('a unit removed in a later release is ignored', () async {
      await _boot({
        'plotcalc.breakdown.order.v1': ['bigha', 'kani', 'katha'],
        'plotcalc.breakdown.enabled.v1': ['bigha', 'kani'],
      });
      final cfg = SettingsBloc().state.breakdown;
      expect(cfg.order.every(AreaUnit.values.contains), isTrue);
      expect(cfg.enabled, {AreaUnit.bigha});
    });

    test('a corrupt half-written preference falls back cleanly', () async {
      await _boot({'plotcalc.breakdown.order.v1': <String>['bigha']});
      expect(SettingsBloc().state.breakdown.order,
          BreakdownConfig.defaults.order);
    });
  });

  group('AreaBreakdownView', () {
    Future<void> pump(WidgetTester tester, SettingsBloc bloc, double sqm) async {
      await tester.pumpWidget(
        BlocProvider<SettingsBloc>.value(
          value: bloc,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: AreaBreakdownView(sqm: sqm)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders a compound reading', (tester) async {
      await _boot();
      final sqm = AreaUnit.bigha.toSqm(1) +
          AreaUnit.katha.toSqm(5) +
          AreaUnit.chatak.toSqm(3);
      await pump(tester, SettingsBloc(), sqm);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('bigha'), findsOneWidget);
      expect(find.text('katha'), findsOneWidget);
      expect(find.text('chatak'), findsOneWidget);
    });

    testWidgets('reacts to a unit being switched off', (tester) async {
      await _boot();
      final bloc = SettingsBloc();
      addTearDown(bloc.close);
      await pump(tester, bloc, AreaUnit.bigha.toSqm(1) + AreaUnit.katha.toSqm(5));
      expect(find.text('katha'), findsOneWidget);

      bloc.add(const BreakdownUnitToggled(AreaUnit.katha));
      await tester.pumpAndSettle();
      expect(find.text('katha'), findsNothing);
    });

    testWidgets('explains itself when nothing is enabled', (tester) async {
      await _boot();
      final bloc = SettingsBloc();
      addTearDown(bloc.close);
      for (final u in BreakdownConfig.defaults.enabled) {
        bloc.add(BreakdownUnitToggled(u));
      }
      await pump(tester, bloc, 1337.8);
      expect(find.textContaining('Enable at least one unit'), findsOneWidget);
    });
  });
}
