import '../entities/plot_sheet.dart';
import '../repositories/sheet_repository.dart';

class SaveSheet {
  final SheetRepository _repo;
  SaveSheet(this._repo);

  Future<void> call(PlotSheet sheet) => _repo.save(sheet);
}
