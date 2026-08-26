import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/input_method.dart';
import 'package:plotcalc/core/geometry/presets.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/usecases/get_plots.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/draw/bloc/draw_bloc.dart';
import 'package:plotcalc/presentation/features/draw/bloc/draw_event.dart';
import 'package:plotcalc/presentation/features/result/view/result_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saving a measurement and coming back to reshape it is the point of the
/// app; these cover the round trip.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
  });

  const square = [
    Vertex(0, 0),
    Vertex(20, 0),
    Vertex(20, 20),
    Vertex(0, 20),
  ];

  group('saving from the summary', () {
    Future<void> pump(WidgetTester tester, ResultArgs args) async {
      tester.view.physicalSize = const Size(393, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ResultScreen(args: args),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('an unsaved plot says so, and offers to save', (tester) async {
      // The badge used to read SAVED unconditionally, which was a lie.
      await pump(
        tester,
        const ResultArgs(name: 'North field', vertices: square),
      );
      expect(find.text('NOT SAVED'), findsOneWidget);
      expect(find.text('SAVED'), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('a plot opened from history shows as saved', (tester) async {
      await pump(
        tester,
        const ResultArgs(
          name: 'North field',
          vertices: square,
          plotId: 'abc',
        ),
      );
      expect(find.text('SAVED'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('the shape can be reopened for editing from here', (
      tester,
    ) async {
      await pump(
        tester,
        const ResultArgs(name: 'North field', vertices: square),
      );
      expect(find.text('Edit shape'), findsOneWidget);
    });
  });

  group('re-editing a saved shape', () {
    test('the canvas opens on the saved outline, not a preset', () async {
      final bloc = DrawBloc();
      addTearDown(bloc.close);
      bloc.add(const DrawInitialized(
        DrawArgs(
          method: InputMethod.draw,
          preset: ShapePreset.freeform,
          vertices: square,
          plotId: 'abc',
          name: 'North field',
        ),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.vertices, square);
      expect(
        bloc.state.vertices,
        isNot(ShapePreset.freeform.vertices),
        reason: 'editing must start from the saved shape',
      );
    });

    test('without an outline it still falls back to the preset', () async {
      final bloc = DrawBloc();
      addTearDown(bloc.close);
      bloc.add(const DrawInitialized(
        DrawArgs(method: InputMethod.draw, preset: ShapePreset.square),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.vertices, ShapePreset.square.vertices);
    });
  });

  group('a reshaped plot keeps its identity', () {
    test('adjusting writes back to the same plot, not a new one', () async {
      final plot = Plot(
        id: 'abc',
        name: 'North field',
        vertices: square,
        tag: PlotTag.agricultural,
        createdAt: DateTime.utc(2026, 1, 1),
        colorValue: 0xFF00FF00,
      );
      await sl<SavePlot>()(plot);

      // What the result screen does after an adjustment.
      const bigger = [
        Vertex(0, 0),
        Vertex(22, 0),
        Vertex(22, 22),
        Vertex(0, 22),
      ];
      final stored = (await sl<GetPlots>()()).single;
      await sl<SavePlot>()(stored.copyWith(vertices: bigger));

      final all = await sl<GetPlots>()();
      expect(all.length, 1, reason: 'updated, not duplicated');
      expect(all.single.id, 'abc');
      expect(all.single.name, 'North field');
      expect(all.single.tag, PlotTag.agricultural);
      expect(all.single.vertices, bigger);
      expect(all.single.createdAt, DateTime.utc(2026, 1, 1),
          reason: 'still the same measurement, just reshaped');
    });
  });
}
