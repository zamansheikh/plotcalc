import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../l10n/l10n.dart';
import 'plot_summary.dart';

/// Renders a plot summary as a one-page A4 document.
///
/// Deliberately plain black-on-white rather than the app's dark theme: this
/// is meant to be printed and attached to a deed or a sale discussion.
class PlotPdf {
  const PlotPdf._();

  static Future<Uint8List> build(
    PlotSummary summary,
    AppLocalizations t, {
    Uint8List? plotImage,
  }) async {
    final doc = pw.Document(title: summary.name);
    final needsBengali = _bengali.hasMatch(summary.asText(t));

    doc.addPage(
      pw.Page(
        theme: await _theme(bengali: needsBengali),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(summary, t),
            pw.SizedBox(height: 18),
            _headline(summary, t),
            pw.SizedBox(height: 18),
            if (plotImage != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(plotImage),
                  height: 220,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 18),
            ],
            _facts(summary, t),
            pw.SizedBox(height: 18),
            pw.Text(
              t.resultEquivalent,
              style: pw.TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            _conversions(summary, t),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              t.appName,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static final _bengali = RegExp(r'[\u0980-\u09FF]');

  /// Themes are cached for the life of the process. Loading a TTF means
  /// fetching it (once) and then parsing it, which is the slow part of an
  /// export — doing that on every tap made the PDF button feel broken.
  static final _themes = <bool, pw.ThemeData?>{};

  /// PDF's built-in faces are Latin-1 only: Bengali renders as nothing, and
  /// even an em-dash in a unit name is dropped. Noto covers both, but has to
  /// be fetched. Falling back to the built-ins keeps export working offline,
  /// in English.
  ///
  /// The Bengali face is by far the largest, so it is only loaded when the
  /// document actually contains Bengali.
  static Future<pw.ThemeData?> _theme({required bool bengali}) async {
    if (_themes.containsKey(bengali)) return _themes[bengali];
    try {
      // Fetched together rather than in sequence.
      final fonts = await Future.wait([
        PdfGoogleFonts.notoSansRegular(),
        PdfGoogleFonts.notoSansBold(),
        if (bengali) PdfGoogleFonts.notoSansBengaliRegular(),
      ]);
      final theme = pw.ThemeData.withFont(
        base: fonts[0],
        bold: fonts[1],
        fontFallback: bengali ? [fonts[2]] : const [],
      );
      _themes[bengali] = theme;
      return theme;
    } catch (_) {
      // Cache the failure too: offline, retrying on every export just adds
      // another timeout to the wait.
      _themes[bengali] = null;
      return null;
    }
  }

  /// Test seam: lets a suite start from a clean cache.
  static void resetFontCacheForTest() => _themes.clear();

  static pw.Widget _header(PlotSummary s, AppLocalizations t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        t.resultTitle.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          letterSpacing: 1.4,
          color: PdfColors.grey700,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        s.name,
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  static pw.Widget _headline(PlotSummary s, AppLocalizations t) {
    final chain = s.breakdownLine(t);
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
          pw.Text(
            '${s.unit.format(s.areaSqm)} ${s.unit.labelOf(t)}',
            style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
          ),
          if (chain.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              chain,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _facts(PlotSummary s, AppLocalizations t) => pw.Row(
    children: [
      _fact(t.drawPerimeter, '${s.perimeterM.toStringAsFixed(1)} m'),
      _fact(t.drawSides, '${s.sides}'),
    ],
  );

  static pw.Widget _fact(String label, String value) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            letterSpacing: 1.2,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  static pw.Widget _conversions(PlotSummary s, AppLocalizations t) =>
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
        cellStyle: const pw.TextStyle(fontSize: 10),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellAlignments: {1: pw.Alignment.centerRight},
        headers: [t.settingsAreaUnit, t.drawArea],
        data: [for (final (name, value) in s.conversions(t)) [name, value]],
      );
}
