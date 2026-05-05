part of 'measurement_unit_bloc.dart';

class MeasurementUnitState extends Equatable {
  final InputUnit unit;

  const MeasurementUnitState(this.unit);

  @override
  List<Object?> get props => [unit];
}
