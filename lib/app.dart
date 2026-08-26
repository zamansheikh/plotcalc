import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'presentation/shared/settings/settings_bloc.dart';
import 'presentation/shared/settings/settings_state.dart';

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
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (a, b) => a.locale != b.locale,
        builder: (context, settings) => MaterialApp.router(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: _router,
        ),
      ),
    );
  }
}
