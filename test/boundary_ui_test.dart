import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/boundary_adjust.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/presentation/features/adjust/bloc/adjust_bloc.dart';
import 'package:plotcalc/presentation/features/adjust/bloc/adjust_event.dart';
import 'package:plotcalc/presentation/features/adjust/bloc/adjust_state.dart';

/// The user's story: "I measured 5.2 katha but I want 5.5. I move one side —
/// how far?" These drive the state the screen is built on.
void main() {
  late AdjustBloc bloc;
  setUp(() => bloc = AdjustBloc());
  tearDown(() => bloc.close());
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// A plot of exactly 5.2 katha, as a rectangle.
  List<Vertex> plotOf(double katha) {
    final sqm = AreaUnit.katha.toSqm(katha);
    final w = 20.0;
    final h = sqm / w;
    return [Vertex(0, 0), Vertex(w, 0), Vertex(w, h), Vertex(0, h)];
  }

  group('the 5.2 -> 5.5 katha story', () {
    test('moving one side reports a real distance', () async {
      final base = plotOf(5.2);
      bloc.add(AdjustInitialized(base: base, initialMultiplier: 1));
      await settle();
      bloc
        ..add(const MethodChanged(AdjustMethod.boundary))
        ..add(TargetChanged(AreaUnit.katha.toSqm(5.5)))
        ..add(const SelectionToggled(0));
      await settle();

      final s = bloc.state.solveBoundary()!;
      expect(s.isExact, isTrue);
      expect(s.offsetM, greaterThan(0), reason: 'push the boundary out');
      // 0.3 katha over a 20 m side is about 1 metre.
      expect(s.offsetM, closeTo(AreaUnit.katha.toSqm(0.3) / 20, 1e-6));
      expect(
        AreaUnit.katha.fromSqm(Geometry.polygonArea(s.vertices)),
        closeTo(5.5, 1e-6),
      );
    });

    test('sharing it across two sides halves the distance', () async {
      final base = plotOf(5.2);
      bloc
        ..add(AdjustInitialized(base: base, initialMultiplier: 1))
        ..add(const MethodChanged(AdjustMethod.boundary))
        ..add(TargetChanged(AreaUnit.katha.toSqm(5.5)));
      await settle();
      bloc.add(const SelectionToggled(0));
      await settle();
      final one = bloc.state.solveBoundary()!.offsetM;

      bloc.add(const SelectionToggled(2)); // the opposite side
      await settle();
      final two = bloc.state.solveBoundary()!;

      expect(two.isExact, isTrue);
      expect(two.offsetM, closeTo(one / 2, one * 1e-6));
      expect(
        AreaUnit.katha.fromSqm(Geometry.polygonArea(two.vertices)),
        closeTo(5.5, 1e-6),
      );
    });

    test('5.2 -> 5.0 pulls the boundary in', () async {
      final base = plotOf(5.2);
      bloc
        ..add(AdjustInitialized(base: base, initialMultiplier: 1))
        ..add(const MethodChanged(AdjustMethod.boundary))
        ..add(TargetChanged(AreaUnit.katha.toSqm(5.0)))
        ..add(const SelectionToggled(1));
      await settle();

      final s = bloc.state.solveBoundary()!;
      expect(s.isExact, isTrue);
      expect(s.offsetM, lessThan(0), reason: 'pull the boundary in');
      expect(
        AreaUnit.katha.fromSqm(Geometry.polygonArea(s.vertices)),
        closeTo(5.0, 1e-6),
      );
    });

    test('the sides left alone keep their length', () async {
      // Pushing the south boundary must not shorten the east and west ones
      // by anything other than the offset.
      final base = plotOf(5.2);
      bloc
        ..add(AdjustInitialized(base: base, initialMultiplier: 1))
        ..add(const MethodChanged(AdjustMethod.boundary))
        ..add(TargetChanged(AreaUnit.katha.toSqm(5.5)))
        ..add(const SelectionToggled(0));
      await settle();

      final moved = bloc.state.solveBoundary()!.vertices;
      // Side 2 is the one opposite the moved side; its length is unchanged.
      expect(
        Geometry.sideLength(moved[2], moved[3]),
        closeTo(Geometry.sideLength(base[2], base[3]), 1e-9),
      );
    });
  });

  group('selection behaviour', () {
    test('tapping the same side twice deselects it', () async {
      bloc
        ..add(AdjustInitialized(base: plotOf(5.2)))
        ..add(const SelectionToggled(1))
        ..add(const SelectionToggled(1));
      await settle();
      expect(bloc.state.selection, isEmpty);
    });

    test('switching between sides and corners clears the selection', () async {
      // Side 2 and corner 2 are different things, so carrying the numbers
      // across would silently move the wrong part of the plot.
      bloc
        ..add(AdjustInitialized(base: plotOf(5.2)))
        ..add(const SelectionToggled(2))
        ..add(const TargetKindChanged(AdjustTargetKind.corner));
      await settle();
      expect(bloc.state.selection, isEmpty);
      expect(bloc.state.targetKind, AdjustTargetKind.corner);
    });

    test('nothing selected means no answer to show', () async {
      bloc
        ..add(AdjustInitialized(base: plotOf(5.2)))
        ..add(const MethodChanged(AdjustMethod.boundary))
        ..add(TargetChanged(AreaUnit.katha.toSqm(5.5)));
      await settle();
      expect(bloc.state.solveBoundary(), isNull);
    });

    test('clear removes the selection but keeps the target', () async {
      final target = AreaUnit.katha.toSqm(5.5);
      bloc
        ..add(AdjustInitialized(base: plotOf(5.2)))
        ..add(TargetChanged(target))
        ..add(const SelectionToggled(0))
        ..add(const SelectionCleared());
      await settle();
      expect(bloc.state.selection, isEmpty);
      expect(bloc.state.targetSqm, target);
    });

    test('switching method leaves the plot and target alone', () async {
      final base = plotOf(5.2);
      final expected = Geometry.polygonArea(base) * 1.2;
      bloc
        ..add(AdjustInitialized(base: base, initialMultiplier: 1.2))
        ..add(const MethodChanged(AdjustMethod.boundary));
      await settle();
      expect(bloc.state.baseVertices, base);
      expect(bloc.state.targetSqm, closeTo(expected, 1e-9));
    });
  });

  group('corners', () {
    test('moving one corner reaches the target', () async {
      bloc
        ..add(AdjustInitialized(base: plotOf(5.2)))
        ..add(const MethodChanged(AdjustMethod.boundary))
        ..add(const TargetKindChanged(AdjustTargetKind.corner))
        ..add(TargetChanged(AreaUnit.katha.toSqm(5.4)))
        ..add(const SelectionToggled(0));
      await settle();

      final s = bloc.state.solveBoundary()!;
      expect(s.isExact, isTrue);
      expect(
        AreaUnit.katha.fromSqm(Geometry.polygonArea(s.vertices)),
        closeTo(5.4, 1e-5),
      );
    });
  });
}
