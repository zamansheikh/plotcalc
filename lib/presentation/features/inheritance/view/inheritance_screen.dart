import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/division_plan.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/inheritance/christian.dart';
import '../../../../core/inheritance/dayabhaga.dart';
import '../../../../core/inheritance/faraid.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../mouza/view/map_widgets.dart'
    show mapPrimaryButtonStyle, mapSecondaryButtonStyle;
import '../../sheet/view/sheet_dialogs.dart' show showUnitPicker;
import '../../subdivide/view/division_canvas.dart' show ownerColour;
import '../../subdivide/view/subdivide_screen.dart' show DivisionPrefill;
import '../inheritance_forms.dart';
import '../inheritance_text.dart';
import 'family_steps.dart';

/// Who gets what share of an estate, in three plain steps — who died (and
/// their religion), who survived them, and the result — which can go
/// straight on to dividing the land in বিভাজন.
///
/// Muslim shares follow Hanafi law with the 1961 ordinance and distant
/// kindred; Hindu shares the Dayabhaga order with the 1937 Act; Christian
/// shares the Succession Act 1925. Only relatives who could change a share
/// are asked about.
class InheritanceScreen extends StatefulWidget {
  const InheritanceScreen({super.key});

  @override
  State<InheritanceScreen> createState() => _InheritanceScreenState();
}

class _InheritanceScreenState extends State<InheritanceScreen> {
  int _step = 0;

  // Step 1: the deceased, their religion and the estate.
  Gender? _deceased;
  InheritanceLaw _law = InheritanceLaw.muslim;
  final _name = TextEditingController();
  final _land = TextEditingController();
  AreaUnit _unit = AreaUnit.shotok;
  Plot? _plot;
  List<Plot> _plots = const [];
  bool _settingLand = false;

  // Step 2: the family, one form per law (kept while switching).
  final _muslim = MuslimForm();
  final _hindu = HinduForm();
  final _christian = ChristianForm();

  @override
  void initState() {
    super.initState();
    _land.addListener(() {
      // Typing an amount by hand lets go of a picked plot.
      if (!_settingLand && _plot != null) setState(() => _plot = null);
      setState(() {});
    });
    _name.addListener(() => setState(() {}));
    sl<GetPlots>()().then((plots) {
      if (mounted) setState(() => _plots = plots);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _land.dispose();
    super.dispose();
  }

  /// A Hindu woman's estate is not worked out here (see the note).
  bool get _unsupported =>
      _law == InheritanceLaw.hindu && _deceased == Gender.female;

  Gender get _gender => _deceased ?? Gender.male;

  bool get _anyone => switch (_law) {
    InheritanceLaw.muslim => _muslim.family(_gender).anyone,
    InheritanceLaw.hindu => _hindu.family.anyone,
    InheritanceLaw.christian => _christian.family(_gender).anyone,
  };

  InheritanceResult _compute() => switch (_law) {
    InheritanceLaw.muslim => Faraid.compute(_muslim.family(_gender)),
    InheritanceLaw.hindu => Dayabhaga.compute(_hindu.family),
    InheritanceLaw.christian => ChristianSuccession.compute(
      _christian.family(_gender),
    ),
  };

  /// The estate's land in m², or null for shares only.
  double? get _estateSqm {
    final plot = _plot;
    if (plot != null) return Geometry.polygonArea(plot.vertices);
    final v = SheetSummary.parseAmount(_land.text);
    if (v == null || v <= 0) return null;
    return _unit.toSqm(v);
  }

  void _pickPlot(Plot p) {
    HapticFeedback.selectionClick();
    final unit = p.preferredUnit ?? _unit;
    _settingLand = true;
    _land.text = _plain(unit.fromSqm(Geometry.polygonArea(p.vertices)));
    _settingLand = false;
    setState(() {
      _plot = p;
      _unit = unit;
    });
  }

  Future<void> _pickUnit() async {
    final accent = context.read<SettingsBloc>().state.accent;
    final picked = await showUnitPicker(
      context,
      title: context.l10n.inheritLand,
      current: _unit,
      accent: accent,
    );
    final unit = picked?.unit;
    if (unit == null || !mounted) return;
    // The same land in the new unit.
    final sqm = _estateSqm;
    setState(() => _unit = unit);
    if (sqm != null) {
      _settingLand = true;
      _land.text = _plain(unit.fromSqm(sqm));
      _settingLand = false;
    }
  }

  static String _plain(double v) =>
      v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  void _setDeceased(Gender g) {
    HapticFeedback.selectionClick();
    setState(() {
      if (g != _deceased) {
        _muslim
          ..husband = false
          ..wives = 0;
        _christian.spouse = false;
      }
      _deceased = g;
    });
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  String _estateName(AppLocalizations t) {
    final name = _name.text.trim();
    if (name.isNotEmpty) return t.inheritEstate(name);
    return _deceased == Gender.female
        ? t.inheritDeceasedWoman
        : t.inheritDeceasedMan;
  }

  String _disclaimer(AppLocalizations t) => switch (_law) {
    InheritanceLaw.muslim => t.inheritDisclaimer,
    InheritanceLaw.hindu => t.inheritDisclaimerHindu,
    InheritanceLaw.christian => t.inheritDisclaimerChristian,
  };

  void _divide(InheritanceResult r) {
    final words = InheritanceText(context.l10n);
    context.push(
      AppRoutes.divide,
      extra: DivisionPrefill(
        plotId: _plot?.id,
        owners: [
          for (final h in r.heirs)
            DivisionOwner(
              name: words.label(h),
              // In the app's digits; বিভাজন reads Bengali digits too.
              amount: InheritanceText.fraction(h.share),
            ),
        ],
      ),
    );
  }

  Future<void> _share(InheritanceResult r) async {
    final t = context.l10n;
    final words = InheritanceText(t);
    final sqm = _estateSqm;
    final n = NumberFormat.decimalPattern();
    String area(double v) => '${_unit.format(v)} ${_unit.labelOf(t)}';
    final lines = <String>[
      _estateName(t),
      if (sqm != null) area(sqm),
      _law == InheritanceLaw.muslim
          ? t.inheritBase(n.format(r.base))
          : t.inheritBaseParts(n.format(r.base)),
      '',
      for (final h in r.heirs)
        '${words.label(h)}: ${InheritanceText.fraction(h.share)}'
            ' (${InheritanceText.percent(h.share)})'
            '${sqm == null ? '' : ' — ${area(sqm * h.share.value)}'}'
            '${h.lifeInterest ? ' · ${t.inheritLifeInterest}' : ''}',
      if (r.excluded.isNotEmpty) '',
      for (final e in r.excluded) words.exclusion(e),
      for (final note in r.notes) ...['', words.note(note)],
      '',
      _disclaimer(t),
      '— ${t.appName}',
    ];
    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: _estateName(t)),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final accent = context.watch<SettingsBloc>().state.accent;
    final stepName = switch (_step) {
      0 => t.inheritStepDeceased,
      1 => t.inheritStepFamily,
      _ => t.inheritStepResult,
    };
    final result = _step == 2 ? _compute() : null;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: PhoneChrome(
            child: Column(
              children: [
                _Header(
                  title: t.inheritTitle,
                  subtitle: t.inheritStep(_step + 1, stepName),
                  step: _step,
                  accent: accent,
                  onBack: _back,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        0 => _deceasedStep(t, accent),
                        1 => _familyStep(accent),
                        _ => _resultStep(t, accent, result!),
                      },
                    ),
                  ),
                ),
                _bottomBar(t, accent, result),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _familyStep(Color accent) {
    void changed() => setState(() {});
    return switch (_law) {
      InheritanceLaw.muslim => MuslimFamilyStep(
        form: _muslim,
        deceased: _gender,
        accent: accent,
        onChanged: changed,
      ),
      InheritanceLaw.hindu => HinduFamilyStep(
        form: _hindu,
        accent: accent,
        onChanged: changed,
      ),
      InheritanceLaw.christian => ChristianFamilyStep(
        form: _christian,
        deceased: _gender,
        accent: accent,
        onChanged: changed,
      ),
    };
  }

  Widget _bottomBar(AppLocalizations t, Color accent, InheritanceResult? r) {
    Widget primary(String label, VoidCallback? onTap, {Key? key}) =>
        FilledButton(
          key: key,
          onPressed: onTap,
          style: mapPrimaryButtonStyle(accent),
          child: Text(
            label,
            style: AppTypography.sans(
              size: 14,
              weight: FontWeight.w700,
              color: onTap == null ? AppColors.textDim : AppColors.ink,
            ),
          ),
        );
    final usable = r != null && !r.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: switch (_step) {
        0 => SizedBox(
          width: double.infinity,
          child: primary(
            t.mouzaNext,
            _deceased == null || _unsupported
                ? null
                : () => setState(() => _step = 1),
            key: const ValueKey('inherit-next'),
          ),
        ),
        1 => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_anyone)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t.inheritNeedHeir, style: AppTypography.bodyDim),
              ),
            SizedBox(
              width: double.infinity,
              child: primary(
                t.inheritSeeResult,
                _anyone ? () => setState(() => _step = 2) : null,
                key: const ValueKey('inherit-see'),
              ),
            ),
          ],
        ),
        _ => Row(
          children: [
            OutlinedButton.icon(
              key: const ValueKey('inherit-share'),
              onPressed: usable ? () => _share(r) : null,
              style: mapSecondaryButtonStyle,
              icon: const Icon(Icons.ios_share, size: 16),
              label: Text(t.inheritShare),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: primary(
                t.inheritDivide,
                usable ? () => _divide(r) : null,
                key: const ValueKey('inherit-divide'),
              ),
            ),
          ],
        ),
      },
    );
  }

  // ------------------------------------------- step 1: who died, religion

  Widget _deceasedStep(AppLocalizations t, Color accent) {
    final sqm = _estateSqm;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(t.inheritStepDeceased, style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (g, icon, label) in [
              (Gender.male, Icons.man, t.inheritMan),
              (Gender.female, Icons.woman, t.inheritWoman),
            ]) ...[
              if (g == Gender.female) const SizedBox(width: 12),
              Expanded(
                child: _ChoiceCard(
                  key: ValueKey('inherit-${g.name}'),
                  icon: icon,
                  label: label,
                  selected: _deceased == g,
                  accent: accent,
                  onTap: () => _setDeceased(g),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(t.inheritReligion, style: AppTypography.sectionTitle),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (law, label) in [
              (InheritanceLaw.muslim, t.inheritMuslim),
              (InheritanceLaw.hindu, t.inheritHindu),
              (InheritanceLaw.christian, t.inheritChristian),
            ]) ...[
              if (law != InheritanceLaw.muslim) const SizedBox(width: 8),
              Expanded(
                child: _LawChip(
                  key: ValueKey('inherit-law-${law.name}'),
                  label: label,
                  selected: _law == law,
                  accent: accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _law = law);
                  },
                ),
              ),
            ],
          ],
        ),
        if (_unsupported) ...[
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('inherit-hindu-woman'),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.amber),
              borderRadius: BorderRadius.circular(14),
            ),
            child: InheritNote(t.inheritHinduWoman),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('inherit-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.sans(size: 15),
          decoration: _fieldDecoration(t.inheritNameHint, accent),
        ),
        const SizedBox(height: 22),
        Text(t.inheritLand, style: AppTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(t.inheritLandHint, style: AppTypography.bodyDim),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('inherit-land'),
                controller: _land,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTypography.mono(size: 18, weight: FontWeight.w500),
                decoration: _fieldDecoration('০', accent),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _pickUnit,
              style: mapSecondaryButtonStyle,
              child: Row(
                children: [
                  Text(_unit.labelOf(t)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 16),
                ],
              ),
            ),
          ],
        ),
        if (sqm != null && _plot == null) ...[
          const SizedBox(height: 6),
          Text(
            '${AreaUnit.sqft.format(sqm)} ${AreaUnit.sqft.labelOf(t)}',
            style: AppTypography.bodyDim,
          ),
        ],
        if (_plots.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            t.inheritFromSaved.toUpperCase(),
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _plots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = _plots[i];
                final unit = p.preferredUnit ?? _unit;
                return _PlotChip(
                  plot: p,
                  area:
                      '${unit.format(Geometry.polygonArea(p.vertices))} ${unit.labelOf(t)}',
                  selected: _plot?.id == p.id,
                  accent: accent,
                  onTap: () => _pickPlot(p),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint, Color accent) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.sans(size: 15, color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
      );

  // ------------------------------------------------- step 3: who gets what

  Widget _resultStep(AppLocalizations t, Color accent, InheritanceResult r) {
    final words = InheritanceText(t);
    final sqm = _estateSqm;
    final n = NumberFormat.decimalPattern();
    final adjustment = words.adjustment(r.adjustment);
    final excludedSiblings = r.excluded.any(
      (e) => switch (e.kind) {
        HeirKind.fullBrother ||
        HeirKind.fullSister ||
        HeirKind.paternalBrother ||
        HeirKind.paternalSister ||
        HeirKind.maternalBrother ||
        HeirKind.maternalSister => true,
        _ => false,
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // The estate and how it splits.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.lineMid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _estateName(t),
                      style: AppTypography.sans(
                        size: 13,
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                  if (!r.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.limeDim,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _law == InheritanceLaw.muslim
                            ? t.inheritBase(n.format(r.base))
                            : t.inheritBaseParts(n.format(r.base)),
                        key: const ValueKey('inherit-base'),
                        style: AppTypography.sans(
                          size: 11,
                          weight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                sqm == null
                    ? t.inheritSharesOnly
                    : '${_unit.format(sqm)} ${_unit.labelOf(t)}',
                style: AppTypography.sans(
                  size: sqm == null ? 18 : 26,
                  weight: FontWeight.w700,
                ),
              ),
              if (!r.isEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        for (var i = 0; i < r.heirs.length; i++)
                          Expanded(
                            flex: r.partsOf(r.heirs[i]),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: i == r.heirs.length - 1 ? 0 : 1.5,
                              ),
                              color: ownerColour(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (adjustment != null) ...[
          const SizedBox(height: 10),
          InheritNote(adjustment),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < r.heirs.length; i++) ...[
          _HeirRow(
            key: ValueKey('inherit-row-$i'),
            colour: ownerColour(i),
            label: words.label(r.heirs[i]),
            reason: words.reason(r.heirs[i].reason),
            area: sqm == null
                ? null
                : '${_unit.format(sqm * r.heirs[i].share.value)} ${_unit.labelOf(t)}',
            fraction: InheritanceText.fraction(r.heirs[i].share),
            percent: InheritanceText.percent(r.heirs[i].share),
            parts: t.inheritParts(
              n.format(r.partsOf(r.heirs[i])),
              n.format(r.base),
            ),
            accent: accent,
            lifeInterest: r.heirs[i].lifeInterest
                ? t.inheritLifeInterest
                : null,
          ),
          const SizedBox(height: 8),
        ],
        for (final note in r.notes)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: InheritNote(words.note(note)),
          ),
        if (r.excluded.isNotEmpty) ...[
          const SizedBox(height: 8),
          InheritSection(
            title: t.inheritExcludedTitle,
            children: [
              for (final e in r.excluded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    words.exclusion(e),
                    style: AppTypography.sans(
                      size: 13,
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              if (r.siblingsReduceMother && excludedSiblings)
                InheritNote(t.inheritMotherCut),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Text(_disclaimer(t), style: AppTypography.bodyDim),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _step = 1),
            icon: Icon(Icons.edit_outlined, size: 16, color: accent),
            label: Text(
              t.inheritEdit,
              style: AppTypography.sans(size: 13, color: accent),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ pieces

/// One religion to choose.
class _LawChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _LawChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.limeDim : AppColors.surface,
        border: Border.all(
          color: selected ? accent : AppColors.line,
          width: selected ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.sans(
          size: 14,
          weight: FontWeight.w700,
          color: selected ? accent : AppColors.text,
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final int step;
  final Color accent;
  final VoidCallback onBack;
  const _Header({
    required this.title,
    required this.subtitle,
    required this.step,
    required this.accent,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(
      children: [
        Row(
          children: [
            SmallIconButton(icon: Icons.chevron_left, onTap: onBack),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.heroTitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.mono(
                      size: 11,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? accent : AppColors.surfaceHi,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _ChoiceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: selected ? AppColors.limeDim : AppColors.surface,
        border: Border.all(
          color: selected ? accent : AppColors.line,
          width: selected ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: selected ? accent : AppColors.text),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.sans(
              size: 16,
              weight: FontWeight.w700,
              color: selected ? accent : AppColors.text,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlotChip extends StatelessWidget {
  final Plot plot;
  final String area;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _PlotChip({
    required this.plot,
    required this.area,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? AppColors.limeDim : AppColors.surface,
        border: Border.all(color: selected ? accent : AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: PlotThumbnail(
              vertices: plot.vertices,
              color: Color(plot.colorValue),
            ),
          ),
          const Spacer(),
          Text(
            plot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(size: 12, weight: FontWeight.w600),
          ),
          Text(
            area,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(size: 11, color: AppColors.textDim),
          ),
        ],
      ),
    ),
  );
}

class _HeirRow extends StatelessWidget {
  final Color colour;
  final String label;
  final String reason;
  final String? area;
  final String fraction;
  final String percent;
  final String parts;
  final Color accent;

  /// Shown as a "for life" tag (a Hindu woman's limited estate).
  final String? lifeInterest;
  const _HeirRow({
    super.key,
    required this.colour,
    required this.label,
    required this.reason,
    required this.area,
    required this.fraction,
    required this.percent,
    required this.parts,
    required this.accent,
    this.lifeInterest,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 40,
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTypography.sans(
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (lifeInterest != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.amber),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        lifeInterest!,
                        style: AppTypography.sans(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                reason,
                style: AppTypography.sans(size: 12, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              area ?? fraction,
              style: AppTypography.sans(
                size: area == null ? 20 : 16,
                weight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              area == null ? percent : '$fraction · $percent',
              style: AppTypography.sans(size: 12, color: AppColors.text),
            ),
            Text(
              parts,
              style: AppTypography.sans(size: 11, color: AppColors.textFaint),
            ),
          ],
        ),
      ],
    ),
  );
}
