// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionClose => 'Close';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionChange => 'Change';

  @override
  String get actionUndo => 'UNDO';

  @override
  String get actionRemove => 'REMOVE';

  @override
  String get actionCalculate => 'Calculate';

  @override
  String get actionGenerate => 'Generate';

  @override
  String get labelAll => 'All';

  @override
  String get labelOr => 'OR';

  @override
  String get appName => 'PlotCalc';

  @override
  String get tabPlots => 'Plots';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSubdivide => 'Subdivide';

  @override
  String get tabInfo => 'Info';

  @override
  String routeNotFound(String uri) {
    return 'Route not found: $uri';
  }

  @override
  String get defaultPlotLabel => 'Plot';

  @override
  String get unitSqftLabel => 'sq ft';

  @override
  String get unitSqftName => 'Square feet';

  @override
  String get unitSqmLabel => 'm²';

  @override
  String get unitSqmName => 'Square meters';

  @override
  String get unitAcreLabel => 'acre';

  @override
  String get unitAcreName => 'Acres';

  @override
  String get unitHectareLabel => 'hectare';

  @override
  String get unitHectareName => 'Hectares';

  @override
  String get unitBighaLabel => 'bigha';

  @override
  String get unitBighaName => 'Bigha';

  @override
  String get unitKathaLabel => 'katha';

  @override
  String get unitKathaName => 'Katha';

  @override
  String get unitChatakLabel => 'chatak';

  @override
  String get unitChatakName => 'Chatak';

  @override
  String get unitShotokLabel => 'shotok';

  @override
  String get unitShotokName => 'Shotok';

  @override
  String get unitMeters => 'Meters';

  @override
  String get unitFeet => 'Feet';

  @override
  String get unitMeterShort => 'm';

  @override
  String get unitFeetShort => 'ft';

  @override
  String get tagAgricultural => 'Agricultural';

  @override
  String get tagResidential => 'Residential';

  @override
  String get tagCommercial => 'Commercial';

  @override
  String get tagForest => 'Forest';

  @override
  String get tagOther => 'Other';

  @override
  String get presetRectangle => 'Rectangle';

  @override
  String get presetSquare => 'Square';

  @override
  String get presetTriangle => 'Triangle';

  @override
  String get presetTrapezoid => 'Trapezoid';

  @override
  String get presetPentagon => 'Pentagon';

  @override
  String get presetFreeform => 'Free-form';

  @override
  String get methodDraw => 'Draw';

  @override
  String get methodTap => 'Tap';

  @override
  String get methodType => 'Type';

  @override
  String get methodDrawSub => 'Tap & drag';

  @override
  String get methodTapSub => 'Place vertices';

  @override
  String get methodTypeSub => 'Sides + angles';

  @override
  String get homeTitle => 'Plots';

  @override
  String get homeBuildBy => 'Build By · Zaman Sheikh';

  @override
  String get homeThisMonth => 'THIS MONTH · MEASURED';

  @override
  String homePlusPlots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '+$countString plots';
  }

  @override
  String get homeMeasurePlot => 'Measure plot';

  @override
  String get homeMeasureSub => 'Draw or type sides';

  @override
  String get homeBadgeNew => 'NEW';

  @override
  String get homeToolLabel => 'TOOL';

  @override
  String get homeAllUnits => 'All units';

  @override
  String homeRecent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'RECENT · $countString';
  }

  @override
  String get homeSeeAll => 'See all';

  @override
  String get pickerStep => 'STEP 1 / 3';

  @override
  String get pickerQuestion => 'How do you want to start?';

  @override
  String get pickerSubtitle => 'Pick a method, then a shape.';

  @override
  String get pickerShapePresets => 'SHAPE PRESETS';

  @override
  String get pickerStartDrawing => 'Start drawing';

  @override
  String get pickerPlaceVertices => 'Place vertices';

  @override
  String get pickerEnterDimensions => 'Enter dimensions';

  @override
  String pickerSidesN(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString–N sides';
  }

  @override
  String get pickerTapEachCorner => 'Tap each corner on the canvas';

  @override
  String get drawTitle => 'Draw plot';

  @override
  String get drawTitleTap => 'Tap to place vertices';

  @override
  String get drawTitleEdit => 'Edit plot';

  @override
  String drawVerticesUnsaved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString VERTICES · UNSAVED';
  }

  @override
  String get drawArea => 'AREA';

  @override
  String get drawPerimeter => 'PERIMETER';

  @override
  String get drawSides => 'SIDES';

  @override
  String get drawDiag => 'DIAG';

  @override
  String get drawHintDone => 'Tap “Done” or keep adding vertices';

  @override
  String get drawHintMin => 'Place at least 3 vertices';

  @override
  String drawHintPlaced(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString placed · tap canvas to add more';
  }

  @override
  String drawVertexOf(int index, int total) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Vertex $indexString of $totalString';
  }

  @override
  String drawVertexInfo(String x, String y, String angle) {
    return 'x: ${x}m · y: ${y}m · ∠ $angle°';
  }

  @override
  String drawSavedToast(String name, String tag) {
    return 'Saved “$name” · $tag';
  }

  @override
  String drawDefaultName(String time) {
    return 'Plot · $time';
  }

  @override
  String get edgeAdjustDiagonal => 'Adjust diagonal';

  @override
  String get edgeAdjustSide => 'Adjust side';

  @override
  String edgeNowLength(String value, String unit) {
    return 'now $value $unit';
  }

  @override
  String get edgeNewLength => 'NEW LENGTH';

  @override
  String get edgeWhichEndpoint => 'WHICH ENDPOINT MOVES?';

  @override
  String edgeMoveEndpoint(String label) {
    return 'Move $label';
  }

  @override
  String get edgeInsertMidpoint => 'Insert vertex at midpoint';

  @override
  String get saveSheetTitle => 'Save plot';

  @override
  String get saveSheetName => 'NAME';

  @override
  String get saveSheetNameHint => 'Plot name';

  @override
  String get saveSheetCategory => 'CATEGORY';

  @override
  String get typeTitle => 'Enter dimensions';

  @override
  String typeSubtitle(String shape, String unit) {
    return '$shape · values in $unit';
  }

  @override
  String get typeWidth => 'Width';

  @override
  String get typeHeight => 'Height';

  @override
  String get typeSide => 'Side';

  @override
  String get typeSideA => 'Side A';

  @override
  String get typeSideB => 'Side B';

  @override
  String get typeSideC => 'Side C';

  @override
  String get typeTop => 'Top';

  @override
  String get typeBottom => 'Bottom';

  @override
  String get typeSideLength => 'Side length';

  @override
  String get typeSidesCount => 'Sides';

  @override
  String get typeTriangle3 => 'Triangle (3 sides)';

  @override
  String get typeRegularPentagon => 'Regular pentagon';

  @override
  String get typeRegularPolygon => 'Regular polygon';

  @override
  String get typeErrPositive => 'Each value must be a positive number.';

  @override
  String get typeErrTriangle =>
      'Sides do not form a triangle (each pair must sum > third).';

  @override
  String get typeErrMinSides => 'A polygon needs at least 3 sides.';

  @override
  String get historyTitle => 'History';

  @override
  String historySubtitle(int count, String area) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString plots · $area acre total';
  }

  @override
  String get historySearch => 'Search plots…';

  @override
  String get historyFilter => 'Filter';

  @override
  String historyChip(String label, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$label · $countString';
  }

  @override
  String historySelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString SELECTED';
  }

  @override
  String get historyEmpty => 'No plots yet — measure one from Home.';

  @override
  String historyPlotMeta(int sides, String when) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return ' · $sidesString sides · $when';
  }

  @override
  String historyToday(String time) {
    return 'Today · $time';
  }

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get historyCompare2 => 'Compare 2 plots';

  @override
  String get filterTitle => 'Filter by category';

  @override
  String get filterAllPlots => 'All plots';

  @override
  String plotTagSides(String tag, int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return '$tag · $sidesString sides';
  }

  @override
  String get plotRenameTitle => 'Rename plot';

  @override
  String get plotDeleteTitle => 'Delete plot?';

  @override
  String plotDeleteBody(String name) {
    return '“$name” will be removed permanently.';
  }

  @override
  String get plotClearAllTitle => 'Clear all history?';

  @override
  String plotClearAllBody(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $countString saved plots will be removed. This can’t be undone.',
      one: 'All 1 saved plot will be removed. This can’t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get plotClearAll => 'Clear all';

  @override
  String get compareTitle => 'Compare';

  @override
  String get comparePlotA => 'PLOT A';

  @override
  String get comparePlotB => 'PLOT B';

  @override
  String get compareNameA => 'Plot A';

  @override
  String get compareNameB => 'Plot B';

  @override
  String get compareDemoPlot => 'Demo plot';

  @override
  String get compareOverlay => 'OVERLAY · CENTERED';

  @override
  String get compareRatio => 'A ÷ B';

  @override
  String get compareDelta => 'A − B';

  @override
  String get compareTotal => 'TOTAL';

  @override
  String get compareRelative => 'RELATIVE SIZE';

  @override
  String compareUnitSides(String unit, int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return '$unit · $sidesString sides';
  }

  @override
  String get adjustTitle => 'Adjust to size';

  @override
  String get adjustTargetArea => 'TARGET AREA';

  @override
  String adjustPctFromBase(String pct) {
    return '$pct% FROM BASE';
  }

  @override
  String adjustBaseValue(String value, String unit) {
    return 'Base · $value $unit';
  }

  @override
  String get adjustBase => 'BASE';

  @override
  String get adjustAdjusted => 'ADJUSTED';

  @override
  String get adjustAnchor => 'ANCHOR';

  @override
  String get adjustUniform => 'Uniform';

  @override
  String get adjustWidth => 'Width';

  @override
  String get adjustHeight => 'Height';

  @override
  String get adjustExpandDirection => 'EXPAND DIRECTION';

  @override
  String get adjustAnchorFrom => 'ANCHOR FROM';

  @override
  String get adjustApply => 'Apply adjustment';

  @override
  String get converterTitle => 'Converter';

  @override
  String get converterSubtitle => 'Type a number, pick a unit';

  @override
  String get converterValue => 'VALUE';

  @override
  String get converterConvertsTo => 'CONVERTS TO';

  @override
  String get resultTitle => 'Plot Summary';

  @override
  String resultTotalArea(String unit) {
    return 'TOTAL AREA · $unit';
  }

  @override
  String get resultSaved => 'SAVED';

  @override
  String get resultEquivalent => 'EQUIVALENT IN';

  @override
  String get resultValuation => 'VALUATION';

  @override
  String resultRatePer(String unit) {
    return 'RATE / $unit';
  }

  @override
  String get resultCurrency => 'Tk';

  @override
  String get resultEstValue => 'EST. VALUE';

  @override
  String get resultExportPdf => 'PDF';

  @override
  String get resultShareImage => 'Share image';

  @override
  String get resultAdjust => 'Adjust';

  @override
  String get subdivideTitle => 'Subdivide';

  @override
  String get subdivideSubtitle => 'Pick a saved plot to split into lots';

  @override
  String subdivideSaved(String name) {
    return 'Subdivision saved for “$name”';
  }

  @override
  String get subdivideSaveAction => 'Save subdivision';

  @override
  String subdivideSummary(String name, int lots) {
    final intl.NumberFormat lotsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lotsString = lotsNumberFormat.format(lots);

    return '$name · $lotsString lots · 100%';
  }

  @override
  String subdivideMeta(String area, String unit, int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return '$area $unit · $sidesString sides';
  }

  @override
  String get subdivideEmpty => 'No saved plots yet';

  @override
  String get subdivideEmptyBody =>
      'Measure a plot first, then come back here to split it into lots.';

  @override
  String get subdivideGoHome => 'Go to Home';

  @override
  String subdivideLot(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Lot $nString';
  }

  @override
  String get khotiyanTitle => 'Khotiyan';

  @override
  String get khotiyanSubtitle => 'Share calculator · Ana · Gonda · Kora';

  @override
  String get khotiyanHissya => 'HISSYA';

  @override
  String khotiyanTilFraction(String selected, String total) {
    return '$selected / $total til';
  }

  @override
  String get khotiyanSelectUnits => 'SELECT UNITS';

  @override
  String get khotiyanAna => 'Ana';

  @override
  String get khotiyanGonda => 'Gonda';

  @override
  String get khotiyanKora => 'Kora';

  @override
  String get khotiyanKranti => 'Kranti';

  @override
  String get khotiyanTil => 'Til';

  @override
  String get khotiyanTotalLand => 'TOTAL LAND';

  @override
  String get khotiyanYourLand => 'YOUR LAND';

  @override
  String get infoTitle => 'Land guide';

  @override
  String get infoSubtitle =>
      'Units, measurement, surveying — and Bangladeshi land records';

  @override
  String get infoArticle => 'Article';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Tweak the look, feel, and units';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBengali => 'বাংলা';

  @override
  String get settingsTheme => 'THEME';

  @override
  String get settingsAccent => 'Accent color';

  @override
  String get settingsGridStyle => 'GRID STYLE';

  @override
  String get settingsGridDots => 'Dots';

  @override
  String get settingsGridLines => 'Lines';

  @override
  String get settingsGridBlueprint => 'Blueprint';

  @override
  String get settingsAreaUnit => 'AREA UNIT';

  @override
  String get settingsLengthUnit => 'LENGTH UNIT';

  @override
  String get settingsUnderlay => 'UNDERLAY';

  @override
  String get settingsMapUnderlay => 'Map underlay';

  @override
  String get settingsMapUnderlaySub =>
      'Show road & parcel hints behind the canvas';

  @override
  String get drawerMenu => 'Menu';

  @override
  String get drawerMenuSub => 'Settings, info, and more';

  @override
  String get drawerKhotiyanSub => 'Calculate share by Ana, Gonda, Kora';

  @override
  String get drawerSettingsSub => 'Theme, units, grid style';

  @override
  String get drawerAboutSub => 'Version, credits, what PlotCalc does';

  @override
  String drawerVersion(String version) {
    return 'PlotCalc · v$version';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutTagline => 'Offline land measurement, your way';

  @override
  String get aboutWhatItDoes => 'WHAT IT DOES';

  @override
  String get aboutDraw =>
      'Draw plots by tapping vertices, dragging a template, or typing exact measurements.';

  @override
  String get aboutConvert =>
      'Convert between 10 area units, including the Mymensingh regional bigha and katha.';

  @override
  String get aboutAdjust =>
      'Adjust a polygon to hit a target area while keeping its shape.';

  @override
  String get aboutCompare => 'Compare two saved plots side-by-side.';

  @override
  String get aboutSubdivide => 'Subdivide a plot into proportional lots.';

  @override
  String get aboutOffline => 'WORKS OFFLINE';

  @override
  String get aboutOfflineBody =>
      'Every measurement, conversion, and saved plot lives on your device. No accounts, no internet required.';

  @override
  String get aboutBuild => 'BUILD';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutPlatform => 'Platform';

  @override
  String get aboutPlatformValue => 'Android · iOS';

  @override
  String get aboutCredits => 'CREDITS';

  @override
  String get pickerQuestionAccent => 'start';

  @override
  String get historyEmptyFiltered =>
      'No plots match this filter.\nTap “All” to clear.';

  @override
  String get adjustAnchorN => 'N';

  @override
  String get adjustAnchorE => 'E';

  @override
  String get adjustAnchorW => 'W';

  @override
  String get adjustAnchorS => 'S';

  @override
  String homeSides(int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return ' · $sidesString sides';
  }

  @override
  String get drawFirstVertexHint =>
      'Tap anywhere on the canvas\nto drop your first vertex';

  @override
  String get drawCompassN => 'N';

  @override
  String get unitBighaMymensinghLabel => 'bigha (M)';

  @override
  String get unitBighaMymensinghName => 'Bigha — Mymensingh';

  @override
  String get unitKathaMymensinghLabel => 'katha (M)';

  @override
  String get unitKathaMymensinghName => 'Katha — Mymensingh';

  @override
  String get breakdownTitle => 'Breakdown';

  @override
  String get breakdownSectionLabel => 'BREAKDOWN';

  @override
  String get settingsBreakdown => 'BREAKDOWN UNITS';

  @override
  String get settingsBreakdownSub =>
      'Choose which units make up a compound reading';

  @override
  String get breakdownConfigTitle => 'Breakdown units';

  @override
  String get breakdownConfigSubtitle =>
      'Drag to reorder, tap to switch on or off';

  @override
  String get breakdownConfigHint =>
      'Units are used largest first, and the smallest one you enable carries the remainder.';

  @override
  String get breakdownEmpty => 'Enable at least one unit to see a breakdown.';

  @override
  String get breakdownNone => 'No units enabled';

  @override
  String get actionResetDefaults => 'Reset to defaults';

  @override
  String breakdownOf(int count, int total) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$countString of $totalString units on';
  }

  @override
  String get calcTitle => 'Land calculator';

  @override
  String get calcSubtitle => 'Total, adjust, and combine areas';

  @override
  String get calcTotalLabel => 'TOTAL AREA';

  @override
  String get calcAdjustTitle => 'Adjust area';

  @override
  String get calcAdd => 'Add';

  @override
  String get calcSubtract => 'Subtract';

  @override
  String get calcCombineTitle => 'Combine units';

  @override
  String get calcClear => 'Clear';

  @override
  String get calcEmpty => 'Enter an area to see its breakdown.';

  @override
  String get calcCannotGoNegative => 'Total cannot go below zero.';

  @override
  String get homeCalculatorSub => 'Add, subtract, break down';

  @override
  String get calcModeTotal => 'Single value';

  @override
  String get calcModeParts => 'By unit';

  @override
  String get calcPartsHint => 'Edit any unit — the total updates as you type.';

  @override
  String get calcAdjustLabel => 'ADJUST TOTAL';

  @override
  String get calcResultLabel => 'BREAKDOWN';

  @override
  String get calcAmountLabel => 'AMOUNT';

  @override
  String get actionCopy => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get resultShare => 'Share';

  @override
  String get exportFailed => 'Could not export. Please try again.';

  @override
  String get plotDisplayUnit => 'Display unit';

  @override
  String get plotUnitFollowsSettings => 'Follow app setting';

  @override
  String get plotUnitTitle => 'Read this plot in';

  @override
  String plotUnitSaved(String name, String unit) {
    return '“$name” now reads in $unit';
  }

  @override
  String get breakdownEditUnits => 'Units';

  @override
  String get adjustMethodScale => 'Resize';

  @override
  String get adjustMethodBoundary => 'Move boundary';

  @override
  String get adjustPickSides => 'Sides';

  @override
  String get adjustPickCorners => 'Corners';

  @override
  String get adjustTapToPick => 'Tap a side on the plan to move it';

  @override
  String get adjustTapToPickCorner => 'Tap a corner on the plan to move it';

  @override
  String adjustMoveOut(String distance) {
    return 'Move out $distance';
  }

  @override
  String adjustMoveIn(String distance) {
    return 'Move in $distance';
  }

  @override
  String get adjustUnreachable =>
      'Cannot reach that by moving this alone — pick more sides';

  @override
  String adjustSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString selected';
  }

  @override
  String get actionClearSelection => 'Clear';

  @override
  String get adjustPickSlide => 'Slide';

  @override
  String get adjustTapToSlide => 'Tap a corner to slide it along a boundary';

  @override
  String get adjustSlideAlong => 'Along';

  @override
  String get adjustSlideSwap => 'Other side';

  @override
  String get resultEditShape => 'Edit shape';

  @override
  String plotUpdated(String name) {
    return '“$name” updated';
  }

  @override
  String get resultUnsaved => 'NOT SAVED';

  @override
  String get subdivideAddLot => 'Add lot';

  @override
  String get subdivideRemoveLot => 'Remove';

  @override
  String get subdivideModeEqual => 'Equal';

  @override
  String get subdivideModePercent => 'Percent';

  @override
  String get subdivideModeArea => 'Area';

  @override
  String subdivideSavedLots(int count, String name) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Saved $countString lots from “$name”';
  }

  @override
  String subdivideLotsDontSum(String total, String plot) {
    return 'Lots add up to $total, plot is $plot';
  }

  @override
  String get aboutDeveloper => 'Developer';

  @override
  String get aboutDeveloperName => 'Zaman Sheikh';

  @override
  String get aboutFacebook => 'Facebook';

  @override
  String get aboutGithub => 'GitHub';

  @override
  String get aboutOpenLinkFailed => 'Could not open the link';

  @override
  String get historyTabPlots => 'Plots';

  @override
  String get historyTabSheets => 'Sheets';

  @override
  String get historySelectHint => 'LONG-PRESS PLOTS TO SELECT';

  @override
  String get historyCompareShort => 'Compare';

  @override
  String historySum(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Sum $countString plots';
  }

  @override
  String get sheetTitle => 'Land sheet';

  @override
  String get sheetNameTitle => 'Name this sheet';

  @override
  String sheetDefaultName(String number) {
    return 'Sheet $number';
  }

  @override
  String get sheetTotalLabel => 'TOTAL AREA';

  @override
  String sheetTotalArea(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Total · $countString plots';
  }

  @override
  String sheetCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString plots';
  }

  @override
  String get sheetPriceLabel => 'PRICE';

  @override
  String sheetPricePer(String unit) {
    return 'per $unit';
  }

  @override
  String get sheetRate => 'Rate';

  @override
  String get sheetTotalValue => 'Total value';

  @override
  String get sheetPlotsHeader => 'PLOTS IN THIS SHEET';

  @override
  String get sheetAddPlots => 'Add plots';

  @override
  String get sheetAllAdded => 'Every saved plot is already in this sheet.';

  @override
  String get sheetEmpty => 'No plots in this sheet yet.';

  @override
  String get sheetsEmpty =>
      'No sheets yet.\nLong-press plots to select them, then tap Sum.';

  @override
  String sheetMissing(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString plots in this sheet were deleted.';
  }

  @override
  String get sheetDeleteTitle => 'Delete sheet?';

  @override
  String sheetDeleteBody(String name) {
    return '“$name” will be deleted. Its plots stay saved.';
  }

  @override
  String get sheetColPlot => 'Plot';

  @override
  String get sheetColShare => 'Share';

  @override
  String get sheetColValue => 'Value';

  @override
  String sheetPrepared(String date) {
    return 'Prepared $date';
  }

  @override
  String get sheetUnitTitle => 'Read this sheet in';

  @override
  String get sheetPriceUnitTitle => 'Price is quoted per';

  @override
  String sheetPlotRemoved(String name) {
    return '“$name” removed from the sheet';
  }

  @override
  String get sheetLayoutHeader => 'LAYOUT';

  @override
  String get sheetArrange => 'Arrange';

  @override
  String get sheetArrangeTitle => 'Arrange plots';

  @override
  String get sheetArrangeHint => 'Drag a plot to move it · pinch to zoom';

  @override
  String get sheetTurnLeft => 'Turn left';

  @override
  String get sheetTurnRight => 'Turn right';

  @override
  String get sheetFitView => 'Fit to screen';

  @override
  String get sheetAutoArrange => 'Arrange automatically';

  @override
  String get sheetLayoutSaved => 'Layout saved';

  @override
  String get sheetDiscardTitle => 'Discard changes?';

  @override
  String get sheetDiscardBody => 'This arrangement has not been saved.';

  @override
  String get sheetDiscard => 'Discard';

  @override
  String get sheetTapToSelect => 'Tap a plot to select it';

  @override
  String get mouzaEntryTitle => 'Measure from a mouza map';

  @override
  String get mouzaEntrySub => 'Photo → scale → tap the corners';

  @override
  String get mouzaTitle => 'Mouza map';

  @override
  String get mouzaStepPhoto => 'Photo';

  @override
  String get mouzaStepScale => 'Scale';

  @override
  String get mouzaStepCorners => 'Corners';

  @override
  String get mouzaPickTitle => 'Take a photo of the map';

  @override
  String get mouzaPickSub =>
      'Then set its scale and tap the corners of your plot. The area is worked out for you.';

  @override
  String get mouzaPickCamera => 'Take photo';

  @override
  String get mouzaPickGallery => 'Choose from gallery';

  @override
  String get mouzaTipsTitle => 'FOR AN ACCURATE RESULT';

  @override
  String get mouzaTip1 => 'Lay the map flat and shoot from straight above.';

  @override
  String get mouzaTip2 =>
      'Keep the scale bar, or a side whose length you know, in the photo.';

  @override
  String get mouzaTip3 => 'Use good light — no shadow, no glare.';

  @override
  String get mouzaPickFailed => 'Could not open the photo.';

  @override
  String get mouzaScaleHintFirst =>
      'Tap two points whose distance you know — like the two ends of the map\'s scale bar.';

  @override
  String get mouzaScaleHintSecond => 'Now tap the second point.';

  @override
  String get mouzaScaleDistance => 'DISTANCE BETWEEN THE TWO POINTS';

  @override
  String get mouzaScaleNoBar =>
      'No scale bar? Use any side whose length is written in the deed.';

  @override
  String get mouzaDragTip =>
      'Drag a point to fine-tune it — a magnifier shows exactly where it is.';

  @override
  String get mouzaUnitFoot => 'ft';

  @override
  String get mouzaUnitMeter => 'm';

  @override
  String get mouzaUnitChain => 'chain';

  @override
  String get mouzaUnitLink => 'link';

  @override
  String get mouzaNext => 'Next';

  @override
  String get mouzaStartOver => 'Start over';

  @override
  String get mouzaTraceHintFirst =>
      'Tap each corner of the plot, one after another.';

  @override
  String mouzaTraceHintMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString corners — keep going around the plot.';
  }

  @override
  String get mouzaNewPlot => 'New plot';

  @override
  String get mouzaChangeScale => 'Scale';

  @override
  String get mouzaSeeResult => 'See result';

  @override
  String get mouzaDefaultName => 'Mouza map plot';

  @override
  String get mouzaLeaveTitle => 'Leave the map?';

  @override
  String get mouzaLeaveBody => 'The corners you tapped will be lost.';

  @override
  String get mouzaAreaSoFar => 'AREA';
}
