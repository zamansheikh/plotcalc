import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/lot_division.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:plotcalc/domain/usecases/get_plots.dart';
import 'package:plotcalc/domain/usecases/save_plot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Saving a subdivision writes each lot to history as a plot in its own
/// right, named after the parent.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
  });

  final parent = Plot(
    id: 'p1',
    name: 'land_abc',
    // 600 m2, so the shares below come out in round numbers.
    vertices: const [
      Vertex(0, 0),
      Vertex(30, 0),
      Vertex(30, 20),
      Vertex(0, 20),
    ],
    tag: PlotTag.agricultural,
    createdAt: DateTime.utc(2026, 1, 1),
    colorValue: 0xFF00FF00,
    preferredUnit: AreaUnit.katha,
  );

  /// Mirrors what the screen does on Save.
  Future<void> saveLots(Plot from, List<double> shares) async {
    final lots = LotDivision.divide(from.vertices, shares);
    for (var i = 0; i < lots.length; i++) {
      await sl<SavePlot>()(
        Plot(
          id: const Uuid().v4(),
          name: '${from.name}_lot_${i + 1}',
          vertices: lots[i].vertices,
          tag: from.tag,
          createdAt: DateTime.now(),
          colorValue: 0xFF00FF00,
          preferredUnit: from.preferredUnit,
        ),
      );
    }
  }

  test('lots are named after the parent', () async {
    await sl<SavePlot>()(parent);
    await saveLots(parent, [1, 1, 1]);

    final names = (await sl<GetPlots>()()).map((p) => p.name).toList();
    expect(names, contains('land_abc'));
    expect(names, contains('land_abc_lot_1'));
    expect(names, contains('land_abc_lot_2'));
    expect(names, contains('land_abc_lot_3'));
  });

  test('each saved lot really holds its share of the land', () async {
    await saveLots(parent, [3, 2]); // the 5 shotok story
    final saved = await sl<GetPlots>()();
    final byName = {for (final p in saved) p.name: p};

    expect(Geometry.polygonArea(byName['land_abc_lot_1']!.vertices), closeTo(360, 1e-6));
    expect(Geometry.polygonArea(byName['land_abc_lot_2']!.vertices), closeTo(240, 1e-6));
  });

  test('the lots add up to the parent', () async {
    await saveLots(parent, [0.2, 0.3, 0.5]);
    final lots = (await sl<GetPlots>()())
        .where((p) => p.name.contains('_lot_'))
        .toList();
    final sum = lots.fold<double>(0, (a, p) => a + Geometry.polygonArea(p.vertices));
    expect(sum, closeTo(Geometry.polygonArea(parent.vertices), 1e-6));
  });

  test('lots inherit the parent tag and unit', () async {
    await saveLots(parent, [1, 1]);
    for (final p in (await sl<GetPlots>()()).where(
      (p) => p.name.contains('_lot_'),
    )) {
      expect(p.tag, PlotTag.agricultural);
      expect(p.preferredUnit, AreaUnit.katha);
    }
  });

  test('the parent is left untouched', () async {
    await sl<SavePlot>()(parent);
    await saveLots(parent, [1, 1]);
    final again = (await sl<GetPlots>()()).firstWhere((p) => p.id == 'p1');
    expect(again.vertices, parent.vertices);
    expect(again.name, 'land_abc');
  });

  test('each lot is a separate record with its own id', () async {
    await saveLots(parent, [1, 1, 1]);
    final lots = (await sl<GetPlots>()())
        .where((p) => p.name.contains('_lot_'))
        .toList();
    expect(lots.length, 3);
    expect(lots.map((p) => p.id).toSet().length, 3);
  });

  test('saved lots survive a restart', () async {
    await saveLots(parent, [1, 1]);
    await GetIt.I.reset();
    await configureDependencies();
    final names = (await sl<GetPlots>()()).map((p) => p.name).toList();
    expect(names, containsAll(['land_abc_lot_1', 'land_abc_lot_2']));
  });
}
