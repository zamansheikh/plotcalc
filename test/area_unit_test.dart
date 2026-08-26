import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/units/area_unit.dart';

/// Square feet per unit, written out independently of the implementation so
/// the test pins the values rather than restating the same expression.
const expectedSqft = <AreaUnit, double>{
  AreaUnit.sqft: 1,
  AreaUnit.sqm: 10.763910416709722,
  AreaUnit.acre: 43560,
  AreaUnit.hectare: 107639.10416709722,
  AreaUnit.bigha: 14400,
  AreaUnit.katha: 720,
  AreaUnit.chatak: 45,
  AreaUnit.shotok: 435.6,
  AreaUnit.kathaMymensingh: 2831.4,
  AreaUnit.bighaMymensingh: 56628,
};

/// Square metres per unit, at 1 ft = 0.3048 m exactly.
const expectedSqm = <AreaUnit, double>{
  AreaUnit.sqft: 0.09290304,
  AreaUnit.sqm: 1,
  AreaUnit.acre: 4046.8564224,
  AreaUnit.hectare: 10000,
  AreaUnit.bigha: 1337.803776,
  AreaUnit.katha: 66.8901888,
  AreaUnit.chatak: 4.1806368,
  AreaUnit.shotok: 40.468564224,
  AreaUnit.kathaMymensingh: 263.045667456,
  AreaUnit.bighaMymensingh: 5260.91334912,
};

void main() {
  group('exact sizes', () {
    test('every unit has the expected size in square feet', () {
      for (final u in AreaUnit.values) {
        expect(
          u.sqftPerUnit,
          closeTo(expectedSqft[u]!, expectedSqft[u]! * 1e-12),
          reason: u.name,
        );
      }
    });

    test('every unit has the expected size in square metres', () {
      for (final u in AreaUnit.values) {
        expect(
          u.sqmPerUnit,
          closeTo(expectedSqm[u]!, expectedSqm[u]! * 1e-12),
          reason: u.name,
        );
      }
    });

    test('the table covers every enum value', () {
      expect(expectedSqft.keys.toSet(), AreaUnit.values.toSet());
      expect(expectedSqm.keys.toSet(), AreaUnit.values.toSet());
    });
  });

  group('definitional identities', () {
    // Each is a relationship that defines the units, so it must hold exactly
    // (to floating-point tolerance), not approximately.
    void identity(String what, double a, double b) {
      test(what, () => expect(a, closeTo(b, b.abs() * 1e-12)));
    }

    identity('20 katha = 1 bigha',
        20 * AreaUnit.katha.sqmPerUnit, AreaUnit.bigha.sqmPerUnit);
    identity('16 chatak = 1 katha',
        16 * AreaUnit.chatak.sqmPerUnit, AreaUnit.katha.sqmPerUnit);
    identity('320 chatak = 1 bigha',
        320 * AreaUnit.chatak.sqmPerUnit, AreaUnit.bigha.sqmPerUnit);
    identity('100 shotok = 1 acre',
        100 * AreaUnit.shotok.sqmPerUnit, AreaUnit.acre.sqmPerUnit);
    identity('1 hectare = 10000 m²', AreaUnit.hectare.sqmPerUnit, 10000);
    identity('1 sq ft = 0.09290304 m² (0.3048² exactly)',
        AreaUnit.sqft.sqmPerUnit, 0.3048 * 0.3048);

    // Mymensingh regional pair.
    identity('6.5 shotok = 1 katha (Mymensingh)',
        6.5 * AreaUnit.shotok.sqmPerUnit, AreaUnit.kathaMymensingh.sqmPerUnit);
    identity('20 katha (M) = 1 bigha (M)',
        20 * AreaUnit.kathaMymensingh.sqmPerUnit,
        AreaUnit.bighaMymensingh.sqmPerUnit);
    identity('130 shotok = 1 bigha (M)',
        130 * AreaUnit.shotok.sqmPerUnit,
        AreaUnit.bighaMymensingh.sqmPerUnit);
    identity('1 bigha (M) = 1.3 acre',
        AreaUnit.bighaMymensingh.sqmPerUnit, 1.3 * AreaUnit.acre.sqmPerUnit);

    test('1 katha (M) is 6.5/1.65 the standard katha', () {
      final ratio =
          AreaUnit.kathaMymensingh.sqmPerUnit / AreaUnit.katha.sqmPerUnit;
      expect(ratio, closeTo(2831.4 / 720, 1e-9));
      expect(ratio, greaterThan(3.9)); // a Mymensingh katha is much larger
    });

    test('1 acre ≈ 3.025 standard bigha', () {
      expect(
        AreaUnit.acre.sqmPerUnit / AreaUnit.bigha.sqmPerUnit,
        closeTo(3.025, 0.001),
      );
    });
  });

  group('regression: bigha was an order of magnitude too small', () {
    // The shipped factor 0.00747384 made 1 bigha ≈ 133.8 m² instead of
    // ≈ 1337.8 m², so every conversion into bigha read 10× too high.
    test('1 bigha is ~1337.8 m², not ~133.8 m²', () {
      expect(AreaUnit.bigha.sqmPerUnit, closeTo(1337.803776, 1e-6));
      expect(AreaUnit.bigha.sqmPerUnit, greaterThan(1000));
    });

    test('one bigha of land reads as 1 bigha', () {
      expect(AreaUnit.bigha.fromSqm(1337.803776), closeTo(1, 1e-9));
    });

    test('a 1 bigha plot is ~33 shotok, ~20 katha, ~14400 sq ft', () {
      const oneBigha = 1337.803776;
      expect(AreaUnit.shotok.fromSqm(oneBigha), closeTo(33.0578, 0.001));
      expect(AreaUnit.katha.fromSqm(oneBigha), closeTo(20, 1e-9));
      expect(AreaUnit.sqft.fromSqm(oneBigha), closeTo(14400, 1e-6));
    });
  });

  group('conversion', () {
    test('fromSqm and toSqm round-trip for every unit', () {
      for (final u in AreaUnit.values) {
        for (final sqm in [0.5, 1.0, 42.0, 1337.803776, 1e6]) {
          expect(
            u.toSqm(u.fromSqm(sqm)),
            closeTo(sqm, sqm * 1e-12),
            reason: '${u.name} @ $sqm',
          );
        }
      }
    });

    test('factor stays consistent with sqmPerUnit', () {
      for (final u in AreaUnit.values) {
        expect(u.factor, closeTo(1 / u.sqmPerUnit, 1e-15), reason: u.name);
        expect(u.fromSqm(1), closeTo(u.factor, 1e-15), reason: u.name);
      }
    });

    test('cross-unit conversion is symmetric', () {
      for (final a in AreaUnit.values) {
        for (final b in AreaUnit.values) {
          final oneA = a.toSqm(1);
          final inB = b.fromSqm(oneA);
          expect(a.fromSqm(b.toSqm(inB)), closeTo(1, 1e-9),
              reason: '${a.name} -> ${b.name}');
        }
      }
    });

    test('a real-world acre converts correctly across the board', () {
      final acre = AreaUnit.acre.toSqm(1);
      expect(AreaUnit.sqft.fromSqm(acre), closeTo(43560, 1e-6));
      expect(AreaUnit.shotok.fromSqm(acre), closeTo(100, 1e-9));
      expect(AreaUnit.katha.fromSqm(acre), closeTo(60.5, 1e-9));
      expect(AreaUnit.bigha.fromSqm(acre), closeTo(3.025, 1e-9));
      expect(AreaUnit.kathaMymensingh.fromSqm(acre), closeTo(15.3846, 0.0001));
      expect(AreaUnit.bighaMymensingh.fromSqm(acre), closeTo(0.769231, 1e-6));
      expect(AreaUnit.hectare.fromSqm(acre), closeTo(0.404686, 1e-6));
    });
  });

  group('persistence keys', () {
    test('fromKey round-trips every unit', () {
      for (final u in AreaUnit.values) {
        expect(AreaUnit.fromKey(u.name), u, reason: u.name);
      }
    });

    test('unknown keys fall back to sqft', () {
      expect(AreaUnit.fromKey('nope'), AreaUnit.sqft);
    });

    test('stored names are stable', () {
      // Renaming a value would silently reset saved user preferences.
      expect(AreaUnit.values.map((u) => u.name), [
        'sqft', 'sqm', 'acre', 'hectare', 'bigha',
        'katha', 'chatak', 'shotok', 'bighaMymensingh', 'kathaMymensingh',
      ]);
    });
  });
}
