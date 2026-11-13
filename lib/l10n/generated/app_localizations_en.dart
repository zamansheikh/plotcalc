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

  @override
  String get overlayEntryTitle => 'Pantograph';

  @override
  String get overlayEntrySub => 'CS ↔ RS overlay';

  @override
  String get mouzaCompareLink =>
      'Have two surveys of this mouza? Lay them over each other with Pantograph';

  @override
  String get overlayTitle => 'Pantograph';

  @override
  String get overlayStepMaps => 'Maps';

  @override
  String get overlayStepMatch => 'Match';

  @override
  String get overlayStepMeasure => 'Measure';

  @override
  String get overlayMapsTitle => 'Add both maps of the mouza';

  @override
  String get overlayMapsSub =>
      'Usually the old survey (CS or SA) and the newer one (RS or BS). Next you mark a few places found on both, and one map is laid over the other.';

  @override
  String get overlayMapOld => 'OLD SURVEY';

  @override
  String get overlayMapNew => 'NEW SURVEY';

  @override
  String get overlayAddPhoto => 'Add photo';

  @override
  String get overlaySurveyOther => 'Other';

  @override
  String get overlaySameSheet =>
      'Both must be the same sheet of the same mouza (same J.L. no.).';

  @override
  String get overlayMatchStart =>
      'Tap a place you can find on both maps — a road crossing, a corner of the mouza boundary, a pillar.';

  @override
  String overlayMatchOther(String map) {
    return 'Now tap the very same place on the $map map. The small circle shows where it was.';
  }

  @override
  String get overlayMatchGuessed =>
      'Placed where it should be — if it is not exactly on the spot, tap the right spot or drag it.';

  @override
  String overlayMatchMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString matched. Add more, spread towards the corners of the sheet — four or more is best.';
  }

  @override
  String get overlayNextPair => 'Next place';

  @override
  String get overlayRemovePair => 'Remove';

  @override
  String overlayQualityUnchecked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Add $countString more to check the match';
  }

  @override
  String get overlayQualityGood => 'Match: good';

  @override
  String get overlayQualityFair => 'Match: fair — look over the places';

  @override
  String get overlayQualityPoor => 'Match: poor — a place is probably wrong';

  @override
  String get overlayQualityPoorWhich =>
      'Add one more place to find out which is wrong';

  @override
  String overlaySuspect(String n) {
    return 'Place $n looks wrong — check it';
  }

  @override
  String get overlayViewBoth => 'Both';

  @override
  String get overlayColours => 'Colours';

  @override
  String get overlayScaleHint =>
      'Set the scale on either map\'s scale bar — both share it now.';

  @override
  String get overlayPlot => 'plot';

  @override
  String get overlayTraceHint =>
      'Choose the map, then tap the corners of one plot on it.';

  @override
  String get overlayFinishPlot => 'Plot done';

  @override
  String get overlayPlotNameTitle => 'Plot number';

  @override
  String get overlayPlotsHeader => 'PLOTS';

  @override
  String get overlayOverlapHeader => 'SHARED AREA';

  @override
  String overlayOverlapShare(String pa, String a, String pb, String b) {
    return '$pa of $a · $pb of $b';
  }

  @override
  String get overlayNoOverlap => 'The traced plots do not overlap.';

  @override
  String get overlayOverlapEmpty =>
      'Trace a plot on each map to see how much they share.';

  @override
  String get overlayReport => 'Report';

  @override
  String get overlayReportTitle => 'PANTOGRAPH';

  @override
  String overlayReportMatched(int count, String quality) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Matched at $countString places · $quality';
  }

  @override
  String overlayReportMismatch(String value) {
    return 'Average mismatch $value';
  }

  @override
  String get overlayReportMap => 'Map';

  @override
  String get overlayLeaveBody =>
      'The matching and the traced plots will be lost.';

  @override
  String get overlayNeedTwo => 'Match at least two places to continue.';

  @override
  String overlayMovePlace(String n) {
    return 'Place $n: tap the right spot, or drag its mark, on either map.';
  }

  @override
  String get divisionOwnersTab => 'Owners';

  @override
  String get divisionSidesTab => 'Side & road';

  @override
  String get divisionBoundsTab => 'Boundaries';

  @override
  String get divisionHowLabel => 'HOW TO DIVIDE';

  @override
  String get divisionModeEqual => 'Equal';

  @override
  String get divisionModeShares => 'By share';

  @override
  String get divisionModeAreas => 'By area';

  @override
  String get divisionShareHint => 'e.g. 1/3';

  @override
  String get divisionShareHelp =>
      'Write shares as parts — 1/3, 6 anna, 25% — or as counts: 2 for a son, 1 for a daughter.';

  @override
  String get divisionAreaHelp =>
      'Leave an area blank and that owner shares what is left.';

  @override
  String get divisionAreaHint => 'rest';

  @override
  String get divisionNameHint => 'Name';

  @override
  String get divisionAddOwner => 'Add one more';

  @override
  String get divisionRest => 'Unassigned';

  @override
  String get divisionRoad => 'Road';

  @override
  String divisionRoadWidth(String width) {
    return 'Road · $width';
  }

  @override
  String get divisionIssueSharesOver =>
      'Shares add up to more than the whole land.';

  @override
  String get divisionIssueSharesMixed =>
      'Write all shares the same way — either parts (1/3, 6 anna) or counts (2, 1).';

  @override
  String get divisionIssueShareUnreadable =>
      'A share could not be read — write it like 1/3, 6 anna, 25% or 2.';

  @override
  String get divisionIssueAreasOver =>
      'The areas add up to more than the land.';

  @override
  String get divisionIssueAreaUnreadable => 'An area could not be read.';

  @override
  String get divisionIssueRoadTooWide =>
      'The road is as deep as the whole plot.';

  @override
  String divisionRestNote(String area) {
    return '$area is not given to anyone yet.';
  }

  @override
  String get divisionGiveRest => 'Add an owner for it';

  @override
  String get divisionFrontTitle => 'WHICH SIDE SHOULD EVERY LOT TOUCH?';

  @override
  String get divisionFrontHint =>
      'Usually the road side: every lot gets its own stretch of it. Tap a side on the drawing, or pick one here.';

  @override
  String get divisionFrontAny => 'Free';

  @override
  String divisionSideN(String n, String length) {
    return 'Side $n · $length';
  }

  @override
  String get divisionRoadTitle => 'COMMON ROAD ALONG THAT SIDE';

  @override
  String get divisionRoadHint => 'Taken out first; every lot opens onto it.';

  @override
  String get divisionRoadNone => 'None';

  @override
  String get divisionRoadNeedsFront => 'Choose the side first.';

  @override
  String get divisionStraighten => 'Straighten dividers';

  @override
  String get divisionFront => 'Front';

  @override
  String get divisionNorth => 'N';

  @override
  String get cardinalNorth => 'North';

  @override
  String get cardinalEast => 'East';

  @override
  String get cardinalSouth => 'South';

  @override
  String get cardinalWest => 'West';

  @override
  String get divisionOutside => 'plot boundary';

  @override
  String get divisionSaved => 'Saved as a sheet';

  @override
  String get divisionOpenSheet => 'Open';

  @override
  String divisionSheetName(String name) {
    return '$name — division';
  }

  @override
  String get divisionPdfTitle => 'DIVISION';

  @override
  String get divisionPdfTotal => 'Total land';

  @override
  String get divisionPdfNorth => 'The top of the drawing is north.';

  @override
  String get divisionPdfDisclaimer =>
      'Drawn for measurement — not a legal deed.';

  @override
  String get divisionColShare => 'Share';

  @override
  String get divisionColSide => 'Side';

  @override
  String get divisionColLength => 'Length';

  @override
  String get divisionColBeyond => 'Beyond';

  @override
  String get divisionSlid => 'Sizes changed to areas.';

  @override
  String get divisionEdit => 'Change division';

  @override
  String get divisionParentGone =>
      'The plot this was divided from has been deleted.';

  @override
  String divisionPeople(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$name · $countString owners';
  }

  @override
  String get divisionDragHint =>
      'Drag a divider to shift land, or its end to turn it.';

  @override
  String get divisionBoundsEmpty =>
      'Nothing to show until the division works out.';

  @override
  String get divisionColLocal => 'In local units';

  @override
  String get inheritTitle => 'Inheritance shares';

  @override
  String get inheritDrawerSub => 'Who gets what share, by Islamic law';

  @override
  String inheritStep(int step, String name) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);

    return 'Step $stepString of 3 · $name';
  }

  @override
  String get inheritStepDeceased => 'Who has died?';

  @override
  String get inheritStepFamily => 'Who survived them?';

  @override
  String get inheritStepResult => 'Who gets what';

  @override
  String get inheritMan => 'A man';

  @override
  String get inheritWoman => 'A woman';

  @override
  String get inheritNameHint => 'Their name (optional)';

  @override
  String get inheritLand => 'Land to share (optional)';

  @override
  String get inheritLandHint => 'Leave it empty to see the shares only.';

  @override
  String get inheritFromSaved => 'Or pick a saved plot';

  @override
  String get inheritSeeResult => 'See the shares';

  @override
  String get inheritNeedHeir => 'Add at least one heir';

  @override
  String get inheritFamily => 'Close family';

  @override
  String get inheritMore => 'Other relatives';

  @override
  String get inheritPredeceasedAdd => 'A child who died before them';

  @override
  String get inheritPredeceasedAddSub => 'Their children take their share';

  @override
  String inheritPredeceasedTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Child who died earlier · $nString';
  }

  @override
  String get inheritPredeceasedNote =>
      'Their children take what they would have taken (Muslim Family Laws Ordinance 1961, s. 4).';

  @override
  String get inheritTheirSons => 'Their sons';

  @override
  String get inheritTheirDaughters => 'Their daughters';

  @override
  String get inheritNoChildrenNote =>
      'With no children of their own they take nothing.';

  @override
  String get inheritHalfSiblings => 'Half brothers and sisters';

  @override
  String get inheritMaleLine => 'Nephews, uncles and cousins';

  @override
  String get inheritSubGrandfather => 'Father\'s father';

  @override
  String get inheritSubPaternalGrandmother => 'Father\'s mother';

  @override
  String get inheritSubMaternalGrandmother => 'Mother\'s mother';

  @override
  String get inheritSubFull => 'Same father and mother';

  @override
  String get inheritSubPaternal => 'Same father, another mother';

  @override
  String get inheritSubMaternal => 'Same mother, another father';

  @override
  String get inheritSubFullNephew => 'A full brother\'s son';

  @override
  String get inheritSubPaternalNephew => 'A half brother\'s son (same father)';

  @override
  String get inheritSubFullUncle => 'Father\'s full brother';

  @override
  String get inheritSubPaternalUncle => 'Father\'s half brother (same father)';

  @override
  String get inheritSubFullCousin => 'Son of the father\'s full brother';

  @override
  String get inheritSubPaternalCousin => 'Son of the father\'s half brother';

  @override
  String get inheritWivesMax => 'At most four.';

  @override
  String inheritHiddenBy(String who) {
    return 'With $who alive, brothers, sisters, uncles and others take nothing, so they are not asked.';
  }

  @override
  String get inheritSiblingsForMother =>
      'Brothers and sisters take nothing here, but two or more cut the mother to 1/6.';

  @override
  String get inheritDistant =>
      'Distant relatives (মামা, খালা, ফুফু, নানা, a sister\'s children…) inherit only when no sharer or residuary is left; then they are asked about here.';

  @override
  String get inheritHeirHusband => 'Husband';

  @override
  String get inheritHeirWife => 'Wife';

  @override
  String get inheritHeirSon => 'Son';

  @override
  String get inheritHeirDaughter => 'Daughter';

  @override
  String get inheritHeirGrandson => 'son';

  @override
  String get inheritHeirGranddaughter => 'daughter';

  @override
  String get inheritHeirFather => 'Father';

  @override
  String get inheritHeirMother => 'Mother';

  @override
  String get inheritHeirGrandfather => 'Grandfather';

  @override
  String get inheritHeirPaternalGrandmother => 'Father\'s mother';

  @override
  String get inheritHeirMaternalGrandmother => 'Mother\'s mother';

  @override
  String get inheritHeirFullBrother => 'Brother';

  @override
  String get inheritHeirFullSister => 'Sister';

  @override
  String get inheritHeirPaternalBrother => 'Half brother (father)';

  @override
  String get inheritHeirPaternalSister => 'Half sister (father)';

  @override
  String get inheritHeirMaternalBrother => 'Half brother (mother)';

  @override
  String get inheritHeirMaternalSister => 'Half sister (mother)';

  @override
  String get inheritHeirFullNephew => 'Nephew';

  @override
  String get inheritHeirPaternalNephew => 'Nephew (half brother)';

  @override
  String get inheritHeirFullUncle => 'Uncle';

  @override
  String get inheritHeirPaternalUncle => 'Uncle (half)';

  @override
  String get inheritHeirFullCousin => 'Cousin';

  @override
  String get inheritHeirPaternalCousin => 'Cousin (half uncle)';

  @override
  String inheritNumbered(String heir, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$heir $nString';
  }

  @override
  String inheritChildOf(String parent, String child) {
    return '$parent\'s $child';
  }

  @override
  String get inheritWhyHusbandHalf => 'No children: the husband takes 1/2.';

  @override
  String get inheritWhyHusbandQuarter =>
      'With children: the husband takes 1/4.';

  @override
  String get inheritWhyWifeQuarter =>
      'No children: wives take 1/4, shared equally.';

  @override
  String get inheritWhyWifeEighth =>
      'With children: wives take 1/8, shared equally.';

  @override
  String get inheritWhySonResidue =>
      'Sons and daughters take what is left after the fixed shares, a son twice a daughter.';

  @override
  String get inheritWhyDaughterWithSon =>
      'With a son, a daughter takes half what a son takes.';

  @override
  String get inheritWhyDaughterHalf =>
      'An only daughter with no son takes 1/2.';

  @override
  String get inheritWhyDaughtersTwoThirds =>
      'Daughters with no son take 2/3 between them.';

  @override
  String get inheritWhyFatherSixth => 'With a son: the father takes 1/6.';

  @override
  String get inheritWhyFatherSixthAndRest =>
      'Daughters but no son: the father takes 1/6 and what is left.';

  @override
  String get inheritWhyFatherRest =>
      'No children: the father takes what is left after the fixed shares.';

  @override
  String get inheritWhyGrandfatherSixth =>
      'With the father gone, the grandfather takes his place: 1/6 with a son.';

  @override
  String get inheritWhyGrandfatherSixthAndRest =>
      'In the father\'s place: 1/6 and what is left.';

  @override
  String get inheritWhyGrandfatherRest =>
      'In the father\'s place: what is left.';

  @override
  String get inheritWhyMotherSixthChild =>
      'With children: the mother takes 1/6.';

  @override
  String get inheritWhyMotherSixthSiblings =>
      'With two or more brothers or sisters: the mother takes 1/6.';

  @override
  String get inheritWhyMotherThird =>
      'No children and fewer than two siblings: the mother takes 1/3.';

  @override
  String get inheritWhyMotherThirdOfRest =>
      'Only the spouse and both parents: the mother takes 1/3 of what the spouse leaves.';

  @override
  String get inheritWhyGrandmotherSixth =>
      'With the mother gone: grandmothers take 1/6, shared equally.';

  @override
  String get inheritWhyUterineSixth =>
      'No children, father or grandfather: one half sibling through the mother takes 1/6.';

  @override
  String get inheritWhyUterineThird =>
      'Half siblings through the mother take 1/3, brothers and sisters alike.';

  @override
  String get inheritWhySisterHalf =>
      'An only sister with no brother takes 1/2.';

  @override
  String get inheritWhySistersTwoThirds =>
      'Sisters with no brother take 2/3 between them.';

  @override
  String get inheritWhyPaternalSisterSixth =>
      'With one full sister taking 1/2, half sisters take 1/6 to make 2/3.';

  @override
  String get inheritWhySiblingsResidue =>
      'Brothers and sisters take what is left, a brother twice a sister.';

  @override
  String get inheritWhySisterWithDaughters =>
      'With a daughter, a sister takes what is left.';

  @override
  String get inheritWhyAgnateResidue =>
      'The nearest man of the family line takes what is left.';

  @override
  String get inheritWhyRepresented =>
      'Their late parent\'s share, a son twice a daughter (Ordinance 1961).';

  @override
  String get inheritWhySole => 'With no other heir, takes everything.';

  @override
  String get inheritAwl =>
      'The fixed shares came to more than the whole, so every share was cut in the same proportion (awl).';

  @override
  String get inheritRadd =>
      'Something was left over, so it went back to the heirs other than the spouse, in proportion (radd).';

  @override
  String get inheritSpouseRest =>
      'With no other heir, the spouse takes the rest too. If distant kin survive, ask an expert.';

  @override
  String get inheritExcludedTitle => 'Who gets nothing';

  @override
  String inheritOut(String heir, String reason) {
    return '$heir: nothing, $reason';
  }

  @override
  String get inheritOutSon => 'because there is a son';

  @override
  String get inheritOutFather => 'because the father is alive';

  @override
  String get inheritOutGrandfather => 'because the grandfather is alive';

  @override
  String get inheritOutMother => 'because the mother is alive';

  @override
  String get inheritOutChild => 'because there are children';

  @override
  String get inheritOutFullBrother => 'because there is a full brother';

  @override
  String get inheritOutPaternalBrother => 'because there is a half brother';

  @override
  String get inheritOutSisterWithDaughters =>
      'because a sister takes the rest with the daughters';

  @override
  String get inheritOutTwoFullSisters =>
      'because two full sisters take the 2/3';

  @override
  String get inheritOutCloser => 'because a closer relative takes the rest';

  @override
  String get inheritOutNothingLeft =>
      'because the fixed shares took everything';

  @override
  String get inheritWhoSon => 'a son';

  @override
  String get inheritWhoFather => 'the father';

  @override
  String get inheritWhoGrandfather => 'the grandfather';

  @override
  String get inheritMotherCut =>
      'They take nothing, but because of them the mother takes 1/6.';

  @override
  String inheritBase(String n) {
    return 'Base $n';
  }

  @override
  String inheritParts(String parts, String base) {
    return '$parts of $base parts';
  }

  @override
  String inheritEstate(String name) {
    return '$name\'s estate';
  }

  @override
  String get inheritDeceasedMan => 'The deceased (a man)';

  @override
  String get inheritDeceasedWoman => 'The deceased (a woman)';

  @override
  String get inheritSharesOnly => 'Shares of the whole estate';

  @override
  String get inheritDivide => 'Divide the land by these shares';

  @override
  String get inheritShare => 'Share';

  @override
  String get inheritDisclaimer =>
      'Worked out by Hanafi rules and the Muslim Family Laws Ordinance 1961. Check with an expert before a deed or a court.';

  @override
  String get inheritPickPlot => 'Which plot is being divided?';

  @override
  String get inheritEdit => 'Change the family';

  @override
  String get inheritReligion => 'Religion of the deceased';

  @override
  String get inheritMuslim => 'Muslim';

  @override
  String get inheritHindu => 'Hindu';

  @override
  String get inheritChristian => 'Christian';

  @override
  String get inheritHinduWoman =>
      'A Hindu woman\'s property follows other rules. What she got as a widow, daughter or mother goes back, at her death, to the heirs of the man she got it from: work it out for him instead. Her own property (stridhan) goes first to her children; beyond that, ask a Hindu-law lawyer.';

  @override
  String inheritLate(String heir, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Late $heir $nString';
  }

  @override
  String get inheritViaWife => 'wife';

  @override
  String get inheritHeirSonsWidow => 'Son\'s widow';

  @override
  String get inheritHeirUnmarriedDaughter => 'Unmarried daughter';

  @override
  String get inheritHeirMarriedDaughter => 'Married daughter';

  @override
  String get inheritHeirDaughtersSon => 'Daughter\'s son';

  @override
  String get inheritHeirDaughtersDaughter => 'Daughter\'s daughter';

  @override
  String get inheritHeirBrother => 'Brother';

  @override
  String get inheritHeirSister => 'Sister';

  @override
  String get inheritHeirGrandNephew => 'Nephew\'s son';

  @override
  String get inheritHeirSistersSon => 'Sister\'s son';

  @override
  String get inheritHeirSistersDaughter => 'Sister\'s daughter';

  @override
  String get inheritHeirBrothersDaughter => 'Brother\'s daughter';

  @override
  String get inheritHeirMaternalGrandfather => 'Mother\'s father';

  @override
  String get inheritHeirPaternalAunt => 'Father\'s sister';

  @override
  String get inheritHeirMaternalUncle => 'Mother\'s brother';

  @override
  String get inheritHeirMaternalAunt => 'Mother\'s sister';

  @override
  String get inheritHeirCousin => 'First cousin';

  @override
  String get inheritSubWidows => 'Together they take one son\'s share.';

  @override
  String get inheritSubUnmarried => 'Not yet married';

  @override
  String get inheritSubMarriedWithSon => 'Has a son, or may still have one';

  @override
  String get inheritHinduDaughterNote =>
      'A widowed or childless daughter who has no son and cannot have one does not inherit.';

  @override
  String get inheritDeadSonAdd => 'A son who died before him';

  @override
  String get inheritDeadSonAddSub => 'His sons and his widow take his share';

  @override
  String inheritDeadSonTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Son who died earlier · $nString';
  }

  @override
  String get inheritTheirWidow => 'His widow is alive';

  @override
  String get inheritSubBrothersSon => 'A brother\'s son';

  @override
  String get inheritSubSistersSon => 'A sister\'s son';

  @override
  String get inheritSubUnclesSon => 'Father\'s brother\'s son';

  @override
  String get inheritSubHalfBrotherHindu => 'Same father, another mother';

  @override
  String get inheritHinduHiddenMale =>
      'With a son, grandson or son\'s widow, daughters and everyone else take nothing, so they are not asked.';

  @override
  String get inheritHinduHiddenWidow =>
      'With the widow alive, daughters and the rest take nothing now; at her death the property goes on to them.';

  @override
  String get inheritHinduDistant =>
      'Relatives beyond these follow a long classical order not covered here, and a will, gift or earlier partition changes things: ask a Hindu-law lawyer.';

  @override
  String get inheritSpouseChristian => 'Widow or widower';

  @override
  String get inheritChristianDeadNote =>
      'Their children share their share equally (Succession Act 1925, s. 40).';

  @override
  String get inheritDeadSiblingAdd => 'A brother or sister who died earlier';

  @override
  String get inheritDeadSiblingAddSub => 'Their children take their share';

  @override
  String inheritDeadSiblingTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Brother or sister who died earlier · $nString';
  }

  @override
  String get inheritSubAnyBlood => 'Full or half: the same';

  @override
  String get inheritChristianHiddenDesc =>
      'With children or grandchildren, parents, brothers, sisters and other relatives take nothing.';

  @override
  String get inheritChristianHiddenFather =>
      'With the father alive, the mother, brothers, sisters and others take nothing.';

  @override
  String get inheritChristianDistant =>
      'For relatives further than first cousins, ask a lawyer. With no relative at all, the property goes to the Government.';

  @override
  String get inheritLifeInterest => 'For life';

  @override
  String get inheritDisclaimerHindu =>
      'Worked out by the Dayabhaga law followed in Bangladesh and the Hindu Women\'s Rights to Property Act 1937. Check with an expert before a deed or a court.';

  @override
  String get inheritDisclaimerChristian =>
      'Worked out by the Succession Act 1925 (Part V). A will, a pre-marriage contract or custom changes things. Check with an expert before a deed or a court.';

  @override
  String get inheritWhyHinduSons => 'Sons share equally.';

  @override
  String get inheritWhyHinduWidow =>
      'The widow takes a son\'s share (widows together share one), for life (1937 Act).';

  @override
  String get inheritWhyHinduSonsLine =>
      'His late father\'s share, shared among his sons.';

  @override
  String get inheritWhyHinduSonsWidowAsSon =>
      'A dead son\'s widow with no son takes as a son, for life (1937 Act).';

  @override
  String get inheritWhyHinduSonsWidowAsGrandson =>
      'Beside her sons she takes as one of them, for life (1937 Act).';

  @override
  String get inheritWhyHinduUnmarriedDaughters =>
      'With no son, grandson or widow, unmarried daughters share equally, for life.';

  @override
  String get inheritWhyHinduMarriedDaughters =>
      'With no unmarried daughter, married daughters who have or may have a son share equally, for life.';

  @override
  String get inheritWhyHinduDaughtersSons =>
      'Daughters\' sons share equally, per head.';

  @override
  String get inheritWhyHinduFather => 'Next in line: the father takes all.';

  @override
  String get inheritWhyHinduMother =>
      'Next in line: the mother takes all, for life.';

  @override
  String get inheritWhyHinduBrothers =>
      'Next in line: brothers share equally (a full brother before a half brother).';

  @override
  String get inheritWhyHinduNephews =>
      'Next in line: brothers\' sons share equally.';

  @override
  String get inheritWhyHinduGrandNephews =>
      'Next in line: brothers\' grandsons share equally.';

  @override
  String get inheritWhyHinduSistersSons =>
      'Next in line: sisters\' sons share equally.';

  @override
  String get inheritWhyHinduGrandfather =>
      'Next in line: the father\'s father takes all.';

  @override
  String get inheritWhyHinduGrandmother =>
      'Next in line: the father\'s mother takes all, for life.';

  @override
  String get inheritWhyHinduUncles =>
      'Next in line: the father\'s brothers share equally.';

  @override
  String get inheritWhyHinduCousins =>
      'Next in line: the uncles\' sons share equally.';

  @override
  String get inheritWhyChristianSpouseThird =>
      'With children or grandchildren: the spouse takes 1/3 (s. 33).';

  @override
  String get inheritWhyChristianSpouseHalf =>
      'No descendants, but other relatives: the spouse takes 1/2 (s. 33).';

  @override
  String get inheritWhyChristianSpouseAll =>
      'No relative at all: the spouse takes everything (s. 33).';

  @override
  String get inheritWhyChristianChildren =>
      'Sons and daughters share equally (s. 37).';

  @override
  String get inheritWhyChristianChildOfDead =>
      'Their late parent\'s share, shared equally (s. 40).';

  @override
  String get inheritWhyChristianGrandchildrenPerHead =>
      'No child alive: grandchildren share per head (s. 38).';

  @override
  String get inheritWhyChristianFather =>
      'No descendants: the father takes the rest (s. 42).';

  @override
  String get inheritWhyChristianMotherAndSiblings =>
      'Father gone: the mother and each brother or sister share equally (ss. 43-45).';

  @override
  String get inheritWhyChristianMother =>
      'Father gone, no brother or sister: the mother takes the rest (s. 46).';

  @override
  String get inheritWhyChristianSiblings =>
      'Both parents gone: brothers and sisters share equally, full or half (s. 47).';

  @override
  String get inheritWhyChristianSiblingsChildren =>
      'Their late parent\'s share, shared equally (ss. 44-47).';

  @override
  String get inheritWhyChristianNearest =>
      'The nearest relatives share per head (s. 48).';

  @override
  String get inheritNoteHinduLimited =>
      'A life interest (জীবনস্বত্ব): she uses and enjoys it, cannot sell it except for real need, and at her death it goes to the deceased\'s heirs of that time, not to hers.';

  @override
  String get inheritNoteHinduSonsWidow =>
      'How a dead son\'s widow shares beside her own sons is not settled by any reported case; here she counts as one of them.';

  @override
  String get inheritNoteChristianSpouseAll =>
      'The spouse takes everything only if no relative of any degree survives; with any relative at all, the spouse takes 1/2.';

  @override
  String get inheritNoteChristianPerHead =>
      'No child is alive, so the grandchildren share per head, not by family branch (s. 38).';

  @override
  String get inheritNoteNoHeirs =>
      'With no heir at all, the property goes to the Government.';

  @override
  String get inheritOutMaleLine =>
      'because there is a son, grandson or son\'s widow';

  @override
  String get inheritOutWidowFirst =>
      'while the widow lives (may take after her)';

  @override
  String get inheritOutUnmarriedDaughter =>
      'because there is an unmarried daughter';

  @override
  String get inheritOutCloserKin => 'because a nearer heir takes first';

  @override
  String get inheritHeirPaternalAuntConsanguine =>
      'Father\'s half sister (father)';

  @override
  String get inheritHeirPaternalAuntUterine => 'Father\'s half sister (mother)';

  @override
  String get inheritHeirFatherUterineBrother =>
      'Father\'s half brother (mother)';

  @override
  String get inheritHeirMaternalUncleConsanguine =>
      'Mother\'s half brother (father)';

  @override
  String get inheritHeirMaternalUncleUterine =>
      'Mother\'s half brother (mother)';

  @override
  String get inheritHeirMaternalAuntConsanguine =>
      'Mother\'s half sister (father)';

  @override
  String get inheritHeirMaternalAuntUterine => 'Mother\'s half sister (mother)';

  @override
  String inheritChildrenOf(String parent) {
    return '$parent\'s children';
  }

  @override
  String get inheritDistantTitle => 'Distant relatives';

  @override
  String get inheritDistantIntro =>
      'With no sharer or residuary heir besides the spouse, distant relatives inherit (zawil arham). The spouse keeps their usual share; they take the rest.';

  @override
  String get inheritSubMaternalGrandfather => 'Mother\'s father';

  @override
  String get inheritLineAdd => 'A brother or sister who died, with children';

  @override
  String get inheritLineAddSub => 'Their children may inherit here';

  @override
  String inheritLineTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Late brother or sister · $nString';
  }

  @override
  String get inheritBloodFull => 'Full';

  @override
  String get inheritBloodConsanguine => 'Same father';

  @override
  String get inheritBloodUterine => 'Same mother';

  @override
  String get inheritLineBrotherSons =>
      'His sons are nephews and take ahead of everyone here: add them above as nephews.';

  @override
  String get inheritAuntsHalf => 'Half aunts and uncles';

  @override
  String get inheritDistantBeyond =>
      'For cousins through women (ফুফাতো, মামাতো, খালাতো), a paternal uncle\'s daughter, or a daughter\'s daughter\'s children, ask an expert.';

  @override
  String get inheritWhyDistantKindred =>
      'The nearest distant relative: takes what the spouse leaves.';

  @override
  String get inheritWhyDistantSiblingLine =>
      'Takes as their late parent would have, a son twice a daughter (equal through a half sibling by the mother).';

  @override
  String get inheritWhyDistantUnclesAunts =>
      'The father\'s side takes 2/3 and the mother\'s 1/3; full blood first, a man twice a woman.';

  @override
  String get inheritNoteDistantKindred =>
      'No sharer or residuary heir survives besides the spouse, so distant relatives inherit, by the rules in Mulla\'s Principles of Mahomedan Law (Imam Muhammad\'s method).';

  @override
  String get inheritNoteDistantGrandfather =>
      'The mother\'s father is put before the children of brothers and sisters, as Mulla does; an older text hints otherwise. Ask an expert for this case.';

  @override
  String get inheritNoteDistantAwl =>
      'The spouse and the siblings\' children came to more than the whole; the books give no rule for this case. Ask an expert.';

  @override
  String inheritBaseParts(String n) {
    return '$n parts in all';
  }
}
