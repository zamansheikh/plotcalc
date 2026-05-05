import '../repositories/plot_repository.dart';

class ClearAllPlots {
  final PlotRepository _repo;
  ClearAllPlots(this._repo);

  Future<void> call() => _repo.deleteAll();
}
