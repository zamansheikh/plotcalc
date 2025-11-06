part of 'measurement_unit_bloc.dart';

abstract class MeasurementUnitEvent extends Equatable {
  const MeasurementUnitEvent();

  @override
  List<Object?> get props => [];
}

class LoadMeasurementUnitEvent extends MeasurementUnitEvent {
  const LoadMeasurementUnitEvent();
}

class ChangeMeasurementUnitEvent extends MeasurementUnitEvent {
  final InputUnit unit;

  const ChangeMeasurementUnitEvent(this.unit);

  @override
  List<Object?> get props => [unit];
}
