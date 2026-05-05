import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

class Point extends Equatable {
  final double x;
  final double y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];
}

class Measurement extends Equatable {
  final String id;
  final String name;
  final ShapeType shapeType;
  final List<Point> points;
  final Map<String, double>? dimensions; // For rectangles, circles, etc.
  final Map<int, double>?
  sideMeasurements; // For polygons - side index to measurement
  final Map<String, double>?
  diagonalMeasurements; // For polygons - "0-2" to measurement
  final double area; // in square meters
  final DateTime createdAt;
  final MeasurementUnit preferredUnit;

  const Measurement({
    required this.id,
    required this.name,
    required this.shapeType,
    required this.points,
    this.dimensions,
    this.sideMeasurements,
    this.diagonalMeasurements,
    required this.area,
    required this.createdAt,
    this.preferredUnit = MeasurementUnit.squareMeters,
  });

  Measurement copyWith({String? name}) {
    return Measurement(
      id: id,
      name: name ?? this.name,
      shapeType: shapeType,
      points: points,
      dimensions: dimensions,
      sideMeasurements: sideMeasurements,
      diagonalMeasurements: diagonalMeasurements,
      area: area,
      createdAt: createdAt,
      preferredUnit: preferredUnit,
    );
  }

  double getAreaIn(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.squareMeters:
        return area;
      case MeasurementUnit.squareFeet:
        return area * AppConstants.sqMeterToSqFeet;
      case MeasurementUnit.acres:
        return area * AppConstants.sqMeterToAcre;
      case MeasurementUnit.hectares:
        return area * AppConstants.sqMeterToHectare;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    shapeType,
    points,
    dimensions,
    sideMeasurements,
    diagonalMeasurements,
    area,
    createdAt,
    preferredUnit,
  ];
}
