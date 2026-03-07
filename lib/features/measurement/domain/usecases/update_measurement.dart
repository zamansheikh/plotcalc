import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

@injectable
class UpdateMeasurement implements UseCase<void, UpdateMeasurementParams> {
  final MeasurementRepository repository;

  UpdateMeasurement(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateMeasurementParams params) async {
    return await repository.updateMeasurement(params.measurement);
  }
}

class UpdateMeasurementParams extends Equatable {
  final Measurement measurement;

  const UpdateMeasurementParams({required this.measurement});

  @override
  List<Object> get props => [measurement];
}
