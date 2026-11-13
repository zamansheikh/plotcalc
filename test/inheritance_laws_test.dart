import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/inheritance/christian.dart';
import 'package:plotcalc/core/inheritance/dayabhaga.dart';

/// "kind#number" (with the dead parent's number for their children) →
/// fraction, checking the shares add up to the whole.
Map<String, String> shares(InheritanceResult r) {
  expect(r.total, Fraction.one, reason: 'shares must add up to the whole');
  return {
    for (final h in r.heirs)
      '${h.kind.name}${h.viaNumber != null ? '@${h.viaNumber}' : ''}'
              '${h.of > 1 ? '#${h.number}' : ''}':
          '${h.share}',
  };
}

Set<String> out(InheritanceResult r) => {
  for (final e in r.excluded) '${e.kind.name}:${e.reason.name}',
};

void main() {
  group('Christian (Succession Act 1925)', () {
    InheritanceResult c(ChristianFamily f) => ChristianSuccession.compute(f);

    test('widow and two children: a third each', () {
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              spouse: true,
              sons: 1,
              daughters: 1,
            ),
          ),
        ),
        {'wife': '1/3', 'son': '1/3', 'daughter': '1/3'},
      );
    });

    test('a dead child\'s children take that child\'s share (s.40)', () {
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              spouse: true,
              sons: 1,
              predeceased: [
                PredeceasedChild(Gender.female, sons: 1, daughters: 1),
              ],
            ),
          ),
        ),
        {
          'wife': '1/3',
          'son': '1/3',
          'grandson@1': '1/6',
          'granddaughter@1': '1/6',
        },
      );
    });

    test('Henry alive, John dead with 4, Mary dead with 1 (s.40 ill. i)', () {
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              sons: 1,
              predeceased: [
                PredeceasedChild(Gender.male, sons: 4),
                PredeceasedChild(Gender.female, daughters: 1),
              ],
            ),
          ),
        ),
        {
          'son': '1/3',
          'grandson@1#1': '1/12',
          'grandson@1#2': '1/12',
          'grandson@1#3': '1/12',
          'grandson@1#4': '1/12',
          'granddaughter@1': '1/3',
        },
      );
    });

    test('no child alive: grandchildren per head, not by branch (s.38)', () {
      final r = c(
        const ChristianFamily(
          deceased: Gender.male,
          predeceased: [
            PredeceasedChild(Gender.male, sons: 1),
            PredeceasedChild(Gender.female, sons: 3),
          ],
        ),
      );
      expect(r.heirs.map((h) => '${h.share}').toSet(), {'1/4'});
      expect(r.notes, contains(ResultNote.christianPerHead));
    });

    test('widower with no children and the father: half each', () {
      final r = c(
        const ChristianFamily(
          deceased: Gender.female,
          spouse: true,
          father: true,
          mother: true,
          brothers: 2,
        ),
      );
      expect(shares(r), {'husband': '1/2', 'father': '1/2'});
      expect(out(r), {'mother:father', 'brother:father'});
    });

    test('widow, mother and two brothers (father dead): 1/2, 1/6 each', () {
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              spouse: true,
              mother: true,
              brothers: 2,
            ),
          ),
        ),
        {
          'wife': '1/2',
          'mother': '1/6',
          'brother#1': '1/6',
          'brother#2': '1/6',
        },
      );
    });

    test('mother, a brother and a dead sister\'s two children (s.44)', () {
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              mother: true,
              brothers: 1,
              deadSiblings: [
                PredeceasedChild(Gender.female, sons: 1, daughters: 1),
              ],
            ),
          ),
        ),
        {
          'mother': '1/3',
          'brother': '1/3',
          'grandson@1': '1/6',
          'granddaughter@1': '1/6',
        },
      );
    });

    test('mother alone takes all (s.46); widow alone takes all (s.33(c))', () {
      expect(
        shares(c(const ChristianFamily(deceased: Gender.male, mother: true))),
        {'mother': '1'},
      );
      final r = c(const ChristianFamily(deceased: Gender.male, spouse: true));
      expect(shares(r), {'wife': '1'});
      expect(r.notes, contains(ResultNote.christianSpouseAllCheck));
    });

    test('both parents dead: brothers and sisters, a dead one\'s children', () {
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              brothers: 1,
              sisters: 1,
              deadSiblings: [PredeceasedChild(Gender.male, sons: 2)],
            ),
          ),
        ),
        {
          'brother': '1/3',
          'sister': '1/3',
          'grandson@1#1': '1/6',
          'grandson@1#2': '1/6',
        },
      );
    });

    test('nearest degree: a grandmother shuts out an uncle (s.48 ill. i)', () {
      final r = c(
        const ChristianFamily(
          deceased: Gender.male,
          spouse: true,
          paternalGrandmother: true,
          maternalUncles: 1,
        ),
      );
      expect(shares(r), {'wife': '1/2', 'paternalGrandmother': '1/2'});
      expect(out(r), {'maternalUncle:closer'});
      expect(
        shares(
          c(
            const ChristianFamily(
              deceased: Gender.male,
              paternalAunts: 1,
              maternalUncles: 1,
              maternalAunts: 1,
            ),
          ),
        ).values.toSet(),
        {'1/3'},
      );
    });

    test('nobody at all: the Government', () {
      final r = c(const ChristianFamily(deceased: Gender.male));
      expect(r.isEmpty, isTrue);
      expect(r.notes, [ResultNote.noHeirs]);
    });
  });

  group('Hindu (Dayabhaga, 1937 Act)', () {
    InheritanceResult h(HinduFamily f) => Dayabhaga.compute(f);

    test('widow and two sons: a third each, the widow for life', () {
      final r = h(const HinduFamily(widows: 1, sons: 2));
      expect(shares(r), {'wife': '1/3', 'son#1': '1/3', 'son#2': '1/3'});
      expect(r.heirs.first.lifeInterest, isTrue);
      expect(r.notes, contains(ResultNote.hinduLimitedEstate));
    });

    test('two widows share one son\'s share', () {
      expect(shares(h(const HinduFamily(widows: 2, sons: 2))), {
        'wife#1': '1/6',
        'wife#2': '1/6',
        'son#1': '1/3',
        'son#2': '1/3',
      });
    });

    test('a dead son\'s sons share his part', () {
      expect(
        shares(
          h(
            const HinduFamily(
              sons: 2,
              predeceasedSons: [PredeceasedSon(sons: 2)],
            ),
          ),
        ),
        {
          'son#1': '1/3',
          'son#2': '1/3',
          'grandson@1#1': '1/6',
          'grandson@1#2': '1/6',
        },
      );
    });

    test('a dead son\'s widow without sons takes as a son', () {
      final r = h(
        const HinduFamily(
          widows: 1,
          sons: 1,
          predeceasedSons: [PredeceasedSon(widow: true)],
        ),
      );
      expect(shares(r), {'wife': '1/3', 'son': '1/3', 'sonsWidow@1': '1/3'});
    });

    test('with her own son, she takes as a son\'s son (flagged unsettled)', () {
      final r = h(
        const HinduFamily(
          widows: 1,
          sons: 1,
          predeceasedSons: [PredeceasedSon(sons: 1, widow: true)],
        ),
      );
      expect(shares(r), {
        'wife': '1/3',
        'son': '1/3',
        'grandson@1': '1/6',
        'sonsWidow@1': '1/6',
      });
      expect(r.notes, contains(ResultNote.hinduSonsWidowUnsettled));
    });

    test('a widow with daughters only takes all; daughters wait', () {
      final r = h(const HinduFamily(widows: 1, unmarriedDaughters: 2));
      expect(shares(r), {'wife': '1'});
      expect(out(r), {'unmarriedDaughter:widowFirst'});
    });

    test('daughters: unmarried first, then married with a son', () {
      final r = h(
        const HinduFamily(
          unmarriedDaughters: 1,
          marriedDaughters: 1,
          father: true,
        ),
      );
      expect(shares(r), {'unmarriedDaughter': '1'});
      expect(out(r), {'marriedDaughter:unmarriedDaughter', 'father:closer'});
      expect(shares(h(const HinduFamily(marriedDaughters: 2))), {
        'marriedDaughter#1': '1/2',
        'marriedDaughter#2': '1/2',
      });
    });

    test('daughters\' sons per head; father before mother', () {
      expect(shares(h(const HinduFamily(daughtersSons: 5))).values.toSet(), {
        '1/5',
      });
      final r = h(const HinduFamily(father: true, mother: true));
      expect(shares(r), {'father': '1'});
      expect(out(r), {'mother:closer'});
      expect(
        h(const HinduFamily(mother: true)).heirs.single.lifeInterest,
        isTrue,
      );
    });

    test('a full brother shuts out a half brother; then nephews', () {
      final r = h(const HinduFamily(fullBrothers: 1, halfBrothers: 1));
      expect(shares(r), {'fullBrother': '1'});
      expect(out(r), {'paternalBrother:fullBrother'});
      expect(shares(h(const HinduFamily(sistersSons: 2, uncles: 1))), {
        'sistersSon#1': '1/2',
        'sistersSon#2': '1/2',
      });
    });
  });
}
