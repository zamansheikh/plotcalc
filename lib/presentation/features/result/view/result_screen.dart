import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/presets.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../adjust/view/adjust_screen.dart' show AdjustArgs;
import '../../../../l10n/l10n.dart';

class ResultArgs {
  final String name;
  final List<Vertex> vertices;
  const ResultArgs({required this.name, required this.vertices});

  const ResultArgs.demo()
    : name = 'Kothrud — Field 04',
      vertices = const [
        Vertex(-22, -18),
        Vertex(18, -22),
        Vertex(26, 8),
        Vertex(4, 22),
        Vertex(-24, 14),
      ];
}

class ResultScreen extends StatefulWidget {
  final ResultArgs args;
  const ResultScreen({super.key, required this.args});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<Vertex> _verts = widget.args.vertices.isEmpty
      ? ShapePreset.freeform.vertices
      : widget.args.vertices;

  Future<void> _openAdjust() async {
    final result = await context.push<List<Vertex>>(
      AppRoutes.adjust,
      extra: AdjustArgs(name: widget.args.name, vertices: _verts),
    );
    if (!mounted || result == null || result.isEmpty) return;
    setState(() => _verts = result);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final areaUnit = settings.areaUnit;
    final areaSqm = Geometry.polygonArea(_verts);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _HeroArea(
                      vertices: _verts,
                      areaSqm: areaSqm,
                      accent: accent,
                      areaUnit: areaUnit,
                      gridStyle: settings.gridStyle,
                    ),
                    const SizedBox(height: 14),
                    _ConversionsHeader(),
                    const SizedBox(height: 6),
                    _ConversionsGrid(
                      areaSqm: areaSqm,
                      selected: areaUnit,
                      accent: accent,
                    ),
                    const SizedBox(height: 14),
                    _ResultActions(accent: accent, onAdjust: _openAdjust),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmallIconButton(icon: Icons.chevron_left, onTap: () => context.pop()),
          Text(
            context.l10n.resultTitle,
            style: AppTypography.sans(size: 14, weight: FontWeight.w600),
          ),
          SmallIconButton(icon: Icons.ios_share, onTap: () {}),
        ],
      ),
    );
  }
}

class _HeroArea extends StatelessWidget {
  final List<Vertex> vertices;
  final double areaSqm;
  final Color accent;
  final AreaUnit areaUnit;
  final GridStyle gridStyle;

  const _HeroArea({
    required this.vertices,
    required this.areaSqm,
    required this.accent,
    required this.areaUnit,
    required this.gridStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lineMid),
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              GridBackground(style: gridStyle),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.resultTotalArea(areaUnit.labelOf(context.l10n).toUpperCase()),
                        style: AppTypography.mono(
                          size: 10,
                          color: AppColors.textFaint,
                          letterSpacing: 1.32,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: accent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.resultSaved,
                          style: AppTypography.mono(size: 9, color: accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          areaUnit.format(areaSqm),
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(
                            size: 44,
                            weight: FontWeight.w500,
                            color: accent,
                            letterSpacing: -1.32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        areaUnit.labelOf(context.l10n),
                        style: AppTypography.mono(
                          size: 14,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _MiniPolyPainter(
                        vertices: vertices,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPolyPainter extends CustomPainter {
  final List<Vertex> vertices;
  final Color color;
  _MiniPolyPainter({required this.vertices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.length < 3) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final v in vertices) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }
    final w = maxX - minX, h = maxY - minY;
    const pad = 6.0;
    final sx = w == 0 ? 1.0 : (size.width - pad * 2) / w;
    final sy = h == 0 ? 1.0 : (size.height - pad * 2) / h;
    final s = sx < sy ? sx : sy;
    final ox = (size.width - w * s) / 2 - minX * s;
    final oy = (size.height - h * s) / 2 - minY * s;

    final path = Path();
    for (var i = 0; i < vertices.length; i++) {
      final p = Offset(vertices[i].x * s + ox, vertices[i].y * s + oy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniPolyPainter old) =>
      old.vertices != vertices || old.color != color;
}

class _ConversionsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _Label(context.l10n.resultEquivalent),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.mono(
        size: 11,
        color: AppColors.textFaint,
        letterSpacing: 1.32,
      ),
    );
  }
}

class _ConversionsGrid extends StatelessWidget {
  final double areaSqm;
  final AreaUnit selected;
  final Color accent;

  const _ConversionsGrid({
    required this.areaSqm,
    required this.selected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final units = AreaUnit.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 56,
        ),
        itemCount: units.length,
        itemBuilder: (_, i) {
          final u = units[i];
          final active = u == selected;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.limeDim : AppColors.surface,
              border: Border.all(color: active ? accent : AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  u.nameOf(context.l10n).toUpperCase(),
                  style: AppTypography.mono(
                    size: 9,
                    color: AppColors.textFaint,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        u.format(areaSqm),
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(
                          size: 13,
                          weight: FontWeight.w500,
                          color: active ? accent : AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      u.labelOf(context.l10n),
                      style: AppTypography.mono(
                        size: 9,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ValuationCard extends StatefulWidget {
  final double areaSqm;
  final AreaUnit areaUnit;
  final Color accent;
  const _ValuationCard({
    required this.areaSqm,
    required this.areaUnit,
    required this.accent,
  });

  @override
  State<_ValuationCard> createState() => _ValuationCardState();
}

class _ValuationCardState extends State<_ValuationCard> {
  static const _initialRate = 4200.0;
  late final TextEditingController _rateCtrl = TextEditingController(
    text: _initialRate.toStringAsFixed(0),
  );
  double _rate = _initialRate;

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  void _onRateChanged(String v) {
    final n = double.tryParse(v.replaceAll(',', ''));
    if (n != null && n != _rate) {
      setState(() => _rate = n);
    } else if (n == null && _rate != 0) {
      setState(() => _rate = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inUnit = widget.areaUnit.fromSqm(widget.areaSqm);
    final value = inUnit * _rate;
    final f = NumberFormat.decimalPattern();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _Label(context.l10n.resultValuation),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Rate row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.resultRatePer(widget.areaUnit.labelOf(context.l10n).toUpperCase()),
                            style: AppTypography.mono(
                              size: 9,
                              color: AppColors.textFaint,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  context.l10n.resultCurrency,
                                  style: AppTypography.mono(
                                    size: 12,
                                    color: AppColors.textDim,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _rateCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                    ],
                                    cursorColor: widget.accent,
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: '0',
                                    ),
                                    style: AppTypography.mono(
                                      size: 16,
                                      weight: FontWeight.w500,
                                    ),
                                    onChanged: _onRateChanged,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: AppColors.line),
                const SizedBox(height: 14),
                // Value row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      context.l10n.resultEstValue,
                      style: AppTypography.mono(
                        size: 9,
                        color: AppColors.textFaint,
                        letterSpacing: 0.9,
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            context.l10n.resultCurrency,
                            style: AppTypography.mono(
                              size: 12,
                              color: widget.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              f.format(value.round()),
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.mono(
                                size: 22,
                                weight: FontWeight.w500,
                                color: widget.accent,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  final Color accent;
  final VoidCallback onAdjust;
  const _ResultActions({required this.accent, required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.picture_as_pdf_outlined,
              label: context.l10n.resultExportPdf,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.ios_share,
              label: context.l10n.resultShareImage,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.tune,
              label: context.l10n.resultAdjust,
              onTap: onAdjust,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.text),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.sans(size: 12, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
