import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/export/plot_pdf.dart';
import '../../../../core/export/sheet_summary.dart';
import '../../../../core/geometry/map_align.dart';
import '../../../../core/geometry/map_scale.dart';
import '../../../../core/geometry/polygon_overlap.dart';
import '../../../../core/units/area_unit.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../l10n/l10n.dart';
import 'overlay_canvas.dart';

/// A plot traced on the overlay, in map A's pixels.
class OverlayPlot {
  final String name;
  final List<Offset> points;

  /// Traced on the new survey's lines (B) rather than the old one's (A).
  final bool onNew;
  const OverlayPlot(this.name, this.points, this.onNew);
}

/// How much of an old-survey plot lies in a new-survey one.
class OverlapRow {
  final OverlayPlot old;
  final OverlayPlot newer;

  /// Shared area in map A's square pixels.
  final double px2;
  const OverlapRow(this.old, this.newer, this.px2);

  double get ofOld => px2 / PolygonOverlap.area(old.points);
  double get ofNew => px2 / PolygonOverlap.area(newer.points);
}

/// The comparison's numbers, and its PDF.
class OverlayReport {
  OverlayReport._();

  /// Every old/new pair of plots that share any ground, largest first.
  static List<OverlapRow> overlaps(List<OverlayPlot> plots) {
    final rows = <OverlapRow>[];
    for (final o in plots.where((p) => !p.onNew)) {
      for (final n in plots.where((p) => p.onNew)) {
        final a = PolygonOverlap.intersectionArea(o.points, n.points);
        // Slivers from tracing the same shared boundary twice are noise.
        final smaller = [
          PolygonOverlap.area(o.points),
          PolygonOverlap.area(n.points),
        ].reduce((x, y) => x < y ? x : y);
        if (a > smaller * 0.002) rows.add(OverlapRow(o, n, a));
      }
    }
    rows.sort((x, y) => y.px2.compareTo(x.px2));
    return rows;
  }

  /// The overlay around the traced plots, drawn off screen at print
  /// resolution.
  static Future<Uint8List> renderImage(
    OverlayFrame frame,
    List<OverlayPlot> plots,
  ) async {
    var region = Rect.fromLTWH(
      0,
      0,
      frame.a.width.toDouble(),
      frame.a.height.toDouble(),
    );
    if (plots.isNotEmpty) {
      var r = Rect.fromPoints(
        plots.first.points.first,
        plots.first.points.first,
      );
      for (final p in plots) {
        for (final q in p.points) {
          r = r.expandToInclude(
            Rect.fromCenter(center: q, width: 0, height: 0),
          );
        }
      }
      final pad = (r.longestSide * 0.35).clamp(40.0, double.infinity);
      region = r.inflate(pad);
    }
    // Drawn at half size and doubled, so lines and labels print at a
    // readable weight rather than hairline thin.
    const logicalWidth = 700.0;
    final logicalHeight = (logicalWidth * region.height / region.width).clamp(
      200.0,
      900.0,
    );
    final scale =
        (logicalWidth / region.width) < (logicalHeight / region.height)
        ? logicalWidth / region.width
        : logicalHeight / region.height;
    final offset =
        Offset(logicalWidth, logicalHeight) / 2 - region.center * scale;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)..scale(2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, logicalWidth, logicalHeight),
      Paint()..color = Colors.white,
    );
    paintOverlayScene(
      canvas,
      frame,
      scale,
      offset,
      size: Size(logicalWidth, logicalHeight),
    );
    final img = await rec.endRecording().toImage(
      (logicalWidth * 2).round(),
      (logicalHeight * 2).round(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return data!.buffer.asUint8List();
  }

  static Future<Uint8List> build({
    required AppLocalizations t,
    required Uint8List image,
    required List<OverlayPlot> plots,
    required MapScale scale,
    required MapAlignment alignment,
    required String labelOld,
    required String labelNew,
    required AreaUnit areaUnit,
    required LengthUnit lengthUnit,
    required double imageWidth,
    DateTime? date,
  }) async {
    final mpp = scale.metersPerPixel;
    String area(double px2) =>
        '${areaUnit.format(px2 * mpp * mpp)} ${areaUnit.labelOf(t)}';
    final quality = switch (alignment.quality(imageWidth)) {
      AlignQuality.good => t.overlayQualityGood,
      AlignQuality.fair => t.overlayQualityFair,
      AlignQuality.poor => t.overlayQualityPoor,
      AlignQuality.unchecked => t.overlayQualityUnchecked(
        4 - alignment.pairs.length,
      ),
    };
    final rows = overlaps(plots);
    final text = [
      t.overlayReportTitle,
      labelOld,
      labelNew,
      quality,
      for (final p in plots) p.name,
    ].join(' ');
    final theme = await PlotPdf.themeFor(bengali: PlotPdf.hasBengali(text));
    pw.Widget txt(String s, pw.TextStyle st) => PlotPdf.text(s, st);
    final small = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final head = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey800,
    );
    const cell = pw.TextStyle(fontSize: 10);
    pw.Widget c(String s, pw.TextStyle st, {bool right = false}) =>
        pw.Container(
          alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: txt(s, st),
        );
    pw.Widget swatch(PdfColor color, String label) => pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(width: 10, height: 10, color: color),
        pw.SizedBox(width: 4),
        txt(label, const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(width: 14),
      ],
    );
    PdfColor pdf(Color c) => PdfColor(c.r, c.g, c.b);

    final mismatch =
        '${lengthUnit.format(alignment.rms * mpp)} ${lengthUnit.labelOf(t)}';
    final when = DateFormat.yMMMd().format(date ?? DateTime.now());

    final doc = pw.Document(title: '$labelOld ↔ $labelNew');
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [txt(t.appName, small), txt(t.sheetPrepared(when), small)],
        ),
        build: (_) => [
          txt(t.overlayReportTitle.toUpperCase(), small),
          pw.SizedBox(height: 4),
          txt(
            '$labelOld ↔ $labelNew',
            pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          txt(
            t.overlayReportMatched(alignment.pairs.length, quality),
            const pw.TextStyle(fontSize: 11),
          ),
          if (alignment.checkable)
            txt(t.overlayReportMismatch(mismatch), small),
          pw.SizedBox(height: 12),
          pw.Image(pw.MemoryImage(image), fit: pw.BoxFit.contain),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              swatch(pdf(oldInk), labelOld),
              swatch(pdf(newInk), labelNew),
              swatch(pdf(overlapInk), t.overlayOverlapHeader),
            ],
          ),
          pw.SizedBox(height: 16),
          txt(t.overlayPlotsHeader, small),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  c(t.overlayReportMap, head),
                  c(t.sheetColPlot, head),
                  c(t.drawArea, head, right: true),
                ],
              ),
              for (final p in plots)
                pw.TableRow(
                  children: [
                    c(p.onNew ? labelNew : labelOld, cell),
                    c(p.name, cell),
                    c(area(PolygonOverlap.area(p.points)), cell, right: true),
                  ],
                ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            txt(t.overlayOverlapHeader, small),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    c(labelOld, head),
                    c(labelNew, head),
                    c(t.drawArea, head, right: true),
                    c('% $labelOld', head, right: true),
                    c('% $labelNew', head, right: true),
                  ],
                ),
                for (final r in rows)
                  pw.TableRow(
                    children: [
                      c(r.old.name, cell),
                      c(r.newer.name, cell),
                      c(area(r.px2), cell, right: true),
                      c(SheetSummary.percent(r.ofOld), cell, right: true),
                      c(SheetSummary.percent(r.ofNew), cell, right: true),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> share({
    required AppLocalizations t,
    required OverlayFrame frame,
    required List<OverlayPlot> plots,
    required MapScale scale,
    required MapAlignment alignment,
    required String labelOld,
    required String labelNew,
    required AreaUnit areaUnit,
    required LengthUnit lengthUnit,
  }) async {
    final image = await renderImage(frame, plots);
    final bytes = await build(
      t: t,
      image: image,
      plots: plots,
      scale: scale,
      alignment: alignment,
      labelOld: labelOld,
      labelNew: labelNew,
      areaUnit: areaUnit,
      lengthUnit: lengthUnit,
      imageWidth: frame.a.width.toDouble(),
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'pantograph-${labelOld.toLowerCase()}-'
          '${labelNew.toLowerCase()}.pdf',
    );
  }
}
