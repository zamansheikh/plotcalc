import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../l10n/l10n.dart';
import '../geometry/division_plan.dart';
import '../geometry/geometry.dart';
import '../geometry/vertex.dart';
import '../units/area_breakdown.dart';
import '../units/area_unit.dart';
import '../units/length_unit.dart';
import 'plot_pdf.dart';
import 'sheet_summary.dart';

/// বণ্টননামা: a division drawn to print — who gets which piece, how big,
/// in which share, and what bounds it on each side.
class DivisionPdf {
  DivisionPdf._();

  static String cardinal(AppLocalizations t, Cardinal c) => switch (c) {
    Cardinal.north => t.cardinalNorth,
    Cardinal.east => t.cardinalEast,
    Cardinal.south => t.cardinalSouth,
    Cardinal.west => t.cardinalWest,
  };

  /// The share as the owner's row says it: what was typed, or what equal
  /// and blank entries amount to.
  static String shareText(
    AppLocalizations t,
    DivisionSpec spec,
    DivisionPiece p,
    double landSqm,
  ) {
    final pct = SheetSummary.percent(landSqm == 0 ? 0 : p.areaSqm / landSqm);
    final i = p.owner;
    if (i == null) return pct;
    final typed = spec.owners[i].amount.trim();
    return switch (spec.mode) {
      DivisionMode.equal =>
        '${NumberFormat.decimalPattern().format(1)}/'
            '${NumberFormat.decimalPattern().format(spec.owners.length)}',
      DivisionMode.shares => typed.isEmpty ? pct : typed,
      DivisionMode.areas => pct,
    };
  }

  static Future<Uint8List> build({
    required AppLocalizations t,
    required String plotName,
    required List<Vertex> parent,
    required DivisionSpec spec,
    required DivisionResult result,
    required String Function(DivisionPiece) nameOf,
    required AreaUnit areaUnit,
    required LengthUnit lengthUnit,
    required BreakdownConfig breakdown,
    DateTime? date,
  }) async {
    final total = Geometry.polygonArea(parent);
    final landSqm = Geometry.polygonArea(result.land);
    String area(double sqm) => '${areaUnit.format(sqm)} ${areaUnit.labelOf(t)}';
    String chain(double sqm) => AreaBreakdown.of(
      sqm,
      breakdown,
    ).parts.map((p) => '${p.formatted} ${p.unit.labelOf(t)}').join(' · ');
    String len(double m) => '${lengthUnit.format(m)} ${lengthUnit.labelOf(t)}';
    final n = NumberFormat.decimalPattern();

    final pieces = result.pieces;
    final lots = [
      for (var i = 0; i < pieces.length; i++)
        if (pieces[i].kind != PieceKind.road) i,
    ];
    final allText = [
      plotName,
      t.divisionPdfTitle,
      for (final p in pieces) nameOf(p),
    ].join(' ');
    final theme = await PlotPdf.themeFor(bengali: PlotPdf.hasBengali(allText));
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
    final when = DateFormat.yMMMd().format(date ?? DateTime.now());
    final numberOf = {for (var k = 0; k < lots.length; k++) lots[k]: k + 1};

    final doc = pw.Document(title: plotName);
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (_) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                txt(t.divisionPdfDisclaimer, small),
                txt('${t.appName} · ${t.sheetPrepared(when)}', small),
              ],
            ),
          ],
        ),
        build: (_) => [
          txt(t.divisionPdfTitle.toUpperCase(), small),
          pw.SizedBox(height: 4),
          txt(
            plotName,
            pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          txt(
            '${t.divisionPdfTotal}: ${area(total)}',
            const pw.TextStyle(fontSize: 12),
          ),
          if (chain(total).isNotEmpty) txt(chain(total), small),
          if (result.road != null)
            txt(
              '${t.divisionRoadWidth(len(spec.roadWidthM))}: '
              '${area(result.road!.areaSqm)}',
              small,
            ),
          pw.SizedBox(height: 12),
          _drawing(parent, result, numberOf, nameOf, txt, t.divisionNorth),
          pw.SizedBox(height: 4),
          txt(t.divisionPdfNorth, small),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FixedColumnWidth(24),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
              4: pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  c('#', head),
                  c(t.divisionNameHint, head),
                  c(t.divisionColShare, head),
                  c(t.drawArea, head, right: true),
                  c(t.divisionColLocal, head),
                ],
              ),
              for (final i in lots)
                pw.TableRow(
                  children: [
                    c(n.format(numberOf[i]), cell),
                    c(nameOf(pieces[i]), cell),
                    c(shareText(t, spec, pieces[i], landSqm), cell),
                    c(area(pieces[i].areaSqm), cell, right: true),
                    c(chain(pieces[i].areaSqm), small),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          txt(t.divisionBoundsTab, head),
          pw.SizedBox(height: 6),
          for (final i in lots) ...[
            txt(
              '${n.format(numberOf[i])}. ${nameOf(pieces[i])} — '
              '${area(pieces[i].areaSqm)}',
              pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    c(t.divisionColSide, head),
                    c(t.divisionColLength, head, right: true),
                    c(t.divisionColBeyond, head),
                  ],
                ),
                for (final s in Chouhoddi.of([
                  for (final p in pieces) p.vertices,
                ], i))
                  pw.TableRow(
                    children: [
                      c(cardinal(t, s.side), cell),
                      c(len(s.lengthM), cell, right: true),
                      c(
                        s.neighbour == null
                            ? t.divisionOutside
                            : nameOf(pieces[s.neighbour!]),
                        cell,
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _drawing(
    List<Vertex> parent,
    DivisionResult result,
    Map<int, int> numberOf,
    String Function(DivisionPiece) nameOf,
    pw.Widget Function(String, pw.TextStyle) txt,
    String north,
  ) {
    const width = 523.0, height = 260.0, pad = 16.0;
    final (minX, minY, maxX, maxY) = Geometry.bbox(parent);
    final w = (maxX - minX).clamp(1e-6, double.infinity);
    final h = (maxY - minY).clamp(1e-6, double.infinity);
    final sc = [
      (width - pad * 2) / w,
      (height - pad * 2) / h,
    ].reduce((a, b) => a < b ? a : b);
    final ox = (width - w * sc) / 2, oy = (height - h * sc) / 2;
    double px(double x) => ox + (x - minX) * sc;
    double py(double y) => oy + (y - minY) * sc;
    const tints = [
      PdfColor.fromInt(0xFFE8F5C8),
      PdfColor.fromInt(0xFFF3E3D3),
      PdfColor.fromInt(0xFFDDF0FA),
      PdfColor.fromInt(0xFFFDF0C8),
      PdfColor.fromInt(0xFFEAE3FA),
      PdfColor.fromInt(0xFFD9F5EA),
      PdfColor.fromInt(0xFFFBDDE2),
    ];
    PdfColor fill(DivisionPiece p) => switch (p.kind) {
      PieceKind.owner => tints[p.owner! % tints.length],
      PieceKind.road => PdfColors.grey300,
      PieceKind.rest => PdfColors.grey100,
    };
    Vertex centroid(List<Vertex> v) {
      var x = 0.0, y = 0.0;
      for (final q in v) {
        x += q.x;
        y += q.y;
      }
      return Vertex(x / v.length, y / v.length);
    }

    final n = NumberFormat.decimalPattern();
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
              void trace(List<Vertex> poly) {
                for (var i = 0; i < poly.length; i++) {
                  final x = px(poly[i].x), y = size.y - py(poly[i].y);
                  if (i == 0) {
                    canvas.moveTo(x, y);
                  } else {
                    canvas.lineTo(x, y);
                  }
                }
              }

              for (final p in result.pieces) {
                if (p.vertices.length < 3) continue;
                trace(p.vertices);
                canvas
                  ..setFillColor(fill(p))
                  ..setStrokeColor(PdfColors.grey700)
                  ..setLineWidth(0.8)
                  ..fillAndStrokePath(close: true);
              }
              trace(parent);
              canvas
                ..setStrokeColor(PdfColors.black)
                ..setLineWidth(1.6)
                ..strokePath(close: true);
              // North arrow, top left.
              canvas
                ..moveTo(18, size.y - 8)
                ..lineTo(13, size.y - 22)
                ..lineTo(23, size.y - 22)
                ..closePath()
                ..setFillColor(PdfColors.grey700)
                ..fillPath();
            },
          ),
          for (var i = 0; i < result.pieces.length; i++)
            if (result.pieces[i].vertices.length >= 3)
              pw.Positioned(
                left: px(centroid(result.pieces[i].vertices).x) - 40,
                top: py(centroid(result.pieces[i].vertices).y) - 8,
                child: pw.SizedBox(
                  width: 80,
                  child: pw.Center(
                    child: txt(
                      numberOf[i] == null
                          ? nameOf(result.pieces[i])
                          : n.format(numberOf[i]),
                      pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          pw.Positioned(
            left: 8,
            top: 24,
            child: pw.SizedBox(
              width: 20,
              child: pw.Center(
                child: txt(north, const pw.TextStyle(fontSize: 9)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
