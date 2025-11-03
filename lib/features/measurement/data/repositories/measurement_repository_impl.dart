import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../datasources/measurement_local_data_source.dart';
import '../models/measurement_model.dart';

@Injectable(as: MeasurementRepository)
class MeasurementRepositoryImpl implements MeasurementRepository {
  final MeasurementLocalDataSource localDataSource;

  MeasurementRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Measurement>> calculateArea({
    required List<Point> points,
    Map<String, double>? dimensions,
  }) async {
    try {
      // Validate input
      if (points.isEmpty) {
        return const Left(ValidationFailure('No points provided'));
      }

      double area = 0;
      ShapeType shapeType = _determineShapeType(points, dimensions);

      // Calculate area based on shape type
      switch (shapeType) {
        case ShapeType.rectangle:
          if (dimensions != null &&
              dimensions.containsKey('width') &&
              dimensions.containsKey('height')) {
            area = dimensions['width']! * dimensions['height']!;
          } else {
            return const Left(
              ValidationFailure('Rectangle requires width and height'),
            );
          }
          break;

        case ShapeType.circle:
          if (dimensions != null && dimensions.containsKey('radius')) {
            area = math.pi * math.pow(dimensions['radius']!, 2);
          } else {
            return const Left(ValidationFailure('Circle requires radius'));
          }
          break;

        case ShapeType.triangle:
          if (points.length == 3) {
            area = _calculateTriangleArea(points);
          } else {
            return const Left(ValidationFailure('Triangle requires 3 points'));
          }
          break;

        case ShapeType.polygon:
          if (points.length >= 3) {
            area = _calculatePolygonArea(points);
          } else {
            return const Left(
              ValidationFailure('Polygon requires at least 3 points'),
            );
          }
          break;
      }

      if (area < AppConstants.minShapeArea) {
        return const Left(CalculationFailure('Area too small'));
      }

      final measurement = Measurement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Measurement ${DateTime.now().toString()}',
        shapeType: shapeType,
        points: points,
        dimensions: dimensions,
        area: area,
        createdAt: DateTime.now(),
      );

      return Right(measurement);
    } catch (e) {
      return Left(CalculationFailure('Failed to calculate area: $e'));
    }
  }

  ShapeType _determineShapeType(
    List<Point> points,
    Map<String, double>? dimensions,
  ) {
    if (dimensions != null) {
      if (dimensions.containsKey('width') && dimensions.containsKey('height')) {
        return ShapeType.rectangle;
      }
      if (dimensions.containsKey('radius')) {
        return ShapeType.circle;
      }
    }

    if (points.length == 3) {
      return ShapeType.triangle;
    }

    return ShapeType.polygon;
  }

  double _calculateTriangleArea(List<Point> points) {
    // Using Heron's formula
    final a = _distance(points[0], points[1]);
    final b = _distance(points[1], points[2]);
    final c = _distance(points[2], points[0]);
    final s = (a + b + c) / 2;
    return math.sqrt(s * (s - a) * (s - b) * (s - c));
  }

  double _calculatePolygonArea(List<Point> points) {
    // Using Shoelace formula
    double area = 0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }

    return area.abs() / 2;
  }

  double _distance(Point p1, Point p2) {
    return math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
  }

  @override
  Future<Either<Failure, void>> saveMeasurement(Measurement measurement) async {
    try {
      final model = MeasurementModel.fromEntity(measurement);
      await localDataSource.saveMeasurement(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Measurement>>> getAllMeasurements() async {
    try {
      final models = await localDataSource.getAllMeasurements();
      final measurements = models.map((model) => model.toEntity()).toList();
      return Right(measurements);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Measurement>> getMeasurementById(String id) async {
    try {
      final model = await localDataSource.getMeasurementById(id);
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMeasurement(String id) async {
    try {
      await localDataSource.deleteMeasurement(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMeasurement(
    Measurement measurement,
  ) async {
    try {
      final model = MeasurementModel.fromEntity(measurement);
      await localDataSource.updateMeasurement(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
