import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/data/repositories/plot_repository_impl.dart';
import 'package:plotcalc/domain/entities/plot.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plot sample({AreaUnit? unit}) => Plot(
  id: 'p1',
  name: 'North field',
  // 1 bigha, so the numbers below are easy to check.
  vertices: const [
    Vertex(0, 0),
    Vertex(36.5761, 0),
    Vertex(36.5761, 36.5761),
    Vertex(0, 36.5761),
  ],
  tag: PlotTag.agricultural,
  createdAt: DateTime.utc(2026, 1, 1),
  colorValue: 0xFF00FF00,
  preferredUnit: unit,
);

void main() {
  late PlotRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
    repo = PlotRepositoryImpl(prefs);
  });

  test('a chosen unit survives a restart', () async {
    await repo.save(sample(unit: AreaUnit.bigha));

    // A fresh repository over the same store — i.e. the next app launch.
    final reopened = PlotRepositoryImpl(sl<SharedPreferences>());
    final loaded = (await reopened.getAll()).single;
    expect(loaded.preferredUnit, AreaUnit.bigha);
  });

  test('clearing the override survives a restart', () async {
    await repo.save(sample(unit: AreaUnit.bigha));
    final stored = (await repo.getAll()).single;
    await repo.save(stored.copyWith(clearPreferredUnit: true));

    final reopened = PlotRepositoryImpl(sl<SharedPreferences>());
    expect((await reopened.getAll()).single.preferredUnit, isNull);
  });

  test('plots written by the previous release still load', () async {
    // The exact JSON shape from before the field existed.
    await sl<SharedPreferences>().setString(
      'plotcalc.plots.v1',
      '[{"id":"old","name":"Legacy","vertices":['
      '{"x":0.0,"y":0.0},{"x":10.0,"y":0.0},{"x":10.0,"y":10.0}],'
      '"tag":"other","createdAt":"2025-06-01T00:00:00.000Z",'
      '"colorValue":16711680}]',
    );
    final loaded = (await PlotRepositoryImpl(sl<SharedPreferences>()).getAll())
        .single;
    expect(loaded.name, 'Legacy');
    expect(loaded.preferredUnit, isNull, reason: 'follows the app setting');
  });

  test('saving a plot without an override leaves the stored JSON unchanged',
      () async {
    await repo.save(sample());
    final raw = sl<SharedPreferences>().getString('plotcalc.plots.v1')!;
    expect(raw.contains('preferredUnit'), isFalse);
  });

  test('the override only affects the plot it was set on', () async {
    await repo.save(sample(unit: AreaUnit.bigha));
    await repo.save(sample().copyWith(id: 'p2', name: 'South field'));

    final all = await repo.getAll();
    final north = all.firstWhere((p) => p.id == 'p1');
    final south = all.firstWhere((p) => p.id == 'p2');
    expect(north.preferredUnit, AreaUnit.bigha);
    expect(south.preferredUnit, isNull);
  });

  test('every unit can be stored and read back', () async {
    for (final u in AreaUnit.values) {
      await repo.deleteAll();
      await repo.save(sample(unit: u));
      final back = (await PlotRepositoryImpl(sl<SharedPreferences>()).getAll())
          .single;
      expect(back.preferredUnit, u, reason: u.name);
    }
  });
}
