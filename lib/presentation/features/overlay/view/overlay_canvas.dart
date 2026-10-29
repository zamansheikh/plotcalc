import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/geometry/map_align.dart';
import '../../../../core/geometry/map_scale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/length_unit.dart';
import '../../draw/view/plot_labels.dart';

/// Ink colours for the two surveys once laid over each other: the old one
/// blue, the new one red, so a line on both reads purple — the light-table
/// look amins know from tracing paper.
const oldInk = Color(0xFF1D4ED8);
const newInk = Color(0xFFDC2626);
const overlapInk = Color(0xFF7C3AED);

/// Turns a scanned sheet into clean ink on white: paper (anything brighter
/// than [_paper]) becomes pure white and lines darker than [_line] take the
/// full [ink]. A colour matrix cannot threshold, but a steep brightness
/// ramp clamped at both ends does the same job. Old sheets are rarely
/// white — yellowed, grey or shadowed — so the ramp sits well below white.
const _line = 0.35, _paper = 0.68;

ColorFilter inkFilter(Color ink) {
  const k = 1 / (_paper - _line);
  List<double> row(double c) => [
    (1 - c) * k * 0.299,
    (1 - c) * k * 0.587,
    (1 - c) * k * 0.114,
    0,
    (c - (1 - c) * k * _line) * 255,
  ];
  return ColorFilter.matrix([
    ...row(ink.r),
    ...row(ink.g),
    ...row(ink.b),
    0, 0, 0, 1, 0, //
  ]);
}

/// What the canvas shows.
enum OverlayView { a, b, both }

/// A traced plot, in map A's pixels.
class OverlayShape {
  final List<Offset> points;
  final Color color;
  final String label;
  const OverlayShape(this.points, this.color, this.label);
}

/// Everything one frame of the comparison canvas needs.
class OverlayFrame {
  final ui.Image a;
  final ui.Image b;

  /// Maps B's pixels onto A's. Null until two pairs are matched.
  final PlaneTransform? bToA;
  final OverlayView view;

  /// 0 = only A, 1 = only B, ½ = both at full strength.
  final double mix;
  final bool tint;

  /// Matched places: (on A, on B).
  final List<(Offset, Offset)> pairs;
  final List<Color> pairColors;
  final int? selectedPair;

  /// A place marked on one map and waiting for its twin on the other.
  final Offset? pendingA;
  final Offset? pendingB;

  final List<Offset> scalePoints;
  final String? scaleLabel;
  final MapScale? mapScale;
  final List<OverlayShape> plots;
  final List<Offset> draft;
  final Color draftColor;
  final Color accent;
  final LengthUnit lengthUnit;
  final String lengthLabel;
  final String meterLabel;

  const OverlayFrame({
    required this.a,
    required this.b,
    required this.bToA,
    required this.view,
    required this.mix,
    required this.tint,
    required this.pairs,
    required this.pairColors,
    required this.accent,
    required this.lengthUnit,
    required this.lengthLabel,
    required this.meterLabel,
    this.selectedPair,
    this.pendingA,
    this.pendingB,
    this.scalePoints = const [],
    this.scaleLabel,
    this.mapScale,
    this.plots = const [],
    this.draft = const [],
    this.draftColor = oldInk,
  });

  /// The image the view draws in its own pixels.
  ui.Image get base => view == OverlayView.b ? b : a;
}

/// Paints [frame] at a given view: screen = image pixel × [scale] + [offset].
/// Also used, at a larger zoom, inside the magnifier and the reference
/// inset, and off screen for the PDF report.
void paintOverlayScene(
  Canvas canvas,
  OverlayFrame f,
  double scale,
  Offset offset, {
  bool labels = true,
  Size size = const Size(1e6, 1e6),
  List<Rect> avoid = const [],
}) {
  Offset px(Offset p) => p * scale + offset;
  // Every label placed so far, and the canvas's own controls ([avoid]);
  // later labels keep clear of them.
  final taken = <LabelBox>[for (final r in avoid) LabelBox.rect(r)];
  final lengthStyle = AppTypography.mono(
    size: 10,
    weight: FontWeight.w600,
    color: AppColors.text,
  );
  String length(List<Offset> outline, int i) {
    final m = f.mapScale!.lengthOf(
      outline[i],
      outline[(i + 1) % outline.length],
    );
    return '${f.lengthUnit.format(m)} ${f.lengthLabel}';
  }

  // Paper.
  final paper = Rect.fromLTWH(
    offset.dx,
    offset.dy,
    f.base.width * scale,
    f.base.height * scale,
  );

  if (f.view == OverlayView.both && f.bToA != null) {
    final aAlpha = (2 * (1 - f.mix)).clamp(0.0, 1.0);
    final bAlpha = (2 * f.mix).clamp(0.0, 1.0);
    canvas.drawRect(paper, Paint()..color = Colors.white);
    _drawImage(canvas, f.a, scale, offset, f.tint ? oldInk : null, aAlpha);
    // B through the fitted transform, multiplied in so both sets of lines
    // stay visible and white stays white.
    canvas.saveLayer(
      null,
      Paint()
        ..blendMode = BlendMode.multiply
        ..color = Color.fromRGBO(0, 0, 0, bAlpha),
    );
    canvas
      ..translate(offset.dx, offset.dy)
      ..scale(scale)
      ..transform(f.bToA!.toMatrix4());
    canvas.drawImage(
      f.b,
      Offset.zero,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = f.tint ? inkFilter(newInk) : null,
    );
    canvas.restore();
  } else {
    _drawImage(canvas, f.base, scale, offset, null, 1);
  }

  // Matched places.
  for (var i = 0; i < f.pairs.length; i++) {
    final (pa, pb) = f.pairs[i];
    final color = f.pairColors[i];
    final selected = f.selectedPair == i;
    switch (f.view) {
      case OverlayView.a:
        _marker(canvas, px(pa), color, '${i + 1}', selected: selected);
      case OverlayView.b:
        _marker(canvas, px(pb), color, '${i + 1}', selected: selected);
      case OverlayView.both:
        final t = f.bToA;
        if (t == null) break;
        // Where B's mark lands against A's: a short line shows the miss.
        final q = px(t.apply(pb));
        canvas.drawLine(
          px(pa),
          q,
          Paint()
            ..color = color
            ..strokeWidth = 2,
        );
        _marker(canvas, px(pa), color, '${i + 1}', selected: selected);
    }
  }
  final pending = f.view == OverlayView.a
      ? f.pendingA
      : (f.view == OverlayView.b ? f.pendingB : null);
  if (pending != null) {
    _marker(canvas, px(pending), f.accent, '?', selected: true);
  }

  // Plots and where they overlap.
  if (f.view == OverlayView.both) {
    final paths = [
      for (final s in f.plots)
        Path()..addPolygon([for (final p in s.points) px(p)], true),
    ];
    for (var i = 0; i < f.plots.length; i++) {
      canvas
        ..drawPath(
          paths[i],
          Paint()..color = f.plots[i].color.withValues(alpha: 0.14),
        )
        ..drawPath(
          paths[i],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeJoin = StrokeJoin.round
            ..color = f.plots[i].color,
        );
    }
    for (var i = 0; i < f.plots.length; i++) {
      for (var j = i + 1; j < f.plots.length; j++) {
        if (f.plots[i].color == f.plots[j].color) continue;
        final shared = Path.combine(
          PathOperation.intersect,
          paths[i],
          paths[j],
        );
        canvas.drawPath(
          shared,
          Paint()..color = overlapInk.withValues(alpha: 0.38),
        );
      }
    }
    if (labels) {
      // Names first, in the middle of each plot; then every side's length
      // of every plot, placed so that none covers another.
      for (var i = 0; i < f.plots.length; i++) {
        final s = f.plots[i];
        if (s.points.length < 3) continue;
        final c = s.points.reduce((x, y) => x + y) / s.points.length.toDouble();
        taken.add(
          LabelBox.rect(
            _pill(canvas, px(c), s.label, fill: s.color, ink: Colors.white),
          ),
        );
      }
      if (f.mapScale != null) {
        for (final s in f.plots) {
          if (s.points.length < 3) continue;
          taken.addAll(
            paintSideLengths(
              canvas,
              [for (final p in s.points) px(p)],
              text: (i) => length(s.points, i),
              style: lengthStyle,
              fill: AppColors.ink.withValues(alpha: 0.85),
              border: s.color.withValues(alpha: 0.8),
              bounds: size,
              reserved: taken,
            ),
          );
        }
      }
    }

    // The plot being traced.
    if (f.draft.isNotEmpty) {
      final pts = [for (final p in f.draft) px(p)];
      final edge = Paint()
        ..color = f.draftColor
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      if (pts.length >= 3) {
        canvas.drawPath(
          Path()..addPolygon(pts, true),
          Paint()..color = f.draftColor.withValues(alpha: 0.18),
        );
        canvas.drawLine(
          pts.last,
          pts.first,
          Paint()
            ..color = f.draftColor.withValues(alpha: 0.5)
            ..strokeWidth = 2,
        );
      }
      for (var i = 0; i + 1 < pts.length; i++) {
        canvas.drawLine(pts[i], pts[i + 1], edge);
      }
      if (labels && f.mapScale != null) {
        paintSideLengths(
          canvas,
          pts,
          text: (i) => length(f.draft, i),
          style: lengthStyle,
          fill: AppColors.ink.withValues(alpha: 0.9),
          border: f.draftColor,
          bounds: size,
          reserved: taken,
        );
      }
      for (final p in pts) {
        _dot(canvas, p, f.draftColor);
      }
    }
  }

  // The known line used for the scale.
  if (f.view == OverlayView.both && f.scalePoints.isNotEmpty) {
    final pts = [for (final p in f.scalePoints) px(p)];
    if (pts.length == 2) {
      canvas.drawLine(
        pts[0],
        pts[1],
        Paint()
          ..color = AppColors.amber
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      if (labels && f.scaleLabel != null) {
        _pill(
          canvas,
          (pts[0] + pts[1]) / 2 + const Offset(0, -16),
          f.scaleLabel!,
          fill: AppColors.amber,
          ink: AppColors.ink,
        );
      }
    }
    for (var i = 0; i < pts.length; i++) {
      _marker(canvas, pts[i], AppColors.amber, '${i + 1}');
    }
  }
}

void _drawImage(
  Canvas canvas,
  ui.Image img,
  double scale,
  Offset offset,
  Color? ink,
  double alpha,
) {
  if (alpha <= 0) return;
  canvas.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    Rect.fromLTWH(offset.dx, offset.dy, img.width * scale, img.height * scale),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(0, 0, 0, alpha)
      ..colorFilter = ink == null ? null : inkFilter(ink),
  );
}

void _dot(Canvas canvas, Offset at, Color color) {
  canvas
    ..drawCircle(at, 9, Paint()..color = Colors.white.withValues(alpha: 0.8))
    ..drawCircle(at, 6.5, Paint()..color = color)
    ..drawCircle(at, 2.6, Paint()..color = Colors.white);
}

void _marker(
  Canvas canvas,
  Offset at,
  Color color,
  String label, {
  bool selected = false,
}) {
  final r = selected ? 9.0 : 7.0;
  canvas
    ..drawCircle(
      at,
      r + 3,
      Paint()..color = AppColors.ink.withValues(alpha: 0.6),
    )
    ..drawCircle(at, r, Paint()..color = color)
    ..drawCircle(at, r * 0.4, Paint()..color = AppColors.ink);
  if (selected) {
    canvas.drawCircle(
      at,
      r + 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: AppTypography.mono(
        size: 10,
        weight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final c = at + const Offset(13, -13);
  canvas.drawCircle(c, math.max(8, tp.width / 2 + 4), Paint()..color = color);
  tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
}

Rect _pill(
  Canvas canvas,
  Offset center,
  String text, {
  required Color fill,
  required Color ink,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: ink),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center,
      width: tp.width + 10,
      height: tp.height + 4,
    ),
    const Radius.circular(5),
  );
  canvas.drawRRect(r, Paint()..color = fill);
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  return r.outerRect;
}

/// The interactive canvas: the scene, a scale bar, a reference inset (the
/// other map, around the place being matched) and the magnifier.
class OverlayPainter extends CustomPainter {
  final OverlayFrame frame;
  final double scale;
  final Offset offset;

  /// Around a point on the *other* map: what to look for on this one.
  final ({ui.Image image, Offset at, String label, Color color})? inset;

  /// While dragging: the finger, and the point being moved (this view's
  /// image pixels).
  final Offset? finger;
  final Offset? dragPoint;

  const OverlayPainter({
    required this.frame,
    required this.scale,
    required this.offset,
    this.inset,
    this.finger,
    this.dragPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.surface);
    paintOverlayScene(
      canvas,
      frame,
      scale,
      offset,
      size: size,
      avoid: mapControlAreas(size, inset: inset != null),
    );
    if (frame.mapScale != null && frame.view == OverlayView.both) {
      _scaleBar(canvas, size);
    }
    _inset(canvas, size);
    _loupe(canvas, size);
  }

  void _scaleBar(Canvas canvas, Size size) {
    final mPerPx = frame.mapScale!.metersPerPixel / scale;
    const steps = <double>[1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000];
    final m = steps.firstWhere((v) => v / mPerPx >= 60, orElse: () => 5000);
    final w = m / mPerPx;
    final left = 12.0, y = size.height - 14;
    for (final p in [
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.7)
        ..strokeWidth = 5,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 2,
    ]) {
      canvas
        ..drawLine(Offset(left, y), Offset(left + w, y), p)
        ..drawLine(Offset(left, y - 5), Offset(left, y + 2), p)
        ..drawLine(Offset(left + w, y - 5), Offset(left + w, y + 2), p);
    }
    _pill(
      canvas,
      Offset(left + w + 28, y - 1),
      '${m.round()} ${frame.meterLabel}',
      fill: AppColors.ink.withValues(alpha: 0.8),
      ink: AppColors.text,
    );
  }

  void _inset(Canvas canvas, Size size) {
    final i = inset;
    if (i == null) return;
    const radius = 54.0;
    const center = Offset(radius + 10, radius + 10);
    // Show about a twelfth of the other sheet's width across the circle.
    final z = (radius * 2) / (i.image.width / 12);
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      )
      ..drawColor(AppColors.surface, BlendMode.src);
    canvas.drawImageRect(
      i.image,
      Rect.fromLTWH(0, 0, i.image.width.toDouble(), i.image.height.toDouble()),
      Rect.fromLTWH(
        center.dx - i.at.dx * z,
        center.dy - i.at.dy * z,
        i.image.width * z,
        i.image.height * z,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final cross = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 1.4;
    canvas
      ..drawLine(
        center - const Offset(12, 0),
        center + const Offset(12, 0),
        cross,
      )
      ..drawLine(
        center - const Offset(0, 12),
        center + const Offset(0, 12),
        cross,
      )
      ..restore()
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = i.color,
      );
    _pill(
      canvas,
      center + const Offset(0, radius + 4),
      i.label,
      fill: i.color,
      ink: AppColors.ink,
    );
  }

  void _loupe(Canvas canvas, Size size) {
    final f = finger, p = dragPoint;
    if (f == null || p == null) return;
    const radius = 58.0;
    var center = f + const Offset(0, -110);
    if (center.dy < radius + 6) center = f + const Offset(0, 110);
    center = Offset(
      center.dx.clamp(radius + 6, size.width - radius - 6),
      center.dy.clamp(radius + 6, size.height - radius - 6),
    );
    final zoom = scale * 3;
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      )
      ..drawColor(AppColors.surface, BlendMode.src);
    paintOverlayScene(canvas, frame, zoom, center - p * zoom, labels: false);
    final cross = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 1.2;
    canvas
      ..drawLine(
        center - const Offset(14, 0),
        center + const Offset(14, 0),
        cross,
      )
      ..drawLine(
        center - const Offset(0, 14),
        center + const Offset(0, 14),
        cross,
      )
      ..restore()
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = frame.accent,
      );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter old) => true;
}

/// Parts of a map canvas covered by its own controls: zoom buttons (top
/// right), scale bar (bottom left) and, when shown, the reference circle
/// (top left). Labels placed there would be hidden.
List<Rect> mapControlAreas(Size size, {bool inset = false}) => [
  Rect.fromLTWH(size.width - 72, 0, 72, 136),
  Rect.fromLTWH(0, size.height - 34, 240, 34),
  if (inset) const Rect.fromLTWH(0, 0, 140, 150),
];
