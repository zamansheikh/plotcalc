import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

@injectable
class SaveMeasurement implements UseCase<void, SaveMeasurementParams> {
  final MeasurementRepository repository;

  SaveMeasurement(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveMeasurementParams params) async {
    return await repository.saveMeasurement(params.measurement);
  }
}

class SaveMeasurementParams extends Equatable {
  final Measurement measurement;

  const SaveMeasurementParams({required this.measurement});

  @override
  List<Object> get props => [measurement];
}
