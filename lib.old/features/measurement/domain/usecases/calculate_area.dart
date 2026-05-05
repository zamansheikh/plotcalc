import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

@injectable
class CalculateArea implements UseCase<Measurement, CalculateAreaParams> {
  final MeasurementRepository repository;

  CalculateArea(this.repository);

  @override
  Future<Either<Failure, Measurement>> call(CalculateAreaParams params) async {
    return await repository.calculateArea(
      points: params.points,
      dimensions: params.dimensions,
      sideMeasurements: params.sideMeasurements,
      diagonalMeasurements: params.diagonalMeasurements,
    );
  }
}

class CalculateAreaParams extends Equatable {
  final List<Point> points;
  final Map<String, double>? dimensions;
  final Map<int, double> sideMeasurements; // Side measurements in meters
  final Map<String, double> diagonalMeasurements; // Diagonal measurements in meters

  const CalculateAreaParams({
    required this.points,
    this.dimensions,
    this.sideMeasurements = const {},
    this.diagonalMeasurements = const {},
  });

  @override
  List<Object?> get props => [points, dimensions, sideMeasurements, diagonalMeasurements];
}
