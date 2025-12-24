import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/usecases/calculate_area.dart';
import '../../domain/usecases/save_measurement.dart';
import '../../domain/usecases/get_all_measurements.dart';
import '../../domain/usecases/delete_measurement.dart';
import '../../../../core/usecases/usecase.dart';

part 'measurement_event.dart';
part 'measurement_state.dart';

@injectable
class MeasurementBloc extends Bloc<MeasurementEvent, MeasurementState> {
  final CalculateArea calculateArea;
  final SaveMeasurement saveMeasurement;
  final GetAllMeasurements getAllMeasurements;
  final DeleteMeasurement deleteMeasurement;

  MeasurementBloc({
    required this.calculateArea,
    required this.saveMeasurement,
    required this.getAllMeasurements,
    required this.deleteMeasurement,
  }) : super(const MeasurementInitial()) {
    on<CalculateAreaEvent>(_onCalculateArea);
    on<SaveMeasurementEvent>(_onSaveMeasurement);
    on<LoadAllMeasurementsEvent>(_onLoadAllMeasurements);
    on<DeleteMeasurementEvent>(_onDeleteMeasurement);
    on<ClearCurrentMeasurementEvent>(_onClearCurrentMeasurement);
  }

  Future<void> _onCalculateArea(
    CalculateAreaEvent event,
    Emitter<MeasurementState> emit,
  ) async {
    emit(const MeasurementLoading());

    final result = await calculateArea(
      CalculateAreaParams(
        points: event.points,
        dimensions: event.dimensions,
        sideMeasurements: event.sideMeasurements,
        diagonalMeasurements: event.diagonalMeasurements,
      ),
    );

    result.fold(
      (failure) => emit(MeasurementError(failure.message)),
      (measurement) => emit(MeasurementCalculated(measurement)),
    );
  }

  Future<void> _onSaveMeasurement(
    SaveMeasurementEvent event,
    Emitter<MeasurementState> emit,
  ) async {
    emit(const MeasurementLoading());

    final result = await saveMeasurement(
      SaveMeasurementParams(measurement: event.measurement),
    );

    result.fold((failure) => emit(MeasurementError(failure.message)), (_) {
      emit(const MeasurementSaved('Measurement saved successfully'));
      add(const LoadAllMeasurementsEvent());
    });
  }

  Future<void> _onLoadAllMeasurements(
    LoadAllMeasurementsEvent event,
    Emitter<MeasurementState> emit,
  ) async {
    emit(const MeasurementLoading());

    try {
      final result = await getAllMeasurements(NoParams());

      result.fold(
        (failure) => emit(MeasurementError(failure.message)),
        (measurements) => emit(MeasurementsLoaded(measurements)),
      );
    } catch (e) {
      emit(MeasurementError('Unexpected error: $e'));
    }
  }

  Future<void> _onDeleteMeasurement(
    DeleteMeasurementEvent event,
    Emitter<MeasurementState> emit,
  ) async {
    emit(const MeasurementLoading());

    final result = await deleteMeasurement(
      DeleteMeasurementParams(id: event.id),
    );

    result.fold((failure) => emit(MeasurementError(failure.message)), (_) {
      emit(const MeasurementDeleted('Measurement deleted successfully'));
      // Reload measurements after deletion
      add(const LoadAllMeasurementsEvent());
    });
  }

  void _onClearCurrentMeasurement(
    ClearCurrentMeasurementEvent event,
    Emitter<MeasurementState> emit,
  ) {
    emit(const MeasurementInitial());
  }
}
