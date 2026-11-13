import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/export/sheet_summary.dart';
import '../../../core/inheritance/inheritance.dart';
import '../../../l10n/l10n.dart';

/// Words for the inheritance shares: who an heir is, why they take what
/// they take, why someone takes nothing, and notes on the whole result.
class InheritanceText {
  final AppLocalizations t;
  const InheritanceText(this.t);

  String kind(HeirKind k) => switch (k) {
    HeirKind.husband => t.inheritHeirHusband,
    HeirKind.wife => t.inheritHeirWife,
    HeirKind.son => t.inheritHeirSon,
    HeirKind.daughter => t.inheritHeirDaughter,
    HeirKind.grandson => t.inheritHeirGrandson,
    HeirKind.granddaughter => t.inheritHeirGranddaughter,
    HeirKind.father => t.inheritHeirFather,
    HeirKind.mother => t.inheritHeirMother,
    HeirKind.grandfather => t.inheritHeirGrandfather,
    HeirKind.paternalGrandmother => t.inheritHeirPaternalGrandmother,
    HeirKind.maternalGrandmother => t.inheritHeirMaternalGrandmother,
    HeirKind.fullBrother => t.inheritHeirFullBrother,
    HeirKind.fullSister => t.inheritHeirFullSister,
    HeirKind.paternalBrother => t.inheritHeirPaternalBrother,
    HeirKind.paternalSister => t.inheritHeirPaternalSister,
    HeirKind.maternalBrother => t.inheritHeirMaternalBrother,
    HeirKind.maternalSister => t.inheritHeirMaternalSister,
    HeirKind.fullNephew => t.inheritHeirFullNephew,
    HeirKind.paternalNephew => t.inheritHeirPaternalNephew,
    HeirKind.fullUncle => t.inheritHeirFullUncle,
    HeirKind.paternalUncle => t.inheritHeirPaternalUncle,
    HeirKind.fullCousin => t.inheritHeirFullCousin,
    HeirKind.paternalCousin => t.inheritHeirPaternalCousin,
    HeirKind.sonsWidow => t.inheritHeirSonsWidow,
    HeirKind.unmarriedDaughter => t.inheritHeirUnmarriedDaughter,
    HeirKind.marriedDaughter => t.inheritHeirMarriedDaughter,
    HeirKind.daughtersSon => t.inheritHeirDaughtersSon,
    HeirKind.daughtersDaughter => t.inheritHeirDaughtersDaughter,
    HeirKind.brother => t.inheritHeirBrother,
    HeirKind.sister => t.inheritHeirSister,
    HeirKind.grandNephew => t.inheritHeirGrandNephew,
    HeirKind.sistersSon => t.inheritHeirSistersSon,
    HeirKind.sistersDaughter => t.inheritHeirSistersDaughter,
    HeirKind.brothersDaughter => t.inheritHeirBrothersDaughter,
    HeirKind.maternalGrandfather => t.inheritHeirMaternalGrandfather,
    HeirKind.paternalAunt => t.inheritHeirPaternalAunt,
    HeirKind.maternalUncle => t.inheritHeirMaternalUncle,
    HeirKind.maternalAunt => t.inheritHeirMaternalAunt,
    HeirKind.cousin => t.inheritHeirCousin,
    HeirKind.paternalAuntConsanguine => t.inheritHeirPaternalAuntConsanguine,
    HeirKind.paternalAuntUterine => t.inheritHeirPaternalAuntUterine,
    HeirKind.fatherUterineBrother => t.inheritHeirFatherUterineBrother,
    HeirKind.maternalUncleConsanguine => t.inheritHeirMaternalUncleConsanguine,
    HeirKind.maternalUncleUterine => t.inheritHeirMaternalUncleUterine,
    HeirKind.maternalAuntConsanguine => t.inheritHeirMaternalAuntConsanguine,
    HeirKind.maternalAuntUterine => t.inheritHeirMaternalAuntUterine,
  };

  /// "Son 2", "Wife", "Late son 1's daughter", "Late son 1's wife". The
  /// parent's word is lowercased for English (Bengali has no case).
  String label(HeirShare h) {
    final viaKind = h.viaKind;
    if (viaKind == null) {
      return h.of > 1
          ? t.inheritNumbered(kind(h.kind), h.number)
          : kind(h.kind);
    }
    final base = h.kind == HeirKind.sonsWidow ? t.inheritViaWife : kind(h.kind);
    final self = h.of > 1 ? t.inheritNumbered(base, h.number) : base;
    final parent = t.inheritLate(kind(viaKind).toLowerCase(), h.viaNumber ?? 1);
    return t.inheritChildOf(parent, self);
  }

  String reason(ShareReason r) => switch (r) {
    ShareReason.husbandHalf => t.inheritWhyHusbandHalf,
    ShareReason.husbandQuarter => t.inheritWhyHusbandQuarter,
    ShareReason.wifeQuarter => t.inheritWhyWifeQuarter,
    ShareReason.wifeEighth => t.inheritWhyWifeEighth,
    ShareReason.sonResidue => t.inheritWhySonResidue,
    ShareReason.daughterWithSon => t.inheritWhyDaughterWithSon,
    ShareReason.daughterHalf => t.inheritWhyDaughterHalf,
    ShareReason.daughtersTwoThirds => t.inheritWhyDaughtersTwoThirds,
    ShareReason.fatherSixth => t.inheritWhyFatherSixth,
    ShareReason.fatherSixthAndRest => t.inheritWhyFatherSixthAndRest,
    ShareReason.fatherRest => t.inheritWhyFatherRest,
    ShareReason.grandfatherSixth => t.inheritWhyGrandfatherSixth,
    ShareReason.grandfatherSixthAndRest => t.inheritWhyGrandfatherSixthAndRest,
    ShareReason.grandfatherRest => t.inheritWhyGrandfatherRest,
    ShareReason.motherSixthChild => t.inheritWhyMotherSixthChild,
    ShareReason.motherSixthSiblings => t.inheritWhyMotherSixthSiblings,
    ShareReason.motherThird => t.inheritWhyMotherThird,
    ShareReason.motherThirdOfRest => t.inheritWhyMotherThirdOfRest,
    ShareReason.grandmotherSixth => t.inheritWhyGrandmotherSixth,
    ShareReason.uterineSixth => t.inheritWhyUterineSixth,
    ShareReason.uterineThird => t.inheritWhyUterineThird,
    ShareReason.sisterHalf => t.inheritWhySisterHalf,
    ShareReason.sistersTwoThirds => t.inheritWhySistersTwoThirds,
    ShareReason.paternalSisterSixth => t.inheritWhyPaternalSisterSixth,
    ShareReason.siblingsResidue => t.inheritWhySiblingsResidue,
    ShareReason.sisterWithDaughters => t.inheritWhySisterWithDaughters,
    ShareReason.agnateResidue => t.inheritWhyAgnateResidue,
    ShareReason.represented => t.inheritWhyRepresented,
    ShareReason.sole => t.inheritWhySole,
    ShareReason.hinduSons => t.inheritWhyHinduSons,
    ShareReason.hinduWidow => t.inheritWhyHinduWidow,
    ShareReason.hinduSonsLine => t.inheritWhyHinduSonsLine,
    ShareReason.hinduSonsWidowAsSon => t.inheritWhyHinduSonsWidowAsSon,
    ShareReason.hinduSonsWidowAsGrandson =>
      t.inheritWhyHinduSonsWidowAsGrandson,
    ShareReason.hinduUnmarriedDaughters => t.inheritWhyHinduUnmarriedDaughters,
    ShareReason.hinduMarriedDaughters => t.inheritWhyHinduMarriedDaughters,
    ShareReason.hinduDaughtersSons => t.inheritWhyHinduDaughtersSons,
    ShareReason.hinduFather => t.inheritWhyHinduFather,
    ShareReason.hinduMother => t.inheritWhyHinduMother,
    ShareReason.hinduBrothers => t.inheritWhyHinduBrothers,
    ShareReason.hinduNephews => t.inheritWhyHinduNephews,
    ShareReason.hinduGrandNephews => t.inheritWhyHinduGrandNephews,
    ShareReason.hinduSistersSons => t.inheritWhyHinduSistersSons,
    ShareReason.hinduGrandfather => t.inheritWhyHinduGrandfather,
    ShareReason.hinduGrandmother => t.inheritWhyHinduGrandmother,
    ShareReason.hinduUncles => t.inheritWhyHinduUncles,
    ShareReason.hinduCousins => t.inheritWhyHinduCousins,
    ShareReason.christianSpouseThird => t.inheritWhyChristianSpouseThird,
    ShareReason.christianSpouseHalf => t.inheritWhyChristianSpouseHalf,
    ShareReason.christianSpouseAll => t.inheritWhyChristianSpouseAll,
    ShareReason.christianChildren => t.inheritWhyChristianChildren,
    ShareReason.christianChildOfDead => t.inheritWhyChristianChildOfDead,
    ShareReason.christianGrandchildrenPerHead =>
      t.inheritWhyChristianGrandchildrenPerHead,
    ShareReason.christianFather => t.inheritWhyChristianFather,
    ShareReason.christianMotherAndSiblings =>
      t.inheritWhyChristianMotherAndSiblings,
    ShareReason.christianMother => t.inheritWhyChristianMother,
    ShareReason.christianSiblings => t.inheritWhyChristianSiblings,
    ShareReason.christianSiblingsChildren =>
      t.inheritWhyChristianSiblingsChildren,
    ShareReason.christianNearest => t.inheritWhyChristianNearest,
    ShareReason.distantKindred => t.inheritWhyDistantKindred,
    ShareReason.distantSiblingLine => t.inheritWhyDistantSiblingLine,
    ShareReason.distantUnclesAunts => t.inheritWhyDistantUnclesAunts,
  };

  String exclusion(Exclusion e) => t.inheritOut(
    e.viaKind == null
        ? kind(e.kind)
        : t.inheritChildrenOf(
            t.inheritLate(kind(e.viaKind!).toLowerCase(), e.viaNumber ?? 1),
          ),
    switch (e.reason) {
      ExclusionReason.son => t.inheritOutSon,
      ExclusionReason.father => t.inheritOutFather,
      ExclusionReason.grandfather => t.inheritOutGrandfather,
      ExclusionReason.mother => t.inheritOutMother,
      ExclusionReason.child => t.inheritOutChild,
      ExclusionReason.fullBrother => t.inheritOutFullBrother,
      ExclusionReason.paternalBrother => t.inheritOutPaternalBrother,
      ExclusionReason.sisterWithDaughters => t.inheritOutSisterWithDaughters,
      ExclusionReason.twoFullSisters => t.inheritOutTwoFullSisters,
      ExclusionReason.closerAgnate => t.inheritOutCloser,
      ExclusionReason.nothingLeft => t.inheritOutNothingLeft,
      ExclusionReason.maleLine => t.inheritOutMaleLine,
      ExclusionReason.widowFirst => t.inheritOutWidowFirst,
      ExclusionReason.unmarriedDaughter => t.inheritOutUnmarriedDaughter,
      ExclusionReason.closer => t.inheritOutCloserKin,
    },
  );

  String? adjustment(Adjustment a) => switch (a) {
    Adjustment.none => null,
    Adjustment.awl => t.inheritAwl,
    Adjustment.radd => t.inheritRadd,
    Adjustment.spouseTakesRest => t.inheritSpouseRest,
  };

  String note(ResultNote n) => switch (n) {
    ResultNote.hinduLimitedEstate => t.inheritNoteHinduLimited,
    ResultNote.hinduSonsWidowUnsettled => t.inheritNoteHinduSonsWidow,
    ResultNote.christianSpouseAllCheck => t.inheritNoteChristianSpouseAll,
    ResultNote.christianPerHead => t.inheritNoteChristianPerHead,
    ResultNote.noHeirs => t.inheritNoteNoHeirs,
    ResultNote.muslimDistantKindred => t.inheritNoteDistantKindred,
    ResultNote.distantGrandfatherUnsettled => t.inheritNoteDistantGrandfather,
    ResultNote.distantAwl => t.inheritNoteDistantAwl,
  };

  /// A fraction in the app's digits, e.g. "১/৮".
  static String fraction(Fraction f) {
    final n = NumberFormat.decimalPattern();
    return f.den == 1
        ? n.format(f.num)
        : '${n.format(f.num)}/${n.format(f.den)}';
  }

  static String percent(Fraction f) => SheetSummary.percent(f.value);
}
