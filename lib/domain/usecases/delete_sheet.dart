import '../repositories/sheet_repository.dart';

class DeleteSheet {
  final SheetRepository _repo;
  DeleteSheet(this._repo);

  Future<void> call(String id) => _repo.delete(id);
}
