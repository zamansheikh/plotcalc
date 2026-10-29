import '../entities/plot_sheet.dart';

abstract class SheetRepository {
  Future<List<PlotSheet>> getAll();
  Future<PlotSheet?> getById(String id);
  Future<void> save(PlotSheet sheet);
  Future<void> delete(String id);
  Stream<List<PlotSheet>> watchAll();
}
