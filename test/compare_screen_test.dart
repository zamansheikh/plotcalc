import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/compare/view/compare_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
  });

  Plot plot(String id, String name, double side) => Plot(
    id: id,
    name: name,
    vertices: [
      const Vertex(0, 0),
      Vertex(side, 0),
      Vertex(side, side),
      Vertex(0, side),
    ],
    tag: PlotTag.agricultural,
    createdAt: DateTime(2026, 10, 29),
    colorValue: 0xFFC8FF5A,
  );

  Future<void> open(WidgetTester tester, {List<String>? ids}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: MaterialApp(
          locale: const Locale('bn'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CompareScreen(plotIds: ids),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Opening Compare threw: it read the translations in initState.
  testWidgets('opens without an error, with the two picked plots', (
    tester,
  ) async {
    await sl<SavePlot>()(plot('a', 'উত্তরের জমি', 20));
    await sl<SavePlot>()(plot('b', 'দক্ষিণের জমি', 10));
    await sl<SavePlot>()(plot('c', 'পুকুর', 15));
    await open(tester, ids: const ['a', 'c']);
    expect(tester.takeException(), isNull);
    expect(find.text('উত্তরের জমি'), findsOneWidget);
    expect(find.text('পুকুর'), findsOneWidget);
    expect(find.text('দক্ষিণের জমি'), findsNothing);
  });

  testWidgets('opens with no saved plots, on demo shapes', (tester) async {
    await open(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(CompareScreen), findsOneWidget);
  });
}
