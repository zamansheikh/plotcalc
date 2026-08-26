import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plotcalc/core/di/injection.dart';
import 'package:plotcalc/core/units/area_breakdown.dart';
import 'package:plotcalc/core/units/area_unit.dart';
import 'package:plotcalc/presentation/shared/settings/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The breakdown is the app's headline number, so this suite tries to break
/// it rather than to confirm it: randomised sweeps over every unit
/// combination, an independent reimplementation to check against, and the
/// specific defects found while writing it.

/// Deliberately naive re-implementation, written from the description rather
/// than from the code, so agreement means something.
({Map<AreaUnit, double> parts, double leftover}) reference(
  double sqm,
  List<AreaUnit> units,
) {
  final out = <AreaUnit, double>{};
  var remaining = sqm;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (i == units.length - 1) {
      out[u] = remaining / u.sqmPerUnit;
      remaining = 0;
    } else {
      final whole = (remaining / u.sqmPerUnit + 1e-9).floor().toDouble();
      if (whole > 0) {
        out[u] = whole;
        remaining -= whole * u.sqmPerUnit;
        if (remaining < 0) remaining = 0;
      }
    }
  }
  return (parts: out, leftover: remaining);
}

/// How much area can vanish unnoticed: half a printed digit of the last unit.
double invisibleFor(AreaUnit last) =>
    0.5 * pow(10, -last.precision) * last.sqmPerUnit;

void main() {
  group('randomised sweep', () {
    test('30k random areas x random unit sets hold every invariant', () {
      final rnd = Random(7);
      final failures = <String>[];

      for (var t = 0; t < 30000; t++) {
        final all = AreaUnit.values.toList()..shuffle(rnd);
        final chosen = all.take(1 + rnd.nextInt(all.length)).toList()
          ..sort((a, b) => b.sqmPerUnit.compareTo(a.sqmPerUnit));
        final cfg = BreakdownConfig(order: chosen, enabled: chosen.toSet());
        final sqm = [
          rnd.nextDouble() * 0.01,
          rnd.nextDouble() * 10,
          rnd.nextDouble() * 5000,
          rnd.nextDouble() * 1e6,
        ][rnd.nextInt(4)];

        final b = AreaBreakdown.of(sqm, cfg);
        final where = '$sqm over ${chosen.map((u) => u.name).toList()}';

        // Nothing is lost beyond what could not have been printed anyway.
        final lost = sqm - b.accountedSqm;
        if (lost < -1e-9 || lost > invisibleFor(chosen.last) + sqm * 1e-9) {
          failures.add('lost $lost: $where');
        }
        for (final p in b.parts) {
          if (p.value < 0) failures.add('negative ${p.unit.name}: $where');
          if (!p.isRemainder && p.value != p.value.roundToDouble()) {
            failures.add('non-whole ${p.unit.name}: $where');
          }
          // A term that prints as 0 reads as a bug to the user.
          if (RegExp(r'^0(\.0+)?$').hasMatch(p.formatted.replaceAll(',', ''))) {
            failures.add('prints zero "${p.formatted} ${p.unit.name}": $where');
          }
        }
        if (sqm > 1e-6 && b.parts.isEmpty) failures.add('empty: $where');
      }

      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
    });

    test('agrees with an independent implementation', () {
      final rnd = Random(23);
      for (var t = 0; t < 5000; t++) {
        final chosen = (AreaUnit.values.toList()..shuffle(rnd))
            .take(1 + rnd.nextInt(6))
            .toList()
          ..sort((a, b) => b.sqmPerUnit.compareTo(a.sqmPerUnit));
        final sqm = rnd.nextDouble() * 50000;
        final mine = AreaBreakdown.of(
          sqm,
          BreakdownConfig(order: chosen, enabled: chosen.toSet()),
        );
        final theirs = reference(sqm, chosen);

        for (final p in mine.parts.where((p) => !p.isRemainder)) {
          expect(
            p.value,
            theirs.parts[p.unit],
            reason: 'whole ${p.unit.name} for $sqm',
          );
        }
      }
    });

    test('arbitrary user ordering never loses area', () {
      // The editor lets units be dragged into any order, including
      // small-to-large, which the greedy walk still has to handle.
      final rnd = Random(41);
      for (var t = 0; t < 20000; t++) {
        final chosen = (AreaUnit.values.toList()..shuffle(rnd))
            .take(1 + rnd.nextInt(AreaUnit.values.length))
            .toList();
        final sqm = rnd.nextDouble() * 20000;
        final b = AreaBreakdown.of(
          sqm,
          BreakdownConfig(order: chosen, enabled: chosen.toSet()),
        );
        final lost = sqm - b.accountedSqm;
        expect(lost, greaterThan(-1e-9));
        expect(lost, lessThan(invisibleFor(chosen.last) + sqm * 1e-9));
      }
    });
  });

  group('every unit set of the default catalogue', () {
    test('all 1023 non-empty subsets behave', () {
      final units = AreaUnit.values;
      for (var mask = 1; mask < 1 << 10; mask++) {
        final chosen = [
          for (var i = 0; i < units.length; i++)
            if (mask & (1 << i) != 0) units[i],
        ]..sort((a, b) => b.sqmPerUnit.compareTo(a.sqmPerUnit));
        const sqm = 1337.803776; // one bigha
        final b = AreaBreakdown.of(
          sqm,
          BreakdownConfig(order: chosen, enabled: chosen.toSet()),
        );
        expect(b.parts, isNotEmpty, reason: '$mask');
        final lost = sqm - b.accountedSqm;
        expect(lost, lessThan(invisibleFor(chosen.last) + 1e-6), reason: '$mask');
      }
    });
  });

  group('regression: a term that prints as zero', () {
    // Found by sweep: the dust cut-off was 1e-9 while the display rounds at
    // 0-4 decimals, so "1 bigha, 0.00 chatak" could appear.
    const bighaThenChatak = BreakdownConfig(
      order: [AreaUnit.bigha, AreaUnit.chatak],
      enabled: {AreaUnit.bigha, AreaUnit.chatak},
    );

    test('an invisible tail is dropped when there is something else', () {
      // One bigha plus a millionth of a chatak.
      final sqm = AreaUnit.bigha.toSqm(1) + AreaUnit.chatak.toSqm(1e-6);
      final b = AreaBreakdown.of(sqm, bighaThenChatak);
      expect(b.parts.length, 1);
      expect(b.parts.single.unit, AreaUnit.bigha);
    });

    test('a tail that can be printed is kept', () {
      final sqm = AreaUnit.bigha.toSqm(1) + AreaUnit.chatak.toSqm(0.5);
      final b = AreaBreakdown.of(sqm, bighaThenChatak);
      expect(b.parts.length, 2);
      expect(b.parts.last.formatted, '0.50');
    });

    test('a tiny area on its own still shows a real figure', () {
      // Nothing else to show, so it must not be dropped — and must not
      // print as "0.00".
      final b = AreaBreakdown.of(AreaUnit.chatak.toSqm(0.0004), bighaThenChatak);
      expect(b.parts.length, 1);
      expect(b.parts.single.formatted, isNot(matches(r'^0(\.0+)?$')));
      expect(double.parse(b.parts.single.formatted), greaterThan(0));
    });

    test('no part ever prints as zero, across the whole catalogue', () {
      for (final u in AreaUnit.values) {
        for (final frac in [1e-9, 1e-6, 1e-4, 0.004, 0.4]) {
          final cfg = BreakdownConfig(order: [u], enabled: {u});
          final b = AreaBreakdown.of(u.toSqm(frac), cfg);
          for (final p in b.parts) {
            expect(p.formatted, isNot(matches(r'^0(\.0+)?$')),
                reason: '${u.name} at $frac');
          }
        }
      }
    });
  });

  group('regression: rivals surviving a restore', () {
    // toggled() stops the pair being switched on together, but a stored
    // preference is just data and can say anything.
    Future<BreakdownConfig> restoreWith(List<String> enabled) async {
      SharedPreferences.setMockInitialValues({
        'plotcalc.breakdown.order.v1': [for (final u in AreaUnit.values) u.name],
        'plotcalc.breakdown.enabled.v1': enabled,
      });
      await GetIt.I.reset();
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      return SettingsBloc().state.breakdown;
    }

    test('a stored file with both rivals loads with only one', () async {
      final cfg = await restoreWith([
        'bigha', 'bighaMymensingh', 'katha', 'kathaMymensingh',
      ]);
      BreakdownConfig.rivals.forEach((a, b) {
        expect(cfg.isOn(a) && cfg.isOn(b), isFalse,
            reason: '${a.name} + ${b.name}');
      });
    });

    test('the survivor is whichever comes first in the stored order', () async {
      // restoreWith stores AreaUnit.values order, where bigha precedes
      // bighaMymensingh — so bigha is the one that survives.
      final cfg = await restoreWith(['bigha', 'bighaMymensingh']);
      expect(cfg.isOn(AreaUnit.bigha), isTrue);
      expect(cfg.isOn(AreaUnit.bighaMymensingh), isFalse);
    });

    test('reversing the stored order reverses the survivor', () async {
      // Proves the rule really is "first in order wins", not "bigha wins".
      SharedPreferences.setMockInitialValues({
        'plotcalc.breakdown.order.v1': [
          'bighaMymensingh',
          for (final u in AreaUnit.values)
            if (u != AreaUnit.bighaMymensingh) u.name,
        ],
        'plotcalc.breakdown.enabled.v1': ['bigha', 'bighaMymensingh'],
      });
      await GetIt.I.reset();
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      final cfg = SettingsBloc().state.breakdown;
      expect(cfg.isOn(AreaUnit.bighaMymensingh), isTrue);
      expect(cfg.isOn(AreaUnit.bigha), isFalse);
    });

    test('sanitizing leaves an already-valid config alone', () {
      final before = BreakdownConfig.defaults;
      expect(before.sanitized().enabled, before.enabled);
    });

    test('sanitizing never invents a unit', () {
      final cfg = BreakdownConfig.defaults
          .copyWith(enabled: {AreaUnit.bigha, AreaUnit.bighaMymensingh});
      expect(cfg.sanitized().enabled.length, 1);
      expect(cfg.sanitized().enabled.every(cfg.enabled.contains), isTrue);
    });
  });

  group('extremes', () {
    test('very small and very large areas stay readable', () {
      for (final sqm in [1e-12, 1e-6, 1e-3, 1e9, 1e12]) {
        final b = AreaBreakdown.of(sqm, BreakdownConfig.defaults);
        for (final p in b.parts) {
          expect(p.value.isFinite, isTrue, reason: '$sqm');
          expect(p.formatted, isNot(contains('e')), reason: '$sqm');
          expect(p.formatted, isNot(contains('NaN')), reason: '$sqm');
        }
      }
    });

    test('non-finite and non-positive areas produce nothing', () {
      for (final v in [0.0, -1.0, double.nan, double.infinity,
                       double.negativeInfinity]) {
        expect(AreaBreakdown.of(v, BreakdownConfig.defaults).isEmpty, isTrue,
            reason: '$v');
      }
    });
  });
}
