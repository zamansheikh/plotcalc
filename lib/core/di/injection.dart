import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/plot_repository_impl.dart';
import '../../domain/repositories/plot_repository.dart';
import '../../domain/usecases/clear_all_plots.dart';
import '../../domain/usecases/delete_plot.dart';
import '../../domain/usecases/get_plots.dart';
import '../../domain/usecases/save_plot.dart';

final GetIt sl = GetIt.instance;

const _seedsCleanedKey = 'plotcalc.seeds_cleaned.v1';

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final repo = PlotRepositoryImpl(prefs);
  sl.registerSingleton<PlotRepository>(repo);

  await _purgeLegacySeeds(repo, prefs);

  sl.registerFactory<GetPlots>(() => GetPlots(sl()));
  sl.registerFactory<SavePlot>(() => SavePlot(sl()));
  sl.registerFactory<DeletePlot>(() => DeletePlot(sl()));
  sl.registerFactory<ClearAllPlots>(() => ClearAllPlots(sl()));
}

/// Removes demo plots (id prefix `seed-`) left over from earlier builds.
/// Runs once per install — guarded by a SharedPreferences flag.
Future<void> _purgeLegacySeeds(
  PlotRepositoryImpl repo,
  SharedPreferences prefs,
) async {
  if (prefs.getBool(_seedsCleanedKey) == true) return;
  final all = await repo.getAll();
  for (final p in all) {
    if (p.id.startsWith('seed-')) {
      await repo.delete(p.id);
    }
  }
  await prefs.setBool(_seedsCleanedKey, true);
}
