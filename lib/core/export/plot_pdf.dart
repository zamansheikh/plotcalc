
import 'package:bangla_pdf/bangla_pdf.dart' as bp;
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
            _text(
              t.resultEquivalent,
              pw.TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            _conversions(summary, t),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            _text(
              t.appName,
              pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static final _bengali = RegExp(r'[\u0980-\u09FF]');

  /// Themes are cached for the life of the process. Loading a TTF means
  /// parsing it, which is the slow part of an export — doing that on every
  /// tap made the PDF button feel broken.
  ///
  /// Bundled under the SIL Open Font License 1.1.
  static const latinFontAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const latinBoldFontAsset = 'assets/fonts/NotoSans-Bold.ttf';

  static final _themes = <bool, pw.ThemeData?>{};

  /// PDF's built-in faces are Latin-1 only — even an em dash is dropped — so
  /// the Latin text is drawn with a bundled Noto Sans.
  ///
  /// There is no Bengali face here on purpose. Bengali does not just need
  /// glyphs, it needs shaping: package:pdf draws code points in order, which
  /// breaks conjuncts, puts ি ে ৈ on the wrong side of their consonant and
  /// misplaces reph. Bengali goes through [bp.Text] instead, which shapes
  /// with the font's own OpenType tables and carries its own typeface.
  static Future<pw.ThemeData?> _theme({required bool bengali}) async {
    if (_themes.containsKey(bengali)) return _themes[bengali];
    try {
      // Awaited one at a time, not gathered with Future.wait: the bundle
      // hands back a SynchronousFuture, which Future.wait mishandles — it
      // returns an empty list and the fonts silently go missing.
      final base = pw.Font.ttf(await rootBundle.load(latinFontAsset));
      final bold = pw.Font.ttf(await rootBundle.load(latinBoldFontAsset));
      final theme = pw.ThemeData.withFont(base: base, bold: bold);
      _themes[bengali] = theme;
      return theme;
    } catch (_) {
      // A missing asset must not cost the user their export; the document is
      // still readable in Latin.
      _themes[bengali] = null;
      return null;
    }
  }

  /// Draws [value], shaping it when it contains Bengali.
  ///
  /// Latin stays on plain [pw.Text] so it keeps the theme's face, its bold
  /// and its letter spacing — the shaping path honours only size, colour and
  /// alignment, so routing English through it would flatten the document.
  static pw.Widget _text(String value, pw.TextStyle style) {
    if (!_bengali.hasMatch(value)) return pw.Text(value, style: style);
    return bp.Text(
      value,
      fontSize: style.fontSize ?? 12,
      color: style.color ?? PdfColors.black,
      textAlign: pw.TextAlign.start,
    );
  }

  /// Shared with the sheet PDF, so both documents load fonts and shape
  /// Bengali the same way.
  static Future<pw.ThemeData?> themeFor({required bool bengali}) =>
      _theme(bengali: bengali);
  static pw.Widget text(String value, pw.TextStyle style) =>
      _text(value, style);
  static bool hasBengali(String value) => _bengali.hasMatch(value);

  /// Test seam: lets a suite start from a clean cache.
  static void resetFontCacheForTest() => _themes.clear();

  static pw.Widget _header(PlotSummary s, AppLocalizations t) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _text(
        t.resultTitle.toUpperCase(),
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
          _text(
            '${s.unit.format(s.areaSqm)} ${s.unit.labelOf(t)}',
            pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
          ),
          if (chain.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _text(
              chain,
              const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
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
        _text(
          label,
          pw.TextStyle(
            fontSize: 9,
            letterSpacing: 1.2,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        _text(
          value,
          pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  static pw.Widget _conversions(PlotSummary s, AppLocalizations t) {
    // Built row by row rather than with TableHelper: the helper takes styled
    // strings, and a shaped Bengali cell is a widget.
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell(t.settingsAreaUnit, _headerStyle, right: false),
            _cell(t.drawArea, _headerStyle, right: true),
          ],
        ),
        for (final (name, value) in s.conversions(t))
          pw.TableRow(
            children: [
              _cell(name, _cellStyle, right: false),
              _cell(value, _cellStyle, right: true),
            ],
          ),
      ],
    );
  }

  static final _headerStyle = pw.TextStyle(
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey800,
  );

  static const _cellStyle = pw.TextStyle(fontSize: 10);

  static pw.Widget _cell(String value, pw.TextStyle style, {
    required bool right,
  }) => pw.Container(
    alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: _text(value, style),
  );
}
