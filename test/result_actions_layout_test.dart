import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/result/view/result_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The action row carries four buttons. On a Pixel 6 it overflowed by 21px
/// when the icon sat beside the label, so these pin the layout at the
/// narrowest widths the app realistically runs at.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
  });

  const args = ResultArgs(
    name: 'North field',
    vertices: [Vertex(0, 0), Vertex(30, 0), Vertex(30, 30), Vertex(0, 30)],
  );

  Future<void> pumpAt(WidgetTester tester, Size logical, Locale locale) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = logical;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ResultScreen(args: args),
        ),
      ),
    );
    // pump, not pumpAndSettle: settle waits on the scroll physics forever.
    await tester.pump(const Duration(milliseconds: 400));
  }

  // 320dp is the narrowest Android phone worth supporting; 360 is a Pixel.
  for (final width in [320.0, 360.0, 411.0]) {
    for (final locale in [const Locale('en'), const Locale('bn')]) {
      testWidgets(
        'the action row fits at ${width.toInt()}dp in ${locale.languageCode}',
        (tester) async {
          await pumpAt(tester, Size(width, 800), locale);
          expect(
            tester.takeException(),
            isNull,
            reason: 'a RenderFlex overflow would surface here',
          );
        },
      );
    }
  }

  testWidgets('all four actions are present', (tester) async {
    await pumpAt(tester, const Size(360, 800), const Locale('en'));
    // Two Copies: the action row, and the breakdown card's own shortcut.
    expect(find.text('Copy'), findsNWidgets(2));
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Adjust'), findsOneWidget);
  });
}
