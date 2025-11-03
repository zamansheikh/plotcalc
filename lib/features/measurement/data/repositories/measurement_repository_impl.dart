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
    Map<int, double> sideMeasurements = const {},
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
            area = _calculateTriangleArea(points, sideMeasurements);
          } else {
            return const Left(ValidationFailure('Triangle requires 3 points'));
          }
          break;

        case ShapeType.polygon:
          if (points.length >= 3) {
            area = _calculatePolygonArea(points, sideMeasurements);
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

  double _calculateTriangleArea(
    List<Point> points,
    Map<int, double> sideMeasurements,
  ) {
    print('DEBUG: _calculateTriangleArea');
    print('  sideMeasurements: $sideMeasurements');
    print('  sideMeasurements.length: ${sideMeasurements.length}');
    print('  points.length: ${points.length}');

    // If we have all 3 side measurements, use Heron's formula with actual measurements
    if (sideMeasurements.length >= 3) {
      // Get all 3 side measurements
      final sideA = sideMeasurements[0] ?? 0;
      final sideB = sideMeasurements[1] ?? 0;
      final sideC = sideMeasurements[2] ?? 0;

      print('  sideA: $sideA, sideB: $sideB, sideC: $sideC');

      if (sideA > 0 && sideB > 0 && sideC > 0) {
        // Use Heron's formula directly with measured sides
        final result = _heronArea(sideA, sideB, sideC);
        print('  Using direct Heron with measured sides: $result');
        return result;
      }
    }

    // Fallback: calculate pixel-based area and scale it
    final a = _distance(points[0], points[1]);
    final b = _distance(points[1], points[2]);
    final c = _distance(points[2], points[0]);

    print('  Using fallback - pixel distances: a=$a, b=$b, c=$c');

    // Calculate pixel-based area
    final pixelArea = _heronArea(a, b, c);
    print('  pixelArea: $pixelArea');

    // If we have at least one side measurement, use it to scale
    if (sideMeasurements.isNotEmpty && sideMeasurements.values.isNotEmpty) {
      // Get first available side measurement
      final sideMeasurement = sideMeasurements.values.first;
      final pixelSide = a; // First side in pixels

      print(
        '  Scaling with sideMeasurement: $sideMeasurement, pixelSide: $pixelSide',
      );

      if (pixelSide > 0) {
        final scaleFactor = sideMeasurement / pixelSide;
        final result = pixelArea * (scaleFactor * scaleFactor);
        print('  scaleFactor: $scaleFactor, scaledArea: $result');
        return result;
      }
    }

    print('  No measurements, returning pixelArea: $pixelArea');
    return pixelArea;
  }

  double _heronArea(double a, double b, double c) {
    final s = (a + b + c) / 2;
    return math.sqrt(s * (s - a) * (s - b) * (s - c));
  }

  double _calculatePolygonArea(
    List<Point> points,
    Map<int, double> sideMeasurements,
  ) {
    // If we have all side measurements, use better calculation
    if (sideMeasurements.length == points.length) {
      // We have measurements for all sides - scale using first side ratio
      final side0PixelDistance = _distance(points[0], points[1]);
      final side0Measured = sideMeasurements[0] ?? 1.0;

      if (side0PixelDistance > 0) {
        // Calculate pixel-based area using Shoelace
        double pixelArea = 0;
        final n = points.length;

        for (int i = 0; i < n; i++) {
          final j = (i + 1) % n;
          pixelArea += points[i].x * points[j].y;
          pixelArea -= points[j].x * points[i].y;
        }

        pixelArea = pixelArea.abs() / 2;

        // Scale by square of the ratio
        final scaleFactor = side0Measured / side0PixelDistance;
        return pixelArea * (scaleFactor * scaleFactor);
      }
    }

    // Fallback: calculate pixel-based area and scale it
    double area = 0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }

    final pixelArea = area.abs() / 2;

    // If we have at least one side measurement, use it to scale
    if (sideMeasurements.isNotEmpty && sideMeasurements.values.isNotEmpty) {
      final side0Distance = _distance(points[0], points[1]);
      final measuredSideMeters = sideMeasurements[0] ?? 1.0;

      if (side0Distance > 0) {
        final scaleFactor = measuredSideMeters / side0Distance;
        // Area scales by square of linear scale factor
        return pixelArea * (scaleFactor * scaleFactor);
      }
    }

    return pixelArea;
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
