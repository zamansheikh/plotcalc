import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/measurement.dart';

class MeasurementModel {
  final String id;
  final String name;
  final String shapeType;
  final String points; // JSON string of List<PointModel>
  final String? dimensions; // JSON string of Map<String, double>
  final String? sideMeasurements; // JSON string of Map<int, double>
  final String? diagonalMeasurements; // JSON string of Map<String, double>
  final double area;
  final String createdAt;
  final String preferredUnit;

  MeasurementModel({
    required this.id,
    required this.name,
    required this.shapeType,
    required this.points,
    this.dimensions,
    this.sideMeasurements,
    this.diagonalMeasurements,
    required this.area,
    required this.createdAt,
    required this.preferredUnit,
  });

  factory MeasurementModel.fromEntity(Measurement measurement) {
    return MeasurementModel(
      id: measurement.id,
      name: measurement.name,
      shapeType: measurement.shapeType.name,
      points: _pointsToJson(measurement.points),
      dimensions: measurement.dimensions != null
          ? _dimensionsToJson(measurement.dimensions!)
          : null,
      sideMeasurements: measurement.sideMeasurements != null
          ? _sideMeasurementsToJson(measurement.sideMeasurements!)
          : null,
      diagonalMeasurements: measurement.diagonalMeasurements != null
          ? _dimensionsToJson(measurement.diagonalMeasurements!)
          : null,
      area: measurement.area,
      createdAt: measurement.createdAt.toIso8601String(),
      preferredUnit: measurement.preferredUnit.name,
    );
  }

  Measurement toEntity() {
    return Measurement(
      id: id,
      name: name,
      shapeType: ShapeType.values.firstWhere((e) => e.name == shapeType),
      points: _jsonToPoints(points),
      dimensions: dimensions != null ? _jsonToDimensions(dimensions!) : null,
      sideMeasurements: sideMeasurements != null 
          ? _jsonToSideMeasurements(sideMeasurements!) 
          : null,
      diagonalMeasurements: diagonalMeasurements != null 
          ? _jsonToDimensions(diagonalMeasurements!) 
          : null,
      area: area,
      createdAt: DateTime.parse(createdAt),
      preferredUnit: MeasurementUnit.values.firstWhere(
        (e) => e.name == preferredUnit,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shapeType': shapeType,
      'points': points,
      'dimensions': dimensions,
      'sideMeasurements': sideMeasurements,
      'diagonalMeasurements': diagonalMeasurements,
      'area': area,
      'createdAt': createdAt,
      'preferredUnit': preferredUnit,
    };
  }

  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    return MeasurementModel(
      id: map['id'] as String,
      name: map['name'] as String,
      shapeType: map['shapeType'] as String,
      points: map['points'] as String,
      dimensions: map['dimensions'] as String?,
      sideMeasurements: map['sideMeasurements'] as String?,
      diagonalMeasurements: map['diagonalMeasurements'] as String?,
      area: map['area'] as double,
      createdAt: map['createdAt'] as String,
      preferredUnit: map['preferredUnit'] as String,
    );
  }

  static String _pointsToJson(List<Point> points) {
    final list = points.map((p) => {'x': p.x, 'y': p.y}).toList();
    return list.toString();
  }

  static List<Point> _jsonToPoints(String json) {
    // Simple parsing - in production, use json_serializable or dart:convert
    final cleaned = json
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('{', '')
        .replaceAll('}', '');
    final pairs = cleaned.split(', x:');
    return pairs.map((pair) {
      final parts = pair.replaceAll('x:', '').split(', y:');
      if (parts.length == 2) {
        return Point(
          double.parse(parts[0].trim()),
          double.parse(parts[1].trim()),
        );
      }
      return const Point(0, 0);
    }).toList();
  }

  static String _dimensionsToJson(Map<String, double> dimensions) {
    return dimensions.toString();
  }

  static Map<String, double> _jsonToDimensions(String json) {
    final map = <String, double>{};
    final cleaned = json.replaceAll('{', '').replaceAll('}', '');
    final pairs = cleaned.split(', ');
    for (var pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0].trim()] = double.parse(parts[1].trim());
      }
    }
    return map;
  }

  static String _sideMeasurementsToJson(Map<int, double> sideMeasurements) {
    return sideMeasurements.toString();
  }

  static Map<int, double> _jsonToSideMeasurements(String json) {
    final map = <int, double>{};
    final cleaned = json.replaceAll('{', '').replaceAll('}', '');
    final pairs = cleaned.split(', ');
    for (var pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[int.parse(parts[0].trim())] = double.parse(parts[1].trim());
      }
    }
    return map;
  }
}
