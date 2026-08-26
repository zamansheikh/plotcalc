import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/geometry/geometry.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../domain/entities/plot.dart';
import '../../../../domain/usecases/get_plots.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/plot_thumbnail.dart';
import '../../../../l10n/l10n.dart';
import '../../../shared/widgets/tab_header.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/geometry/lot_division.dart';
import '../../../../domain/usecases/save_plot.dart';
import '../../../../core/units/length_unit.dart';

/// How the lots are being sized.
enum _SplitMode { equal, percent, area }

const _lotColours = [
  AppColors.lime,
  AppColors.soil,
  AppColors.sky,
  AppColors.amber,
  AppColors.violet,
  AppColors.emerald,
  AppColors.rose,
];

class SubdivideScreen extends StatefulWidget {
  const SubdivideScreen({super.key});

  @override
  State<SubdivideScreen> createState() => _SubdivideScreenState();
}

class _SubdivideScreenState extends State<SubdivideScreen> {
  Plot? _plot;

  /// Shares of the parent plot, normalised to 1. Percent and area entry are
  /// both just different ways of writing a share down.
  List<double> _shares = LotDivision.equalShares(2);

  /// One angle per divider. A divider is a chord, not a vertical line —
  /// dragging either end pivots it about the other.
  List<double> _angles = [LotDivision.defaultAngle];
  _SplitMode _mode = _SplitMode.equal;

  List<Vertex> get _verts => _plot?.vertices ?? const [];
  double get _totalSqm => Geometry.polygonArea(_verts);

  List<Lot> get _lots =>
      LotDivision.divide(_verts, _shares, angles: _angles);

  List<CutLine> get _cutLines =>
      LotDivision.cutLines(_verts, _shares, angles: _angles);

  Color _colourFor(int i) => _lotColours[i % _lotColours.length];

  void _setShares(List<double> next) {
    final sum = next.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return;
    setState(() => _shares = [for (final s in next) s / sum]);
  }

  void _addLot() {
    // The new lot takes an even share and everyone gives up a little.
    final next = [..._shares, 1 / (_shares.length + 1)];
    setState(() => _angles = [..._angles, LotDivision.defaultAngle]);
    _setShares(next);
    setState(() => _mode = _SplitMode.percent);
  }

  void _removeLot(int index) {
    if (_shares.length <= 2) return;
    final next = [..._shares]..removeAt(index);
    setState(() {
      if (index < _angles.length) _angles = [..._angles]..removeAt(index);
    });
    _setShares(next);
  }

  void _makeEqual() {
    setState(() {
      _mode = _SplitMode.equal;
      _shares = LotDivision.equalShares(_shares.length);
    });
  }

  void _resetAngles() => setState(
    () => _angles = List.filled(_shares.length, LotDivision.defaultAngle),
  );

  /// Sets one lot's share, taking the difference from the others in
  /// proportion so the plot still adds up.
  void _setShare(int index, double share) {
    final clamped = share.clamp(0.01, 0.99);
    final others = [
      for (var i = 0; i < _shares.length; i++)
        if (i != index) i,
    ];
    final otherSum = others.fold<double>(0, (a, i) => a + _shares[i]);
    final remaining = 1 - clamped;
    final next = List<double>.of(_shares);
    next[index] = clamped;
    for (final i in others) {
      next[i] = otherSum <= 0
          ? remaining / others.length
          : remaining * (_shares[i] / otherSum);
    }
    _setShares(next);
  }

  /// Slides a whole divider sideways, moving land between its two lots.
  void _moveCut(int index, Vertex to) => _setShares(
    LotDivision.sharesAfterMove(_verts, _shares, _angles, index, to),
  );

  /// Pivots a divider about its other end. The area it was promised is kept
  /// — the line re-solves its position, so only the direction changes.
  void _pivotCut(int index, bool draggingA, Vertex to) {
    final lines = _cutLines;
    if (index < 0 || index >= lines.length) return;
    final fixed = draggingA ? lines[index].b : lines[index].a;
    final angle = LotDivision.angleAfterDrag(fixed, to);
    setState(() {
      final next = List<double>.of(_angles);
      while (next.length <= index) {
        next.add(LotDivision.defaultAngle);
      }
      next[index] = angle;
      _angles = next;
    });
  }

  /// Saves each lot as its own plot, named after the parent.
  Future<void> _saveLots() async {
    final parent = _plot;
    if (parent == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.l10n;
    final lots = _lots;

    for (var i = 0; i < lots.length; i++) {
      await sl<SavePlot>()(
        Plot(
          id: const Uuid().v4(),
          // "land_abc" divided into "land_abc_lot_1", "land_abc_lot_2" ...
          name: '${parent.name}_lot_${i + 1}',
          vertices: lots[i].vertices,
          tag: parent.tag,
          createdAt: DateTime.now(),
          colorValue: _colourFor(i).toARGB32(),
          preferredUnit: parent.preferredUnit,
        ),
      );
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.subdivideSavedLots(lots.length, parent.name)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final accent = settings.accent;

    if (_plot == null) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Header(
              title: context.l10n.subdivideTitle,
              subtitle: context.l10n.subdivideSubtitle,
            ),
            Expanded(
              child: _PlotPicker(
                onSelect: (p) => setState(() => _plot = p),
              ),
            ),
          ],
        ),
      );
    }

    final verts = _verts;
    final totalSqm = _totalSqm;
    final lots = _lots;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SelectedHeader(
            plot: _plot!,
            lotCount: lots.length,
            onChange: () => setState(() => _plot = null),
          ),
          _Canvas(
            verts: verts,
            lots: lots,
            colours: [for (var i = 0; i < lots.length; i++) _colourFor(i)],
            cutLines: _cutLines,
            accent: accent,
            lengthUnit: settings.lengthUnit,
            onMoveCut: _moveCut,
            onPivotCut: _pivotCut,
            onResetAngles: _resetAngles,
          ),
          const SizedBox(height: 10),
          _ModeRow(
            mode: _mode,
            accent: accent,
            onEqual: _makeEqual,
            onMode: (m) => setState(() => _mode = m),
            onAdd: _addLot,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                return _LotTile(
                  index: i,
                  lot: lots[i],
                  colour: _colourFor(i),
                  name: '${_plot!.name}_lot_${i + 1}',
                  totalSqm: totalSqm,
                  areaUnit: settings.areaUnit,
                  mode: _mode,
                  accent: accent,
                  canRemove: lots.length > 2,
                  onRemove: () => _removeLot(i),
                  onShare: (share) => _setShare(i, share),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Was a snackbar and nothing else: it announced a save that
                // never happened. Each lot is now written to history in its
                // own right.
                onPressed: _saveLots,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.l10n.subdivideSaveAction,
                  style: AppTypography.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return TabHeader(title: title, subtitle: subtitle);
  }
}

class _SelectedHeader extends StatelessWidget {
  final Plot plot;
  final int lotCount;
  final VoidCallback onChange;
  const _SelectedHeader({
    required this.plot,
    required this.lotCount,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      title: context.l10n.subdivideTitle,
      subtitle: context.l10n.subdivideSummary(plot.name, lotCount),
      trailing: OutlinedButton.icon(
        onPressed: onChange,
        icon: const Icon(Icons.swap_horiz, size: 14),
        label: Text(
          context.l10n.actionChange,
          style: AppTypography.sans(size: 12, weight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _PlotPicker extends StatefulWidget {
  final ValueChanged<Plot> onSelect;
  const _PlotPicker({required this.onSelect});

  @override
  State<_PlotPicker> createState() => _PlotPickerState();
}

class _PlotPickerState extends State<_PlotPicker> {
  late final Future<List<Plot>> _future = sl<GetPlots>()();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plot>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.lime),
          );
        }
        final plots = snap.data ?? const [];
        if (plots.isEmpty) {
          return _EmptyState();
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: plots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _PlotPickerTile(plot: plots[i], onTap: widget.onSelect),
        );
      },
    );
  }
}

class _PlotPickerTile extends StatelessWidget {
  final Plot plot;
  final ValueChanged<Plot> onTap;
  const _PlotPickerTile({required this.plot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(plot.colorValue);
    final areaSqm = Geometry.polygonArea(plot.vertices);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(plot),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: PlotThumbnail(vertices: plot.vertices, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.name,
                      style: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.subdivideMeta(AreaUnit.sqft.format(areaSqm), AreaUnit.sqft.labelOf(context.l10n), plot.vertices.length),
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        plot.tag.labelOf(context.l10n).toUpperCase(),
                        style: AppTypography.mono(
                          size: 9,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeDim,
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.call_split, size: 28, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.subdivideEmpty,
              style: AppTypography.sans(size: 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.subdivideEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyDim,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.subdivideGoHome,
                style: AppTypography.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Canvas extends StatefulWidget {
  final List<Vertex> verts;
  final List<Lot> lots;
  final List<Color> colours;
  final List<CutLine> cutLines;
  final Color accent;
  final LengthUnit lengthUnit;
  final void Function(int index, Vertex to) onMoveCut;
  final void Function(int index, bool draggingA, Vertex to) onPivotCut;
  final VoidCallback onResetAngles;

  const _Canvas({
    required this.verts,
    required this.lots,
    required this.colours,
    required this.cutLines,
    required this.accent,
    required this.lengthUnit,
    required this.onMoveCut,
    required this.onPivotCut,
    required this.onResetAngles,
  });

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  /// Which divider end is being dragged, if any: (index, isFirstEnd).
  (int, bool)? _grabbed;

  /// Which divider is being slid whole.
  int? _sliding;

  @override
  Widget build(BuildContext context) {
    final verts = widget.verts;
    final lots = widget.lots;
    final colours = widget.colours;
    final cutLines = widget.cutLines;
    final lengthUnit = widget.lengthUnit;
    final onMoveCut = widget.onMoveCut;
    final onPivotCut = widget.onPivotCut;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 230,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth, h = c.maxHeight;
                final cx = w / 2, cy = h / 2;
                final scale = _scaleFor(verts, w, h);

                Vertex toWorld(Offset p) =>
                    Vertex((p.dx - cx) / scale, (p.dy - cy) / scale);
                Offset toScreen(Vertex v) =>
                    Offset(cx + v.x * scale, cy + v.y * scale);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) {
                    // Grabbing an end pivots the divider; grabbing anywhere
                    // else slides the whole line.
                    _grabbed = null;
                    var best = 30.0;
                    for (var i = 0; i < cutLines.length; i++) {
                      for (final isA in [true, false]) {
                        final end = isA ? cutLines[i].a : cutLines[i].b;
                        final dist = (toScreen(end) - d.localPosition).distance;
                        if (dist < best) {
                          best = dist;
                          _grabbed = (i, isA);
                        }
                      }
                    }
                    if (_grabbed != null) return;
                    var nearest = 0;
                    var nearestDist = double.infinity;
                    for (var i = 0; i < cutLines.length; i++) {
                      final mid = toScreen(
                        Vertex(
                          (cutLines[i].a.x + cutLines[i].b.x) / 2,
                          (cutLines[i].a.y + cutLines[i].b.y) / 2,
                        ),
                      );
                      final dist = (mid - d.localPosition).distance;
                      if (dist < nearestDist) {
                        nearestDist = dist;
                        nearest = i;
                      }
                    }
                    _sliding = cutLines.isEmpty ? null : nearest;
                  },
                  onPanUpdate: (d) {
                    final grabbed = _grabbed;
                    if (grabbed != null) {
                      onPivotCut(
                        grabbed.$1,
                        grabbed.$2,
                        toWorld(d.localPosition),
                      );
                      return;
                    }
                    final sliding = _sliding;
                    if (sliding != null) {
                      onMoveCut(sliding, toWorld(d.localPosition));
                    }
                  },
                  onPanEnd: (_) {
                    _grabbed = null;
                    _sliding = null;
                  },
                  child: Stack(
                    children: [
                      GridBackground(
                        style: context.watch<SettingsBloc>().state.gridStyle,
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DivisionPainter(
                            verts: verts,
                            lots: lots,
                            colours: colours,
                            cutLines: cutLines,
                            lengthUnit: lengthUnit,
                            lengthLabel: lengthUnit.labelOf(context.l10n),
                            names: [
                              for (var i = 0; i < lots.length; i++)
                                context.l10n.subdivideLot(i + 1),
                            ],
                            scale: scale,
                            center: Offset(cx, cy),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static double _scaleFor(List<Vertex> verts, double w, double h) {
    if (verts.length < 2) return 4.2;
    final (minX, minY, maxX, maxY) = Geometry.bbox(verts);
    final dx = maxX - minX, dy = maxY - minY;
    const pad = 48.0;
    final sx = dx == 0 ? 4.2 : (w - pad) / dx;
    final sy = dy == 0 ? 4.2 : (h - pad) / dy;
    return math.min(sx, sy).clamp(1.0, 12.0);
  }
}

/// Fills each lot with its own colour and marks the draggable boundaries.
///
/// The lots are the polygons the division actually produced, so what is
/// shaded here is exactly the land the figures below describe.
/// Fills each lot with its own colour, marks the draggable dividers, and
/// writes the length of every boundary onto it.
///
/// The lots are the polygons the division actually produced, so what is
/// shaded here is exactly the land the figures below describe.
class _DivisionPainter extends CustomPainter {
  final List<Vertex> verts;
  final List<Lot> lots;
  final List<Color> colours;
  final List<CutLine> cutLines;
  final List<String> names;
  final LengthUnit lengthUnit;
  final String lengthLabel;
  final double scale;
  final Offset center;

  _DivisionPainter({
    required this.verts,
    required this.lots,
    required this.colours,
    required this.cutLines,
    required this.names,
    required this.lengthUnit,
    required this.lengthLabel,
    required this.scale,
    required this.center,
  });

  Offset _at(Vertex v) =>
      Offset(center.dx + v.x * scale, center.dy + v.y * scale);

  Path _path(List<Vertex> poly) {
    final path = Path();
    if (poly.isEmpty) return path;
    path.moveTo(_at(poly.first).dx, _at(poly.first).dy);
    for (final v in poly.skip(1)) {
      path.lineTo(_at(v).dx, _at(v).dy);
    }
    path.close();
    return path;
  }

  void _label(Canvas canvas, Offset at, String text, Color colour) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.mono(
          size: 9,
          weight: FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: at,
      width: tp.width + 8,
      height: 14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = colour,
    );
    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (verts.length < 3) return;

    for (var i = 0; i < lots.length; i++) {
      final colour = colours[i % colours.length];
      final path = _path(lots[i].vertices);
      canvas.drawPath(path, Paint()..color = colour.withValues(alpha: 0.22));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = colour,
      );
    }

    canvas.drawPath(
      _path(verts),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.text.withValues(alpha: 0.5),
    );

    // Every side of the plot, measured — split where a divider lands on it,
    // so a boundary cut in the middle reads as its two real pieces.
    final divideEnds = [
      for (final line in cutLines) ...[line.a, line.b],
    ];
    for (var i = 0; i < verts.length; i++) {
      final a = verts[i];
      final b = verts[(i + 1) % verts.length];
      for (final (p, q) in LotDivision.splitEdge(a, b, divideEnds)) {
        final pa = _at(p);
        final qa = _at(q);
        // Too short to letter without the labels colliding.
        if ((qa - pa).distance < 26) continue;
        final ang = math.atan2(q.y - p.y, q.x - p.x);
        final off = Offset(-math.sin(ang) * 11, math.cos(ang) * 11);
        _label(
          canvas,
          Offset((pa.dx + qa.dx) / 2, (pa.dy + qa.dy) / 2) + off,
          '${lengthUnit.format(Geometry.sideLength(p, q))} $lengthLabel',
          AppColors.text.withValues(alpha: 0.75),
        );
      }
    }

    // Dividers, with their own length and a handle at each end.
    for (final line in cutLines) {
      final a = _at(line.a);
      final b = _at(line.b);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 2
          ..color = AppColors.text.withValues(alpha: 0.9),
      );
      _label(
        canvas,
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
        '${lengthUnit.format(line.lengthM)} $lengthLabel',
        AppColors.text,
      );
      for (final end in [a, b]) {
        canvas.drawCircle(end, 7, Paint()..color = AppColors.ink);
        canvas.drawCircle(
          end,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.text,
        );
      }
    }

    // Lot names, centred on the piece they belong to.
    for (var i = 0; i < lots.length; i++) {
      final poly = lots[i].vertices;
      if (poly.isEmpty) continue;
      var sx = 0.0, sy = 0.0;
      for (final v in poly) {
        sx += v.x;
        sy += v.y;
      }
      final mid = _at(Vertex(sx / poly.length, sy / poly.length));
      final tp = TextPainter(
        text: TextSpan(
          text: names[i].toUpperCase(),
          style: AppTypography.mono(
            size: 10,
            weight: FontWeight.w600,
            color: colours[i % colours.length],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DivisionPainter old) =>
      old.verts != verts ||
      old.cutLines != cutLines ||
      old.scale != scale ||
      old.center != center ||
      old.lots.length != lots.length;
}

/// One lot: its colour, name, share and area — and, in percent or area
/// mode, a field for saying how big it should be.
class _LotTile extends StatelessWidget {
  final int index;
  final Lot lot;
  final Color colour;
  final String name;
  final double totalSqm;
  final AreaUnit areaUnit;
  final _SplitMode mode;
  final Color accent;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<double> onShare;

  const _LotTile({
    required this.index,
    required this.lot,
    required this.colour,
    required this.name,
    required this.totalSqm,
    required this.areaUnit,
    required this.mode,
    required this.accent,
    required this.canRemove,
    required this.onRemove,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 34,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(size: 12, weight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(lot.share * 100).toStringAsFixed(1)}% · '
                  '${areaUnit.format(lot.areaSqm)} '
                  '${areaUnit.labelOf(context.l10n)}',
                  style: AppTypography.mono(size: 10, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          if (mode != _SplitMode.equal)
            SizedBox(
              width: 96,
              child: _ShareField(
                key: ValueKey('$index-${mode.name}'),
                mode: mode,
                share: lot.share,
                totalSqm: totalSqm,
                areaUnit: areaUnit,
                accent: accent,
                onShare: onShare,
              ),
            ),
          if (canRemove)
            IconButton(
              tooltip: context.l10n.subdivideRemoveLot,
              onPressed: onRemove,
              icon: const Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: AppColors.textFaint,
              ),
            ),
        ],
      ),
    );
  }
}

/// Types a lot's size, as a percentage or as an area depending on the mode.
class _ShareField extends StatefulWidget {
  final _SplitMode mode;
  final double share;
  final double totalSqm;
  final AreaUnit areaUnit;
  final Color accent;
  final ValueChanged<double> onShare;

  const _ShareField({
    super.key,
    required this.mode,
    required this.share,
    required this.totalSqm,
    required this.areaUnit,
    required this.accent,
    required this.onShare,
  });

  @override
  State<_ShareField> createState() => _ShareFieldState();
}

class _ShareFieldState extends State<_ShareField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _text());

  String _text() {
    final v = widget.mode == _SplitMode.percent
        ? widget.share * 100
        : widget.areaUnit.fromSqm(widget.share * widget.totalSqm);
    return v
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void didUpdateWidget(_ShareField old) {
    super.didUpdateWidget(old);
    final typed = double.tryParse(_ctrl.text);
    final shown = typed == null
        ? null
        : widget.mode == _SplitMode.percent
        ? typed / 100
        : widget.areaUnit.toSqm(typed) / widget.totalSqm;
    // Leave the field alone while it still represents this lot, so typing
    // is never corrected mid-keystroke.
    if (shown == null || (shown - widget.share).abs() > 1e-4) {
      _ctrl.text = _text();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      cursorColor: widget.accent,
      style: AppTypography.mono(
        size: 13,
        weight: FontWeight.w600,
        color: widget.accent,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        suffixText: widget.mode == _SplitMode.percent
            ? '%'
            : widget.areaUnit.labelOf(context.l10n),
        suffixStyle: AppTypography.mono(size: 9, color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.accent),
        ),
      ),
      onChanged: (raw) {
        final v = double.tryParse(raw);
        if (v == null || v <= 0) return;
        widget.onShare(
          widget.mode == _SplitMode.percent
              ? v / 100
              : widget.areaUnit.toSqm(v) / widget.totalSqm,
        );
      },
    );
  }
}

/// Equal / Percent / Area, and the button that adds another lot.
class _ModeRow extends StatelessWidget {
  final _SplitMode mode;
  final Color accent;
  final VoidCallback onEqual;
  final ValueChanged<_SplitMode> onMode;
  final VoidCallback onAdd;

  const _ModeRow({
    required this.mode,
    required this.accent,
    required this.onEqual,
    required this.onMode,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (_SplitMode.equal, context.l10n.subdivideModeEqual),
      (_SplitMode.percent, context.l10n.subdivideModePercent),
      (_SplitMode.area, context.l10n.subdivideModeArea),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (m, label) in options) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _Pill(
                  label: label,
                  active: mode == m,
                  accent: accent,
                  onTap: () => m == _SplitMode.equal ? onEqual() : onMode(m),
                ),
              ),
            ),
          ],
          _Pill(
            label: context.l10n.subdivideAddLot,
            active: false,
            accent: accent,
            icon: Icons.add,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final IconData? icon;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accent : AppColors.ink,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: active ? AppColors.ink : accent,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                maxLines: 1,
                style: AppTypography.sans(
                  size: 11,
                  weight: FontWeight.w500,
                  color: active ? AppColors.ink : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

