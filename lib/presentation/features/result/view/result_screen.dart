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
import '../../../shared/widgets/area_breakdown_view.dart';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../../core/export/plot_export.dart';
import '../../../../core/export/plot_summary.dart';
import '../../../../core/units/area_breakdown.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/input_method.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../../domain/usecases/save_plot.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/plot.dart';
import '../../draw/view/save_plot_sheet.dart';

class ResultArgs {
  final String name;
  final List<Vertex> vertices;

  /// Unit this plot is read in; `null` follows the app setting.
  final AreaUnit? unit;

  /// The saved plot this came from, when it came from one. Without it an
  /// adjustment can only live until the screen is closed.
  final String? plotId;

  const ResultArgs({
    required this.name,
    required this.vertices,
    this.unit,
    this.plotId,
  });

  const ResultArgs.demo()
    : unit = null,
      plotId = null,
      name = 'Kothrud — Field 04',
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
  /// Set once this plot exists in history — either it arrived from there,
  /// or it was saved from this screen.
  late String? _plotId = widget.args.plotId;
  late String _name = widget.args.name;

  /// Wraps the plot drawing so it can be rasterised for share/PDF.
  final _artKey = GlobalKey();
  /// Which export is running, so the tapped button can show a spinner.
  _Export? _running;

  late List<Vertex> _verts = widget.args.vertices.isEmpty
      ? ShapePreset.freeform.vertices
      : widget.args.vertices;

  Future<void> _openAdjust() async {
    final result = await context.push<List<Vertex>>(
      AppRoutes.adjust,
      extra: AdjustArgs(name: _name, vertices: _verts),
    );
    if (!mounted || result == null || result.isEmpty) return;
    setState(() => _verts = result);
    await _persist();
  }

  /// Saves this measurement to history. Until now the only way to keep a
  /// plot was to save it before calculating, which is the wrong moment —
  /// you decide it is worth keeping once you have seen the numbers.
  Future<void> _save() async {
    final settings = context.read<SettingsBloc>().state;
    final result = await showSavePlotSheet(
      context,
      defaultName: _name,
      accent: settings.accent,
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final t = context.l10n;
    final existingId = _plotId;

    if (existingId != null) {
      final all = await sl<GetPlots>()();
      final plot = all.where((p) => p.id == existingId).firstOrNull;
      if (plot != null) {
        await sl<SavePlot>()(
          plot.copyWith(
            name: result.name,
            tag: result.tag,
            vertices: _verts,
          ),
        );
        setState(() => _name = result.name);
        messenger.showSnackBar(
          SnackBar(content: Text(t.plotUpdated(result.name))),
        );
        return;
      }
    }

    final plot = Plot(
      id: const Uuid().v4(),
      name: result.name,
      vertices: _verts,
      tag: result.tag,
      createdAt: DateTime.now(),
      colorValue: settings.accent.toARGB32(),
      preferredUnit: widget.args.unit,
    );
    await sl<SavePlot>()(plot);
    setState(() {
      _plotId = plot.id;
      _name = plot.name;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.drawSavedToast(plot.name, plot.tag.labelOf(t))),
      ),
    );
  }

  /// Reopens the drawing canvas on this outline so corners can be moved by
  /// hand, then keeps whatever comes back.
  Future<void> _openEditor() async {
    final result = await context.push<List<Vertex>>(
      AppRoutes.draw,
      extra: DrawArgs(
        method: InputMethod.draw,
        preset: ShapePreset.freeform,
        vertices: _verts,
        plotId: _plotId,
        name: _name,
      ),
    );
    if (!mounted || result == null || result.isEmpty) return;
    setState(() => _verts = result);
    await _persist();
  }

  /// Writes the reshaped outline back to the saved plot. An unsaved plot has
  /// no id, and simply keeps the change for as long as the screen is open.
  Future<void> _persist() async {
    final id = _plotId;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = context.l10n.plotUpdated(_name);
    final existing = await sl<GetPlots>()();
    final plot = existing.where((p) => p.id == id).firstOrNull;
    if (plot == null) return;
    await sl<SavePlot>()(plot.copyWith(vertices: _verts));
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  /// Rasterises the plot drawing for the share sheet and the PDF. Returns
  /// null if the boundary isn't laid out yet, in which case callers simply
  /// export without a picture rather than failing.
  Future<Uint8List?> _captureArt() async {
    try {
      final obj = _artKey.currentContext?.findRenderObject();
      if (obj is! RenderRepaintBoundary) return null;
      final image = await obj.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  PlotSummary _summary(SettingsState settings) {
    final areaSqm = Geometry.polygonArea(_verts);
    return PlotSummary(
      name: widget.args.name,
      areaSqm: areaSqm,
      perimeterM: Geometry.polygonPerimeter(_verts),
      sides: _verts.length,
      // Exports must read in the same unit as the screen they came from.
      unit: widget.args.unit ?? settings.areaUnit,
      breakdown: AreaBreakdown.of(areaSqm, settings.breakdown),
    );
  }

  Future<void> _export(_Export kind) async {
    if (_running != null) return;
    setState(() => _running = kind);

    final t = context.l10n;
    final summary = _summary(context.read<SettingsBloc>().state);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (kind) {
        case _Export.copy:
          await PlotExport.copy(summary, t);
          messenger.showSnackBar(
            SnackBar(content: Text(t.copiedToClipboard)),
          );
        case _Export.share:
          await PlotExport.share(summary, t, image: await _captureArt());
        case _Export.pdf:
          await PlotExport.sharePdf(summary, t, image: await _captureArt());
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.exportFailed)));
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;
    final areaUnit = widget.args.unit ?? settings.areaUnit;
    final areaSqm = Geometry.polygonArea(_verts);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(
              saved: _plotId != null,
              onSave: _save,
              onEdit: _openEditor,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _artKey,
                      child: _HeroArea(
                        saved: _plotId != null,
                        vertices: _verts,
                      areaSqm: areaSqm,
                      accent: accent,
                      areaUnit: areaUnit,
                        gridStyle: settings.gridStyle,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AreaBreakdownView(sqm: areaSqm),
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
                    _ResultActions(
                      accent: accent,
                      running: _running,
                      onAdjust: _openAdjust,
                      onShare: () => _export(_Export.share),
                      onPdf: () => _export(_Export.pdf),
                      onCopy: () => _export(_Export.copy),
                    ),
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
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  const _TopBar({
    required this.saved,
    required this.onSave,
    required this.onEdit,
  });

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
          // One slot, one job at a time: an unsaved measurement needs
          // keeping, a saved one needs reshaping. (It was a second, dead
          // share button before — sharing already sits in the action row.)
          Tooltip(
            message: saved
                ? context.l10n.resultEditShape
                : context.l10n.actionSave,
            child: SmallIconButton(
              icon: saved ? Icons.edit_outlined : Icons.bookmark_border,
              onTap: saved ? onEdit : onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroArea extends StatelessWidget {
  final bool saved;
  final List<Vertex> vertices;
  final double areaSqm;
  final Color accent;
  final AreaUnit areaUnit;
  final GridStyle gridStyle;

  const _HeroArea({
    required this.saved,
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
                      // The unit is part of this label, and the longest of
                      // them collides with the SAVED badge on a narrow phone.
                      Flexible(
                        child: Text(
                          context.l10n.resultTotalArea(
                            areaUnit.labelOf(context.l10n).toUpperCase(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(
                            size: 10,
                            color: AppColors.textFaint,
                            letterSpacing: 1.32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: saved ? accent : AppColors.line,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          saved
                              ? context.l10n.resultSaved
                              : context.l10n.resultUnsaved,
                          style: AppTypography.mono(
                            size: 9,
                            color: saved ? accent : AppColors.textFaint,
                          ),
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
          // Tall enough for a Bengali unit name, which sits higher than Latin.
          mainAxisExtent: 62,
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
                  // "BIGHA — MYMENSINGH" wraps on a narrow phone and pushes
                  // the tile past its fixed height; the unit label below
                  // already disambiguates.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

enum _Export { copy, share, pdf }

class _ResultActions extends StatelessWidget {
  final Color accent;
  final _Export? running;
  final VoidCallback onAdjust;
  final VoidCallback onShare;
  final VoidCallback onPdf;
  final VoidCallback onCopy;
  const _ResultActions({
    required this.accent,
    required this.running,
    required this.onAdjust,
    required this.onShare,
    required this.onPdf,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final busy = running != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.copy_all_outlined,
              label: context.l10n.actionCopy,
              accent: accent,
              spinning: running == _Export.copy,
              onTap: busy ? null : onCopy,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.ios_share,
              label: context.l10n.resultShare,
              accent: accent,
              spinning: running == _Export.share,
              onTap: busy ? null : onShare,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.picture_as_pdf_outlined,
              label: context.l10n.resultExportPdf,
              accent: accent,
              spinning: running == _Export.pdf,
              onTap: busy ? null : onPdf,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.tune,
              label: context.l10n.resultAdjust,
              accent: accent,
              onTap: busy ? null : onAdjust,
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
  final Color accent;
  final bool spinning;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.spinning = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        // Icon above label rather than beside it: four of these have to fit
        // a phone width, and a side-by-side layout overflowed.
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 17,
              width: 17,
              child: spinning
                  ? CircularProgressIndicator(strokeWidth: 2, color: accent)
                  : Icon(
                      icon,
                      size: 17,
                      color: onTap == null
                          ? AppColors.textFaint
                          : AppColors.text,
                    ),
            ),
            const SizedBox(height: 5),
            // Four buttons share a phone width, and Bengali labels run
            // longer than English; scale down rather than overflow.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTypography.sans(
                  size: 11,
                  weight: FontWeight.w500,
                  color: onTap == null ? AppColors.textFaint : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
