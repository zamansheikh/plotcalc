/// Muslim inheritance shares (ফারায়েজ) as applied in Bangladesh: Hanafi
/// rules, with section 4 of the Muslim Family Laws Ordinance 1961 for the
/// children of a son or daughter who died before the deceased.
///
/// All arithmetic is on exact fractions, so shares always add up to the
/// whole estate and can be shown the way they are worked by hand: as parts
/// of a common base (মাসআলা).
///
/// Covered: spouse, children (and, through the ordinance, the children of a
/// child who died earlier), parents, the father's father, both grandmothers,
/// full, consanguine and uterine brothers and sisters, and the male line
/// after them (brothers' sons, paternal uncles, their sons), and the
/// distant kindred who take when none of those is left: the mother's
/// father, the children of dead brothers and sisters, and the father's and
/// mother's brothers and sisters (খালা, মামা, ফুফু), by Mulla's rules and
/// Imam Muhammad's method.
library;

import 'inheritance.dart';

export 'inheritance.dart';

/// Who survived the deceased.
class Family {
  final Gender deceased;

  /// Only when the deceased is a woman.
  final bool husband;

  /// Only when the deceased is a man; at most four.
  final int wives;
  final int sons;
  final int daughters;
  final List<PredeceasedChild> predeceased;
  final bool father;
  final bool mother;

  /// The father's father.
  final bool grandfather;

  /// The father's mother.
  final bool paternalGrandmother;

  /// The mother's mother.
  final bool maternalGrandmother;
  final int fullBrothers;
  final int fullSisters;

  /// Same father, different mother (বৈমাত্রেয়).
  final int paternalBrothers;
  final int paternalSisters;

  /// Same mother, different father (বৈপিত্রেয়).
  final int maternalBrothers;
  final int maternalSisters;

  /// Sons of full brothers, and of consanguine brothers.
  final int fullNephews;
  final int paternalNephews;

  /// The father's full brothers, and his consanguine brothers.
  final int fullUncles;
  final int paternalUncles;

  /// Sons of those uncles.
  final int fullCousins;
  final int paternalCousins;

  /// Distant kindred (যাবিল আরহাম): they take only when no sharer or
  /// residuary other than the spouse survives.
  final DistantKin distant;

  const Family({
    required this.deceased,
    this.husband = false,
    this.wives = 0,
    this.sons = 0,
    this.daughters = 0,
    this.predeceased = const [],
    this.father = false,
    this.mother = false,
    this.grandfather = false,
    this.paternalGrandmother = false,
    this.maternalGrandmother = false,
    this.fullBrothers = 0,
    this.fullSisters = 0,
    this.paternalBrothers = 0,
    this.paternalSisters = 0,
    this.maternalBrothers = 0,
    this.maternalSisters = 0,
    this.fullNephews = 0,
    this.paternalNephews = 0,
    this.fullUncles = 0,
    this.paternalUncles = 0,
    this.fullCousins = 0,
    this.paternalCousins = 0,
    this.distant = const DistantKin(),
  });

  /// The same family with [distant] kindred.
  Family withDistant(DistantKin distant) => Family(
    deceased: deceased,
    husband: husband,
    wives: wives,
    sons: sons,
    daughters: daughters,
    predeceased: predeceased,
    father: father,
    mother: mother,
    grandfather: grandfather,
    paternalGrandmother: paternalGrandmother,
    maternalGrandmother: maternalGrandmother,
    fullBrothers: fullBrothers,
    fullSisters: fullSisters,
    paternalBrothers: paternalBrothers,
    paternalSisters: paternalSisters,
    maternalBrothers: maternalBrothers,
    maternalSisters: maternalSisters,
    fullNephews: fullNephews,
    paternalNephews: paternalNephews,
    fullUncles: fullUncles,
    paternalUncles: paternalUncles,
    fullCousins: fullCousins,
    paternalCousins: paternalCousins,
    distant: distant,
  );

  /// Predeceased children who left children; the others change nothing.
  List<PredeceasedChild> get representing => [
    for (final c in predeceased)
      if (c.hasChildren) c,
  ];

  int get _deadSons =>
      representing.where((c) => c.gender == Gender.male).length;
  int get _deadDaughters =>
      representing.where((c) => c.gender == Gender.female).length;

  /// Sons and daughters as the shares are worked out: a child who died
  /// earlier and left children counts as if alive.
  int get sonsAsIfAlive => sons + _deadSons;
  int get daughtersAsIfAlive => daughters + _deadDaughters;
  bool get hasChild => sonsAsIfAlive + daughtersAsIfAlive > 0;
  bool get hasSon => sonsAsIfAlive > 0;

  /// Brothers and sisters of every kind, inheriting or not: two or more cut
  /// the mother's share to a sixth even when the father excludes them.
  int get siblings =>
      fullBrothers +
      fullSisters +
      paternalBrothers +
      paternalSisters +
      maternalBrothers +
      maternalSisters;

  bool get hasSpouse => deceased == Gender.female ? husband : wives > 0;

  /// Anyone at all who could inherit.
  bool get anyone =>
      hasSpouse ||
      hasChild ||
      father ||
      mother ||
      grandfather ||
      paternalGrandmother ||
      maternalGrandmother ||
      siblings > 0 ||
      fullNephews + paternalNephews > 0 ||
      fullUncles + paternalUncles > 0 ||
      fullCousins + paternalCousins > 0 ||
      distant.any;
}

/// One group of heirs of a kind, before it is split among its members.
class _Group {
  final HeirKind kind;
  final int count;
  Fraction share;
  ShareReason reason;

  /// Takes part in radd (the spouse does not).
  final bool spouse;
  _Group(this.kind, this.count, this.share, this.reason, {this.spouse = false});
}

/// Distant kindred that can be entered: the mother's father; the children
/// of brothers and sisters who died earlier (a full or consanguine
/// brother's sons are residuaries, so only his daughters count here); the
/// father's sisters, his uterine brothers; the mother's brothers and
/// sisters. Remoter ones (cousins through women, grandchildren through a
/// daughter's daughter…) are left to an expert.
class DistantKin {
  final bool maternalGrandfather;
  final List<SiblingLine> siblingLines;
  final int fullPaternalAunts;
  final int consanguinePaternalAunts;
  final int uterinePaternalAunts;
  final int fatherUterineBrothers;
  final int fullMaternalUncles;
  final int consanguineMaternalUncles;
  final int uterineMaternalUncles;
  final int fullMaternalAunts;
  final int consanguineMaternalAunts;
  final int uterineMaternalAunts;

  const DistantKin({
    this.maternalGrandfather = false,
    this.siblingLines = const [],
    this.fullPaternalAunts = 0,
    this.consanguinePaternalAunts = 0,
    this.uterinePaternalAunts = 0,
    this.fatherUterineBrothers = 0,
    this.fullMaternalUncles = 0,
    this.consanguineMaternalUncles = 0,
    this.uterineMaternalUncles = 0,
    this.fullMaternalAunts = 0,
    this.consanguineMaternalAunts = 0,
    this.uterineMaternalAunts = 0,
  });

  /// A full or consanguine brother's sons are nephews (residuaries), asked
  /// for elsewhere; they are not distant kindred.
  static int claimantSons(SiblingLine l) =>
      l.gender == Gender.male && l.blood != Blood.uterine ? 0 : l.sons;
  static int claimants(SiblingLine l) => claimantSons(l) + l.daughters;

  /// The father's and the mother's side, nearest blood first; each tier a
  /// list of (who, how many, male).
  List<List<(HeirKind, int, bool)>> get paternalTiers => [
    [(HeirKind.paternalAunt, fullPaternalAunts, false)],
    [(HeirKind.paternalAuntConsanguine, consanguinePaternalAunts, false)],
    [
      (HeirKind.fatherUterineBrother, fatherUterineBrothers, true),
      (HeirKind.paternalAuntUterine, uterinePaternalAunts, false),
    ],
  ];
  List<List<(HeirKind, int, bool)>> get maternalTiers => [
    [
      (HeirKind.maternalUncle, fullMaternalUncles, true),
      (HeirKind.maternalAunt, fullMaternalAunts, false),
    ],
    [
      (HeirKind.maternalUncleConsanguine, consanguineMaternalUncles, true),
      (HeirKind.maternalAuntConsanguine, consanguineMaternalAunts, false),
    ],
    [
      (HeirKind.maternalUncleUterine, uterineMaternalUncles, true),
      (HeirKind.maternalAuntUterine, uterineMaternalAunts, false),
    ],
  ];

  bool get hasLines => siblingLines.any((l) => claimants(l) > 0);
  bool get hasUnclesAunts => [
    ...paternalTiers,
    ...maternalTiers,
  ].any((tier) => tier.any((e) => e.$2 > 0));

  bool get any => maternalGrandfather || hasLines || hasUnclesAunts;
}

class Faraid {
  Faraid._();

  static final _sixth = Fraction(1, 6);
  static final _third = Fraction(1, 3);
  static final _half = Fraction(1, 2);
  static final _quarter = Fraction(1, 4);
  static final _eighth = Fraction(1, 8);
  static final _twoThirds = Fraction(2, 3);

  /// The shares, with distant kindred taking when no sharer or residuary
  /// other than the spouse is left (Mulla, ss.53-66; Imam Muhammad's
  /// method, followed in the subcontinent).
  static InheritanceResult compute(Family f) {
    final regular = _compute(f);
    final others = regular.heirs.where(
      (h) => h.kind != HeirKind.husband && h.kind != HeirKind.wife,
    );
    if (!f.distant.any) return regular;
    if (others.isNotEmpty) {
      // A sharer or residuary is alive: distant kindred take nothing.
      return InheritanceResult(
        heirs: regular.heirs,
        excluded: [...regular.excluded, ..._distantOut(f.distant, null)],
        adjustment: regular.adjustment,
        siblingsReduceMother: regular.siblingsReduceMother,
        notes: regular.notes,
      );
    }
    return _distantShares(f);
  }

  static InheritanceResult _compute(Family f) {
    final excluded = <Exclusion>[];
    final fixed = <_Group>[];

    final hasChild = f.hasChild;
    final hasSon = f.hasSon;
    final sons = f.sonsAsIfAlive;
    final daughters = f.daughtersAsIfAlive;
    final father = f.father;
    final grandfather = f.grandfather && !father;
    if (f.grandfather && father) {
      excluded.add(
        const Exclusion(HeirKind.grandfather, ExclusionReason.father),
      );
    }

    // Spouse.
    _Group? spouse;
    if (f.deceased == Gender.female && f.husband) {
      spouse = _Group(
        HeirKind.husband,
        1,
        hasChild ? _quarter : _half,
        hasChild ? ShareReason.husbandQuarter : ShareReason.husbandHalf,
        spouse: true,
      );
    } else if (f.deceased == Gender.male && f.wives > 0) {
      spouse = _Group(
        HeirKind.wife,
        f.wives.clamp(1, 4),
        hasChild ? _eighth : _quarter,
        hasChild ? ShareReason.wifeEighth : ShareReason.wifeQuarter,
        spouse: true,
      );
    }
    if (spouse != null) fixed.add(spouse);

    // Daughters with no son: a fixed share.
    if (!hasSon && daughters > 0) {
      fixed.add(
        _Group(
          HeirKind.daughter,
          daughters,
          daughters == 1 ? _half : _twoThirds,
          daughters == 1
              ? ShareReason.daughterHalf
              : ShareReason.daughtersTwoThirds,
        ),
      );
    }

    // Father, or the father's father in his place: 1/6 with a son; 1/6 and
    // the rest with only daughters; the rest with no child.
    _Group? ancestor;
    if (father || grandfather) {
      final kind = father ? HeirKind.father : HeirKind.grandfather;
      if (hasChild) {
        ancestor = _Group(
          kind,
          1,
          _sixth,
          hasSon
              ? (father
                    ? ShareReason.fatherSixth
                    : ShareReason.grandfatherSixth)
              : (father
                    ? ShareReason.fatherSixthAndRest
                    : ShareReason.grandfatherSixthAndRest),
        );
        fixed.add(ancestor);
      }
    }

    // Mother.
    if (f.mother) {
      Fraction share;
      ShareReason reason;
      if (hasChild) {
        share = _sixth;
        reason = ShareReason.motherSixthChild;
      } else if (f.siblings >= 2) {
        share = _sixth;
        reason = ShareReason.motherSixthSiblings;
      } else if (spouse != null && father) {
        // Spouse, father and mother only (উমারিয়্যাতাইন): a third of what
        // is left after the spouse.
        share = (Fraction.one - spouse.share) * _third;
        reason = ShareReason.motherThirdOfRest;
      } else {
        share = _third;
        reason = ShareReason.motherThird;
      }
      fixed.add(_Group(HeirKind.mother, 1, share, reason));
    }

    // Grandmothers: 1/6 between those not excluded.
    final grandmothers = <HeirKind>[];
    if (f.paternalGrandmother) {
      if (f.mother) {
        excluded.add(
          const Exclusion(HeirKind.paternalGrandmother, ExclusionReason.mother),
        );
      } else if (father) {
        excluded.add(
          const Exclusion(HeirKind.paternalGrandmother, ExclusionReason.father),
        );
      } else {
        grandmothers.add(HeirKind.paternalGrandmother);
      }
    }
    if (f.maternalGrandmother) {
      if (f.mother) {
        excluded.add(
          const Exclusion(HeirKind.maternalGrandmother, ExclusionReason.mother),
        );
      } else {
        grandmothers.add(HeirKind.maternalGrandmother);
      }
    }
    for (final g in grandmothers) {
      fixed.add(
        _Group(
          g,
          1,
          _sixth.over(grandmothers.length),
          ShareReason.grandmotherSixth,
        ),
      );
    }

    // Who blocks brothers and sisters of every kind.
    ExclusionReason? siblingBlock;
    if (hasSon) {
      siblingBlock = ExclusionReason.son;
    } else if (father) {
      siblingBlock = ExclusionReason.father;
    } else if (grandfather) {
      siblingBlock = ExclusionReason.grandfather;
    }

    // Uterine brothers and sisters: also blocked by any child.
    final uterine = f.maternalBrothers + f.maternalSisters;
    if (uterine > 0) {
      final block = siblingBlock ?? (hasChild ? ExclusionReason.child : null);
      if (block != null) {
        if (f.maternalBrothers > 0) {
          excluded.add(Exclusion(HeirKind.maternalBrother, block));
        }
        if (f.maternalSisters > 0) {
          excluded.add(Exclusion(HeirKind.maternalSister, block));
        }
      } else {
        // Shared equally, brother and sister alike.
        final total = uterine == 1 ? _sixth : _third;
        final reason = uterine == 1
            ? ShareReason.uterineSixth
            : ShareReason.uterineThird;
        if (f.maternalBrothers > 0) {
          fixed.add(
            _Group(
              HeirKind.maternalBrother,
              f.maternalBrothers,
              total.times(f.maternalBrothers).over(uterine),
              reason,
            ),
          );
        }
        if (f.maternalSisters > 0) {
          fixed.add(
            _Group(
              HeirKind.maternalSister,
              f.maternalSisters,
              total.times(f.maternalSisters).over(uterine),
              reason,
            ),
          );
        }
      }
    }

    // Full sisters, when no full brother makes them residuary and no
    // daughter makes them residuary "with another".
    final fullSistersResidueWithDaughters =
        siblingBlock == null &&
        f.fullSisters > 0 &&
        f.fullBrothers == 0 &&
        daughters > 0;
    if (siblingBlock == null &&
        f.fullSisters > 0 &&
        f.fullBrothers == 0 &&
        daughters == 0) {
      fixed.add(
        _Group(
          HeirKind.fullSister,
          f.fullSisters,
          f.fullSisters == 1 ? _half : _twoThirds,
          f.fullSisters == 1
              ? ShareReason.sisterHalf
              : ShareReason.sistersTwoThirds,
        ),
      );
    }

    // Consanguine sisters with no brother of theirs and no daughter.
    if (siblingBlock == null &&
        f.paternalSisters > 0 &&
        f.paternalBrothers == 0 &&
        f.fullBrothers == 0 &&
        daughters == 0) {
      if (f.fullSisters == 0) {
        fixed.add(
          _Group(
            HeirKind.paternalSister,
            f.paternalSisters,
            f.paternalSisters == 1 ? _half : _twoThirds,
            f.paternalSisters == 1
                ? ShareReason.sisterHalf
                : ShareReason.sistersTwoThirds,
          ),
        );
      } else if (f.fullSisters == 1) {
        // Completing two thirds with the one full sister.
        fixed.add(
          _Group(
            HeirKind.paternalSister,
            f.paternalSisters,
            _sixth,
            ShareReason.paternalSisterSixth,
          ),
        );
      } else {
        excluded.add(
          const Exclusion(
            HeirKind.paternalSister,
            ExclusionReason.twoFullSisters,
          ),
        );
      }
    }

    // The residuary heirs (আসাবা): the first group present takes what the
    // fixed shares leave.
    final residuary = <({HeirKind kind, int count, int units})>[];
    ShareReason? residueReason;
    ExclusionReason? agnateBlock;

    void take(
      List<({HeirKind kind, int count, int units})> members,
      ShareReason reason,
      ExclusionReason blocksOthersAs,
    ) {
      residuary.addAll(members.where((m) => m.count > 0));
      residueReason = reason;
      agnateBlock = blocksOthersAs;
    }

    if (sons > 0) {
      take(
        [
          (kind: HeirKind.son, count: sons, units: 2),
          (kind: HeirKind.daughter, count: daughters, units: 1),
        ],
        ShareReason.sonResidue,
        ExclusionReason.son,
      );
    } else if (father) {
      take(
        [(kind: HeirKind.father, count: 1, units: 1)],
        hasChild ? ShareReason.fatherSixthAndRest : ShareReason.fatherRest,
        ExclusionReason.father,
      );
    } else if (grandfather) {
      take(
        [(kind: HeirKind.grandfather, count: 1, units: 1)],
        hasChild
            ? ShareReason.grandfatherSixthAndRest
            : ShareReason.grandfatherRest,
        ExclusionReason.grandfather,
      );
    } else if (f.fullBrothers > 0) {
      take(
        [
          (kind: HeirKind.fullBrother, count: f.fullBrothers, units: 2),
          (kind: HeirKind.fullSister, count: f.fullSisters, units: 1),
        ],
        ShareReason.siblingsResidue,
        ExclusionReason.fullBrother,
      );
    } else if (fullSistersResidueWithDaughters) {
      take(
        [(kind: HeirKind.fullSister, count: f.fullSisters, units: 1)],
        ShareReason.sisterWithDaughters,
        ExclusionReason.sisterWithDaughters,
      );
    } else if (f.paternalBrothers > 0) {
      take(
        [
          (kind: HeirKind.paternalBrother, count: f.paternalBrothers, units: 2),
          (kind: HeirKind.paternalSister, count: f.paternalSisters, units: 1),
        ],
        ShareReason.siblingsResidue,
        ExclusionReason.paternalBrother,
      );
    } else if (f.paternalSisters > 0 && daughters > 0) {
      take(
        [(kind: HeirKind.paternalSister, count: f.paternalSisters, units: 1)],
        ShareReason.sisterWithDaughters,
        ExclusionReason.sisterWithDaughters,
      );
    } else {
      for (final (kind, count) in [
        (HeirKind.fullNephew, f.fullNephews),
        (HeirKind.paternalNephew, f.paternalNephews),
        (HeirKind.fullUncle, f.fullUncles),
        (HeirKind.paternalUncle, f.paternalUncles),
        (HeirKind.fullCousin, f.fullCousins),
        (HeirKind.paternalCousin, f.paternalCousins),
      ]) {
        if (count > 0) {
          take(
            [(kind: kind, count: count, units: 1)],
            ShareReason.agnateResidue,
            ExclusionReason.closerAgnate,
          );
          break;
        }
      }
    }

    // Brothers and sisters, and the male line, left out by a closer heir.
    final inResidue = {for (final r in residuary) r.kind};
    final inFixed = {for (final g in fixed) g.kind};
    final alreadyOut = {for (final e in excluded) e.kind};
    void outIfEntered(HeirKind kind, int count) {
      if (count == 0 ||
          inResidue.contains(kind) ||
          inFixed.contains(kind) ||
          alreadyOut.contains(kind)) {
        return;
      }
      final reason =
          siblingBlock ?? agnateBlock ?? ExclusionReason.closerAgnate;
      excluded.add(Exclusion(kind, reason));
    }

    for (final (kind, count) in [
      (HeirKind.fullBrother, f.fullBrothers),
      (HeirKind.fullSister, f.fullSisters),
      (HeirKind.paternalBrother, f.paternalBrothers),
      (HeirKind.paternalSister, f.paternalSisters),
    ]) {
      outIfEntered(kind, count);
    }
    // The male line is left out by whoever took the residue (someone
    // always did if any of them was entered).
    for (final (kind, count) in [
      (HeirKind.fullNephew, f.fullNephews),
      (HeirKind.paternalNephew, f.paternalNephews),
      (HeirKind.fullUncle, f.fullUncles),
      (HeirKind.paternalUncle, f.paternalUncles),
      (HeirKind.fullCousin, f.fullCousins),
      (HeirKind.paternalCousin, f.paternalCousins),
    ]) {
      if (count == 0 || inResidue.contains(kind)) continue;
      excluded.add(
        Exclusion(kind, agnateBlock ?? ExclusionReason.closerAgnate),
      );
    }

    // Bring the shares to exactly the whole.
    final fixedTotal = fixed.fold(Fraction.zero, (s, g) => s + g.share);
    var adjustment = Adjustment.none;
    var residue = Fraction.zero;
    if (fixedTotal > Fraction.one) {
      adjustment = Adjustment.awl;
      for (final g in fixed) {
        g.share = g.share / fixedTotal;
      }
    } else if (residuary.isNotEmpty) {
      residue = Fraction.one - fixedTotal;
    } else if (fixedTotal < Fraction.one && fixed.isNotEmpty) {
      final others = fixed.where((g) => !g.spouse).toList();
      if (others.isEmpty) {
        adjustment = Adjustment.spouseTakesRest;
        spouse!.share = Fraction.one;
      } else {
        adjustment = Adjustment.radd;
        final kept = spouse?.share ?? Fraction.zero;
        final othersTotal = others.fold(Fraction.zero, (s, g) => s + g.share);
        for (final g in others) {
          g.share = (Fraction.one - kept) * g.share / othersTotal;
        }
      }
    }

    // A residuary group with nothing left gets nothing.
    if (residuary.isNotEmpty && residue.isZero) {
      for (final r in residuary) {
        // The father with daughters keeps his sixth; only the residue is gone.
        if (inFixed.contains(r.kind)) continue;
        excluded.add(Exclusion(r.kind, ExclusionReason.nothingLeft));
      }
    }

    // Split every group among its members, and the children of a child
    // who died earlier take that child's part.
    final shares = <HeirKind, Fraction>{};
    final reasons = <HeirKind, ShareReason>{};
    final counts = <HeirKind, int>{};
    for (final g in fixed) {
      shares[g.kind] = (shares[g.kind] ?? Fraction.zero) + g.share;
      reasons[g.kind] = g.reason;
      counts[g.kind] = g.count;
    }
    if (residue.isPositive) {
      final units = residuary.fold(0, (s, r) => s + r.count * r.units);
      for (final r in residuary) {
        shares[r.kind] =
            (shares[r.kind] ?? Fraction.zero) +
            residue.times(r.count * r.units).over(units);
        counts[r.kind] = r.count;
        // The father with daughters keeps his "1/6 and the rest" reason.
        reasons[r.kind] ??= residueReason!;
        if (r.kind == HeirKind.daughter) {
          reasons[r.kind] = ShareReason.daughterWithSon;
        }
      }
    }

    final heirs = <HeirShare>[];
    for (final kind in HeirKind.values) {
      final total = shares[kind];
      if (total == null || !total.isPositive) continue;
      if (kind == HeirKind.grandson || kind == HeirKind.granddaughter) continue;
      final count = counts[kind] ?? 1;
      final each = total.over(count);
      if (kind == HeirKind.son || kind == HeirKind.daughter) {
        final living = kind == HeirKind.son ? f.sons : f.daughters;
        for (var i = 0; i < living; i++) {
          heirs.add(
            HeirShare(
              kind: kind,
              number: i + 1,
              of: living,
              share: each,
              reason: reasons[kind]!,
            ),
          );
        }
        final gender = kind == HeirKind.son ? Gender.male : Gender.female;
        final dead = f.predeceased;
        for (var c = 0; c < dead.length; c++) {
          final child = dead[c];
          if (child.gender != gender || !child.hasChildren) continue;
          final units = child.sons * 2 + child.daughters;
          for (final (k, n, u) in [
            (HeirKind.grandson, child.sons, 2),
            (HeirKind.granddaughter, child.daughters, 1),
          ]) {
            for (var i = 0; i < n; i++) {
              heirs.add(
                HeirShare(
                  kind: k,
                  number: i + 1,
                  of: n,
                  share: each.times(u).over(units),
                  reason: ShareReason.represented,
                  via: c,
                  viaKind: child.gender == Gender.male
                      ? HeirKind.son
                      : HeirKind.daughter,
                  viaNumber: [
                    for (var j = 0; j <= c; j++)
                      if (dead[j].gender == child.gender) j,
                  ].length,
                ),
              );
            }
          }
        }
        continue;
      }
      for (var i = 0; i < count; i++) {
        heirs.add(
          HeirShare(
            kind: kind,
            number: i + 1,
            of: count,
            share: each,
            reason: adjustment == Adjustment.spouseTakesRest
                ? ShareReason.sole
                : reasons[kind]!,
          ),
        );
      }
    }

    // A lone residuary heir with no one else takes everything.
    if (heirs.length == 1 && residuary.isNotEmpty && fixed.isEmpty) {
      final h = heirs.single;
      heirs[0] = HeirShare(
        kind: h.kind,
        number: h.number,
        of: h.of,
        share: h.share,
        reason: ShareReason.sole,
      );
    }
    heirs.sort((a, b) => _order(a).compareTo(_order(b)));

    return InheritanceResult(
      heirs: heirs,
      excluded: excluded,
      adjustment: adjustment,
      siblingsReduceMother:
          f.mother && !hasChild && f.siblings >= 2 && siblingBlock != null,
    );
  }

  // ------------------------------------------------------- distant kindred

  /// The deceased's brother or sister a line comes from.
  static HeirKind _lineKind(SiblingLine l) => switch ((l.blood, l.gender)) {
    (Blood.full, Gender.male) => HeirKind.fullBrother,
    (Blood.full, Gender.female) => HeirKind.fullSister,
    (Blood.consanguine, Gender.male) => HeirKind.paternalBrother,
    (Blood.consanguine, Gender.female) => HeirKind.paternalSister,
    (Blood.uterine, Gender.male) => HeirKind.maternalBrother,
    (Blood.uterine, Gender.female) => HeirKind.maternalSister,
  };

  /// Each line with its number among the lines of the same kind.
  static List<(SiblingLine, int, HeirKind, int)> _numberedLines(DistantKin d) {
    final counts = <HeirKind, int>{};
    return [
      for (var i = 0; i < d.siblingLines.length; i++)
        if (DistantKin.claimants(d.siblingLines[i]) > 0)
          () {
            final kind = _lineKind(d.siblingLines[i]);
            counts[kind] = (counts[kind] ?? 0) + 1;
            return (d.siblingLines[i], i, kind, counts[kind]!);
          }(),
    ];
  }

  /// Distant kindred entered who take nothing; [fromClass] is the class
  /// that took (2 the mother's father, 3 siblings' children, 4 uncles and
  /// aunts), or null when a sharer or residuary took.
  static List<Exclusion> _distantOut(DistantKin d, int? fromClass) {
    const closer = ExclusionReason.closer;
    return [
      if (d.maternalGrandfather && fromClass != 2)
        const Exclusion(HeirKind.maternalGrandfather, closer),
      if (fromClass == null || fromClass < 3)
        for (final (_, _, kind, n) in _numberedLines(d))
          Exclusion(HeirKind.grandson, closer, viaKind: kind, viaNumber: n),
      if (fromClass == null || fromClass < 4)
        for (final tier in [...d.paternalTiers, ...d.maternalTiers])
          for (final (kind, count, _) in tier)
            if (count > 0) Exclusion(kind, closer),
    ];
  }

  static InheritanceResult _distantShares(Family f) {
    final d = f.distant;
    final heirs = <HeirShare>[];
    final excluded = <Exclusion>[];
    final notes = <ResultNote>[ResultNote.muslimDistantKindred];

    // The spouse keeps the share they take with no child, and no more.
    final spouse = f.deceased == Gender.female
        ? (f.husband ? (HeirKind.husband, 1, _half) : null)
        : (f.wives > 0 ? (HeirKind.wife, f.wives.clamp(1, 4), _quarter) : null);
    void addSpouse() {
      if (spouse == null) return;
      final (kind, count, share) = spouse;
      for (var i = 0; i < count; i++) {
        heirs.add(
          HeirShare(
            kind: kind,
            number: i + 1,
            of: count,
            share: share.over(count),
            reason: kind == HeirKind.husband
                ? ShareReason.husbandHalf
                : ShareReason.wifeQuarter,
          ),
        );
      }
    }

    final rest = Fraction.one - (spouse?.$3 ?? Fraction.zero);

    // Class II: the mother's father takes the rest.
    if (d.maternalGrandfather) {
      addSpouse();
      heirs.add(
        HeirShare(
          kind: HeirKind.maternalGrandfather,
          number: 1,
          of: 1,
          share: rest,
          reason: ShareReason.distantKindred,
        ),
      );
      if (d.hasLines) notes.add(ResultNote.distantGrandfatherUnsettled);
      excluded.addAll(_distantOut(d, 2));
      return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
    }

    // Class III: each claimant stands for one brother or sister of their
    // parent's kind; those "virtual" siblings share as siblings would (with
    // the spouse as an ordinary sharer, Akbar Ali v. Adar Bibi), and each
    // line's share goes to its claimants — a son twice a daughter, except
    // through a uterine sibling, where all are equal.
    final lines = _numberedLines(d);
    if (lines.isNotEmpty) {
      int sum(HeirKind k) => lines
          .where((l) => l.$3 == k)
          .fold(0, (s, l) => s + DistantKin.claimants(l.$1));
      final virtual = Family(
        deceased: f.deceased,
        husband: f.husband,
        wives: f.wives,
        fullBrothers: sum(HeirKind.fullBrother),
        fullSisters: sum(HeirKind.fullSister),
        paternalBrothers: sum(HeirKind.paternalBrother),
        paternalSisters: sum(HeirKind.paternalSister),
        maternalBrothers: sum(HeirKind.maternalBrother),
        maternalSisters: sum(HeirKind.maternalSister),
      );
      final v = _compute(virtual);
      if (v.adjustment == Adjustment.awl) notes.add(ResultNote.distantAwl);
      final perHead = <HeirKind, Fraction>{};
      for (final h in v.heirs) {
        if (h.kind == HeirKind.husband || h.kind == HeirKind.wife) {
          heirs.add(h);
        } else {
          perHead[h.kind] = h.share;
        }
      }
      final out = {for (final e in v.excluded) e.kind: e.reason};
      for (final (line, index, kind, n) in lines) {
        final each = perHead[kind];
        if (each == null) {
          excluded.add(
            Exclusion(
              HeirKind.grandson,
              out[kind] ?? ExclusionReason.closer,
              viaKind: kind,
              viaNumber: n,
            ),
          );
          continue;
        }
        final sons = DistantKin.claimantSons(line);
        final total = each.times(sons + line.daughters);
        final uterine = line.blood == Blood.uterine;
        final units = uterine
            ? sons + line.daughters
            : sons * 2 + line.daughters;
        for (final (k, count, unit) in [
          (HeirKind.grandson, sons, uterine ? 1 : 2),
          (HeirKind.granddaughter, line.daughters, 1),
        ]) {
          for (var i = 0; i < count; i++) {
            heirs.add(
              HeirShare(
                kind: k,
                number: i + 1,
                of: count,
                share: total.times(unit).over(units),
                reason: ShareReason.distantSiblingLine,
                via: index,
                viaKind: kind,
                viaNumber: n,
              ),
            );
          }
        }
      }
      excluded.addAll(_distantOut(d, 3));
      return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
    }

    // Class IV: the father's side 2/3 and the mother's side 1/3 (all to one
    // side if the other is empty); within a side the nearest blood tier,
    // a male twice a female.
    addSpouse();
    List<(HeirKind, int, bool)>? pick(List<List<(HeirKind, int, bool)>> tiers) {
      for (final tier in tiers) {
        if (tier.any((e) => e.$2 > 0)) return tier;
      }
      return null;
    }

    final paternal = pick(d.paternalTiers);
    final maternal = pick(d.maternalTiers);
    for (final (tier, side) in [
      (
        paternal,
        paternal != null && maternal != null ? Fraction(2, 3) : Fraction.one,
      ),
      (
        maternal,
        paternal != null && maternal != null ? Fraction(1, 3) : Fraction.one,
      ),
    ]) {
      if (tier == null) continue;
      final units = tier.fold(0, (s, e) => s + e.$2 * (e.$3 ? 2 : 1));
      for (final (kind, count, male) in tier) {
        for (var i = 0; i < count; i++) {
          heirs.add(
            HeirShare(
              kind: kind,
              number: i + 1,
              of: count,
              share: (rest * side).times(male ? 2 : 1).over(units),
              reason: ShareReason.distantUnclesAunts,
            ),
          );
        }
      }
    }
    for (final tier in [...d.paternalTiers, ...d.maternalTiers]) {
      for (final (kind, count, _) in tier) {
        if (count > 0 && !heirs.any((h) => h.kind == kind)) {
          excluded.add(Exclusion(kind, ExclusionReason.closer));
        }
      }
    }
    return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
  }

  /// Spouse, children with each predeceased child's children after the
  /// living ones of that gender, then the rest in kind order.
  static int _order(HeirShare h) {
    final kindIndex = switch (h.kind) {
      HeirKind.grandson || HeirKind.granddaughter =>
        h.viaGender == Gender.male
            ? HeirKind.son.index
            : HeirKind.daughter.index,
      _ => h.kind.index,
    };
    final sub = switch (h.kind) {
      HeirKind.grandson || HeirKind.granddaughter =>
        1000 + (h.via ?? 0) * 100 + (h.kind == HeirKind.grandson ? 0 : 50),
      _ => 0,
    };
    return kindIndex * 100000 + sub + h.number;
  }
}
