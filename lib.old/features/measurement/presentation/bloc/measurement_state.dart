part of 'measurement_bloc.dart';

abstract class MeasurementState extends Equatable {
  const MeasurementState();

  @override
  List<Object?> get props => [];
}

class MeasurementInitial extends MeasurementState {
  const MeasurementInitial();
}

class MeasurementLoading extends MeasurementState {
  const MeasurementLoading();
}

class MeasurementCalculated extends MeasurementState {
  final Measurement measurement;

  const MeasurementCalculated(this.measurement);

  @override
  List<Object> get props => [measurement];
}

class MeasurementSaved extends MeasurementState {
  final String message;

  const MeasurementSaved(this.message);

  @override
  List<Object> get props => [message];
}

class MeasurementsLoaded extends MeasurementState {
  final List<Measurement> measurements;

  const MeasurementsLoaded(this.measurements);

  @override
  List<Object> get props => [measurements];
}

class MeasurementDeleted extends MeasurementState {
  final String message;

  const MeasurementDeleted(this.message);

  @override
  List<Object> get props => [message];
}

class MeasurementError extends MeasurementState {
  final String message;

  const MeasurementError(this.message);

  @override
  List<Object> get props => [message];
}
