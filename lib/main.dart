import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'features/measurement/presentation/bloc/measurement_bloc.dart';
import 'features/settings/presentation/bloc/language_bloc.dart';
import 'features/settings/presentation/bloc/measurement_unit_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependencies (includes database initialization)
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MeasurementBloc>(
          create: (context) => getIt<MeasurementBloc>(),
        ),
        BlocProvider<LanguageBloc>(
          create: (context) => LanguageBloc()..add(LoadLanguageEvent()),
        ),
        BlocProvider<MeasurementUnitBloc>(
          create: (context) =>
              MeasurementUnitBloc()..add(const LoadMeasurementUnitEvent()),
        ),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return MaterialApp.router(
            title: 'PlotCalc : LandSketch',
            debugShowCheckedModeBanner: false,
            locale: languageState.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('bn')],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
