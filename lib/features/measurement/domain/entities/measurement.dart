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
  final double area; // in square meters
  final DateTime createdAt;
  final MeasurementUnit preferredUnit;

  const Measurement({
    required this.id,
    required this.name,
    required this.shapeType,
    required this.points,
    this.dimensions,
    required this.area,
    required this.createdAt,
    this.preferredUnit = MeasurementUnit.squareMeters,
  });

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
    area,
    createdAt,
    preferredUnit,
  ];
}
