part of 'measurement_bloc.dart';

abstract class MeasurementEvent extends Equatable {
  const MeasurementEvent();

  @override
  List<Object?> get props => [];
}

class CalculateAreaEvent extends MeasurementEvent {
  final List<Point> points;
  final Map<String, double>? dimensions;

  const CalculateAreaEvent({required this.points, this.dimensions});

  @override
  List<Object?> get props => [points, dimensions];
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
