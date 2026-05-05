import '../entities/plot.dart';
import '../repositories/plot_repository.dart';

class SavePlot {
  final PlotRepository _repo;
  SavePlot(this._repo);

  Future<void> call(Plot plot) => _repo.save(plot);
}
