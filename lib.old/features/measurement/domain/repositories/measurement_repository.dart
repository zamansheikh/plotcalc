import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/measurement.dart';

abstract class MeasurementRepository {
  Future<Either<Failure, Measurement>> calculateArea({
    required List<Point> points,
    Map<String, double>? dimensions,
    Map<int, double> sideMeasurements = const {},
    Map<String, double> diagonalMeasurements = const {},
  });

  Future<Either<Failure, void>> saveMeasurement(Measurement measurement);

  Future<Either<Failure, List<Measurement>>> getAllMeasurements();

  Future<Either<Failure, Measurement>> getMeasurementById(String id);

  Future<Either<Failure, void>> deleteMeasurement(String id);

  Future<Either<Failure, void>> updateMeasurement(Measurement measurement);
}
