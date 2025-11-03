import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/measurement_repository.dart';

@injectable
class DeleteMeasurement implements UseCase<void, DeleteMeasurementParams> {
  final MeasurementRepository repository;

  DeleteMeasurement(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMeasurementParams params) async {
    return await repository.deleteMeasurement(params.id);
  }
}

class DeleteMeasurementParams extends Equatable {
  final String id;

  const DeleteMeasurementParams({required this.id});

  @override
  List<Object> get props => [id];
}
