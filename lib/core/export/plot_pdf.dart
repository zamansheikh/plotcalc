
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  /// Bundled under the SIL Open Font License 1.1.
  static const latinFontAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const latinBoldFontAsset = 'assets/fonts/NotoSans-Bold.ttf';
  static const bengaliFontAsset = 'assets/fonts/NotoSansBengali-Regular.ttf';

  static final _themes = <bool, pw.ThemeData?>{};

  /// PDF's built-in faces are Latin-1 only: Bengali renders as nothing, and
  /// even an em-dash in a unit name is dropped. Noto covers both, but has to
  /// be fetched. Falling back to the built-ins keeps export working offline,
  /// in English.
  ///
  /// The Bengali face is bundled rather than fetched.
  ///
  /// A PDF carries its own fonts — there is no system fallback the way there
  /// is on screen — so a document built without Bengali glyphs comes out
  /// blank, not merely in the wrong typeface. This app is used offline and
  /// now opens in Bengali by default, so downloading the face at export time
  /// would fail exactly when it is needed most.
  ///
  /// The Latin face is bundled for the same reason. The PDF format's own
  /// Helvetica needs no embedding but is ASCII-only, so it drops the em dash
  /// and the mid-dot the breakdown line is built from.
  static Future<pw.ThemeData?> _theme({required bool bengali}) async {
    if (_themes.containsKey(bengali)) return _themes[bengali];
    try {
      // Awaited one at a time, not gathered with Future.wait: the bundle
      // hands back a SynchronousFuture, which Future.wait mishandles — it
      // returns an empty list and the fonts silently go missing.
      final base = pw.Font.ttf(await rootBundle.load(latinFontAsset));
      final bold = pw.Font.ttf(await rootBundle.load(latinBoldFontAsset));
      final theme = pw.ThemeData.withFont(
        base: base,
        bold: bold,
        fontFallback: bengali
            ? [pw.Font.ttf(await rootBundle.load(bengaliFontAsset))]
            : const [],
      );
      _themes[bengali] = theme;
      return theme;
    } catch (_) {
      // A missing asset must not cost the user their export; the document is
      // still readable in Latin.
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
