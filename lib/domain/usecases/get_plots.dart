import '../entities/plot.dart';
import '../repositories/plot_repository.dart';

class GetPlots {
  final PlotRepository _repo;
  GetPlots(this._repo);

  Future<List<Plot>> call() => _repo.getAll();
  Stream<List<Plot>> watch() => _repo.watchAll();
}
