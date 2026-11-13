/// What every inheritance law here shares: exact fractions, the heirs, why
/// each takes what they take, and the result shown to the user.
library;

import 'fraction.dart';

export 'fraction.dart';

enum Gender { male, female }

/// A son or daughter who died before the deceased, leaving children. Under
/// the 1961 ordinance those children take, between them, what their parent
/// would have taken if alive.
class PredeceasedChild {
  final Gender gender;
  final int sons;
  final int daughters;
  const PredeceasedChild(this.gender, {this.sons = 0, this.daughters = 0});

  bool get hasChildren => sons + daughters > 0;

  PredeceasedChild copyWith({Gender? gender, int? sons, int? daughters}) =>
      PredeceasedChild(
        gender ?? this.gender,
        sons: sons ?? this.sons,
        daughters: daughters ?? this.daughters,
      );
}

/// How a brother, sister, uncle or aunt is related: through both parents,
/// only the father (consanguine, বৈমাত্রেয়), or only the mother (uterine,
/// বৈপিত্রেয়).
enum Blood { full, consanguine, uterine }

/// A brother or sister who died before the deceased, with their children —
/// for the Muslim distant kindred rules.
class SiblingLine {
  final Blood blood;
  final Gender gender;
  final int sons;
  final int daughters;
  const SiblingLine(
    this.blood,
    this.gender, {
    this.sons = 0,
    this.daughters = 0,
  });

  SiblingLine copyWith({
    Blood? blood,
    Gender? gender,
    int? sons,
    int? daughters,
  }) => SiblingLine(
    blood ?? this.blood,
    gender ?? this.gender,
    sons: sons ?? this.sons,
    daughters: daughters ?? this.daughters,
  );
}

enum HeirKind {
  husband,
  wife,
  son,
  daughter,

  /// A child of a son or daughter who died earlier.
  grandson,
  granddaughter,
  father,
  mother,
  grandfather,
  paternalGrandmother,
  maternalGrandmother,
  fullBrother,
  fullSister,
  paternalBrother,
  paternalSister,
  maternalBrother,
  maternalSister,
  fullNephew,
  paternalNephew,
  fullUncle,
  paternalUncle,
  fullCousin,
  paternalCousin,

  // Relatives the Hindu and Christian rules (and Muslim distant kindred)
  // name on their own.
  /// A dead son's widow (পুত্রবধূ), under the Hindu Women's Rights to
  /// Property Act 1937.
  sonsWidow,
  unmarriedDaughter,

  /// A married daughter who has, or may still have, a son.
  marriedDaughter,
  daughtersSon,
  daughtersDaughter,

  /// Brother or sister, full or half (the Succession Act does not tell
  /// them apart).
  brother,
  sister,
  grandNephew,
  sistersSon,
  sistersDaughter,
  brothersDaughter,
  maternalGrandfather,
  paternalAunt,
  maternalUncle,
  maternalAunt,

  /// A first cousin on any side.
  cousin,

  // The father's sisters and the mother's brothers and sisters by blood,
  // and the father's uterine brother (the full and consanguine ones are
  // residuaries, not distant kindred).
  paternalAuntConsanguine,
  paternalAuntUterine,
  fatherUterineBrother,
  maternalUncleConsanguine,
  maternalUncleUterine,
  maternalAuntConsanguine,
  maternalAuntUterine,
}

/// Why an heir takes what they take.
enum ShareReason {
  husbandHalf,
  husbandQuarter,
  wifeQuarter,
  wifeEighth,
  sonResidue,
  daughterWithSon,
  daughterHalf,
  daughtersTwoThirds,
  fatherSixth,
  fatherSixthAndRest,
  fatherRest,
  grandfatherSixth,
  grandfatherSixthAndRest,
  grandfatherRest,
  motherSixthChild,
  motherSixthSiblings,
  motherThird,
  motherThirdOfRest,
  grandmotherSixth,
  uterineSixth,
  uterineThird,
  sisterHalf,
  sistersTwoThirds,
  paternalSisterSixth,
  siblingsResidue,
  sisterWithDaughters,
  agnateResidue,

  /// The share of a child who died earlier, passed to their children.
  represented,

  /// Everything, as the only heir (with no one to share the rest).
  sole,

  // Hindu: Dayabhaga and the Hindu Women's Rights to Property Act 1937.
  hinduSons,
  hinduWidow,
  hinduSonsLine,
  hinduSonsWidowAsSon,
  hinduSonsWidowAsGrandson,
  hinduUnmarriedDaughters,
  hinduMarriedDaughters,
  hinduDaughtersSons,
  hinduFather,
  hinduMother,
  hinduBrothers,
  hinduNephews,
  hinduGrandNephews,
  hinduSistersSons,
  hinduGrandfather,
  hinduGrandmother,
  hinduUncles,
  hinduCousins,

  // Christian: Succession Act 1925, Part V.
  christianSpouseThird,
  christianSpouseHalf,
  christianSpouseAll,
  christianChildren,
  christianChildOfDead,
  christianGrandchildrenPerHead,
  christianFather,
  christianMotherAndSiblings,
  christianMother,
  christianSiblings,
  christianSiblingsChildren,
  christianNearest,

  // Muslim distant kindred (যাবিল আরহাম).
  distantKindred,
  distantSiblingLine,
  distantUnclesAunts,
}

/// How the shares were brought to exactly the whole estate.
enum Adjustment {
  none,

  /// The fixed shares came to more than the whole: all cut in proportion
  /// (আওল).
  awl,

  /// Something was left with no one to take the rest: returned to the
  /// heirs other than the spouse, in proportion (রাদ).
  radd,

  /// Only the spouse is an heir here and takes the rest too. Distant
  /// kindred, not covered, would come first.
  spouseTakesRest,
}

/// Why an heir that was entered takes nothing.
enum ExclusionReason {
  son,
  father,
  grandfather,
  mother,
  child,
  fullBrother,
  paternalBrother,
  sisterWithDaughters,
  twoFullSisters,
  closerAgnate,

  /// Heirs with fixed shares took everything.
  nothingLeft,

  /// Hindu: a son, a son's son or a son's widow takes first.
  maleLine,

  /// Hindu: daughters wait while the widow lives.
  widowFirst,

  /// Hindu: married daughters wait for the unmarried ones.
  unmarriedDaughter,

  /// A nearer relative takes first (Hindu order, Christian degrees,
  /// Muslim distant kindred).
  closer,
}

/// Things to know about a result as a whole.
enum ResultNote {
  /// Widow, son's widow, daughter, mother: a life interest that goes back to
  /// the deceased's heirs at her death.
  hinduLimitedEstate,

  /// A dead son's widow beside his sons: how they share is not settled.
  hinduSonsWidowUnsettled,

  /// The spouse takes all only if no relative at all survives.
  christianSpouseAllCheck,

  /// With no child alive, grandchildren share per head.
  christianPerHead,

  /// Nobody inherits: the estate goes to the Government.
  noHeirs,

  /// Shares came from the distant kindred rules.
  muslimDistantKindred,

  /// The mother's father with children of dead siblings: Mulla puts him
  /// first, the Sirajiyyah hints otherwise.
  distantGrandfatherUnsettled,

  /// Spouse and siblings' children came to more than the whole: no rule
  /// found for that case.
  distantAwl,
}

class HeirShare {
  final HeirKind kind;

  /// 1-based among heirs of the same kind (and parent, for grandchildren).
  final int number;

  /// How many of this kind there are (under the same parent).
  final int of;

  /// For the child (or widow) of someone who died before the deceased: that
  /// person's index in the family's list, what they were (son, daughter,
  /// brother…), and their number among the dead of that kind.
  final int? via;
  final HeirKind? viaKind;
  final int? viaNumber;
  final Fraction share;
  final ShareReason reason;

  /// Held as a Hindu woman's limited estate (a life interest).
  final bool lifeInterest;

  const HeirShare({
    required this.kind,
    required this.number,
    required this.of,
    required this.share,
    required this.reason,
    this.via,
    this.viaKind,
    this.viaNumber,
    this.lifeInterest = false,
  });

  /// The predeceased parent's gender, for children of a dead son or
  /// daughter.
  Gender? get viaGender => switch (viaKind) {
    HeirKind.son || HeirKind.brother || HeirKind.fullBrother => Gender.male,
    HeirKind.daughter ||
    HeirKind.sister ||
    HeirKind.fullSister => Gender.female,
    _ => null,
  };
}

class Exclusion {
  final HeirKind kind;
  final ExclusionReason reason;

  /// For the children of someone who died earlier: that person.
  final HeirKind? viaKind;
  final int? viaNumber;
  const Exclusion(this.kind, this.reason, {this.viaKind, this.viaNumber});
}

class InheritanceResult {
  /// One row per person, in a fixed order: spouse, children, parents,
  /// grandparents, siblings, then the male line.
  final List<HeirShare> heirs;
  final List<Exclusion> excluded;
  final Adjustment adjustment;

  /// The siblings that inherit nothing but still cut the mother to 1/6.
  final bool siblingsReduceMother;
  final List<ResultNote> notes;

  const InheritanceResult({
    required this.heirs,
    required this.excluded,
    this.adjustment = Adjustment.none,
    this.siblingsReduceMother = false,
    this.notes = const [],
  });

  bool get isEmpty => heirs.isEmpty;

  /// The common base (মাসআলা): every share is a whole number of these parts.
  int get base => heirs.fold(1, (b, h) => Fraction.lcm(b, h.share.den));

  int partsOf(HeirShare h) => h.share.num * (base ~/ h.share.den);

  Fraction get total => heirs.fold(Fraction.zero, (s, h) => s + h.share);
}
