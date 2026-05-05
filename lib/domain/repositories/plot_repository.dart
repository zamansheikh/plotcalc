import '../entities/plot.dart';

abstract class PlotRepository {
  Future<List<Plot>> getAll();
  Future<Plot?> getById(String id);
  Future<void> save(Plot plot);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Stream<List<Plot>> watchAll();
}
