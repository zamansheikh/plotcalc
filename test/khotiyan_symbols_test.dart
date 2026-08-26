import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/units/khotiyan_symbols.dart';

/// The marks are what a reader sees on an actual khotiyan, so they have to
/// match the reference table the app itself publishes in the Info tab.
void main() {
  /// Bengali writes ড় either as one code point (U+09DC) or as ড plus a
  /// nukta. The two look identical and compare unequal, and the JSON uses
  /// the precomposed form while a Dart literal typed here may not — so both
  /// sides are pushed to the decomposed form before matching.
  String normalise(String s) => s
      .replaceAll('\u09DC', '\u09A1\u09BC')
      .replaceAll('\u09DD', '\u09A2\u09BC')
      .replaceAll('\u09DF', '\u09AF\u09BC');

  /// The symbol table out of docs/land_info.json, as {unit: {value: mark}}.
  Map<String, Map<int, String>> reference() {
    final doc =
        json.decode(File('docs/land_info.json').readAsStringSync())
            as Map<String, dynamic>;
    final topic = (doc['topics'] as List).firstWhere(
      (t) => (t as Map)['id'] == 'land_measurement_symbols',
    ) as Map<String, dynamic>;

    const digits = '০১২৩৪৫৬৭৮৯';
    int? leadingNumber(String s) {
      var out = '';
      for (final ch in s.trim().split('')) {
        final i = digits.indexOf(ch);
        if (i < 0) break;
        out += '$i';
      }
      return out.isEmpty ? null : int.parse(out);
    }

    final map = <String, Map<int, String>>{};
    for (final block in topic['content'] as List) {
      final b = block as Map<String, dynamic>;
      if (b['type'] != 'table') continue;
      if ((b['headers'] as List).first != 'ইউনিট') continue;
      for (final row in b['rows'] as List) {
        final r = (row as List).map((e) => '$e').toList();
        final n = leadingNumber(r[2]);
        if (n == null) continue;
        (map[normalise(r[0])] ??= {})[n] = r[1];
      }
    }
    return map;
  }

  test('every ana mark matches the published table', () {
    final table = reference()[normalise('আনা')]!;
    for (var v = 1; v <= 16; v++) {
      final published = table[v]!.replaceAll(' ', '');
      expect(KhotiyanSymbols.of(KhotiyanUnit.ana, v), published, reason: '$v ana');
    }
  });

  test('kora and kranti match too', () {
    final ref = reference();
    for (var v = 1; v <= 4; v++) {
      expect(
        KhotiyanSymbols.of(KhotiyanUnit.kora, v),
        ref[normalise('কড়া')]![v]!.replaceAll(' ', ''),
        reason: '$v kora',
      );
    }
    for (var v = 1; v <= 3; v++) {
      expect(
        KhotiyanSymbols.of(KhotiyanUnit.kranti, v),
        ref[normalise('ক্রান্তি')]![v]!.replaceAll(' ', ''),
        reason: '$v kranti',
      );
    }
  });

  test('gonda and til have no mark of their own', () {
    // A deed writes these as plain numerals, which the stepper already shows.
    for (var v = 1; v <= 20; v++) {
      expect(KhotiyanSymbols.of(KhotiyanUnit.gonda, v), isNull);
      expect(KhotiyanSymbols.of(KhotiyanUnit.til, v), isNull);
    }
  });

  test('zero is not written at all', () {
    for (final u in KhotiyanUnit.values) {
      expect(KhotiyanSymbols.of(u, 0), isNull, reason: u.name);
      expect(KhotiyanSymbols.of(u, -3), isNull, reason: u.name);
    }
  });

  test('a value past the end of a table has no mark rather than crashing', () {
    expect(KhotiyanSymbols.of(KhotiyanUnit.ana, 17), isNull);
    expect(KhotiyanSymbols.of(KhotiyanUnit.kora, 5), isNull);
    expect(KhotiyanSymbols.of(KhotiyanUnit.kranti, 4), isNull);
  });

  test('the tables are the length the units call for', () {
    // 16 ana to the whole, 4 kora to the gonda, 3 kranti to the kora.
    expect(KhotiyanSymbols.ana.length, 16);
    expect(KhotiyanSymbols.kora.length, 4);
    expect(KhotiyanSymbols.kranti.length, 3);
  });

  test('no mark is blank', () {
    for (final table in [
      KhotiyanSymbols.ana,
      KhotiyanSymbols.kora,
      KhotiyanSymbols.kranti,
    ]) {
      for (final s in table) {
        expect(s.trim(), isNotEmpty);
        expect(s, isNot(contains(' ')), reason: 'marks carry no spacing');
      }
    }
  });

  test('no single font covers a mark, so the chained style is required', () {
    // Inter carries the fraction slash but no Bengali; Noto Sans Bengali
    // carries the numerators but not U+2044. A mark can mix the two, so the
    // chip must use a style with a fallback chain — see _MarkChip.
    final marks = [
      ...KhotiyanSymbols.ana,
      ...KhotiyanSymbols.kora,
      ...KhotiyanSymbols.kranti,
    ];
    final mixed = marks.where(
      (m) => m.contains('\u2044') && m.runes.any((r) => r >= 0x0980),
    );
    expect(mixed, isNotEmpty, reason: 'e.g. \u09F7\u2044 for five ana');
  });
}
