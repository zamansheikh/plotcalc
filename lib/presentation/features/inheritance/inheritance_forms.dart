import '../../../core/inheritance/christian.dart';
import '../../../core/inheritance/dayabhaga.dart';
import '../../../core/inheritance/faraid.dart';

/// The religion whose law decides the shares.
enum InheritanceLaw { muslim, hindu, christian }

/// What has been entered for a Muslim family, and which questions are worth
/// asking given the answers so far: a relative who cannot inherit (and does
/// not change anyone's share) is not asked about.
class MuslimForm {
  bool husband = false;
  int wives = 0;
  int sons = 0;
  int daughters = 0;
  final List<PredeceasedChild> dead = [];
  bool father = false;
  bool mother = false;
  bool grandfather = false;
  bool paternalGrandmother = false;
  bool maternalGrandmother = false;
  int fullBrothers = 0;
  int fullSisters = 0;
  int paternalBrothers = 0;
  int paternalSisters = 0;
  int maternalBrothers = 0;
  int maternalSisters = 0;
  int fullNephews = 0;
  int paternalNephews = 0;
  int fullUncles = 0;
  int paternalUncles = 0;
  int fullCousins = 0;
  int paternalCousins = 0;
  bool halfSiblingsOpen = false;

  // Distant kindred.
  bool maternalGrandfather = false;
  final List<SiblingLine> lines = [];
  int fullPaternalAunts = 0;
  int consanguinePaternalAunts = 0;
  int uterinePaternalAunts = 0;
  int fatherUterineBrothers = 0;
  int fullMaternalUncles = 0;
  int consanguineMaternalUncles = 0;
  int uterineMaternalUncles = 0;
  int fullMaternalAunts = 0;
  int consanguineMaternalAunts = 0;
  int uterineMaternalAunts = 0;
  bool halfAuntsOpen = false;

  int get _deadSons =>
      dead.where((c) => c.gender == Gender.male && c.hasChildren).length;
  int get _deadDaughters =>
      dead.where((c) => c.gender == Gender.female && c.hasChildren).length;
  bool get hasSon => sons + _deadSons > 0;
  bool get hasChild => hasSon || daughters + _deadDaughters > 0;

  bool get askGrandfather => !father;
  bool get askPaternalGrandmother => !father && !mother;
  bool get askMaternalGrandmother => !mother;
  bool get _grandfatherAlive => askGrandfather && grandfather;

  /// Brothers and sisters can inherit…
  bool get siblingsInherit => !hasSon && !father && !_grandfatherAlive;

  /// …or, though excluded, still cut the mother's share.
  bool get siblingsForMother => mother && !hasChild;
  bool get askSiblings => siblingsInherit || siblingsForMother;
  bool get askMaleLine =>
      siblingsInherit && fullBrothers == 0 && paternalBrothers == 0;
  bool get askUncles => askMaleLine && fullNephews + paternalNephews == 0;
  bool get askCousins => askUncles && fullUncles + paternalUncles == 0;

  /// Distant kindred are asked about only when no one but the spouse
  /// inherits otherwise.
  bool askDistant(Gender deceased) => !Faraid.compute(
    _family(deceased),
  ).heirs.any((h) => h.kind != HeirKind.husband && h.kind != HeirKind.wife);

  /// The mother's father comes first; then siblings' children; then uncles
  /// and aunts.
  bool askLines(Gender deceased) =>
      askDistant(deceased) && !maternalGrandfather;
  bool askAuntsUncles(Gender deceased) =>
      askLines(deceased) && !lines.any((l) => DistantKin.claimants(l) > 0);

  /// The family as entered, leaving out anyone not being asked about (they
  /// could not inherit anyway).
  Family family(Gender deceased) {
    final base = _family(deceased);
    if (!askDistant(deceased)) return base;
    final aunts = askAuntsUncles(deceased);
    return base.withDistant(
      DistantKin(
        maternalGrandfather: maternalGrandfather,
        siblingLines: askLines(deceased) ? List.of(lines) : const [],
        fullPaternalAunts: aunts ? fullPaternalAunts : 0,
        consanguinePaternalAunts: aunts ? consanguinePaternalAunts : 0,
        uterinePaternalAunts: aunts ? uterinePaternalAunts : 0,
        fatherUterineBrothers: aunts ? fatherUterineBrothers : 0,
        fullMaternalUncles: aunts ? fullMaternalUncles : 0,
        consanguineMaternalUncles: aunts ? consanguineMaternalUncles : 0,
        uterineMaternalUncles: aunts ? uterineMaternalUncles : 0,
        fullMaternalAunts: aunts ? fullMaternalAunts : 0,
        consanguineMaternalAunts: aunts ? consanguineMaternalAunts : 0,
        uterineMaternalAunts: aunts ? uterineMaternalAunts : 0,
      ),
    );
  }

  Family _family(Gender deceased) {
    final male = deceased == Gender.male;
    final siblings = askSiblings;
    return Family(
      deceased: deceased,
      husband: !male && husband,
      wives: male ? wives : 0,
      sons: sons,
      daughters: daughters,
      predeceased: List.of(dead),
      father: father,
      mother: mother,
      grandfather: askGrandfather && grandfather,
      paternalGrandmother: askPaternalGrandmother && paternalGrandmother,
      maternalGrandmother: askMaternalGrandmother && maternalGrandmother,
      fullBrothers: siblings ? fullBrothers : 0,
      fullSisters: siblings ? fullSisters : 0,
      paternalBrothers: siblings ? paternalBrothers : 0,
      paternalSisters: siblings ? paternalSisters : 0,
      maternalBrothers: siblings ? maternalBrothers : 0,
      maternalSisters: siblings ? maternalSisters : 0,
      fullNephews: askMaleLine ? fullNephews : 0,
      paternalNephews: askMaleLine ? paternalNephews : 0,
      fullUncles: askUncles ? fullUncles : 0,
      paternalUncles: askUncles ? paternalUncles : 0,
      fullCousins: askCousins ? fullCousins : 0,
      paternalCousins: askCousins ? paternalCousins : 0,
    );
  }
}

/// A Hindu man's family. Each later group is asked about only when every
/// earlier one is empty, since the first group present takes everything.
class HinduForm {
  int widows = 0;
  int sons = 0;
  final List<PredeceasedSon> deadSons = [];
  int unmarriedDaughters = 0;
  int marriedDaughters = 0;
  int daughtersSons = 0;
  bool father = false;
  bool mother = false;
  int fullBrothers = 0;
  int halfBrothers = 0;
  int brothersSons = 0;
  int brothersGrandsons = 0;
  int sistersSons = 0;
  bool grandfather = false;
  bool grandmother = false;
  int uncles = 0;
  int unclesSons = 0;

  bool get maleLine => sons > 0 || deadSons.any((s) => s.counts);
  bool get firstGroup => maleLine || widows > 0;
  bool get askDaughters => !firstGroup;
  bool get askMarriedDaughters => askDaughters && unmarriedDaughters == 0;
  bool get askDaughtersSons => askMarriedDaughters && marriedDaughters == 0;
  bool get askFather => askDaughtersSons && daughtersSons == 0;
  bool get askMother => askFather && !father;
  bool get askBrothers => askMother && !mother;
  bool get askHalfBrothers => askBrothers && fullBrothers == 0;
  bool get askBrothersSons => askHalfBrothers && halfBrothers == 0;
  bool get askBrothersGrandsons => askBrothersSons && brothersSons == 0;
  bool get askSistersSons => askBrothersGrandsons && brothersGrandsons == 0;
  bool get askGrandfather => askSistersSons && sistersSons == 0;
  bool get askGrandmother => askGrandfather && !grandfather;
  bool get askUncles => askGrandmother && !grandmother;
  bool get askUnclesSons => askUncles && uncles == 0;

  HinduFamily get family => HinduFamily(
    widows: widows,
    sons: sons,
    predeceasedSons: List.of(deadSons),
    unmarriedDaughters: askDaughters ? unmarriedDaughters : 0,
    marriedDaughters: askMarriedDaughters ? marriedDaughters : 0,
    daughtersSons: askDaughtersSons ? daughtersSons : 0,
    father: askFather && father,
    mother: askMother && mother,
    fullBrothers: askBrothers ? fullBrothers : 0,
    halfBrothers: askHalfBrothers ? halfBrothers : 0,
    brothersSons: askBrothersSons ? brothersSons : 0,
    brothersGrandsons: askBrothersGrandsons ? brothersGrandsons : 0,
    sistersSons: askSistersSons ? sistersSons : 0,
    grandfather: askGrandfather && grandfather,
    grandmother: askGrandmother && grandmother,
    uncles: askUncles ? uncles : 0,
    unclesSons: askUnclesSons ? unclesSons : 0,
  );
}

/// A Christian family under the Succession Act 1925.
class ChristianForm {
  bool spouse = false;
  int sons = 0;
  int daughters = 0;
  final List<PredeceasedChild> dead = [];
  bool father = false;
  bool mother = false;
  int brothers = 0;
  int sisters = 0;
  final List<PredeceasedChild> deadSiblings = [];
  bool paternalGrandfather = false;
  bool paternalGrandmother = false;
  bool maternalGrandfather = false;
  bool maternalGrandmother = false;
  int paternalUncles = 0;
  int paternalAunts = 0;
  int maternalUncles = 0;
  int maternalAunts = 0;
  int cousins = 0;

  bool get hasDescendants =>
      sons + daughters + dead.where((c) => c.hasChildren).length > 0;
  bool get askFather => !hasDescendants;
  bool get askMotherAndSiblings => askFather && !father;
  bool get _siblings =>
      brothers + sisters + deadSiblings.where((c) => c.hasChildren).length > 0;
  bool get askGrandparents => askMotherAndSiblings && !mother && !_siblings;
  bool get askThirdDegree =>
      askGrandparents &&
      !paternalGrandfather &&
      !paternalGrandmother &&
      !maternalGrandfather &&
      !maternalGrandmother;
  bool get askCousins =>
      askThirdDegree &&
      paternalUncles + paternalAunts + maternalUncles + maternalAunts == 0;

  ChristianFamily family(Gender deceased) {
    final ms = askMotherAndSiblings;
    final gp = askGrandparents;
    final third = askThirdDegree;
    return ChristianFamily(
      deceased: deceased,
      spouse: spouse,
      sons: sons,
      daughters: daughters,
      predeceased: List.of(dead),
      father: askFather && father,
      mother: ms && mother,
      brothers: ms ? brothers : 0,
      sisters: ms ? sisters : 0,
      deadSiblings: ms ? List.of(deadSiblings) : const [],
      paternalGrandfather: gp && paternalGrandfather,
      paternalGrandmother: gp && paternalGrandmother,
      maternalGrandfather: gp && maternalGrandfather,
      maternalGrandmother: gp && maternalGrandmother,
      paternalUncles: third ? paternalUncles : 0,
      paternalAunts: third ? paternalAunts : 0,
      maternalUncles: third ? maternalUncles : 0,
      maternalAunts: third ? maternalAunts : 0,
      cousins: askCousins ? cousins : 0,
    );
  }
}
