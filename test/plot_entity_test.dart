import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/domain/entities/plot.dart';

Plot plot({AreaUnit? unit}) => Plot(
  id: 'p1',
  name: 'North field',
  vertices: const [Vertex(0, 0), Vertex(10, 0), Vertex(10, 10)],
  tag: PlotTag.agricultural,
  createdAt: DateTime.utc(2026, 3, 4, 5, 6),
  colorValue: 0xFF00FF00,
  preferredUnit: unit,
);

void main() {
  group('preferred unit', () {
    test('round-trips through JSON', () {
      for (final u in AreaUnit.values) {
        final back = Plot.fromJson(plot(unit: u).toJson());
        expect(back.preferredUnit, u, reason: u.name);
        expect(back, plot(unit: u), reason: 'equality includes the unit');
      }
    });

    test('is absent from JSON when unset', () {
      final json = plot().toJson();
      expect(json.containsKey('preferredUnit'), isFalse,
          reason: 'stored shape unchanged for plots that follow the setting');
      expect(Plot.fromJson(json).preferredUnit, isNull);
    });

    test('a plot saved before the field existed still loads', () {
      // Exactly the shape written by the previous release.
      final legacy = {
        'id': 'old',
        'name': 'Legacy',
        'vertices': [
          {'x': 0.0, 'y': 0.0},
          {'x': 5.0, 'y': 0.0},
          {'x': 5.0, 'y': 5.0},
        ],
        'tag': 'residential',
        'createdAt': '2025-01-02T03:04:05.000Z',
        'colorValue': 0xFF112233,
      };
      final p = Plot.fromJson(legacy);
      expect(p.preferredUnit, isNull);
      expect(p.name, 'Legacy');
      expect(p.tag, PlotTag.residential);
    });

    test('an unreadable value means "follow the setting", not square feet', () {
      for (final bad in [null, '', 'furlong', 42, true]) {
        final json = plot().toJson()..['preferredUnit'] = bad;
        expect(Plot.fromJson(json).preferredUnit, isNull, reason: '$bad');
      }
    });
  });

  group('copyWith', () {
    test('sets a unit', () {
      expect(plot().copyWith(preferredUnit: AreaUnit.bigha).preferredUnit,
          AreaUnit.bigha);
    });

    test('keeps the existing unit when not mentioned', () {
      final p = plot(unit: AreaUnit.katha).copyWith(name: 'Renamed');
      expect(p.preferredUnit, AreaUnit.katha);
      expect(p.name, 'Renamed');
    });

    test('clears the unit only when explicitly asked', () {
      final p = plot(unit: AreaUnit.katha);
      expect(p.copyWith(preferredUnit: null).preferredUnit, AreaUnit.katha,
          reason: 'null alone cannot express "clear"');
      expect(p.copyWith(clearPreferredUnit: true).preferredUnit, isNull);
    });
  });
}
