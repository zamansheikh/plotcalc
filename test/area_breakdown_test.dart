import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';

const _bd = BreakdownConfig(
  order: [AreaUnit.bigha, AreaUnit.katha, AreaUnit.chatak],
  enabled: {AreaUnit.bigha, AreaUnit.katha, AreaUnit.chatak},
);

String _render(AreaBreakdown b) =>
    b.parts.map((p) => '${p.formatted} ${p.unit.name}').join(', ');

void main() {
  group('exact quantities', () {
    test('exactly one bigha is just "1 bigha"', () {
      final b = AreaBreakdown.of(AreaUnit.bigha.toSqm(1), _bd);
      expect(_render(b), '1 bigha');
    });

    test('exactly twenty katha is one bigha, not 19 katha + dust', () {
      // Regression guard: 1337.803776 / 66.8901888 floors to 19 without the
      // quotient epsilon, silently losing a whole bigha.
      final b = AreaBreakdown.of(AreaUnit.katha.toSqm(20), _bd);
      expect(_render(b), '1 bigha');
    });

    test('every whole multiple of every unit lands exactly', () {
      for (final u in AreaUnit.values) {
        for (final n in [1, 2, 3, 7, 19, 20, 21, 100]) {
          final b = AreaBreakdown.of(u.toSqm(n.toDouble()), _bd);
          expect(
            b.accountedSqm,
            closeTo(u.toSqm(n.toDouble()), u.toSqm(n.toDouble()) * 1e-9),
            reason: '$n ${u.name}',
          );
        }
      }
    });
  });

  group('floating-point cliffs (found by sweeping every whole multiple)', () {
    test('33 acre reads as 33 acre, not 32 + remainder', () {
      // 33 * acreSqm / acreSqm == 32.99999999999999 in IEEE-754.
      const acres = BreakdownConfig(
        order: [AreaUnit.acre, AreaUnit.shotok],
        enabled: {AreaUnit.acre, AreaUnit.shotok},
      );
      final b = AreaBreakdown.of(AreaUnit.acre.toSqm(33), acres);
      expect(_render(b), '33 acre');
    });

    test('1 bigha 6 katha does not degrade to 5 katha + 16 chatak', () {
      final sqm = AreaUnit.bigha.toSqm(1) + AreaUnit.katha.toSqm(6);
      expect(_render(AreaBreakdown.of(sqm, _bd)), '1 bigha, 6 katha');
    });

    test('every bigha/katha/chatak combination reconstructs exactly', () {
      // Exhaustive over the ranges that can actually occur, since the
      // failures are sparse and unpredictable (19 of 960 without the guard).
      for (var bigha = 0; bigha < 4; bigha++) {
        for (var katha = 0; katha < 20; katha++) {
          for (var chatak = 0; chatak < 16; chatak++) {
            final sqm = AreaUnit.bigha.toSqm(bigha.toDouble()) +
                AreaUnit.katha.toSqm(katha.toDouble()) +
                AreaUnit.chatak.toSqm(chatak.toDouble());
            if (sqm <= 0) continue;
            final b = AreaBreakdown.of(sqm, _bd);
            double got(AreaUnit u) => b.parts
                .where((p) => p.unit == u)
                .fold(0.0, (sum, p) => sum + p.value);
            final label = '$bigha bigha $katha katha $chatak chatak';
            expect(got(AreaUnit.bigha), bigha, reason: label);
            expect(got(AreaUnit.katha), katha, reason: label);
            expect(got(AreaUnit.chatak), closeTo(chatak, 1e-6), reason: label);
          }
        }
      }
    });

    test('a whole multiple of the largest enabled unit stands alone', () {
      // Only the largest unit can be expected to absorb the whole area: an
      // acre is 3.025 bigha, so "3 bigha, 8 chatak" is a correct reading and
      // not a remainder bug.
      final cases = <BreakdownConfig, AreaUnit>{
        _bd: AreaUnit.bigha,
        const BreakdownConfig(
          order: [AreaUnit.acre, AreaUnit.shotok],
          enabled: {AreaUnit.acre, AreaUnit.shotok},
        ): AreaUnit.acre,
        const BreakdownConfig(
          order: [AreaUnit.kathaMymensingh, AreaUnit.shotok],
          enabled: {AreaUnit.kathaMymensingh, AreaUnit.shotok},
        ): AreaUnit.kathaMymensingh,
      };
      cases.forEach((cfg, largest) {
        for (var n = 1; n <= 200; n++) {
          final b = AreaBreakdown.of(largest.toSqm(n.toDouble()), cfg);
          expect(b.parts.length, 1, reason: '$n ${largest.name}: ${_render(b)}');
          expect(b.parts.single.unit, largest);
          expect(b.parts.single.value, closeTo(n, 1e-9),
              reason: '$n ${largest.name}');
        }
      });
    });
  });

  group('compound readings', () {
    test('1 bigha 5 katha 3 chatak round-trips', () {
      final sqm = AreaUnit.bigha.toSqm(1) +
          AreaUnit.katha.toSqm(5) +
          AreaUnit.chatak.toSqm(3);
      final b = AreaBreakdown.of(sqm, _bd);
      expect(_render(b), '1 bigha, 5 katha, 3.00 chatak');
    });

    test('carries correctly at the 16-chatak boundary', () {
      // 16 chatak is exactly 1 katha, so it must not show as "16 chatak".
      final sqm = AreaUnit.katha.toSqm(1) + AreaUnit.chatak.toSqm(16);
      final b = AreaBreakdown.of(sqm, _bd);
      expect(_render(b), '2 katha');
    });

    test('zero terms are omitted', () {
      final sqm = AreaUnit.bigha.toSqm(2) + AreaUnit.chatak.toSqm(4);
      final b = AreaBreakdown.of(sqm, _bd);
      expect(_render(b), '2 bigha, 4.00 chatak'); // no "0 katha"
    });

    test('the last unit carries the fraction', () {
      final sqm = AreaUnit.katha.toSqm(1) + AreaUnit.chatak.toSqm(2.5);
      final b = AreaBreakdown.of(sqm, _bd);
      expect(b.parts.last.unit, AreaUnit.chatak);
      expect(b.parts.last.isRemainder, isTrue);
      expect(b.parts.last.value, closeTo(2.5, 1e-9));
    });

    test('sub-smallest areas still report something', () {
      final sqm = AreaUnit.chatak.toSqm(0.25);
      final b = AreaBreakdown.of(sqm, _bd);
      expect(b.parts.single.unit, AreaUnit.chatak);
      expect(b.parts.single.value, closeTo(0.25, 1e-9));
    });
  });

  group('losslessness', () {
    test('parts always sum back to the total', () {
      final configs = [
        _bd,
        BreakdownConfig.defaults,
        const BreakdownConfig(
          order: [AreaUnit.acre, AreaUnit.shotok],
          enabled: {AreaUnit.acre, AreaUnit.shotok},
        ),
        BreakdownConfig.defaults.copyWith(
          enabled: {
            AreaUnit.bighaMymensingh,
            AreaUnit.kathaMymensingh,
            AreaUnit.shotok,
          },
        ),
      ];
      for (final cfg in configs) {
        for (final sqm in [
          0.37, 1.0, 40.47, 66.89, 1337.803776, 4046.8564224,
          5260.91334912, 9999.99, 123456.789,
        ]) {
          final b = AreaBreakdown.of(sqm, cfg);
          expect(b.accountedSqm, closeTo(sqm, sqm * 1e-9),
              reason: '$sqm with ${cfg.orderedEnabled.map((u) => u.name)}');
        }
      }
    });

    test('non-final parts are whole numbers', () {
      for (final sqm in [1337.8, 5260.9, 123456.789, 42.0]) {
        final b = AreaBreakdown.of(sqm, BreakdownConfig.defaults);
        for (final p in b.parts.where((p) => !p.isRemainder)) {
          expect(p.value, p.value.roundToDouble(), reason: '$sqm ${p.unit.name}');
          expect(p.value, greaterThan(0));
        }
      }
    });
  });

  group('Mymensingh units in a breakdown', () {
    const my = BreakdownConfig(
      order: [AreaUnit.bighaMymensingh, AreaUnit.kathaMymensingh, AreaUnit.shotok],
      enabled: {
        AreaUnit.bighaMymensingh,
        AreaUnit.kathaMymensingh,
        AreaUnit.shotok,
      },
    );

    test('130 shotok reads as exactly 1 bigha (M)', () {
      final b = AreaBreakdown.of(AreaUnit.shotok.toSqm(130), my);
      expect(_render(b), '1 bighaMymensingh');
    });

    test('20 katha (M) reads as exactly 1 bigha (M)', () {
      final b = AreaBreakdown.of(AreaUnit.kathaMymensingh.toSqm(20), my);
      expect(_render(b), '1 bighaMymensingh');
    });

    test('6.5 shotok reads as exactly 1 katha (M)', () {
      final b = AreaBreakdown.of(AreaUnit.shotok.toSqm(6.5), my);
      expect(_render(b), '1 kathaMymensingh');
    });
  });

  group('edge cases', () {
    test('zero, negative and non-finite areas give an empty breakdown', () {
      for (final v in [0.0, -1.0, double.nan, double.infinity]) {
        expect(AreaBreakdown.of(v, _bd).isEmpty, isTrue, reason: '$v');
      }
    });

    test('no enabled units gives an empty breakdown', () {
      const none = BreakdownConfig(order: [AreaUnit.bigha], enabled: {});
      expect(AreaBreakdown.of(1337.8, none).isEmpty, isTrue);
    });

    test('a single enabled unit is just a plain conversion', () {
      const one = BreakdownConfig(
        order: [AreaUnit.chatak],
        enabled: {AreaUnit.chatak},
      );
      final b = AreaBreakdown.of(AreaUnit.bigha.toSqm(1), one);
      expect(b.parts.single.unit, AreaUnit.chatak);
      expect(b.parts.single.value, closeTo(320, 1e-6));
    });

    test('disabled units are skipped entirely', () {
      final cfg = _bd.toggled(AreaUnit.katha);
      final b = AreaBreakdown.of(AreaUnit.katha.toSqm(5), cfg);
      expect(b.parts.every((p) => p.unit != AreaUnit.katha), isTrue);
      expect(b.accountedSqm, closeTo(AreaUnit.katha.toSqm(5), 1e-9));
    });
  });

  group('config', () {
    test('toggle flips a unit on and off', () {
      final off = BreakdownConfig.defaults.toggled(AreaUnit.katha);
      expect(off.isOn(AreaUnit.katha), isFalse);
      expect(off.toggled(AreaUnit.katha).isOn(AreaUnit.katha), isTrue);
    });

    test('reorder moves a unit and keeps every entry', () {
      final moved = BreakdownConfig.defaults.reordered(0, 3);
      expect(moved.order.toSet(), BreakdownConfig.defaults.order.toSet());
      expect(moved.order.length, BreakdownConfig.defaults.order.length);
      // onReorderItem semantics: newIndex is the post-removal destination.
      expect(moved.order[3], AreaUnit.bighaMymensingh);
    });

    test('reorder matches list semantics in both directions', () {
      const cfg = BreakdownConfig(
        order: [AreaUnit.acre, AreaUnit.bigha, AreaUnit.katha, AreaUnit.chatak],
        enabled: {},
      );
      // Drag "acre" down to the last slot.
      expect(cfg.reordered(0, 3).order,
          [AreaUnit.bigha, AreaUnit.katha, AreaUnit.chatak, AreaUnit.acre]);
      // Drag "chatak" up to the front.
      expect(cfg.reordered(3, 0).order,
          [AreaUnit.chatak, AreaUnit.acre, AreaUnit.bigha, AreaUnit.katha]);
      // A no-op stays put.
      expect(cfg.reordered(1, 1).order, cfg.order);
    });

    test('defaults are ordered largest to smallest', () {
      final o = BreakdownConfig.defaults.order;
      for (var i = 1; i < o.length; i++) {
        expect(o[i].sqmPerUnit, lessThan(o[i - 1].sqmPerUnit),
            reason: '${o[i - 1].name} -> ${o[i].name}');
      }
    });

    test('defaults leave the regional units off', () {
      expect(BreakdownConfig.defaults.isOn(AreaUnit.bighaMymensingh), isFalse);
      expect(BreakdownConfig.defaults.isOn(AreaUnit.kathaMymensingh), isFalse);
    });
  });
}
