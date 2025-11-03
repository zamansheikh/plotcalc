import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

@injectable
class GetAllMeasurements implements UseCase<List<Measurement>, NoParams> {
  final MeasurementRepository repository;

  GetAllMeasurements(this.repository);

  @override
  Future<Either<Failure, List<Measurement>>> call(NoParams params) async {
    return await repository.getAllMeasurements();
  }
}
