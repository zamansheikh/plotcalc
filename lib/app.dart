import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/shared/settings/settings_bloc.dart';

class PlotCalcApp extends StatefulWidget {
  const PlotCalcApp({super.key});

  @override
  State<PlotCalcApp> createState() => _PlotCalcAppState();
}

class _PlotCalcAppState extends State<PlotCalcApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
    return BlocProvider<SettingsBloc>(
      create: (_) => SettingsBloc(),
      child: MaterialApp.router(
        title: 'PlotCalc',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
