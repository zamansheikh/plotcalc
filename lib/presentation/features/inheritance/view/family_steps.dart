import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/inheritance/dayabhaga.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../inheritance_forms.dart';

/// The "who survived them?" step, one per law. Each edits its form in place
/// and calls [onChanged]; questions appear only when the answer could
/// change a share.
class MuslimFamilyStep extends StatelessWidget {
  final MuslimForm form;
  final Gender deceased;
  final Color accent;
  final VoidCallback onChanged;
  const MuslimFamilyStep({
    super.key,
    required this.form,
    required this.deceased,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final f = form;
    final rows = _Rows(accent, onChanged);
    final who = f.hasSon
        ? t.inheritWhoSon
        : f.father
        ? t.inheritWhoFather
        : t.inheritWhoGrandfather;

    final more = <Widget>[
      if (f.askGrandfather)
        rows.toggle(
          'grandfather',
          t.inheritHeirGrandfather,
          f.grandfather,
          (v) => f.grandfather = v,
          sub: t.inheritSubGrandfather,
        ),
      if (f.askPaternalGrandmother)
        rows.toggle(
          'paternalGrandmother',
          t.inheritHeirPaternalGrandmother,
          f.paternalGrandmother,
          (v) => f.paternalGrandmother = v,
          sub: t.inheritSubPaternalGrandmother,
        ),
      if (f.askMaternalGrandmother)
        rows.toggle(
          'maternalGrandmother',
          t.inheritHeirMaternalGrandmother,
          f.maternalGrandmother,
          (v) => f.maternalGrandmother = v,
          sub: t.inheritSubMaternalGrandmother,
        ),
      if (f.askSiblings) ...[
        rows.count(
          'fullBrothers',
          t.inheritHeirFullBrother,
          f.fullBrothers,
          (v) => f.fullBrothers = v,
          sub: t.inheritSubFull,
        ),
        rows.count(
          'fullSisters',
          t.inheritHeirFullSister,
          f.fullSisters,
          (v) => f.fullSisters = v,
          sub: t.inheritSubFull,
        ),
        InheritExpander(
          key: const ValueKey('inherit-half'),
          label: t.inheritHalfSiblings,
          open: f.halfSiblingsOpen,
          count:
              f.paternalBrothers +
              f.paternalSisters +
              f.maternalBrothers +
              f.maternalSisters,
          onTap: () {
            f.halfSiblingsOpen = !f.halfSiblingsOpen;
            onChanged();
          },
        ),
        if (f.halfSiblingsOpen) ...[
          rows.count(
            'paternalBrothers',
            t.inheritHeirPaternalBrother,
            f.paternalBrothers,
            (v) => f.paternalBrothers = v,
            sub: t.inheritSubPaternal,
          ),
          rows.count(
            'paternalSisters',
            t.inheritHeirPaternalSister,
            f.paternalSisters,
            (v) => f.paternalSisters = v,
            sub: t.inheritSubPaternal,
          ),
          rows.count(
            'maternalBrothers',
            t.inheritHeirMaternalBrother,
            f.maternalBrothers,
            (v) => f.maternalBrothers = v,
            sub: t.inheritSubMaternal,
          ),
          rows.count(
            'maternalSisters',
            t.inheritHeirMaternalSister,
            f.maternalSisters,
            (v) => f.maternalSisters = v,
            sub: t.inheritSubMaternal,
          ),
        ],
        if (!f.siblingsInherit) InheritNote(t.inheritSiblingsForMother),
      ],
      if (f.askMaleLine) ...[
        rows.count(
          'fullNephews',
          t.inheritHeirFullNephew,
          f.fullNephews,
          (v) => f.fullNephews = v,
          sub: t.inheritSubFullNephew,
        ),
        rows.count(
          'paternalNephews',
          t.inheritHeirPaternalNephew,
          f.paternalNephews,
          (v) => f.paternalNephews = v,
          sub: t.inheritSubPaternalNephew,
        ),
      ],
      if (f.askUncles) ...[
        rows.count(
          'fullUncles',
          t.inheritHeirFullUncle,
          f.fullUncles,
          (v) => f.fullUncles = v,
          sub: t.inheritSubFullUncle,
        ),
        rows.count(
          'paternalUncles',
          t.inheritHeirPaternalUncle,
          f.paternalUncles,
          (v) => f.paternalUncles = v,
          sub: t.inheritSubPaternalUncle,
        ),
      ],
      if (f.askCousins) ...[
        rows.count(
          'fullCousins',
          t.inheritHeirFullCousin,
          f.fullCousins,
          (v) => f.fullCousins = v,
          sub: t.inheritSubFullCousin,
        ),
        rows.count(
          'paternalCousins',
          t.inheritHeirPaternalCousin,
          f.paternalCousins,
          (v) => f.paternalCousins = v,
          sub: t.inheritSubPaternalCousin,
        ),
      ],
      if (!f.askSiblings) InheritNote(t.inheritHiddenBy(who)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        InheritSection(
          title: t.inheritFamily,
          children: [
            if (deceased == Gender.male)
              rows.count(
                'wives',
                t.inheritHeirWife,
                f.wives,
                (v) => f.wives = v,
                max: 4,
                sub: t.inheritWivesMax,
              )
            else
              rows.toggle(
                'husband',
                t.inheritHeirHusband,
                f.husband,
                (v) => f.husband = v,
              ),
            rows.count('sons', t.inheritHeirSon, f.sons, (v) => f.sons = v),
            rows.count(
              'daughters',
              t.inheritHeirDaughter,
              f.daughters,
              (v) => f.daughters = v,
            ),
            ..._deadChildCards(
              context,
              f.dead,
              accent,
              onChanged,
              title: t.inheritPredeceasedTitle,
              male: t.inheritHeirSon,
              female: t.inheritHeirDaughter,
              note: t.inheritPredeceasedNote,
            ),
            InheritAddRow(
              key: const ValueKey('inherit-add-dead'),
              label: t.inheritPredeceasedAdd,
              sub: t.inheritPredeceasedAddSub,
              onTap: () {
                f.dead.add(const PredeceasedChild(Gender.male, sons: 1));
                onChanged();
              },
            ),
            rows.toggle(
              'father',
              t.inheritHeirFather,
              f.father,
              (v) => f.father = v,
            ),
            rows.toggle(
              'mother',
              t.inheritHeirMother,
              f.mother,
              (v) => f.mother = v,
            ),
          ],
        ),
        const SizedBox(height: 14),
        InheritSection(title: t.inheritMore, children: more),
        if (f.askDistant(deceased)) ...[
          const SizedBox(height: 14),
          InheritSection(
            title: t.inheritDistantTitle,
            children: _distant(context, rows),
          ),
          const SizedBox(height: 12),
          Text(t.inheritDistantBeyond, style: AppTypography.bodyDim),
        ] else ...[
          const SizedBox(height: 12),
          Text(t.inheritDistant, style: AppTypography.bodyDim),
        ],
      ],
    );
  }

  List<Widget> _distant(BuildContext context, _Rows rows) {
    final t = context.l10n;
    final f = form;
    Widget count(String id, String label, int value, ValueChanged<int> set) =>
        rows.count(id, label, value, set);
    return [
      InheritNote(t.inheritDistantIntro),
      rows.toggle(
        'maternalGrandfather',
        t.inheritHeirMaternalGrandfather,
        f.maternalGrandfather,
        (v) => f.maternalGrandfather = v,
        sub: t.inheritSubMaternalGrandfather,
      ),
      if (f.askLines(deceased)) ...[
        for (var i = 0; i < f.lines.length; i++)
          _LineCard(
            key: ValueKey('inherit-line-$i'),
            index: i,
            line: f.lines[i],
            accent: accent,
            onChanged: (l) {
              f.lines[i] = l;
              onChanged();
            },
            onRemove: () {
              f.lines.removeAt(i);
              onChanged();
            },
          ),
        InheritAddRow(
          key: const ValueKey('inherit-add-line'),
          label: t.inheritLineAdd,
          sub: t.inheritLineAddSub,
          onTap: () {
            f.lines.add(const SiblingLine(Blood.full, Gender.female, sons: 1));
            onChanged();
          },
        ),
      ],
      if (f.askAuntsUncles(deceased)) ...[
        count(
          'fullPaternalAunts',
          t.inheritHeirPaternalAunt,
          f.fullPaternalAunts,
          (v) => f.fullPaternalAunts = v,
        ),
        count(
          'fullMaternalUncles',
          t.inheritHeirMaternalUncle,
          f.fullMaternalUncles,
          (v) => f.fullMaternalUncles = v,
        ),
        count(
          'fullMaternalAunts',
          t.inheritHeirMaternalAunt,
          f.fullMaternalAunts,
          (v) => f.fullMaternalAunts = v,
        ),
        InheritExpander(
          key: const ValueKey('inherit-half-aunts'),
          label: t.inheritAuntsHalf,
          open: f.halfAuntsOpen,
          count:
              f.consanguinePaternalAunts +
              f.uterinePaternalAunts +
              f.fatherUterineBrothers +
              f.consanguineMaternalUncles +
              f.uterineMaternalUncles +
              f.consanguineMaternalAunts +
              f.uterineMaternalAunts,
          onTap: () {
            f.halfAuntsOpen = !f.halfAuntsOpen;
            onChanged();
          },
        ),
        if (f.halfAuntsOpen) ...[
          count(
            'consanguinePaternalAunts',
            t.inheritHeirPaternalAuntConsanguine,
            f.consanguinePaternalAunts,
            (v) => f.consanguinePaternalAunts = v,
          ),
          count(
            'uterinePaternalAunts',
            t.inheritHeirPaternalAuntUterine,
            f.uterinePaternalAunts,
            (v) => f.uterinePaternalAunts = v,
          ),
          count(
            'fatherUterineBrothers',
            t.inheritHeirFatherUterineBrother,
            f.fatherUterineBrothers,
            (v) => f.fatherUterineBrothers = v,
          ),
          count(
            'consanguineMaternalUncles',
            t.inheritHeirMaternalUncleConsanguine,
            f.consanguineMaternalUncles,
            (v) => f.consanguineMaternalUncles = v,
          ),
          count(
            'uterineMaternalUncles',
            t.inheritHeirMaternalUncleUterine,
            f.uterineMaternalUncles,
            (v) => f.uterineMaternalUncles = v,
          ),
          count(
            'consanguineMaternalAunts',
            t.inheritHeirMaternalAuntConsanguine,
            f.consanguineMaternalAunts,
            (v) => f.consanguineMaternalAunts = v,
          ),
          count(
            'uterineMaternalAunts',
            t.inheritHeirMaternalAuntUterine,
            f.uterineMaternalAunts,
            (v) => f.uterineMaternalAunts = v,
          ),
        ],
      ],
    ];
  }
}

/// A brother or sister who died, for the distant kindred: how they were
/// related, and the children they left.
class _LineCard extends StatelessWidget {
  final int index;
  final SiblingLine line;
  final Color accent;
  final ValueChanged<SiblingLine> onChanged;
  final VoidCallback onRemove;
  const _LineCard({
    super.key,
    required this.index,
    required this.line,
    required this.accent,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final style = SegmentedButton.styleFrom(
      selectedBackgroundColor: accent,
      selectedForegroundColor: AppColors.ink,
      foregroundColor: AppColors.text,
      side: const BorderSide(color: AppColors.lineMid),
    );
    // A full or consanguine brother's sons are nephews (residuaries).
    final sonsAreNephews =
        line.gender == Gender.male && line.blood != Blood.uterine;
    return _Card(
      title: t.inheritLineTitle(index + 1),
      removeKey: 'inherit-line-$index-remove',
      onRemove: onRemove,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SegmentedButton<Blood>(
            key: ValueKey('inherit-line-$index-blood'),
            segments: [
              ButtonSegment(value: Blood.full, label: Text(t.inheritBloodFull)),
              ButtonSegment(
                value: Blood.consanguine,
                label: Text(t.inheritBloodConsanguine),
              ),
              ButtonSegment(
                value: Blood.uterine,
                label: Text(t.inheritBloodUterine),
              ),
            ],
            selected: {line.blood},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onChanged(line.copyWith(blood: s.first)),
            style: style,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SegmentedButton<Gender>(
            key: ValueKey('inherit-line-$index-gender'),
            segments: [
              ButtonSegment(
                value: Gender.male,
                label: Text(t.inheritHeirBrother),
              ),
              ButtonSegment(
                value: Gender.female,
                label: Text(t.inheritHeirSister),
              ),
            ],
            selected: {line.gender},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                onChanged(line.copyWith(gender: s.first)),
            style: style,
          ),
        ),
        if (!sonsAreNephews)
          InheritCountRow(
            id: 'line-$index-sons',
            label: t.inheritTheirSons,
            value: line.sons,
            max: 20,
            accent: accent,
            onChanged: (v) => onChanged(line.copyWith(sons: v)),
          ),
        InheritCountRow(
          id: 'line-$index-daughters',
          label: t.inheritTheirDaughters,
          value: line.daughters,
          max: 20,
          accent: accent,
          onChanged: (v) => onChanged(line.copyWith(daughters: v)),
        ),
        if (sonsAreNephews) InheritNote(t.inheritLineBrotherSons),
      ],
    );
  }
}

class HinduFamilyStep extends StatelessWidget {
  final HinduForm form;
  final Color accent;
  final VoidCallback onChanged;
  const HinduFamilyStep({
    super.key,
    required this.form,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final f = form;
    final rows = _Rows(accent, onChanged);

    final next = <Widget>[
      if (f.askDaughters) ...[
        rows.count(
          'unmarriedDaughters',
          t.inheritHeirUnmarriedDaughter,
          f.unmarriedDaughters,
          (v) => f.unmarriedDaughters = v,
          sub: t.inheritSubUnmarried,
        ),
        if (f.askMarriedDaughters)
          rows.count(
            'marriedDaughters',
            t.inheritHeirMarriedDaughter,
            f.marriedDaughters,
            (v) => f.marriedDaughters = v,
            sub: t.inheritSubMarriedWithSon,
          ),
        InheritNote(t.inheritHinduDaughterNote),
      ],
      if (f.askDaughtersSons)
        rows.count(
          'daughtersSons',
          t.inheritHeirDaughtersSon,
          f.daughtersSons,
          (v) => f.daughtersSons = v,
        ),
      if (f.askFather)
        rows.toggle(
          'father',
          t.inheritHeirFather,
          f.father,
          (v) => f.father = v,
        ),
      if (f.askMother)
        rows.toggle(
          'mother',
          t.inheritHeirMother,
          f.mother,
          (v) => f.mother = v,
        ),
      if (f.askBrothers)
        rows.count(
          'fullBrothers',
          t.inheritHeirFullBrother,
          f.fullBrothers,
          (v) => f.fullBrothers = v,
          sub: t.inheritSubFull,
        ),
      if (f.askHalfBrothers)
        rows.count(
          'halfBrothers',
          t.inheritHeirPaternalBrother,
          f.halfBrothers,
          (v) => f.halfBrothers = v,
          sub: t.inheritSubHalfBrotherHindu,
        ),
      if (f.askBrothersSons)
        rows.count(
          'brothersSons',
          t.inheritHeirFullNephew,
          f.brothersSons,
          (v) => f.brothersSons = v,
          sub: t.inheritSubBrothersSon,
        ),
      if (f.askBrothersGrandsons)
        rows.count(
          'brothersGrandsons',
          t.inheritHeirGrandNephew,
          f.brothersGrandsons,
          (v) => f.brothersGrandsons = v,
        ),
      if (f.askSistersSons)
        rows.count(
          'sistersSons',
          t.inheritHeirSistersSon,
          f.sistersSons,
          (v) => f.sistersSons = v,
          sub: t.inheritSubSistersSon,
        ),
      if (f.askGrandfather)
        rows.toggle(
          'grandfather',
          t.inheritHeirGrandfather,
          f.grandfather,
          (v) => f.grandfather = v,
          sub: t.inheritSubGrandfather,
        ),
      if (f.askGrandmother)
        rows.toggle(
          'grandmother',
          t.inheritHeirPaternalGrandmother,
          f.grandmother,
          (v) => f.grandmother = v,
          sub: t.inheritSubPaternalGrandmother,
        ),
      if (f.askUncles)
        rows.count(
          'uncles',
          t.inheritHeirFullUncle,
          f.uncles,
          (v) => f.uncles = v,
          sub: t.inheritSubFullUncle,
        ),
      if (f.askUnclesSons)
        rows.count(
          'unclesSons',
          t.inheritHeirFullCousin,
          f.unclesSons,
          (v) => f.unclesSons = v,
          sub: t.inheritSubUnclesSon,
        ),
      if (f.firstGroup)
        InheritNote(
          f.maleLine ? t.inheritHinduHiddenMale : t.inheritHinduHiddenWidow,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        InheritSection(
          title: t.inheritFamily,
          children: [
            rows.count(
              'widows',
              t.inheritHeirWife,
              f.widows,
              (v) => f.widows = v,
              max: 4,
              sub: t.inheritSubWidows,
            ),
            rows.count('sons', t.inheritHeirSon, f.sons, (v) => f.sons = v),
            for (var i = 0; i < f.deadSons.length; i++)
              _DeadSonCard(
                key: ValueKey('inherit-deadson-$i'),
                index: i,
                son: f.deadSons[i],
                accent: accent,
                onChanged: (s) {
                  f.deadSons[i] = s;
                  onChanged();
                },
                onRemove: () {
                  f.deadSons.removeAt(i);
                  onChanged();
                },
              ),
            InheritAddRow(
              key: const ValueKey('inherit-add-deadson'),
              label: t.inheritDeadSonAdd,
              sub: t.inheritDeadSonAddSub,
              onTap: () {
                f.deadSons.add(const PredeceasedSon(sons: 1));
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        InheritSection(title: t.inheritMore, children: next),
        const SizedBox(height: 12),
        Text(t.inheritHinduDistant, style: AppTypography.bodyDim),
      ],
    );
  }
}

class ChristianFamilyStep extends StatelessWidget {
  final ChristianForm form;
  final Gender deceased;
  final Color accent;
  final VoidCallback onChanged;
  const ChristianFamilyStep({
    super.key,
    required this.form,
    required this.deceased,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final f = form;
    final rows = _Rows(accent, onChanged);

    final more = <Widget>[
      if (f.askFather)
        rows.toggle(
          'father',
          t.inheritHeirFather,
          f.father,
          (v) => f.father = v,
        ),
      if (f.askMotherAndSiblings) ...[
        rows.toggle(
          'mother',
          t.inheritHeirMother,
          f.mother,
          (v) => f.mother = v,
        ),
        rows.count(
          'brothers',
          t.inheritHeirBrother,
          f.brothers,
          (v) => f.brothers = v,
          sub: t.inheritSubAnyBlood,
        ),
        rows.count(
          'sisters',
          t.inheritHeirSister,
          f.sisters,
          (v) => f.sisters = v,
          sub: t.inheritSubAnyBlood,
        ),
        ..._deadChildCards(
          context,
          f.deadSiblings,
          accent,
          onChanged,
          prefix: 'deadsib',
          title: t.inheritDeadSiblingTitle,
          male: t.inheritHeirBrother,
          female: t.inheritHeirSister,
          note: t.inheritChristianDeadNote,
        ),
        InheritAddRow(
          key: const ValueKey('inherit-add-deadsib'),
          label: t.inheritDeadSiblingAdd,
          sub: t.inheritDeadSiblingAddSub,
          onTap: () {
            f.deadSiblings.add(const PredeceasedChild(Gender.male, sons: 1));
            onChanged();
          },
        ),
      ],
      if (f.askGrandparents) ...[
        rows.toggle(
          'grandfather',
          t.inheritHeirGrandfather,
          f.paternalGrandfather,
          (v) => f.paternalGrandfather = v,
          sub: t.inheritSubGrandfather,
        ),
        rows.toggle(
          'paternalGrandmother',
          t.inheritHeirPaternalGrandmother,
          f.paternalGrandmother,
          (v) => f.paternalGrandmother = v,
          sub: t.inheritSubPaternalGrandmother,
        ),
        rows.toggle(
          'maternalGrandfather',
          t.inheritHeirMaternalGrandfather,
          f.maternalGrandfather,
          (v) => f.maternalGrandfather = v,
        ),
        rows.toggle(
          'maternalGrandmother',
          t.inheritHeirMaternalGrandmother,
          f.maternalGrandmother,
          (v) => f.maternalGrandmother = v,
          sub: t.inheritSubMaternalGrandmother,
        ),
      ],
      if (f.askThirdDegree) ...[
        rows.count(
          'paternalUncles',
          t.inheritHeirFullUncle,
          f.paternalUncles,
          (v) => f.paternalUncles = v,
        ),
        rows.count(
          'paternalAunts',
          t.inheritHeirPaternalAunt,
          f.paternalAunts,
          (v) => f.paternalAunts = v,
        ),
        rows.count(
          'maternalUncles',
          t.inheritHeirMaternalUncle,
          f.maternalUncles,
          (v) => f.maternalUncles = v,
        ),
        rows.count(
          'maternalAunts',
          t.inheritHeirMaternalAunt,
          f.maternalAunts,
          (v) => f.maternalAunts = v,
        ),
      ],
      if (f.askCousins)
        rows.count(
          'cousins',
          t.inheritHeirCousin,
          f.cousins,
          (v) => f.cousins = v,
        ),
      if (!f.askFather)
        InheritNote(t.inheritChristianHiddenDesc)
      else if (!f.askMotherAndSiblings)
        InheritNote(t.inheritChristianHiddenFather),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        InheritSection(
          title: t.inheritFamily,
          children: [
            rows.toggle(
              'spouse',
              deceased == Gender.male
                  ? t.inheritHeirWife
                  : t.inheritHeirHusband,
              f.spouse,
              (v) => f.spouse = v,
            ),
            rows.count('sons', t.inheritHeirSon, f.sons, (v) => f.sons = v),
            rows.count(
              'daughters',
              t.inheritHeirDaughter,
              f.daughters,
              (v) => f.daughters = v,
            ),
            ..._deadChildCards(
              context,
              f.dead,
              accent,
              onChanged,
              title: t.inheritPredeceasedTitle,
              male: t.inheritHeirSon,
              female: t.inheritHeirDaughter,
              note: t.inheritChristianDeadNote,
            ),
            InheritAddRow(
              key: const ValueKey('inherit-add-dead'),
              label: t.inheritPredeceasedAdd,
              sub: t.inheritPredeceasedAddSub,
              onTap: () {
                f.dead.add(const PredeceasedChild(Gender.male, sons: 1));
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        InheritSection(title: t.inheritMore, children: more),
        const SizedBox(height: 12),
        Text(t.inheritChristianDistant, style: AppTypography.bodyDim),
      ],
    );
  }
}

/// Cards for people who died before the deceased, each with their own
/// children.
List<Widget> _deadChildCards(
  BuildContext context,
  List<PredeceasedChild> list,
  Color accent,
  VoidCallback onChanged, {
  String prefix = 'dead',
  required String Function(int) title,
  required String male,
  required String female,
  required String note,
}) => [
  for (var i = 0; i < list.length; i++)
    InheritDeadCard(
      key: ValueKey('inherit-$prefix-$i'),
      prefix: '$prefix-$i',
      title: title(i + 1),
      maleLabel: male,
      femaleLabel: female,
      note: note,
      person: list[i],
      accent: accent,
      onChanged: (c) {
        list[i] = c;
        onChanged();
      },
      onRemove: () {
        list.removeAt(i);
        onChanged();
      },
    ),
];

/// Builds rows that write into a form and report the change.
class _Rows {
  final Color accent;
  final VoidCallback onChanged;
  const _Rows(this.accent, this.onChanged);

  Widget count(
    String id,
    String label,
    int value,
    ValueChanged<int> set, {
    String? sub,
    int max = 20,
  }) => InheritCountRow(
    id: id,
    label: label,
    sub: sub,
    value: value,
    max: max,
    accent: accent,
    onChanged: (v) {
      set(v);
      onChanged();
    },
  );

  Widget toggle(
    String id,
    String label,
    bool value,
    ValueChanged<bool> set, {
    String? sub,
  }) => InheritToggleRow(
    id: id,
    label: label,
    sub: sub,
    value: value,
    accent: accent,
    onChanged: (v) {
      set(v);
      onChanged();
    },
  );
}

// ------------------------------------------------------------------ pieces

class InheritSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const InheritSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: AppColors.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String label;
  final String? sub;
  const _RowLabel(this.label, this.sub);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.sans(size: 15, weight: FontWeight.w600)),
      if (sub != null)
        Text(
          sub!,
          style: AppTypography.sans(size: 12, color: AppColors.textDim),
        ),
    ],
  );
}

class InheritCountRow extends StatelessWidget {
  final String id;
  final String label;
  final String? sub;
  final int value;
  final int max;
  final Color accent;
  final ValueChanged<int> onChanged;
  const InheritCountRow({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    required this.max,
    required this.accent,
    required this.onChanged,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String key, VoidCallback? onTap) => InkWell(
      key: ValueKey('inherit-$id-$key'),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : AppColors.surfaceHi,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.textFaint : AppColors.text,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _RowLabel(label, sub)),
          button(
            Icons.remove,
            'minus',
            value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              NumberFormat.decimalPattern().format(value),
              key: ValueKey('inherit-$id-value'),
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                size: 17,
                weight: FontWeight.w700,
                color: value > 0 ? accent : AppColors.textDim,
              ),
            ),
          ),
          button(
            Icons.add,
            'plus',
            value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class InheritToggleRow extends StatelessWidget {
  final String id;
  final String label;
  final String? sub;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const InheritToggleRow({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      child: Row(
        children: [
          Expanded(child: _RowLabel(label, sub)),
          Switch(
            key: ValueKey('inherit-$id-switch'),
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.ink,
            activeTrackColor: accent,
            inactiveThumbColor: AppColors.textDim,
            inactiveTrackColor: AppColors.surfaceHi,
          ),
        ],
      ),
    ),
  );
}

class InheritExpander extends StatelessWidget {
  final String label;
  final bool open;
  final int count;
  final VoidCallback onTap;
  const InheritExpander({
    super.key,
    required this.label,
    required this.open,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count > 0
                  ? '$label · ${NumberFormat.decimalPattern().format(count)}'
                  : label,
              style: AppTypography.sans(size: 14, weight: FontWeight.w600),
            ),
          ),
          Icon(
            open ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: AppColors.textDim,
          ),
        ],
      ),
    ),
  );
}

class InheritAddRow extends StatelessWidget {
  final String label;
  final String sub;
  final VoidCallback onTap;
  const InheritAddRow({
    super.key,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              border: Border.all(color: AppColors.lineMid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 16, color: AppColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(child: _RowLabel(label, sub)),
        ],
      ),
    ),
  );
}

class InheritNote extends StatelessWidget {
  final String text;
  const InheritNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.info_outline, size: 15, color: AppColors.textDim),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.sans(size: 12.5, color: AppColors.textDim),
          ),
        ),
      ],
    ),
  );
}

/// Someone who died before the deceased: son or daughter (or brother or
/// sister), and how many children they left.
class InheritDeadCard extends StatelessWidget {
  final String prefix;
  final String title;
  final String maleLabel;
  final String femaleLabel;
  final String note;
  final PredeceasedChild person;
  final Color accent;
  final ValueChanged<PredeceasedChild> onChanged;
  final VoidCallback onRemove;
  const InheritDeadCard({
    super.key,
    required this.prefix,
    required this.title,
    required this.maleLabel,
    required this.femaleLabel,
    required this.note,
    required this.person,
    required this.accent,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _Card(
      title: title,
      removeKey: 'inherit-$prefix-remove',
      onRemove: onRemove,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SegmentedButton<Gender>(
            key: ValueKey('inherit-$prefix-gender'),
            segments: [
              ButtonSegment(value: Gender.male, label: Text(maleLabel)),
              ButtonSegment(value: Gender.female, label: Text(femaleLabel)),
            ],
            selected: {person.gender},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                onChanged(person.copyWith(gender: s.first)),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: accent,
              selectedForegroundColor: AppColors.ink,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.lineMid),
            ),
          ),
        ),
        InheritCountRow(
          id: '$prefix-sons',
          label: t.inheritTheirSons,
          value: person.sons,
          max: 20,
          accent: accent,
          onChanged: (v) => onChanged(person.copyWith(sons: v)),
        ),
        InheritCountRow(
          id: '$prefix-daughters',
          label: t.inheritTheirDaughters,
          value: person.daughters,
          max: 20,
          accent: accent,
          onChanged: (v) => onChanged(person.copyWith(daughters: v)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Text(
            person.hasChildren ? note : t.inheritNoChildrenNote,
            style: AppTypography.sans(size: 12, color: AppColors.textDim),
          ),
        ),
      ],
    );
  }
}

/// A Hindu man's son who died before him: his sons, and whether his widow
/// is alive.
class _DeadSonCard extends StatelessWidget {
  final int index;
  final PredeceasedSon son;
  final Color accent;
  final ValueChanged<PredeceasedSon> onChanged;
  final VoidCallback onRemove;
  const _DeadSonCard({
    super.key,
    required this.index,
    required this.son,
    required this.accent,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _Card(
      title: t.inheritDeadSonTitle(index + 1),
      removeKey: 'inherit-deadson-$index-remove',
      onRemove: onRemove,
      children: [
        InheritCountRow(
          id: 'deadson-$index-sons',
          label: t.inheritTheirSons,
          value: son.sons,
          max: 20,
          accent: accent,
          onChanged: (v) => onChanged(son.copyWith(sons: v)),
        ),
        InheritToggleRow(
          id: 'deadson-$index-widow',
          label: t.inheritTheirWidow,
          value: son.widow,
          accent: accent,
          onChanged: (v) => onChanged(son.copyWith(widow: v)),
        ),
        if (!son.counts)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              t.inheritNoChildrenNote,
              style: AppTypography.sans(size: 12, color: AppColors.textDim),
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String removeKey;
  final VoidCallback onRemove;
  final List<Widget> children;
  const _Card({
    required this.title,
    required this.removeKey,
    required this.onRemove,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceHi,
      border: Border.all(color: AppColors.lineMid),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.sans(size: 13, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                key: ValueKey(removeKey),
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    ),
  );
}
