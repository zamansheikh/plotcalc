import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/theme/app_typography.dart';
import 'presentation/features/info/data/land_info_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  AppTypography.registerBanglaFallback();
  await InfoContent.load();
  runApp(const PlotCalcApp());
}
