// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/measurement/data/datasources/measurement_local_data_source.dart'
    as _i61;
import '../../features/measurement/data/repositories/measurement_repository_impl.dart'
    as _i959;
import '../../features/measurement/domain/repositories/measurement_repository.dart'
    as _i176;
import '../../features/measurement/domain/usecases/calculate_area.dart'
    as _i933;
import '../../features/measurement/domain/usecases/delete_measurement.dart'
    as _i542;
import '../../features/measurement/domain/usecases/get_all_measurements.dart'
    as _i318;
import '../../features/measurement/domain/usecases/save_measurement.dart'
    as _i904;
import '../../features/measurement/domain/usecases/update_measurement.dart'
    as _i405;
import '../../features/measurement/presentation/bloc/measurement_bloc.dart'
    as _i336;
import '../database/database_helper.dart' as _i64;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i64.DatabaseHelper>(() => _i64.DatabaseHelper());
    gh.factory<_i61.MeasurementLocalDataSource>(
      () => _i61.MeasurementLocalDataSourceImpl(gh<_i64.DatabaseHelper>()),
    );
    gh.factory<_i176.MeasurementRepository>(
      () => _i959.MeasurementRepositoryImpl(
        gh<_i61.MeasurementLocalDataSource>(),
      ),
    );
    gh.factory<_i933.CalculateArea>(
      () => _i933.CalculateArea(gh<_i176.MeasurementRepository>()),
    );
    gh.factory<_i542.DeleteMeasurement>(
      () => _i542.DeleteMeasurement(gh<_i176.MeasurementRepository>()),
    );
    gh.factory<_i318.GetAllMeasurements>(
      () => _i318.GetAllMeasurements(gh<_i176.MeasurementRepository>()),
    );
    gh.factory<_i904.SaveMeasurement>(
      () => _i904.SaveMeasurement(gh<_i176.MeasurementRepository>()),
    );
    gh.factory<_i405.UpdateMeasurement>(
      () => _i405.UpdateMeasurement(gh<_i176.MeasurementRepository>()),
    );
    gh.factory<_i336.MeasurementBloc>(
      () => _i336.MeasurementBloc(
        calculateArea: gh<_i933.CalculateArea>(),
        saveMeasurement: gh<_i904.SaveMeasurement>(),
        updateMeasurement: gh<_i405.UpdateMeasurement>(),
        getAllMeasurements: gh<_i318.GetAllMeasurements>(),
        deleteMeasurement: gh<_i542.DeleteMeasurement>(),
      ),
    );
    return this;
  }
}
