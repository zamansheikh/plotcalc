/// Christian intestate succession in Bangladesh: the Succession Act 1925,
/// Part V, Chapter II (sections 32-49), as printed on bdlaws.
///
/// The spouse takes 1/3 beside lineal descendants, 1/2 beside other kindred,
/// everything beside no one (s.33; a widower the same, s.35). The rest goes
/// to descendants by nearest generation (ss.37-40), else the father (s.42),
/// else the mother with brothers and sisters and the children of dead ones
/// (ss.43-46), else brothers and sisters (s.47), else the nearest degree of
/// kindred per head (s.48). Sons and daughters, full and half blood, the
/// father's and mother's side are all alike (s.27).
library;

import 'inheritance.dart';

export 'inheritance.dart';

class ChristianFamily {
  final Gender deceased;

  /// A surviving widow or widower.
  final bool spouse;
  final int sons;
  final int daughters;

  /// Children who died before the deceased, with their own children.
  final List<PredeceasedChild> predeceased;
  final bool father;
  final bool mother;

  /// Living brothers and sisters, full or half blood alike.
  final int brothers;
  final int sisters;

  /// Brothers and sisters who died earlier, with their children.
  final List<PredeceasedChild> deadSiblings;
  final bool paternalGrandfather;
  final bool paternalGrandmother;
  final bool maternalGrandfather;
  final bool maternalGrandmother;

  /// Third degree: the parents' brothers and sisters.
  final int paternalUncles;
  final int paternalAunts;
  final int maternalUncles;
  final int maternalAunts;

  /// Fourth degree: first cousins on any side.
  final int cousins;

  const ChristianFamily({
    required this.deceased,
    this.spouse = false,
    this.sons = 0,
    this.daughters = 0,
    this.predeceased = const [],
    this.father = false,
    this.mother = false,
    this.brothers = 0,
    this.sisters = 0,
    this.deadSiblings = const [],
    this.paternalGrandfather = false,
    this.paternalGrandmother = false,
    this.maternalGrandfather = false,
    this.maternalGrandmother = false,
    this.paternalUncles = 0,
    this.paternalAunts = 0,
    this.maternalUncles = 0,
    this.maternalAunts = 0,
    this.cousins = 0,
  });

  List<PredeceasedChild> get _deadChildren => [
    for (final c in predeceased)
      if (c.hasChildren) c,
  ];
  List<PredeceasedChild> get _deadSiblings => [
    for (final c in deadSiblings)
      if (c.hasChildren) c,
  ];

  bool get hasDescendants => sons + daughters + _deadChildren.length > 0;

  int get _grandparents =>
      (paternalGrandfather ? 1 : 0) +
      (paternalGrandmother ? 1 : 0) +
      (maternalGrandfather ? 1 : 0) +
      (maternalGrandmother ? 1 : 0);
  int get _thirdDegree =>
      paternalUncles + paternalAunts + maternalUncles + maternalAunts;

  /// Any kindred at all besides descendants (as far as entered).
  bool get hasKindred =>
      father ||
      mother ||
      brothers + sisters + _deadSiblings.length > 0 ||
      _grandparents > 0 ||
      _thirdDegree > 0 ||
      cousins > 0;

  bool get anyone => spouse || hasDescendants || hasKindred;
}

class ChristianSuccession {
  ChristianSuccession._();

  static InheritanceResult compute(ChristianFamily f) {
    final heirs = <HeirShare>[];
    final excluded = <Exclusion>[];
    final notes = <ResultNote>[];
    if (!f.anyone) {
      return const InheritanceResult(
        heirs: [],
        excluded: [],
        notes: [ResultNote.noHeirs],
      );
    }

    // s.33 / s.35: the spouse.
    var rest = Fraction.one;
    if (f.spouse) {
      final ShareReason reason;
      final Fraction share;
      if (f.hasDescendants) {
        share = Fraction(1, 3);
        reason = ShareReason.christianSpouseThird;
      } else if (f.hasKindred) {
        share = Fraction(1, 2);
        reason = ShareReason.christianSpouseHalf;
      } else {
        share = Fraction.one;
        reason = ShareReason.christianSpouseAll;
        notes.add(ResultNote.christianSpouseAllCheck);
      }
      heirs.add(
        HeirShare(
          kind: f.deceased == Gender.male ? HeirKind.wife : HeirKind.husband,
          number: 1,
          of: 1,
          share: share,
          reason: reason,
        ),
      );
      rest = Fraction.one - share;
    }
    if (rest.isZero) {
      return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
    }

    // Who is left out by whoever takes first, for the "who gets nothing"
    // list.
    void out(HeirKind kind, bool entered, ExclusionReason reason) {
      if (entered) excluded.add(Exclusion(kind, reason));
    }

    void outKindred(ExclusionReason reason, {bool father = true}) {
      if (father) out(HeirKind.father, f.father, reason);
      out(HeirKind.mother, f.mother, reason);
      out(HeirKind.brother, f.brothers > 0, reason);
      out(HeirKind.sister, f.sisters > 0, reason);
      out(HeirKind.grandfather, f.paternalGrandfather, reason);
      out(HeirKind.paternalGrandmother, f.paternalGrandmother, reason);
      out(HeirKind.maternalGrandfather, f.maternalGrandfather, reason);
      out(HeirKind.maternalGrandmother, f.maternalGrandmother, reason);
      out(HeirKind.fullUncle, f.paternalUncles > 0, reason);
      out(HeirKind.paternalAunt, f.paternalAunts > 0, reason);
      out(HeirKind.maternalUncle, f.maternalUncles > 0, reason);
      out(HeirKind.maternalAunt, f.maternalAunts > 0, reason);
      out(HeirKind.cousin, f.cousins > 0, reason);
    }

    /// Living people of one kind, each taking [each].
    void add(HeirKind kind, int count, Fraction each, ShareReason reason) {
      for (var i = 0; i < count; i++) {
        heirs.add(
          HeirShare(
            kind: kind,
            number: i + 1,
            of: count,
            share: each,
            reason: reason,
          ),
        );
      }
    }

    /// The children of a dead person, sharing [share] equally (sons and
    /// daughters alike).
    void addChildrenOf(
      PredeceasedChild dead,
      int index,
      HeirKind deadKind,
      int deadNumber,
      Fraction share,
      ShareReason reason,
    ) {
      final heads = dead.sons + dead.daughters;
      for (final (kind, n) in [
        (HeirKind.grandson, dead.sons),
        (HeirKind.granddaughter, dead.daughters),
      ]) {
        for (var i = 0; i < n; i++) {
          heirs.add(
            HeirShare(
              kind: kind,
              number: i + 1,
              of: n,
              share: share.over(heads),
              reason: reason,
              via: index,
              viaKind: deadKind,
              viaNumber: deadNumber,
            ),
          );
        }
      }
    }

    /// Every dead person with children, numbered within son/daughter (or
    /// brother/sister).
    List<(PredeceasedChild, int, HeirKind, int)> numbered(
      List<PredeceasedChild> list,
      HeirKind male,
      HeirKind female,
    ) {
      final counts = <HeirKind, int>{};
      return [
        for (var i = 0; i < list.length; i++)
          if (list[i].hasChildren)
            () {
              final kind = list[i].gender == Gender.male ? male : female;
              counts[kind] = (counts[kind] ?? 0) + 1;
              return (list[i], i, kind, counts[kind]!);
            }(),
      ];
    }

    // ss.37-40: lineal descendants.
    if (f.hasDescendants) {
      final living = f.sons + f.daughters;
      final dead = numbered(f.predeceased, HeirKind.son, HeirKind.daughter);
      if (living > 0) {
        // One share per living child and per dead child with descendants.
        final each = rest.over(living + dead.length);
        add(HeirKind.son, f.sons, each, ShareReason.christianChildren);
        add(
          HeirKind.daughter,
          f.daughters,
          each,
          ShareReason.christianChildren,
        );
        for (final (c, i, kind, n) in dead) {
          addChildrenOf(c, i, kind, n, each, ShareReason.christianChildOfDead);
        }
      } else {
        // No child alive: grandchildren per head (s.38).
        final heads = dead.fold(0, (s, d) => s + d.$1.sons + d.$1.daughters);
        for (final (c, i, kind, n) in dead) {
          addChildrenOf(
            c,
            i,
            kind,
            n,
            rest.times(c.sons + c.daughters).over(heads),
            ShareReason.christianGrandchildrenPerHead,
          );
        }
        if (dead.length > 1) notes.add(ResultNote.christianPerHead);
      }
      outKindred(ExclusionReason.child);
      return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
    }

    final siblings = numbered(
      f.deadSiblings,
      HeirKind.brother,
      HeirKind.sister,
    );
    final siblingUnits = f.brothers + f.sisters + siblings.length;

    // s.42: the father takes it all.
    if (f.father) {
      heirs.add(
        HeirShare(
          kind: HeirKind.father,
          number: 1,
          of: 1,
          share: rest,
          reason: ShareReason.christianFather,
        ),
      );
      outKindred(ExclusionReason.father, father: false);
      return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
    }

    // ss.43-47: the mother (if alive) and each brother or sister, a dead
    // one's children taking that one's share.
    if (f.mother || siblingUnits > 0) {
      final units = (f.mother ? 1 : 0) + siblingUnits;
      final each = rest.over(units);
      if (f.mother) {
        heirs.add(
          HeirShare(
            kind: HeirKind.mother,
            number: 1,
            of: 1,
            share: each,
            reason: siblingUnits == 0
                ? ShareReason.christianMother
                : ShareReason.christianMotherAndSiblings,
          ),
        );
      }
      final reason = f.mother
          ? ShareReason.christianMotherAndSiblings
          : ShareReason.christianSiblings;
      add(HeirKind.brother, f.brothers, each, reason);
      add(HeirKind.sister, f.sisters, each, reason);
      for (final (c, i, kind, n) in siblings) {
        addChildrenOf(
          c,
          i,
          kind,
          n,
          each,
          ShareReason.christianSiblingsChildren,
        );
      }
      final closer = ExclusionReason.closer;
      out(HeirKind.grandfather, f.paternalGrandfather, closer);
      out(HeirKind.paternalGrandmother, f.paternalGrandmother, closer);
      out(HeirKind.maternalGrandfather, f.maternalGrandfather, closer);
      out(HeirKind.maternalGrandmother, f.maternalGrandmother, closer);
      out(HeirKind.fullUncle, f.paternalUncles > 0, closer);
      out(HeirKind.paternalAunt, f.paternalAunts > 0, closer);
      out(HeirKind.maternalUncle, f.maternalUncles > 0, closer);
      out(HeirKind.maternalAunt, f.maternalAunts > 0, closer);
      out(HeirKind.cousin, f.cousins > 0, closer);
      return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
    }

    // s.48: the nearest degree of kindred, per head.
    final degrees = <List<(HeirKind, int)>>[
      [
        (HeirKind.grandfather, f.paternalGrandfather ? 1 : 0),
        (HeirKind.paternalGrandmother, f.paternalGrandmother ? 1 : 0),
        (HeirKind.maternalGrandfather, f.maternalGrandfather ? 1 : 0),
        (HeirKind.maternalGrandmother, f.maternalGrandmother ? 1 : 0),
      ],
      [
        (HeirKind.fullUncle, f.paternalUncles),
        (HeirKind.paternalAunt, f.paternalAunts),
        (HeirKind.maternalUncle, f.maternalUncles),
        (HeirKind.maternalAunt, f.maternalAunts),
      ],
      [(HeirKind.cousin, f.cousins)],
    ];
    for (var d = 0; d < degrees.length; d++) {
      final heads = degrees[d].fold(0, (s, k) => s + k.$2);
      if (heads == 0) continue;
      for (final (kind, n) in degrees[d]) {
        add(kind, n, rest.over(heads), ShareReason.christianNearest);
      }
      for (final further in degrees.skip(d + 1)) {
        for (final (kind, n) in further) {
          out(kind, n > 0, ExclusionReason.closer);
        }
      }
      break;
    }
    return InheritanceResult(heirs: heirs, excluded: excluded, notes: notes);
  }
}
