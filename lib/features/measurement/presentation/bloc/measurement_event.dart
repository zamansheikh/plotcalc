part of 'measurement_bloc.dart';

abstract class MeasurementEvent extends Equatable {
  const MeasurementEvent();

  @override
  List<Object?> get props => [];
}

class CalculateAreaEvent extends MeasurementEvent {
  final List<Point> points;
  final Map<String, double>? dimensions;
  final Map<int, double> sideMeasurements;
  final Map<String, double> diagonalMeasurements;

  const CalculateAreaEvent({
    required this.points,
    this.dimensions,
    this.sideMeasurements = const {},
    this.diagonalMeasurements = const {},
  });

  @override
  List<Object?> get props => [
    points,
    dimensions,
    sideMeasurements,
    diagonalMeasurements,
  ];
}

class SaveMeasurementEvent extends MeasurementEvent {
  final Measurement measurement;

  const SaveMeasurementEvent(this.measurement);

  @override
  List<Object> get props => [measurement];
}

class LoadAllMeasurementsEvent extends MeasurementEvent {
  const LoadAllMeasurementsEvent();
}

class DeleteMeasurementEvent extends MeasurementEvent {
  final String id;

  const DeleteMeasurementEvent(this.id);

  @override
  List<Object> get props => [id];
}

class ClearCurrentMeasurementEvent extends MeasurementEvent {
  const ClearCurrentMeasurementEvent();
}
