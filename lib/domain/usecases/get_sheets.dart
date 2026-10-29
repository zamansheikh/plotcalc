import '../entities/plot_sheet.dart';
import '../repositories/sheet_repository.dart';

class GetSheets {
  final SheetRepository _repo;
  GetSheets(this._repo);

  Future<List<PlotSheet>> call() => _repo.getAll();
  Future<PlotSheet?> byId(String id) => _repo.getById(id);
  Stream<List<PlotSheet>> watch() => _repo.watchAll();
}
