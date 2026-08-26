/// The share units a khotiyan is written in, largest first.
enum KhotiyanUnit { ana, gonda, kora, kranti, til }

/// Traditional Bengali land-record marks for khotiyan shares.
///
/// A deed does not write "5 ana"; it writes ৷⁄. These are the marks a reader
/// will actually see on a khotiyan, so the calculator shows them beside the
/// figure rather than leaving the translation to the reader.
///
/// Taken from the symbol table in `docs/land_info.json`, which is the same
/// source the Info tab's article renders.
class KhotiyanSymbols {
  const KhotiyanSymbols._();

  /// 1..16 ana. Sixteen ana is a whole share, written as ১.
  static const ana = [
    '⁄', '৵', '৶', '৷', '৷⁄', '৷৵', '৷৶', '৷৷',
    '৷৷⁄', '৷৷৵', '৷৷৶', '৸', '৸⁄', '৸৵', '৸৶', '১',
  ];

  /// 1..4 kora. Four kora make one gonda.
  static const kora = ['৷', '৷৷', '৸', '৪'];

  /// 1..3 kranti. Three kranti make one kora.
  static const kranti = ['৴', '৴৴', '৩'];

  /// The mark for [value] of [unit], or null when there is nothing to show.
  ///
  /// Gonda and til have no marks of their own — a deed writes them as plain
  /// numerals, which the stepper is already showing — and zero of anything
  /// is not written at all.
  static String? of(KhotiyanUnit unit, int value) {
    if (value <= 0) return null;
    final table = switch (unit) {
      KhotiyanUnit.ana => ana,
      KhotiyanUnit.kora => kora,
      KhotiyanUnit.kranti => kranti,
      KhotiyanUnit.gonda || KhotiyanUnit.til => null,
    };
    if (table == null || value > table.length) return null;
    return table[value - 1];
  }
}
