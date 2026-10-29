import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../geometry/sheet_layout.dart';
import '../units/length_unit.dart';
import 'plot_pdf.dart';
import 'plot_summary.dart';
import 'sheet_pdf.dart';
import 'sheet_summary.dart';

/// The three ways a measurement leaves the app: clipboard, share sheet, PDF.
///
/// Kept free of BuildContext so it can be exercised without pumping a widget;
/// callers pass the already-resolved [AppLocalizations].
class PlotExport {
  const PlotExport._();

  /// Puts the plain-text summary on the clipboard.
  static Future<void> copy(PlotSummary summary, AppLocalizations t) {
    return Clipboard.setData(ClipboardData(text: summary.asText(t)));
  }

  /// Opens the system share sheet with the summary text, attaching a PNG of
  /// the plot when one could be captured.
  static Future<void> share(
    PlotSummary summary,
    AppLocalizations t, {
    Uint8List? image,
  }) async {
    final text = summary.asText(t);
    final params = image == null
        ? ShareParams(text: text, subject: summary.name)
        : ShareParams(
            text: text,
            subject: summary.name,
            files: [
              XFile.fromData(
                image,
                mimeType: 'image/png',
                name: '${_slug(summary.name)}.png',
              ),
            ],
          );
    await SharePlus.instance.share(params);
  }

  /// Opens the share sheet with a two-plot comparison.
  ///
  /// Text only: the comparison is a pair of figures, and the two plots are
  /// drawn at different scales, so a single image would misrepresent it.
  static Future<void> shareComparison(
    PlotSummary a,
    PlotSummary b,
    AppLocalizations t,
  ) {
    return SharePlus.instance.share(
      ShareParams(
        text: PlotSummary.comparisonText(a, b, t),
        subject: t.compareTitle,
      ),
    );
  }

  /// Builds the PDF and hands it to the platform's print/share dialog.
  static Future<void> sharePdf(
    PlotSummary summary,
    AppLocalizations t, {
    Uint8List? image,
  }) async {
    final bytes = await PlotPdf.build(summary, t, plotImage: image);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_slug(summary.name)}.pdf',
    );
  }

  /// Writes the PDF next to the app's documents and returns the path, for
  /// callers that want a file rather than a share sheet.
  static Future<String> savePdf(
    PlotSummary summary,
    AppLocalizations t, {
    Uint8List? image,
  }) async {
    final bytes = await PlotPdf.build(summary, t, plotImage: image);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_slug(summary.name)}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Opens the share sheet with a sheet's plots and totals as text.
  static Future<void> shareSheet(SheetSummary sheet, AppLocalizations t) {
    return SharePlus.instance.share(
      ShareParams(text: sheet.asText(t), subject: sheet.name),
    );
  }

  /// Builds the sheet PDF and hands it to the platform's print/share dialog.
  static Future<void> shareSheetPdf(
    SheetSummary sheet,
    AppLocalizations t, {
    Map<String, PlotPlacement> layout = const {},
    LengthUnit lengthUnit = LengthUnit.ft,
  }) async {
    final bytes = await SheetPdf.build(
      sheet,
      t,
      layout: layout,
      lengthUnit: lengthUnit,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_slug(sheet.name, fallback: 'sheet')}.pdf',
    );
  }

  /// Filenames reach other apps and filesystems, so keep them boring.
  static String _slug(String name, {String fallback = 'plot'}) {
    final s = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? fallback : s;
  }
}
