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
    Map<String, double> diagonalMeasurements = const {},
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
            area = _calculatePolygonArea(
              points,
              sideMeasurements,
              diagonalMeasurements,
            );
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
        sideMeasurements: sideMeasurements.isNotEmpty ? sideMeasurements : null,
        diagonalMeasurements: diagonalMeasurements.isNotEmpty ? diagonalMeasurements : null,
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
    Map<String, double> diagonalMeasurements,
  ) {
    // Calculate pixel-based area using Shoelace Formula first
    double area = 0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }

    final pixelArea = area.abs() / 2;

    // MOST ACCURATE APPROACH: Use diagonals + sides for exact triangulation
    // For a 4-sided polygon: only 1 diagonal is needed (not 2)
    // For N-sided polygon (N>4): need (N-2) diagonals
    int requiredDiagonals = 1; // Default for quadrilateral
    if (points.length > 4) {
      requiredDiagonals = points.length - 2;
    }

    if (diagonalMeasurements.length >= requiredDiagonals &&
        sideMeasurements.length == points.length) {
      print(
        'Using TRIANGULATION METHOD with ${points.length} sides + ${diagonalMeasurements.length} diagonals',
      );
      return _calculatePolygonAreaWithDiagonals(
        points,
        sideMeasurements,
        diagonalMeasurements,
      );
    }

    // BEST APPROACH: Use ALL side measurements for accuracy
    if (sideMeasurements.length == points.length) {
      // All sides are measured - calculate average scale factor for best accuracy
      List<double> scaleFactors = [];

      for (int i = 0; i < n; i++) {
        final pixelSide = _distance(points[i], points[(i + 1) % n]);
        final measuredSide = sideMeasurements[i] ?? 0;

        if (pixelSide > 0 && measuredSide > 0) {
          scaleFactors.add(measuredSide / pixelSide);
        }
      }

      if (scaleFactors.isNotEmpty) {
        // Use average scale factor for best accuracy
        final avgScaleFactor =
            scaleFactors.reduce((a, b) => a + b) / scaleFactors.length;
        print(
          'Using average scale factor: $avgScaleFactor from ${scaleFactors.length} sides',
        );
        return pixelArea * (avgScaleFactor * avgScaleFactor);
      }
    }

    // FALLBACK: If not all sides measured, use first side
    if (sideMeasurements.isNotEmpty && sideMeasurements.values.isNotEmpty) {
      final side0Distance = _distance(points[0], points[1]);
      final measuredSideMeters = sideMeasurements[0] ?? 1.0;

      if (side0Distance > 0) {
        final scaleFactor = measuredSideMeters / side0Distance;
        print('Using single side scale factor: $scaleFactor');
        // Area scales by square of linear scale factor
        return pixelArea * (scaleFactor * scaleFactor);
      }
    }

    print('WARNING: No measurements provided. Returning pixel area.');
    return pixelArea;
  }

  /// Calculate polygon area using triangulation method with diagonals
  /// This is the most accurate method for polygons
  double _calculatePolygonAreaWithDiagonals(
    List<Point> points,
    Map<int, double> sideMeasurements,
    Map<String, double> diagonalMeasurements,
  ) {
    print(
      'Triangulation Method: Breaking polygon into triangles using diagonals',
    );

    double totalArea = 0;

    // For a polygon with N sides, we can split it into (N-2) triangles using (N-2) diagonals
    // Pattern: from point 0, draw diagonals to points 2, 3, 4, ..., N-2
    // This creates triangles: (0,1,2), (0,2,3), (0,3,4), ..., (0,N-2,N-1)

    for (int i = 0; i < points.length - 2; i++) {
      final p1Index = 0;
      final p2Index = i + 1;
      final p3Index = i + 2;

      // Get the three side lengths for this triangle
      final side1Key = '$p1Index-$p2Index'; // Might be an edge or diagonal
      final side2Key = '$p2Index-$p3Index'; // Might be an edge or diagonal
      final side3Key =
          '$p1Index-$p3Index'; // Diagonal for all but last triangle

      double side1 = 0, side2 = 0, side3 = 0;

      // Get side 1 (from p1 to p2)
      if (p2Index - p1Index == 1) {
        // It's an edge
        side1 = sideMeasurements[p1Index] ?? 0;
      } else {
        // It's a diagonal
        side1 = diagonalMeasurements[side1Key] ?? 0;
      }

      // Get side 2 (from p2 to p3)
      if (p3Index - p2Index == 1) {
        // It's an edge
        side2 = sideMeasurements[p2Index] ?? 0;
      } else {
        // It's a diagonal
        side2 = diagonalMeasurements[side2Key] ?? 0;
      }

      // Get side 3 (from p3 to p1)
      if (i == points.length - 3) {
        // Last triangle: side is an edge
        side3 = sideMeasurements[p3Index] ?? 0;
      } else {
        // It's a diagonal
        side3 = diagonalMeasurements[side3Key] ?? 0;
      }

      print('  Triangle $i: sides = ${side1}m, ${side2}m, ${side3}m');

      if (side1 > 0 && side2 > 0 && side3 > 0) {
        final triangleArea = _heronArea(side1, side2, side3);
        print('    Area: $triangleArea m²');
        totalArea += triangleArea;
      } else {
        print('    WARNING: Missing measurements for this triangle');
      }
    }

    print('Total area using triangulation: $totalArea m²');
    return totalArea;
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
