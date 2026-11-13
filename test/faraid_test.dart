import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/inheritance/faraid.dart';

/// Shares by kind as "kind#number" → fraction text, for compact checks.
Map<String, String> shares(Family f) {
  final r = Faraid.compute(f);
  expect(r.total, Fraction.one, reason: 'shares must add up to the whole');
  return {
    for (final h in r.heirs)
      '${h.kind.name}${h.of > 1 || h.via != null ? '#${h.via ?? ''}${h.number}' : ''}':
          '${h.share}',
  };
}

Set<String> excluded(Family f) => {
  for (final e in Faraid.compute(f).excluded) '${e.kind.name}:${e.reason.name}',
};

void main() {
  group('Fraction', () {
    test('reduces and orders', () {
      expect(Fraction(6, 8), Fraction(3, 4));
      expect(Fraction(1, 2) + Fraction(1, 3), Fraction(5, 6));
      expect(Fraction(2, -4), Fraction(-1, 2));
      expect(Fraction(1, 3) < Fraction(1, 2), isTrue);
      expect(Fraction(7, 8).toString(), '7/8');
    });
  });

  group('textbook cases (Hanafi)', () {
    test('wife, son, daughter (the app compared against)', () {
      expect(
        shares(
          const Family(deceased: Gender.male, wives: 1, sons: 1, daughters: 1),
        ),
        {'wife': '1/8', 'son': '7/12', 'daughter': '7/24'},
      );
    });

    test('wife, two sons, a daughter and the mother: base 120', () {
      final f = const Family(
        deceased: Gender.male,
        wives: 1,
        sons: 2,
        daughters: 1,
        mother: true,
      );
      expect(shares(f), {
        'wife': '1/8',
        'son#1': '17/60',
        'son#2': '17/60',
        'daughter': '17/120',
        'mother': '1/6',
      });
      final r = Faraid.compute(f);
      expect(r.base, 120);
      expect([for (final h in r.heirs) r.partsOf(h)], [15, 34, 34, 17, 20]);
    });

    test('husband, father, mother: the mother takes a third of the rest', () {
      expect(
        shares(
          const Family(
            deceased: Gender.female,
            husband: true,
            father: true,
            mother: true,
          ),
        ),
        {'husband': '1/2', 'father': '1/3', 'mother': '1/6'},
      );
      expect(
        shares(
          const Family(
            deceased: Gender.male,
            wives: 1,
            father: true,
            mother: true,
          ),
        ),
        {'wife': '1/4', 'father': '1/2', 'mother': '1/4'},
      );
    });

    test('awl: husband, two full sisters, mother', () {
      final f = const Family(
        deceased: Gender.female,
        husband: true,
        fullSisters: 2,
        mother: true,
      );
      expect(shares(f), {
        'husband': '3/8',
        'mother': '1/8',
        'fullSister#1': '1/4',
        'fullSister#2': '1/4',
      });
      final r = Faraid.compute(f);
      expect(r.adjustment, Adjustment.awl);
      expect(r.base, 8);
    });

    test('awl: husband, daughter, father, mother → base 13', () {
      final r = Faraid.compute(
        const Family(
          deceased: Gender.female,
          husband: true,
          daughters: 1,
          father: true,
          mother: true,
        ),
      );
      expect(r.adjustment, Adjustment.awl);
      expect(r.base, 13);
      expect(
        {for (final h in r.heirs) h.kind.name: r.partsOf(h)},
        {'husband': 3, 'daughter': 6, 'father': 2, 'mother': 2},
      );
    });

    test('radd: wife, two daughters, mother — the wife keeps 1/8', () {
      final f = const Family(
        deceased: Gender.male,
        wives: 1,
        daughters: 2,
        mother: true,
      );
      expect(shares(f), {
        'wife': '1/8',
        'daughter#1': '7/20',
        'daughter#2': '7/20',
        'mother': '7/40',
      });
      expect(Faraid.compute(f).adjustment, Adjustment.radd);
    });

    test('an only daughter takes everything by radd', () {
      final r = Faraid.compute(
        const Family(deceased: Gender.male, daughters: 1),
      );
      expect(r.heirs.single.share, Fraction.one);
      expect(r.adjustment, Adjustment.radd);
    });

    test('a wife alone takes the rest too', () {
      final r = Faraid.compute(const Family(deceased: Gender.male, wives: 2));
      expect([for (final h in r.heirs) '${h.share}'], ['1/2', '1/2']);
      expect(r.adjustment, Adjustment.spouseTakesRest);
    });

    test('full brother gets nothing when fixed shares take all', () {
      final f = const Family(
        deceased: Gender.female,
        husband: true,
        mother: true,
        maternalBrothers: 2,
        fullBrothers: 1,
      );
      expect(shares(f), {
        'husband': '1/2',
        'mother': '1/6',
        'maternalBrother#1': '1/6',
        'maternalBrother#2': '1/6',
      });
      expect(excluded(f), {'fullBrother:nothingLeft'});
    });

    test('a sister takes the rest with a daughter', () {
      expect(
        shares(
          const Family(deceased: Gender.male, daughters: 1, fullSisters: 1),
        ),
        {'daughter': '1/2', 'fullSister': '1/2'},
      );
      // …and then shuts out a consanguine brother.
      final f = const Family(
        deceased: Gender.male,
        daughters: 1,
        fullSisters: 1,
        paternalBrothers: 1,
      );
      expect(shares(f), {'daughter': '1/2', 'fullSister': '1/2'});
      expect(excluded(f), {'paternalBrother:sisterWithDaughters'});
    });

    test('one full sister and consanguine sisters: 1/2 and 1/6, then radd', () {
      expect(
        shares(
          const Family(
            deceased: Gender.male,
            fullSisters: 1,
            paternalSisters: 2,
          ),
        ),
        {
          'fullSister': '3/4',
          'paternalSister#1': '1/8',
          'paternalSister#2': '1/8',
        },
      );
    });

    test('two full sisters shut out consanguine sisters', () {
      final f = const Family(
        deceased: Gender.male,
        fullSisters: 2,
        paternalSisters: 1,
        fullUncles: 1,
      );
      expect(shares(f), {
        'fullSister#1': '1/3',
        'fullSister#2': '1/3',
        'fullUncle': '1/3',
      });
      expect(excluded(f), {'paternalSister:twoFullSisters'});
    });

    test('the father excludes brothers, who still cut the mother to 1/6', () {
      final f = const Family(
        deceased: Gender.male,
        father: true,
        mother: true,
        fullBrothers: 2,
      );
      expect(shares(f), {'father': '5/6', 'mother': '1/6'});
      expect(excluded(f), {'fullBrother:father'});
      expect(Faraid.compute(f).siblingsReduceMother, isTrue);
    });

    test('the grandfather stands in for the father and excludes brothers', () {
      final f = const Family(
        deceased: Gender.male,
        grandfather: true,
        fullBrothers: 1,
        wives: 1,
      );
      expect(shares(f), {'wife': '1/4', 'grandfather': '3/4'});
      expect(excluded(f), {'fullBrother:grandfather'});
      expect(
        excluded(
          const Family(deceased: Gender.male, father: true, grandfather: true),
        ),
        {'grandfather:father'},
      );
    });

    test('daughter and father: 1/2 each (father 1/6 and the rest)', () {
      final f = const Family(deceased: Gender.male, daughters: 1, father: true);
      expect(shares(f), {'daughter': '1/2', 'father': '1/2'});
      expect(
        Faraid.compute(f).heirs.last.reason,
        ShareReason.fatherSixthAndRest,
      );
    });

    test('grandmothers share a sixth; the mother excludes them', () {
      expect(
        shares(
          const Family(
            deceased: Gender.male,
            paternalGrandmother: true,
            maternalGrandmother: true,
            fullUncles: 1,
          ),
        ),
        {
          'paternalGrandmother': '1/12',
          'maternalGrandmother': '1/12',
          'fullUncle': '5/6',
        },
      );
      expect(
        excluded(
          const Family(
            deceased: Gender.male,
            mother: true,
            paternalGrandmother: true,
            maternalGrandmother: true,
          ),
        ),
        {'paternalGrandmother:mother', 'maternalGrandmother:mother'},
      );
    });

    test('the nearest of the male line takes the rest', () {
      final f = const Family(
        deceased: Gender.male,
        wives: 1,
        fullNephews: 2,
        fullUncles: 1,
      );
      expect(shares(f), {
        'wife': '1/4',
        'fullNephew#1': '3/8',
        'fullNephew#2': '3/8',
      });
      expect(excluded(f), {'fullUncle:closerAgnate'});
    });

    test('uterine siblings: equal shares, shut out by a child', () {
      expect(
        shares(
          const Family(
            deceased: Gender.male,
            maternalBrothers: 1,
            maternalSisters: 1,
            fullUncles: 1,
          ),
        ),
        {'maternalBrother': '1/6', 'maternalSister': '1/6', 'fullUncle': '2/3'},
      );
      expect(
        excluded(
          const Family(deceased: Gender.male, daughters: 1, maternalSisters: 1),
        ),
        {'maternalSister:child'},
      );
    });
  });

  group('1961 ordinance: children of a child who died earlier', () {
    test('take the share their father would have had', () {
      final f = Family(
        deceased: Gender.male,
        wives: 1,
        sons: 1,
        predeceased: const [
          PredeceasedChild(Gender.male, sons: 1, daughters: 1),
        ],
      );
      expect(shares(f), {
        'wife': '1/8',
        'son': '7/16',
        'grandson#01': '7/24',
        'granddaughter#01': '7/48',
      });
    });

    test('count as a child for everyone else', () {
      // A predeceased daughter's child: the wife takes 1/8, brothers nothing.
      final f = Family(
        deceased: Gender.male,
        wives: 1,
        fullBrothers: 1,
        predeceased: const [PredeceasedChild(Gender.female, sons: 2)],
      );
      final s = shares(f);
      expect(s['wife'], '1/8');
      expect(s['grandson#01'], '1/4');
      expect(s['fullBrother'], '3/8');
    });

    test('a child who died leaving no children changes nothing', () {
      expect(
        shares(
          Family(
            deceased: Gender.male,
            wives: 1,
            fullBrothers: 1,
            predeceased: const [PredeceasedChild(Gender.male)],
          ),
        ),
        {'wife': '1/4', 'fullBrother': '3/4'},
      );
    });
  });

  group('distant kindred (Mulla, Imam Muhammad)', () {
    Map<String, String> dk(Family f) {
      final r = Faraid.compute(f);
      expect(r.total, Fraction.one, reason: 'shares add up to the whole');
      expect(r.notes, contains(ResultNote.muslimDistantKindred));
      return {
        for (final h in r.heirs)
          '${h.kind.name}${h.viaKind != null ? '@${h.viaKind!.name}${h.viaNumber}' : ''}${h.of > 1 ? '#${h.number}' : ''}':
              '${h.share}',
      };
    }

    test('the spouse keeps the usual share; the rest goes to them', () {
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            wives: 1,
            distant: DistantKin(maternalGrandfather: true),
          ),
        ),
        {'wife': '1/4', 'maternalGrandfather': '3/4'},
      );
      expect(
        dk(
          const Family(
            deceased: Gender.female,
            husband: true,
            distant: DistantKin(fullMaternalUncles: 1),
          ),
        ),
        {'husband': '1/2', 'maternalUncle': '1/2'},
      );
    });

    test("full brother's daughter and full sister's son: 2/3 and 1/3", () {
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            distant: DistantKin(
              siblingLines: [
                SiblingLine(Blood.full, Gender.male, daughters: 1),
                SiblingLine(Blood.full, Gender.female, sons: 1),
              ],
            ),
          ),
        ),
        {'granddaughter@fullBrother1': '2/3', 'grandson@fullSister1': '1/3'},
      );
    });

    test('Mulla s.62 ill. (a): full and uterine lines', () {
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            distant: DistantKin(
              siblingLines: [
                SiblingLine(Blood.full, Gender.male, daughters: 1),
                SiblingLine(Blood.full, Gender.female, sons: 1, daughters: 1),
                SiblingLine(Blood.uterine, Gender.male, daughters: 1),
                SiblingLine(
                  Blood.uterine,
                  Gender.female,
                  sons: 1,
                  daughters: 1,
                ),
              ],
            ),
          ),
        ),
        {
          'granddaughter@fullBrother1': '1/3',
          'grandson@fullSister1': '2/9',
          'granddaughter@fullSister1': '1/9',
          'granddaughter@maternalBrother1': '1/9',
          'grandson@maternalSister1': '1/9',
          'granddaughter@maternalSister1': '1/9',
        },
      );
    });

    test("full sister's son and uterine brother's son: 3/4 and 1/4", () {
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            distant: DistantKin(
              siblingLines: [
                SiblingLine(Blood.full, Gender.female, sons: 1),
                SiblingLine(Blood.uterine, Gender.male, sons: 1),
              ],
            ),
          ),
        ),
        {'grandson@fullSister1': '3/4', 'grandson@maternalBrother1': '1/4'},
      );
    });

    test('Akbar Ali v. Adar Bibi: two widows, a full sister\'s four '
        "children, a consanguine brother's two daughters", () {
      final s = dk(
        const Family(
          deceased: Gender.male,
          wives: 2,
          distant: DistantKin(
            siblingLines: [
              SiblingLine(Blood.full, Gender.female, sons: 2, daughters: 2),
              SiblingLine(Blood.consanguine, Gender.male, daughters: 2),
            ],
          ),
        ),
      );
      expect(s['wife#1'], '1/8');
      expect(s['wife#2'], '1/8');
      // The sister's line 2/3: sons 2/9 each, daughters 1/9 each.
      expect(s['grandson@fullSister1#1'], '2/9');
      expect(s['granddaughter@fullSister1#1'], '1/9');
      // The residue, 1/12, to the brother's two daughters.
      expect(s['granddaughter@paternalBrother1#1'], '1/24');
    });

    test(
      "a full brother's sons are nephews (residuaries), not distant kin",
      () {
        final r = Faraid.compute(
          const Family(
            deceased: Gender.male,
            fullNephews: 1,
            distant: DistantKin(
              maternalGrandfather: true,
              fullMaternalAunts: 1,
            ),
          ),
        );
        expect(
          {for (final h in r.heirs) h.kind.name: '${h.share}'},
          {'fullNephew': '1'},
        );
        expect(r.excluded.length, 2);
      },
    );

    test('uncles and aunts: father\'s side 2/3, mother\'s side 1/3', () {
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            distant: DistantKin(fullPaternalAunts: 1, fullMaternalUncles: 1),
          ),
        ),
        {'paternalAunt': '2/3', 'maternalUncle': '1/3'},
      );
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            distant: DistantKin(
              fullPaternalAunts: 1,
              fullMaternalUncles: 1,
              fullMaternalAunts: 1,
            ),
          ),
        ),
        {'paternalAunt': '2/3', 'maternalUncle': '2/9', 'maternalAunt': '1/9'},
      );
    });

    test('Mulla s.64 ill. (c): uterine on the father\'s side, full on the '
        "mother's", () {
      expect(
        dk(
          const Family(
            deceased: Gender.male,
            distant: DistantKin(
              fatherUterineBrothers: 1,
              uterinePaternalAunts: 1,
              fullMaternalUncles: 1,
              fullMaternalAunts: 1,
            ),
          ),
        ),
        {
          'fatherUterineBrother': '4/9',
          'paternalAuntUterine': '2/9',
          'maternalUncle': '2/9',
          'maternalAunt': '1/9',
        },
      );
    });

    test('a full paternal aunt shuts out the father\'s uterine brother', () {
      final r = Faraid.compute(
        const Family(
          deceased: Gender.male,
          distant: DistantKin(fullPaternalAunts: 1, fatherUterineBrothers: 1),
        ),
      );
      expect(r.heirs.single.kind, HeirKind.paternalAunt);
      expect(r.heirs.single.share, Fraction.one);
      expect(r.excluded.single.kind, HeirKind.fatherUterineBrother);
    });

    test("the mother's father comes first (Mulla), with a note", () {
      final r = Faraid.compute(
        const Family(
          deceased: Gender.male,
          distant: DistantKin(
            maternalGrandfather: true,
            siblingLines: [SiblingLine(Blood.full, Gender.female, sons: 1)],
          ),
        ),
      );
      expect(r.heirs.single.kind, HeirKind.maternalGrandfather);
      expect(r.notes, contains(ResultNote.distantGrandfatherUnsettled));
    });
  });

  test('random families always add up to exactly the whole', () {
    final rnd = math.Random(7);
    int n(int max) => rnd.nextInt(max + 1);
    bool b() => rnd.nextBool();
    var checked = 0;
    for (var i = 0; i < 4000; i++) {
      final male = b();
      final f = Family(
        deceased: male ? Gender.male : Gender.female,
        husband: !male && b(),
        wives: male ? n(4) : 0,
        sons: rnd.nextInt(4) == 0 ? n(3) : 0,
        daughters: rnd.nextInt(3) == 0 ? n(3) : 0,
        predeceased: [
          if (rnd.nextInt(6) == 0)
            PredeceasedChild(
              b() ? Gender.male : Gender.female,
              sons: n(2),
              daughters: n(2),
            ),
        ],
        father: rnd.nextInt(3) == 0,
        mother: b(),
        grandfather: rnd.nextInt(4) == 0,
        paternalGrandmother: rnd.nextInt(4) == 0,
        maternalGrandmother: rnd.nextInt(4) == 0,
        fullBrothers: rnd.nextInt(3) == 0 ? n(3) : 0,
        fullSisters: rnd.nextInt(3) == 0 ? n(3) : 0,
        paternalBrothers: rnd.nextInt(4) == 0 ? n(2) : 0,
        paternalSisters: rnd.nextInt(4) == 0 ? n(2) : 0,
        maternalBrothers: rnd.nextInt(4) == 0 ? n(2) : 0,
        maternalSisters: rnd.nextInt(4) == 0 ? n(2) : 0,
        fullNephews: rnd.nextInt(5) == 0 ? n(2) : 0,
        paternalUncles: rnd.nextInt(5) == 0 ? n(2) : 0,
        fullCousins: rnd.nextInt(6) == 0 ? n(2) : 0,
        distant: rnd.nextInt(3) == 0
            ? DistantKin(
                maternalGrandfather: rnd.nextInt(5) == 0,
                siblingLines: [
                  for (var k = 0; k < n(2); k++)
                    SiblingLine(
                      Blood.values[rnd.nextInt(3)],
                      b() ? Gender.male : Gender.female,
                      sons: n(2),
                      daughters: n(2),
                    ),
                ],
                fullPaternalAunts: rnd.nextInt(3) == 0 ? n(2) : 0,
                uterinePaternalAunts: rnd.nextInt(4) == 0 ? n(1) : 0,
                fatherUterineBrothers: rnd.nextInt(4) == 0 ? n(1) : 0,
                fullMaternalUncles: rnd.nextInt(3) == 0 ? n(2) : 0,
                consanguineMaternalAunts: rnd.nextInt(4) == 0 ? n(2) : 0,
                uterineMaternalAunts: rnd.nextInt(4) == 0 ? n(1) : 0,
              )
            : const DistantKin(),
      );
      final r = Faraid.compute(f);
      if (!f.anyone) {
        expect(r.isEmpty, isTrue);
        continue;
      }
      expect(r.isEmpty, isFalse, reason: 'someone always inherits');
      expect(r.total, Fraction.one, reason: 'family $i');
      expect(
        r.heirs.fold(0, (s, h) => s + r.partsOf(h)),
        r.base,
        reason: 'parts add up to the base',
      );
      for (final h in r.heirs) {
        expect(h.share.isPositive, isTrue);
      }
      checked++;
    }
    expect(checked, greaterThan(3000));
  });
}
