import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../l10n/l10n.dart';
import '../geometry/geometry.dart';
import '../geometry/sheet_layout.dart';
import '../geometry/vertex.dart';
import '../units/length_unit.dart';
import 'plot_pdf.dart';
import 'sheet_summary.dart';

/// Renders a sheet as an A4 document: one table row per plot, then the
/// totals. Black on white like the single-plot PDF, because it is meant to
/// be printed.
class SheetPdf {
  const SheetPdf._();

  static Future<Uint8List> build(
    SheetSummary s,
    AppLocalizations t, {
    DateTime? date,
    Map<String, PlotPlacement> layout = const {},
    LengthUnit lengthUnit = LengthUnit.ft,
  }) async {
    final doc = pw.Document(title: s.name);
    final theme = await PlotPdf.themeFor(
      bengali: PlotPdf.hasBengali(s.asText(t)),
    );
    final when = DateFormat.yMMMd().format(date ?? DateTime.now());

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _text(t.appName, _small),
                _text(t.sheetPrepared(when), _small),
              ],
            ),
          ],
        ),
        build: (context) => [
          _text(
            t.sheetTitle.toUpperCase(),
            pw.TextStyle(
              fontSize: 9,
              letterSpacing: 1.4,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          _text(
            s.name,
            pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 18),
          _totals(s, t),
          pw.SizedBox(height: 18),
          if (s.rows.isNotEmpty) ...[
            _text(
              t.sheetLayoutHeader,
              pw.TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            _layout(s, layout, lengthUnit, lengthUnit.labelOf(t)),
            pw.SizedBox(height: 18),
          ],
          _table(s, t),
        ],
      ),
    );

    return doc.save();
  }

  static final _small = pw.TextStyle(fontSize: 9, color: PdfColors.grey600);

  static pw.Widget _text(String v, pw.TextStyle style) =>
      PlotPdf.text(v, style);

  static pw.Widget _totals(SheetSummary s, AppLocalizations t) {
    final chain = s.breakdownLine(t);
    final label = pw.TextStyle(
      fontSize: 9,
      letterSpacing: 1.2,
      color: PdfColors.grey700,
    );
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _text(t.sheetTotalArea(s.rows.length), label),
          pw.SizedBox(height: 4),
          _text(
            s.area(s.totalSqm, t),
            pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          if (chain.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _text(
              chain,
              const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
            ),
          ],
          if (s.hasPrice) ...[
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _text(t.sheetRate, label),
                      pw.SizedBox(height: 2),
                      _text(s.rateLine(t), const pw.TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _text(t.sheetTotalValue, label),
                      pw.SizedBox(height: 2),
                      _text(
                        SheetSummary.money(s.totalValue!),
                        pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _table(SheetSummary s, AppLocalizations t) {
    final head = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey800,
    );
    const cell = pw.TextStyle(fontSize: 10);
    final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final n = NumberFormat.decimalPattern();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FixedColumnWidth(44),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(48),
        if (s.hasPrice) 5: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('#', head),
            _cell('', head),
            _cell(t.sheetColPlot, head),
            _cell(t.drawArea, head, right: true),
            _cell(t.sheetColShare, head, right: true),
            if (s.hasPrice) _cell(t.sheetColValue, head, right: true),
          ],
        ),
        for (var i = 0; i < s.rows.length; i++)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _cell(n.format(i + 1), cell),
              pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: _shape(s.rows[i].vertices),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _text(s.rows[i].name, cell),
                    _text(s.rows[i].tag.labelOf(t), _small),
                  ],
                ),
              ),
              _cell(s.area(s.rows[i].areaSqm, t), cell, right: true),
              _cell(
                SheetSummary.percent(s.shareOf(s.rows[i])),
                cell,
                right: true,
              ),
              if (s.hasPrice)
                _cell(
                  SheetSummary.money(s.valueOf(s.rows[i].areaSqm)!),
                  cell,
                  right: true,
                ),
            ],
          ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _cell('', bold),
            _cell('', bold),
            _cell(t.compareTotal, bold),
            _cell(s.area(s.totalSqm, t), bold, right: true),
            _cell(
              SheetSummary.percent(s.rows.isEmpty ? 0 : 1),
              bold,
              right: true,
            ),
            if (s.hasPrice)
              _cell(SheetSummary.money(s.totalValue!), bold, right: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(String v, pw.TextStyle style, {bool right = false}) =>
      pw.Container(
        alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: _text(v, style),
      );

  /// Every plot where the sheet's canvas puts it, at one shared scale and
  /// numbered like the table rows, so the page shows how the land fits
  /// together.
  static pw.Widget _layout(
    SheetSummary s,
    Map<String, PlotPlacement> layout,
    LengthUnit lengthUnit,
    String lengthLabel,
  ) {
    const width = 523.0, height = 210.0, pad = 12.0;
    final shapes = [for (final r in s.rows) (r.plotId, r.vertices)];
    final full = SheetLayout.fill(shapes, layout);
    final outlines = [
      for (final r in s.rows) SheetLayout.place(r.vertices, full[r.plotId]!),
    ];
    final (minX, minY, maxX, maxY) = SheetLayout.bounds(shapes, full)!;
    final w = (maxX - minX).clamp(1e-6, double.infinity);
    final h = (maxY - minY).clamp(1e-6, double.infinity);
    final sc = [
      (width - pad * 2) / w,
      (height - pad * 2) / h,
    ].reduce((a, b) => a < b ? a : b);
    final ox = (width - w * sc) / 2, oy = (height - h * sc) / 2;
    // Page coordinates measured from the top, as the labels use them.
    double px(double x) => ox + (x - minX) * sc;
    double py(double y) => oy + (y - minY) * sc;
    final n = NumberFormat.decimalPattern();

    // Side lengths: at each side's middle, just inside the plot, dropped
    // where the side is too short or the label would cover another.
    final taken = <PdfRect>[];
    final sideLabels = <pw.Widget>[];
    for (final poly in outlines) {
      if (poly.length < 3) continue;
      final c = SheetLayout.centroid(poly);
      final cx = px(c.x), cy = py(c.y);
      taken.add(PdfRect(cx - 12, cy - 7, 24, 14));
      for (var i = 0; i < poly.length; i++) {
        final a = poly[i], b = poly[(i + 1) % poly.length];
        final text =
            '${lengthUnit.format(Geometry.sideLength(a, b))} '
            '$lengthLabel';
        final lw = text.length * 4.0 + 6, lh = 10.0;
        final ax = px(a.x), ay = py(a.y), bx = px(b.x), by = py(b.y);
        final ex = bx - ax, ey = by - ay;
        final len = (ex * ex + ey * ey) == 0 ? 0.0 : _hyp(ex, ey);
        if (len < lw + 6) continue;
        var nx = -ey / len, ny = ex / len;
        final mx = (ax + bx) / 2, my = (ay + by) / 2;
        if ((cx - mx) * nx + (cy - my) * ny < 0) {
          nx = -nx;
          ny = -ny;
        }
        final lx = mx + nx * 8, ly = my + ny * 8;
        final r = PdfRect(lx - lw / 2, ly - lh / 2, lw, lh);
        if (taken.any((o) => _overlaps(o, r))) continue;
        taken.add(r);
        sideLabels.add(
          pw.Positioned(
            left: r.left,
            top: r.bottom, // PdfRect's "bottom" is its smaller y: the top here
            child: pw.SizedBox(
              width: lw,
              height: lh,
              child: pw.Center(
                child: _text(
                  text,
                  const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                ),
              ),
            ),
          ),
        );
      }
    }

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Stack(
        children: [
          pw.CustomPaint(
            size: const PdfPoint(width, height),
            painter: (canvas, size) {
              for (final poly in outlines) {
                if (poly.length < 3) continue;
                for (var i = 0; i < poly.length; i++) {
                  // PDF's y axis points up.
                  final x = px(poly[i].x), y = size.y - py(poly[i].y);
                  if (i == 0) {
                    canvas.moveTo(x, y);
                  } else {
                    canvas.lineTo(x, y);
                  }
                }
                canvas
                  ..setFillColor(PdfColors.grey100)
                  ..setStrokeColor(PdfColors.grey800)
                  ..setLineWidth(0.9)
                  ..fillAndStrokePath(close: true);
              }
            },
          ),
          for (var i = 0; i < outlines.length; i++)
            if (outlines[i].length >= 3)
              pw.Positioned(
                left: px(SheetLayout.centroid(outlines[i]).x) - 12,
                top: py(SheetLayout.centroid(outlines[i]).y) - 7,
                child: pw.SizedBox(
                  width: 24,
                  child: pw.Center(
                    child: _text(
                      n.format(i + 1),
                      pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ...sideLabels,
        ],
      ),
    );
  }

  static double _hyp(double x, double y) => math.sqrt(x * x + y * y);

  static bool _overlaps(PdfRect a, PdfRect b) =>
      a.left < b.right &&
      b.left < a.right &&
      a.bottom < b.top &&
      b.bottom < a.top;

  /// The plot outline, fitted into a small box. Drawn as vector paths, so
  /// it stays sharp when printed.
  static pw.Widget _shape(List<Vertex> verts) => pw.CustomPaint(
    size: const PdfPoint(38, 28),
    painter: (canvas, size) {
      if (verts.length < 3) return;
      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      for (final v in verts) {
        if (v.x < minX) minX = v.x;
        if (v.y < minY) minY = v.y;
        if (v.x > maxX) maxX = v.x;
        if (v.y > maxY) maxY = v.y;
      }
      final w = maxX - minX, h = maxY - minY;
      if (w == 0 || h == 0) return;
      const pad = 2.0;
      final sx = (size.x - pad * 2) / w;
      final sy = (size.y - pad * 2) / h;
      final sc = sx < sy ? sx : sy;
      final ox = (size.x - w * sc) / 2;
      final oy = (size.y - h * sc) / 2;
      // PDF's y axis points up and the plot's points down, so flip it.
      for (var i = 0; i < verts.length; i++) {
        final x = ox + (verts[i].x - minX) * sc;
        final y = size.y - (oy + (verts[i].y - minY) * sc);
        if (i == 0) {
          canvas.moveTo(x, y);
        } else {
          canvas.lineTo(x, y);
        }
      }
      canvas
        ..setFillColor(PdfColors.grey200)
        ..setStrokeColor(PdfColors.grey800)
        ..setLineWidth(0.8)
        ..fillAndStrokePath(close: true);
    },
  );
}
