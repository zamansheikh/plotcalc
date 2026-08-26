import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/l10n/l10n.dart';
import 'package:plotcalc/presentation/features/khotiyan/view/khotiyan_screen.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The calculator shows the traditional mark for the amount currently set, so
/// a reader can match what the screen says against the deed in their hand.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    await configureDependencies();
  });

  // Widget tests render in the fallback test font, whose glyphs are far wider
  // than Noto's. The share readout is 32pt and overflows under it at phone
  // widths, so content is checked on a surface wide enough to keep that
  // unrelated noise out; the marks' own fit is measured separately below.
  Future<void> pump(WidgetTester tester, {double width = 600}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 873);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(),
        child: MaterialApp(
          locale: const Locale('bn'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const KhotiyanScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// The plus button belonging to the row at [row] (0 = ana).
  Finder plusOn(int row) => find.byIcon(Icons.add).at(row);

  testWidgets('no mark is shown while every unit is zero', (tester) async {
    await pump(tester);
    // ৷ would appear the moment ana or kora is non-zero.
    expect(find.text('৷'), findsNothing);
    expect(find.text('⁄'), findsNothing);
  });

  testWidgets('five ana reads as ৷⁄', (tester) async {
    await pump(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(plusOn(0));
      await tester.pump();
    }
    expect(find.text('5'), findsOneWidget);
    expect(find.text('৷⁄'), findsOneWidget);
  });

  testWidgets('a whole sixteen ana reads as ১', (tester) async {
    await pump(tester);
    for (var i = 0; i < 16; i++) {
      await tester.tap(plusOn(0));
      await tester.pump();
    }
    expect(find.text('১'), findsOneWidget);
  });

  testWidgets('gonda gets no mark, since a deed writes it as a numeral', (
    tester,
  ) async {
    await pump(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(plusOn(1));
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget, reason: 'the figure still moved');
    // Nothing from the mark tables should have appeared.
    for (final mark in ['৴', '৵', '৶', '৷', '৸']) {
      expect(find.text(mark), findsNothing, reason: mark);
    }
  });

  testWidgets('kora and kranti carry their own marks', (tester) async {
    await pump(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(plusOn(2)); // kora
      await tester.pump();
    }
    await tester.tap(plusOn(3)); // kranti
    await tester.pump();
    expect(find.text('৷৷'), findsOneWidget, reason: '2 kora');
    expect(find.text('৴'), findsOneWidget, reason: '1 kranti');
  });

  testWidgets('the mark clears again when the value returns to zero', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(plusOn(0));
    await tester.pump();
    expect(find.text('⁄'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove).at(0));
    await tester.pump();
    expect(find.text('⁄'), findsNothing);
  });

  // The marks sit on the label side of an already-crowded row. Rather than
  // assert on overflow — which the test font's metrics make meaningless here
  // — measure the chip itself: it has to stay small enough to leave the label
  // its space on the narrowest phone the app supports.
  testWidgets('the widest mark stays a chip, not a column', (tester) async {
    await pump(tester, width: 600);
    for (var i = 0; i < 11; i++) {
      await tester.tap(plusOn(0)); // ৷৷৶ — the widest ana mark, three glyphs
      await tester.pump();
    }
    final chip = find.ancestor(
      of: find.text('৷৷৶'),
      matching: find.byType(Container),
    );
    final size = tester.getSize(chip.first);
    // 320dp is the narrowest Android phone worth supporting; the steppers
    // and the count take about 150 of it, so the chip must stay well under
    // what is left for the label.
    expect(size.width, lessThan(80), reason: 'width was ${size.width}');
    expect(size.height, lessThan(32), reason: 'height was ${size.height}');
  });

  testWidgets('the label yields to the mark rather than overflowing', (
    tester,
  ) async {
    await pump(tester, width: 600);
    await tester.tap(plusOn(0));
    await tester.pump();
    final label = tester.widget<Text>(find.text('আনা'));
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.maxLines, 1);
  });
}
