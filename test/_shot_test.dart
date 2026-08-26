import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/calculator/view/calculator_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    tester.view.physicalSize = const Size(1170, 2200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const CalculatorScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, '1111');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.pump(const Duration(milliseconds: 300));
    final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    final img = await ro.toImage(pixelRatio: 1.6);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    File('.shot/calc.png').writeAsBytesSync(bd!.buffer.asUint8List());
  });
}
