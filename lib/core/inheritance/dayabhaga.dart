/// Hindu intestate succession in Bangladesh, for a man's estate: the
/// Dayabhaga order of heirs, with the Hindu Women's Rights to Property Act
/// 1937 (in force in Bangladesh; Gouri Dasi, HCD, extends it to
/// agricultural land).
///
/// The first group present takes everything:
///  1. sons and the line of a dead son, together with the widow (or widows
///     together) taking a son's share, and a dead son's widow taking as a
///     son, or as a son's son beside her own sons (1937 Act, s.3);
///  2. unmarried daughters; then married daughters who have, or may have,
///     a son;
///  3. daughters' sons, per head;
///  4. father; 5. mother;
///  6. full brothers, else half brothers; 7. brothers' sons;
///  8. brothers' sons' sons; 9. sisters' sons;
///  10. paternal grandfather; 11. paternal grandmother; 12. paternal uncles;
///  13. their sons.
/// Widows, a son's widow, daughters, the mother and the grandmother hold a
/// limited estate: a life interest that goes back to the deceased's heirs
/// at her death.
///
/// Not covered: a woman's own property (stridhan), adoption, custom, a will.
library;

import 'inheritance.dart';

export 'inheritance.dart';

/// A son who died before the deceased.
class PredeceasedSon {
  /// His sons, alive.
  final int sons;

  /// His widow, alive.
  final bool widow;
  const PredeceasedSon({this.sons = 0, this.widow = false});

  bool get counts => sons > 0 || widow;

  PredeceasedSon copyWith({int? sons, bool? widow}) =>
      PredeceasedSon(sons: sons ?? this.sons, widow: widow ?? this.widow);
}

class HinduFamily {
  /// Widows of the deceased (a man).
  final int widows;
  final int sons;
  final List<PredeceasedSon> predeceasedSons;
  final int unmarriedDaughters;

  /// Married daughters who have, or may still have, a son. A widowed or
  /// barren daughter without a son does not inherit and is not asked for.
  final int marriedDaughters;
  final int daughtersSons;
  final bool father;
  final bool mother;
  final int fullBrothers;

  /// Same father, another mother.
  final int halfBrothers;
  final int brothersSons;
  final int brothersGrandsons;
  final int sistersSons;
  final bool grandfather;
  final bool grandmother;
  final int uncles;
  final int unclesSons;

  const HinduFamily({
    this.widows = 0,
    this.sons = 0,
    this.predeceasedSons = const [],
    this.unmarriedDaughters = 0,
    this.marriedDaughters = 0,
    this.daughtersSons = 0,
    this.father = false,
    this.mother = false,
    this.fullBrothers = 0,
    this.halfBrothers = 0,
    this.brothersSons = 0,
    this.brothersGrandsons = 0,
    this.sistersSons = 0,
    this.grandfather = false,
    this.grandmother = false,
    this.uncles = 0,
    this.unclesSons = 0,
  });

  List<PredeceasedSon> get _deadSons => [
    for (final s in predeceasedSons)
      if (s.counts) s,
  ];

  /// The first group: sons, a dead son's line or widow, the widows.
  bool get hasFirstGroup => sons > 0 || _deadSons.isNotEmpty || widows > 0;

  bool get anyone =>
      hasFirstGroup ||
      unmarriedDaughters + marriedDaughters + daughtersSons > 0 ||
      father ||
      mother ||
      fullBrothers + halfBrothers + brothersSons + brothersGrandsons > 0 ||
      sistersSons > 0 ||
      grandfather ||
      grandmother ||
      uncles + unclesSons > 0;
}

class Dayabhaga {
  Dayabhaga._();

  static InheritanceResult compute(HinduFamily f) {
    if (!f.anyone) {
      return const InheritanceResult(
        heirs: [],
        excluded: [],
        notes: [ResultNote.noHeirs],
      );
    }
    final heirs = <HeirShare>[];
    final notes = <ResultNote>{};

    void add(
      HeirKind kind,
      int count,
      Fraction each,
      ShareReason reason, {
      bool lifeInterest = false,
    }) {
      for (var i = 0; i < count; i++) {
        heirs.add(
          HeirShare(
            kind: kind,
            number: i + 1,
            of: count,
            share: each,
            reason: reason,
            lifeInterest: lifeInterest,
          ),
        );
      }
      if (lifeInterest && count > 0) notes.add(ResultNote.hinduLimitedEstate);
    }

    // The groups in order; the first with anyone in it takes everything.
    // Each entry: who is in it (for "who gets nothing"), and how it shares.
    final excludedBy = <HeirKind, ExclusionReason>{};
    ExclusionReason? taker;

    if (f.hasFirstGroup) {
      // One unit per son, one for the widows together, one per dead son
      // with sons or a widow.
      final dead = [
        for (var i = 0; i < f.predeceasedSons.length; i++)
          if (f.predeceasedSons[i].counts) (f.predeceasedSons[i], i),
      ];
      final units = f.sons + (f.widows > 0 ? 1 : 0) + dead.length;
      final unit = Fraction(1, units);
      add(
        HeirKind.wife,
        f.widows,
        unit.over(f.widows == 0 ? 1 : f.widows),
        ShareReason.hinduWidow,
        lifeInterest: true,
      );
      add(HeirKind.son, f.sons, unit, ShareReason.hinduSons);
      var n = 0;
      for (final (son, index) in dead) {
        n++;
        if (son.sons == 0) {
          // His widow takes as a son.
          heirs.add(
            HeirShare(
              kind: HeirKind.sonsWidow,
              number: 1,
              of: 1,
              share: unit,
              reason: ShareReason.hinduSonsWidowAsSon,
              via: index,
              viaKind: HeirKind.son,
              viaNumber: n,
              lifeInterest: true,
            ),
          );
          notes.add(ResultNote.hinduLimitedEstate);
          continue;
        }
        // His sons share his share; his widow, if alive, takes as one of
        // them (as a son's son). How she shares beside them is not settled
        // by any reported case.
        final heads = son.sons + (son.widow ? 1 : 0);
        for (var i = 0; i < son.sons; i++) {
          heirs.add(
            HeirShare(
              kind: HeirKind.grandson,
              number: i + 1,
              of: son.sons,
              share: unit.over(heads),
              reason: ShareReason.hinduSonsLine,
              via: index,
              viaKind: HeirKind.son,
              viaNumber: n,
            ),
          );
        }
        if (son.widow) {
          heirs.add(
            HeirShare(
              kind: HeirKind.sonsWidow,
              number: 1,
              of: 1,
              share: unit.over(heads),
              reason: ShareReason.hinduSonsWidowAsGrandson,
              via: index,
              viaKind: HeirKind.son,
              viaNumber: n,
              lifeInterest: true,
            ),
          );
          notes.addAll([
            ResultNote.hinduLimitedEstate,
            ResultNote.hinduSonsWidowUnsettled,
          ]);
        }
      }
      taker = f.sons > 0 || dead.isNotEmpty
          ? ExclusionReason.maleLine
          : ExclusionReason.widowFirst;
    } else if (f.unmarriedDaughters > 0) {
      add(
        HeirKind.unmarriedDaughter,
        f.unmarriedDaughters,
        Fraction(1, f.unmarriedDaughters),
        ShareReason.hinduUnmarriedDaughters,
        lifeInterest: true,
      );
      excludedBy[HeirKind.marriedDaughter] = ExclusionReason.unmarriedDaughter;
      taker = ExclusionReason.closer;
    } else if (f.marriedDaughters > 0) {
      add(
        HeirKind.marriedDaughter,
        f.marriedDaughters,
        Fraction(1, f.marriedDaughters),
        ShareReason.hinduMarriedDaughters,
        lifeInterest: true,
      );
      taker = ExclusionReason.closer;
    } else {
      // Single heirs and per-head classes, in order.
      final order = <(HeirKind, int, ShareReason, bool)>[
        (
          HeirKind.daughtersSon,
          f.daughtersSons,
          ShareReason.hinduDaughtersSons,
          false,
        ),
        (HeirKind.father, f.father ? 1 : 0, ShareReason.hinduFather, false),
        (HeirKind.mother, f.mother ? 1 : 0, ShareReason.hinduMother, true),
        (
          HeirKind.fullBrother,
          f.fullBrothers,
          ShareReason.hinduBrothers,
          false,
        ),
        (
          HeirKind.paternalBrother,
          f.halfBrothers,
          ShareReason.hinduBrothers,
          false,
        ),
        (HeirKind.fullNephew, f.brothersSons, ShareReason.hinduNephews, false),
        (
          HeirKind.grandNephew,
          f.brothersGrandsons,
          ShareReason.hinduGrandNephews,
          false,
        ),
        (
          HeirKind.sistersSon,
          f.sistersSons,
          ShareReason.hinduSistersSons,
          false,
        ),
        (
          HeirKind.grandfather,
          f.grandfather ? 1 : 0,
          ShareReason.hinduGrandfather,
          false,
        ),
        (
          HeirKind.paternalGrandmother,
          f.grandmother ? 1 : 0,
          ShareReason.hinduGrandmother,
          true,
        ),
        (HeirKind.fullUncle, f.uncles, ShareReason.hinduUncles, false),
        (HeirKind.fullCousin, f.unclesSons, ShareReason.hinduCousins, false),
      ];
      for (var i = 0; i < order.length; i++) {
        final (kind, count, reason, life) = order[i];
        if (count == 0) continue;
        add(kind, count, Fraction(1, count), reason, lifeInterest: life);
        for (final (later, n, _, _) in order.skip(i + 1)) {
          if (n > 0) {
            excludedBy[later] =
                kind == HeirKind.fullBrother &&
                    later == HeirKind.paternalBrother
                ? ExclusionReason.fullBrother
                : ExclusionReason.closer;
          }
        }
        break;
      }
    }

    // Everyone after the group that took.
    if (taker != null) {
      final later = <(HeirKind, bool)>[
        (HeirKind.unmarriedDaughter, f.unmarriedDaughters > 0),
        (HeirKind.marriedDaughter, f.marriedDaughters > 0),
        (HeirKind.daughtersSon, f.daughtersSons > 0),
        (HeirKind.father, f.father),
        (HeirKind.mother, f.mother),
        (HeirKind.fullBrother, f.fullBrothers > 0),
        (HeirKind.paternalBrother, f.halfBrothers > 0),
        (HeirKind.fullNephew, f.brothersSons > 0),
        (HeirKind.grandNephew, f.brothersGrandsons > 0),
        (HeirKind.sistersSon, f.sistersSons > 0),
        (HeirKind.grandfather, f.grandfather),
        (HeirKind.paternalGrandmother, f.grandmother),
        (HeirKind.fullUncle, f.uncles > 0),
        (HeirKind.fullCousin, f.unclesSons > 0),
      ];
      final taken = {for (final h in heirs) h.kind};
      for (final (kind, entered) in later) {
        if (!entered || taken.contains(kind) || excludedBy.containsKey(kind)) {
          continue;
        }
        excludedBy[kind] = taker;
      }
    }

    return InheritanceResult(
      heirs: heirs,
      excluded: [for (final e in excludedBy.entries) Exclusion(e.key, e.value)],
      notes: notes.toList(),
    );
  }
}
