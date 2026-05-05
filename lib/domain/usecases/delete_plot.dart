import '../repositories/plot_repository.dart';

class DeletePlot {
  final PlotRepository _repo;
  DeletePlot(this._repo);

  Future<void> call(String id) => _repo.delete(id);
}
