import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get actionUndo;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get actionRemove;

  /// No description provided for @actionCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get actionCalculate;

  /// No description provided for @actionGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get actionGenerate;

  /// No description provided for @labelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelAll;

  /// No description provided for @labelOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get labelOr;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PlotCalc'**
  String get appName;

  /// No description provided for @tabPlots.
  ///
  /// In en, this message translates to:
  /// **'Plots'**
  String get tabPlots;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabSubdivide.
  ///
  /// In en, this message translates to:
  /// **'Subdivide'**
  String get tabSubdivide;

  /// No description provided for @tabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found: {uri}'**
  String routeNotFound(String uri);

  /// No description provided for @defaultPlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get defaultPlotLabel;

  /// No description provided for @unitSqftLabel.
  ///
  /// In en, this message translates to:
  /// **'sq ft'**
  String get unitSqftLabel;

  /// No description provided for @unitSqftName.
  ///
  /// In en, this message translates to:
  /// **'Square feet'**
  String get unitSqftName;

  /// No description provided for @unitSqmLabel.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get unitSqmLabel;

  /// No description provided for @unitSqmName.
  ///
  /// In en, this message translates to:
  /// **'Square meters'**
  String get unitSqmName;

  /// No description provided for @unitAcreLabel.
  ///
  /// In en, this message translates to:
  /// **'acre'**
  String get unitAcreLabel;

  /// No description provided for @unitAcreName.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get unitAcreName;

  /// No description provided for @unitHectareLabel.
  ///
  /// In en, this message translates to:
  /// **'hectare'**
  String get unitHectareLabel;

  /// No description provided for @unitHectareName.
  ///
  /// In en, this message translates to:
  /// **'Hectares'**
  String get unitHectareName;

  /// No description provided for @unitBighaLabel.
  ///
  /// In en, this message translates to:
  /// **'bigha'**
  String get unitBighaLabel;

  /// No description provided for @unitBighaName.
  ///
  /// In en, this message translates to:
  /// **'Bigha'**
  String get unitBighaName;

  /// No description provided for @unitKathaLabel.
  ///
  /// In en, this message translates to:
  /// **'katha'**
  String get unitKathaLabel;

  /// No description provided for @unitKathaName.
  ///
  /// In en, this message translates to:
  /// **'Katha'**
  String get unitKathaName;

  /// No description provided for @unitChatakLabel.
  ///
  /// In en, this message translates to:
  /// **'chatak'**
  String get unitChatakLabel;

  /// No description provided for @unitChatakName.
  ///
  /// In en, this message translates to:
  /// **'Chatak'**
  String get unitChatakName;

  /// No description provided for @unitShotokLabel.
  ///
  /// In en, this message translates to:
  /// **'shotok'**
  String get unitShotokLabel;

  /// No description provided for @unitShotokName.
  ///
  /// In en, this message translates to:
  /// **'Shotok'**
  String get unitShotokName;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'Meters'**
  String get unitMeters;

  /// No description provided for @unitFeet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get unitFeet;

  /// No description provided for @unitMeterShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMeterShort;

  /// No description provided for @unitFeetShort.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get unitFeetShort;

  /// No description provided for @tagAgricultural.
  ///
  /// In en, this message translates to:
  /// **'Agricultural'**
  String get tagAgricultural;

  /// No description provided for @tagResidential.
  ///
  /// In en, this message translates to:
  /// **'Residential'**
  String get tagResidential;

  /// No description provided for @tagCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get tagCommercial;

  /// No description provided for @tagForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get tagForest;

  /// No description provided for @tagOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tagOther;

  /// No description provided for @presetRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get presetRectangle;

  /// No description provided for @presetSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get presetSquare;

  /// No description provided for @presetTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get presetTriangle;

  /// No description provided for @presetTrapezoid.
  ///
  /// In en, this message translates to:
  /// **'Trapezoid'**
  String get presetTrapezoid;

  /// No description provided for @presetPentagon.
  ///
  /// In en, this message translates to:
  /// **'Pentagon'**
  String get presetPentagon;

  /// No description provided for @presetFreeform.
  ///
  /// In en, this message translates to:
  /// **'Free-form'**
  String get presetFreeform;

  /// No description provided for @methodDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get methodDraw;

  /// No description provided for @methodTap.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get methodTap;

  /// No description provided for @methodType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get methodType;

  /// No description provided for @methodDrawSub.
  ///
  /// In en, this message translates to:
  /// **'Tap & drag'**
  String get methodDrawSub;

  /// No description provided for @methodTapSub.
  ///
  /// In en, this message translates to:
  /// **'Place vertices'**
  String get methodTapSub;

  /// No description provided for @methodTypeSub.
  ///
  /// In en, this message translates to:
  /// **'Sides + angles'**
  String get methodTypeSub;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Plots'**
  String get homeTitle;

  /// No description provided for @homeBuildBy.
  ///
  /// In en, this message translates to:
  /// **'Build By · Zaman Sheikh'**
  String get homeBuildBy;

  /// No description provided for @homeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'THIS MONTH · MEASURED'**
  String get homeThisMonth;

  /// No description provided for @homePlusPlots.
  ///
  /// In en, this message translates to:
  /// **'+{count} plots'**
  String homePlusPlots(int count);

  /// No description provided for @homeMeasurePlot.
  ///
  /// In en, this message translates to:
  /// **'Measure plot'**
  String get homeMeasurePlot;

  /// No description provided for @homeMeasureSub.
  ///
  /// In en, this message translates to:
  /// **'Draw or type sides'**
  String get homeMeasureSub;

  /// No description provided for @homeBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get homeBadgeNew;

  /// No description provided for @homeToolLabel.
  ///
  /// In en, this message translates to:
  /// **'TOOL'**
  String get homeToolLabel;

  /// No description provided for @homeAllUnits.
  ///
  /// In en, this message translates to:
  /// **'All units'**
  String get homeAllUnits;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'RECENT · {count}'**
  String homeRecent(int count);

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @pickerStep.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 / 3'**
  String get pickerStep;

  /// No description provided for @pickerQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do you want to start?'**
  String get pickerQuestion;

  /// No description provided for @pickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a method, then a shape.'**
  String get pickerSubtitle;

  /// No description provided for @pickerShapePresets.
  ///
  /// In en, this message translates to:
  /// **'SHAPE PRESETS'**
  String get pickerShapePresets;

  /// No description provided for @pickerStartDrawing.
  ///
  /// In en, this message translates to:
  /// **'Start drawing'**
  String get pickerStartDrawing;

  /// No description provided for @pickerPlaceVertices.
  ///
  /// In en, this message translates to:
  /// **'Place vertices'**
  String get pickerPlaceVertices;

  /// No description provided for @pickerEnterDimensions.
  ///
  /// In en, this message translates to:
  /// **'Enter dimensions'**
  String get pickerEnterDimensions;

  /// No description provided for @pickerSidesN.
  ///
  /// In en, this message translates to:
  /// **'{count}–N sides'**
  String pickerSidesN(int count);

  /// No description provided for @pickerTapEachCorner.
  ///
  /// In en, this message translates to:
  /// **'Tap each corner on the canvas'**
  String get pickerTapEachCorner;

  /// No description provided for @drawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw plot'**
  String get drawTitle;

  /// No description provided for @drawTitleTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to place vertices'**
  String get drawTitleTap;

  /// No description provided for @drawTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plot'**
  String get drawTitleEdit;

  /// No description provided for @drawVerticesUnsaved.
  ///
  /// In en, this message translates to:
  /// **'{count} VERTICES · UNSAVED'**
  String drawVerticesUnsaved(int count);

  /// No description provided for @drawArea.
  ///
  /// In en, this message translates to:
  /// **'AREA'**
  String get drawArea;

  /// No description provided for @drawPerimeter.
  ///
  /// In en, this message translates to:
  /// **'PERIMETER'**
  String get drawPerimeter;

  /// No description provided for @drawSides.
  ///
  /// In en, this message translates to:
  /// **'SIDES'**
  String get drawSides;

  /// No description provided for @drawDiag.
  ///
  /// In en, this message translates to:
  /// **'DIAG'**
  String get drawDiag;

  /// No description provided for @drawHintDone.
  ///
  /// In en, this message translates to:
  /// **'Tap “Done” or keep adding vertices'**
  String get drawHintDone;

  /// No description provided for @drawHintMin.
  ///
  /// In en, this message translates to:
  /// **'Place at least 3 vertices'**
  String get drawHintMin;

  /// No description provided for @drawHintPlaced.
  ///
  /// In en, this message translates to:
  /// **'{count} placed · tap canvas to add more'**
  String drawHintPlaced(int count);

  /// No description provided for @drawVertexOf.
  ///
  /// In en, this message translates to:
  /// **'Vertex {index} of {total}'**
  String drawVertexOf(int index, int total);

  /// No description provided for @drawVertexInfo.
  ///
  /// In en, this message translates to:
  /// **'x: {x}m · y: {y}m · ∠ {angle}°'**
  String drawVertexInfo(String x, String y, String angle);

  /// No description provided for @drawSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved “{name}” · {tag}'**
  String drawSavedToast(String name, String tag);

  /// No description provided for @drawDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Plot · {time}'**
  String drawDefaultName(String time);

  /// No description provided for @edgeAdjustDiagonal.
  ///
  /// In en, this message translates to:
  /// **'Adjust diagonal'**
  String get edgeAdjustDiagonal;

  /// No description provided for @edgeAdjustSide.
  ///
  /// In en, this message translates to:
  /// **'Adjust side'**
  String get edgeAdjustSide;

  /// No description provided for @edgeNowLength.
  ///
  /// In en, this message translates to:
  /// **'now {value} {unit}'**
  String edgeNowLength(String value, String unit);

  /// No description provided for @edgeNewLength.
  ///
  /// In en, this message translates to:
  /// **'NEW LENGTH'**
  String get edgeNewLength;

  /// No description provided for @edgeWhichEndpoint.
  ///
  /// In en, this message translates to:
  /// **'WHICH ENDPOINT MOVES?'**
  String get edgeWhichEndpoint;

  /// No description provided for @edgeMoveEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Move {label}'**
  String edgeMoveEndpoint(String label);

  /// No description provided for @edgeInsertMidpoint.
  ///
  /// In en, this message translates to:
  /// **'Insert vertex at midpoint'**
  String get edgeInsertMidpoint;

  /// No description provided for @saveSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Save plot'**
  String get saveSheetTitle;

  /// No description provided for @saveSheetName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get saveSheetName;

  /// No description provided for @saveSheetNameHint.
  ///
  /// In en, this message translates to:
  /// **'Plot name'**
  String get saveSheetNameHint;

  /// No description provided for @saveSheetCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get saveSheetCategory;

  /// No description provided for @typeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter dimensions'**
  String get typeTitle;

  /// No description provided for @typeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{shape} · values in {unit}'**
  String typeSubtitle(String shape, String unit);

  /// No description provided for @typeWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get typeWidth;

  /// No description provided for @typeHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get typeHeight;

  /// No description provided for @typeSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get typeSide;

  /// No description provided for @typeSideA.
  ///
  /// In en, this message translates to:
  /// **'Side A'**
  String get typeSideA;

  /// No description provided for @typeSideB.
  ///
  /// In en, this message translates to:
  /// **'Side B'**
  String get typeSideB;

  /// No description provided for @typeSideC.
  ///
  /// In en, this message translates to:
  /// **'Side C'**
  String get typeSideC;

  /// No description provided for @typeTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get typeTop;

  /// No description provided for @typeBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get typeBottom;

  /// No description provided for @typeSideLength.
  ///
  /// In en, this message translates to:
  /// **'Side length'**
  String get typeSideLength;

  /// No description provided for @typeSidesCount.
  ///
  /// In en, this message translates to:
  /// **'Sides'**
  String get typeSidesCount;

  /// No description provided for @typeTriangle3.
  ///
  /// In en, this message translates to:
  /// **'Triangle (3 sides)'**
  String get typeTriangle3;

  /// No description provided for @typeRegularPentagon.
  ///
  /// In en, this message translates to:
  /// **'Regular pentagon'**
  String get typeRegularPentagon;

  /// No description provided for @typeRegularPolygon.
  ///
  /// In en, this message translates to:
  /// **'Regular polygon'**
  String get typeRegularPolygon;

  /// No description provided for @typeErrPositive.
  ///
  /// In en, this message translates to:
  /// **'Each value must be a positive number.'**
  String get typeErrPositive;

  /// No description provided for @typeErrTriangle.
  ///
  /// In en, this message translates to:
  /// **'Sides do not form a triangle (each pair must sum > third).'**
  String get typeErrTriangle;

  /// No description provided for @typeErrMinSides.
  ///
  /// In en, this message translates to:
  /// **'A polygon needs at least 3 sides.'**
  String get typeErrMinSides;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} plots · {area} acre total'**
  String historySubtitle(int count, String area);

  /// No description provided for @historySearch.
  ///
  /// In en, this message translates to:
  /// **'Search plots…'**
  String get historySearch;

  /// No description provided for @historyFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get historyFilter;

  /// No description provided for @historyChip.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}'**
  String historyChip(String label, int count);

  /// No description provided for @historySelected.
  ///
  /// In en, this message translates to:
  /// **'{count} SELECTED'**
  String historySelected(int count);

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plots yet — measure one from Home.'**
  String get historyEmpty;

  /// No description provided for @historyPlotMeta.
  ///
  /// In en, this message translates to:
  /// **' · {sides} sides · {when}'**
  String historyPlotMeta(int sides, String when);

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today · {time}'**
  String historyToday(String time);

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// No description provided for @historyCompare2.
  ///
  /// In en, this message translates to:
  /// **'Compare 2 plots'**
  String get historyCompare2;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterTitle;

  /// No description provided for @filterAllPlots.
  ///
  /// In en, this message translates to:
  /// **'All plots'**
  String get filterAllPlots;

  /// No description provided for @plotTagSides.
  ///
  /// In en, this message translates to:
  /// **'{tag} · {sides} sides'**
  String plotTagSides(String tag, int sides);

  /// No description provided for @plotRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename plot'**
  String get plotRenameTitle;

  /// No description provided for @plotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plot?'**
  String get plotDeleteTitle;

  /// No description provided for @plotDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed permanently.'**
  String plotDeleteBody(String name);

  /// No description provided for @plotClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get plotClearAllTitle;

  /// No description provided for @plotClearAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{All 1 saved plot will be removed. This can’t be undone.} other{All {count} saved plots will be removed. This can’t be undone.}}'**
  String plotClearAllBody(int count);

  /// No description provided for @plotClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get plotClearAll;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compareTitle;

  /// No description provided for @comparePlotA.
  ///
  /// In en, this message translates to:
  /// **'PLOT A'**
  String get comparePlotA;

  /// No description provided for @comparePlotB.
  ///
  /// In en, this message translates to:
  /// **'PLOT B'**
  String get comparePlotB;

  /// No description provided for @compareNameA.
  ///
  /// In en, this message translates to:
  /// **'Plot A'**
  String get compareNameA;

  /// No description provided for @compareNameB.
  ///
  /// In en, this message translates to:
  /// **'Plot B'**
  String get compareNameB;

  /// No description provided for @compareDemoPlot.
  ///
  /// In en, this message translates to:
  /// **'Demo plot'**
  String get compareDemoPlot;

  /// No description provided for @compareOverlay.
  ///
  /// In en, this message translates to:
  /// **'OVERLAY · CENTERED'**
  String get compareOverlay;

  /// No description provided for @compareRatio.
  ///
  /// In en, this message translates to:
  /// **'A ÷ B'**
  String get compareRatio;

  /// No description provided for @compareDelta.
  ///
  /// In en, this message translates to:
  /// **'A − B'**
  String get compareDelta;

  /// No description provided for @compareTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get compareTotal;

  /// No description provided for @compareRelative.
  ///
  /// In en, this message translates to:
  /// **'RELATIVE SIZE'**
  String get compareRelative;

  /// No description provided for @compareUnitSides.
  ///
  /// In en, this message translates to:
  /// **'{unit} · {sides} sides'**
  String compareUnitSides(String unit, int sides);

  /// No description provided for @adjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust to size'**
  String get adjustTitle;

  /// No description provided for @adjustTargetArea.
  ///
  /// In en, this message translates to:
  /// **'TARGET AREA'**
  String get adjustTargetArea;

  /// No description provided for @adjustPctFromBase.
  ///
  /// In en, this message translates to:
  /// **'{pct}% FROM BASE'**
  String adjustPctFromBase(String pct);

  /// No description provided for @adjustBaseValue.
  ///
  /// In en, this message translates to:
  /// **'Base · {value} {unit}'**
  String adjustBaseValue(String value, String unit);

  /// No description provided for @adjustBase.
  ///
  /// In en, this message translates to:
  /// **'BASE'**
  String get adjustBase;

  /// No description provided for @adjustAdjusted.
  ///
  /// In en, this message translates to:
  /// **'ADJUSTED'**
  String get adjustAdjusted;

  /// No description provided for @adjustAnchor.
  ///
  /// In en, this message translates to:
  /// **'ANCHOR'**
  String get adjustAnchor;

  /// No description provided for @adjustUniform.
  ///
  /// In en, this message translates to:
  /// **'Uniform'**
  String get adjustUniform;

  /// No description provided for @adjustWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get adjustWidth;

  /// No description provided for @adjustHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get adjustHeight;

  /// No description provided for @adjustExpandDirection.
  ///
  /// In en, this message translates to:
  /// **'EXPAND DIRECTION'**
  String get adjustExpandDirection;

  /// No description provided for @adjustAnchorFrom.
  ///
  /// In en, this message translates to:
  /// **'ANCHOR FROM'**
  String get adjustAnchorFrom;

  /// No description provided for @adjustApply.
  ///
  /// In en, this message translates to:
  /// **'Apply adjustment'**
  String get adjustApply;

  /// No description provided for @converterTitle.
  ///
  /// In en, this message translates to:
  /// **'Converter'**
  String get converterTitle;

  /// No description provided for @converterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type a number, pick a unit'**
  String get converterSubtitle;

  /// No description provided for @converterValue.
  ///
  /// In en, this message translates to:
  /// **'VALUE'**
  String get converterValue;

  /// No description provided for @converterConvertsTo.
  ///
  /// In en, this message translates to:
  /// **'CONVERTS TO'**
  String get converterConvertsTo;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Plot Summary'**
  String get resultTitle;

  /// No description provided for @resultTotalArea.
  ///
  /// In en, this message translates to:
  /// **'TOTAL AREA · {unit}'**
  String resultTotalArea(String unit);

  /// No description provided for @resultSaved.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get resultSaved;

  /// No description provided for @resultEquivalent.
  ///
  /// In en, this message translates to:
  /// **'EQUIVALENT IN'**
  String get resultEquivalent;

  /// No description provided for @resultValuation.
  ///
  /// In en, this message translates to:
  /// **'VALUATION'**
  String get resultValuation;

  /// No description provided for @resultRatePer.
  ///
  /// In en, this message translates to:
  /// **'RATE / {unit}'**
  String resultRatePer(String unit);

  /// No description provided for @resultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Tk'**
  String get resultCurrency;

  /// No description provided for @resultEstValue.
  ///
  /// In en, this message translates to:
  /// **'EST. VALUE'**
  String get resultEstValue;

  /// No description provided for @resultExportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get resultExportPdf;

  /// No description provided for @resultShareImage.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get resultShareImage;

  /// No description provided for @resultAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get resultAdjust;

  /// No description provided for @subdivideTitle.
  ///
  /// In en, this message translates to:
  /// **'Subdivide'**
  String get subdivideTitle;

  /// No description provided for @subdivideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a saved plot to split into lots'**
  String get subdivideSubtitle;

  /// No description provided for @subdivideSaved.
  ///
  /// In en, this message translates to:
  /// **'Subdivision saved for “{name}”'**
  String subdivideSaved(String name);

  /// No description provided for @subdivideSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save subdivision'**
  String get subdivideSaveAction;

  /// No description provided for @subdivideSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} · {lots} lots · 100%'**
  String subdivideSummary(String name, int lots);

  /// No description provided for @subdivideMeta.
  ///
  /// In en, this message translates to:
  /// **'{area} {unit} · {sides} sides'**
  String subdivideMeta(String area, String unit, int sides);

  /// No description provided for @subdivideEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved plots yet'**
  String get subdivideEmpty;

  /// No description provided for @subdivideEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Measure a plot first, then come back here to split it into lots.'**
  String get subdivideEmptyBody;

  /// No description provided for @subdivideGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get subdivideGoHome;

  /// No description provided for @subdivideLot.
  ///
  /// In en, this message translates to:
  /// **'Lot {n}'**
  String subdivideLot(int n);

  /// No description provided for @khotiyanTitle.
  ///
  /// In en, this message translates to:
  /// **'Khotiyan'**
  String get khotiyanTitle;

  /// No description provided for @khotiyanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share calculator · Ana · Gonda · Kora'**
  String get khotiyanSubtitle;

  /// No description provided for @khotiyanHissya.
  ///
  /// In en, this message translates to:
  /// **'HISSYA'**
  String get khotiyanHissya;

  /// No description provided for @khotiyanTilFraction.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total} til'**
  String khotiyanTilFraction(String selected, String total);

  /// No description provided for @khotiyanSelectUnits.
  ///
  /// In en, this message translates to:
  /// **'SELECT UNITS'**
  String get khotiyanSelectUnits;

  /// No description provided for @khotiyanAna.
  ///
  /// In en, this message translates to:
  /// **'Ana'**
  String get khotiyanAna;

  /// No description provided for @khotiyanGonda.
  ///
  /// In en, this message translates to:
  /// **'Gonda'**
  String get khotiyanGonda;

  /// No description provided for @khotiyanKora.
  ///
  /// In en, this message translates to:
  /// **'Kora'**
  String get khotiyanKora;

  /// No description provided for @khotiyanKranti.
  ///
  /// In en, this message translates to:
  /// **'Kranti'**
  String get khotiyanKranti;

  /// No description provided for @khotiyanTil.
  ///
  /// In en, this message translates to:
  /// **'Til'**
  String get khotiyanTil;

  /// No description provided for @khotiyanTotalLand.
  ///
  /// In en, this message translates to:
  /// **'TOTAL LAND'**
  String get khotiyanTotalLand;

  /// No description provided for @khotiyanYourLand.
  ///
  /// In en, this message translates to:
  /// **'YOUR LAND'**
  String get khotiyanYourLand;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'Land guide'**
  String get infoTitle;

  /// No description provided for @infoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Units, measurement, surveying — and Bangladeshi land records'**
  String get infoSubtitle;

  /// No description provided for @infoArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get infoArticle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tweak the look, feel, and units'**
  String get settingsSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get settingsLanguageBengali;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get settingsTheme;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccent;

  /// No description provided for @settingsGridStyle.
  ///
  /// In en, this message translates to:
  /// **'GRID STYLE'**
  String get settingsGridStyle;

  /// No description provided for @settingsGridDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get settingsGridDots;

  /// No description provided for @settingsGridLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get settingsGridLines;

  /// No description provided for @settingsGridBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Blueprint'**
  String get settingsGridBlueprint;

  /// No description provided for @settingsAreaUnit.
  ///
  /// In en, this message translates to:
  /// **'AREA UNIT'**
  String get settingsAreaUnit;

  /// No description provided for @settingsLengthUnit.
  ///
  /// In en, this message translates to:
  /// **'LENGTH UNIT'**
  String get settingsLengthUnit;

  /// No description provided for @settingsUnderlay.
  ///
  /// In en, this message translates to:
  /// **'UNDERLAY'**
  String get settingsUnderlay;

  /// No description provided for @settingsMapUnderlay.
  ///
  /// In en, this message translates to:
  /// **'Map underlay'**
  String get settingsMapUnderlay;

  /// No description provided for @settingsMapUnderlaySub.
  ///
  /// In en, this message translates to:
  /// **'Show road & parcel hints behind the canvas'**
  String get settingsMapUnderlaySub;

  /// No description provided for @drawerMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get drawerMenu;

  /// No description provided for @drawerMenuSub.
  ///
  /// In en, this message translates to:
  /// **'Settings, info, and more'**
  String get drawerMenuSub;

  /// No description provided for @drawerKhotiyanSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate share by Ana, Gonda, Kora'**
  String get drawerKhotiyanSub;

  /// No description provided for @drawerSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Theme, units, grid style'**
  String get drawerSettingsSub;

  /// No description provided for @drawerAboutSub.
  ///
  /// In en, this message translates to:
  /// **'Version, credits, what PlotCalc does'**
  String get drawerAboutSub;

  /// No description provided for @drawerVersion.
  ///
  /// In en, this message translates to:
  /// **'PlotCalc · v{version}'**
  String drawerVersion(String version);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Offline land measurement, your way'**
  String get aboutTagline;

  /// No description provided for @aboutWhatItDoes.
  ///
  /// In en, this message translates to:
  /// **'WHAT IT DOES'**
  String get aboutWhatItDoes;

  /// No description provided for @aboutDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw plots by tapping vertices, dragging a template, or typing exact measurements.'**
  String get aboutDraw;

  /// No description provided for @aboutConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert between 10 area units, including the Mymensingh regional bigha and katha.'**
  String get aboutConvert;

  /// No description provided for @aboutAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust a polygon to hit a target area while keeping its shape.'**
  String get aboutAdjust;

  /// No description provided for @aboutCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare two saved plots side-by-side.'**
  String get aboutCompare;

  /// No description provided for @aboutSubdivide.
  ///
  /// In en, this message translates to:
  /// **'Subdivide a plot into proportional lots.'**
  String get aboutSubdivide;

  /// No description provided for @aboutOffline.
  ///
  /// In en, this message translates to:
  /// **'WORKS OFFLINE'**
  String get aboutOffline;

  /// No description provided for @aboutOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Every measurement, conversion, and saved plot lives on your device. No accounts, no internet required.'**
  String get aboutOfflineBody;

  /// No description provided for @aboutBuild.
  ///
  /// In en, this message translates to:
  /// **'BUILD'**
  String get aboutBuild;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutBuildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuildLabel;

  /// No description provided for @aboutPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get aboutPlatform;

  /// No description provided for @aboutPlatformValue.
  ///
  /// In en, this message translates to:
  /// **'Android · iOS'**
  String get aboutPlatformValue;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'CREDITS'**
  String get aboutCredits;

  /// No description provided for @pickerQuestionAccent.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get pickerQuestionAccent;

  /// No description provided for @historyEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No plots match this filter.\nTap “All” to clear.'**
  String get historyEmptyFiltered;

  /// No description provided for @adjustAnchorN.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get adjustAnchorN;

  /// No description provided for @adjustAnchorE.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get adjustAnchorE;

  /// No description provided for @adjustAnchorW.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get adjustAnchorW;

  /// No description provided for @adjustAnchorS.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get adjustAnchorS;

  /// No description provided for @homeSides.
  ///
  /// In en, this message translates to:
  /// **' · {sides} sides'**
  String homeSides(int sides);

  /// No description provided for @drawFirstVertexHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the canvas\nto drop your first vertex'**
  String get drawFirstVertexHint;

  /// No description provided for @drawCompassN.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get drawCompassN;

  /// No description provided for @unitBighaMymensinghLabel.
  ///
  /// In en, this message translates to:
  /// **'bigha (M)'**
  String get unitBighaMymensinghLabel;

  /// No description provided for @unitBighaMymensinghName.
  ///
  /// In en, this message translates to:
  /// **'Bigha — Mymensingh'**
  String get unitBighaMymensinghName;

  /// No description provided for @unitKathaMymensinghLabel.
  ///
  /// In en, this message translates to:
  /// **'katha (M)'**
  String get unitKathaMymensinghLabel;

  /// No description provided for @unitKathaMymensinghName.
  ///
  /// In en, this message translates to:
  /// **'Katha — Mymensingh'**
  String get unitKathaMymensinghName;

  /// No description provided for @breakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdownTitle;

  /// No description provided for @breakdownSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN'**
  String get breakdownSectionLabel;

  /// No description provided for @settingsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN UNITS'**
  String get settingsBreakdown;

  /// No description provided for @settingsBreakdownSub.
  ///
  /// In en, this message translates to:
  /// **'Choose which units make up a compound reading'**
  String get settingsBreakdownSub;

  /// No description provided for @breakdownConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown units'**
  String get breakdownConfigTitle;

  /// No description provided for @breakdownConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder, tap to switch on or off'**
  String get breakdownConfigSubtitle;

  /// No description provided for @breakdownConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Units are used largest first, and the smallest one you enable carries the remainder.'**
  String get breakdownConfigHint;

  /// No description provided for @breakdownEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enable at least one unit to see a breakdown.'**
  String get breakdownEmpty;

  /// No description provided for @breakdownNone.
  ///
  /// In en, this message translates to:
  /// **'No units enabled'**
  String get breakdownNone;

  /// No description provided for @actionResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get actionResetDefaults;

  /// No description provided for @breakdownOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} units on'**
  String breakdownOf(int count, int total);

  /// No description provided for @calcTitle.
  ///
  /// In en, this message translates to:
  /// **'Land calculator'**
  String get calcTitle;

  /// No description provided for @calcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total, adjust, and combine areas'**
  String get calcSubtitle;

  /// No description provided for @calcTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL AREA'**
  String get calcTotalLabel;

  /// No description provided for @calcAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust area'**
  String get calcAdjustTitle;

  /// No description provided for @calcAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get calcAdd;

  /// No description provided for @calcSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract'**
  String get calcSubtract;

  /// No description provided for @calcCombineTitle.
  ///
  /// In en, this message translates to:
  /// **'Combine units'**
  String get calcCombineTitle;

  /// No description provided for @calcClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get calcClear;

  /// No description provided for @calcEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter an area to see its breakdown.'**
  String get calcEmpty;

  /// No description provided for @calcCannotGoNegative.
  ///
  /// In en, this message translates to:
  /// **'Total cannot go below zero.'**
  String get calcCannotGoNegative;

  /// No description provided for @homeCalculatorSub.
  ///
  /// In en, this message translates to:
  /// **'Add, subtract, break down'**
  String get homeCalculatorSub;

  /// No description provided for @calcModeTotal.
  ///
  /// In en, this message translates to:
  /// **'Single value'**
  String get calcModeTotal;

  /// No description provided for @calcModeParts.
  ///
  /// In en, this message translates to:
  /// **'By unit'**
  String get calcModeParts;

  /// No description provided for @calcPartsHint.
  ///
  /// In en, this message translates to:
  /// **'Edit any unit — the total updates as you type.'**
  String get calcPartsHint;

  /// No description provided for @calcAdjustLabel.
  ///
  /// In en, this message translates to:
  /// **'ADJUST TOTAL'**
  String get calcAdjustLabel;

  /// No description provided for @calcResultLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN'**
  String get calcResultLabel;

  /// No description provided for @calcAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get calcAmountLabel;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @resultShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get resultShare;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export. Please try again.'**
  String get exportFailed;

  /// No description provided for @plotDisplayUnit.
  ///
  /// In en, this message translates to:
  /// **'Display unit'**
  String get plotDisplayUnit;

  /// No description provided for @plotUnitFollowsSettings.
  ///
  /// In en, this message translates to:
  /// **'Follow app setting'**
  String get plotUnitFollowsSettings;

  /// No description provided for @plotUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Read this plot in'**
  String get plotUnitTitle;

  /// No description provided for @plotUnitSaved.
  ///
  /// In en, this message translates to:
  /// **'“{name}” now reads in {unit}'**
  String plotUnitSaved(String name, String unit);

  /// No description provided for @breakdownEditUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get breakdownEditUnits;

  /// No description provided for @adjustMethodScale.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get adjustMethodScale;

  /// No description provided for @adjustMethodBoundary.
  ///
  /// In en, this message translates to:
  /// **'Move boundary'**
  String get adjustMethodBoundary;

  /// No description provided for @adjustPickSides.
  ///
  /// In en, this message translates to:
  /// **'Sides'**
  String get adjustPickSides;

  /// No description provided for @adjustPickCorners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get adjustPickCorners;

  /// No description provided for @adjustTapToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap a side on the plan to move it'**
  String get adjustTapToPick;

  /// No description provided for @adjustTapToPickCorner.
  ///
  /// In en, this message translates to:
  /// **'Tap a corner on the plan to move it'**
  String get adjustTapToPickCorner;

  /// No description provided for @adjustMoveOut.
  ///
  /// In en, this message translates to:
  /// **'Move out {distance}'**
  String adjustMoveOut(String distance);

  /// No description provided for @adjustMoveIn.
  ///
  /// In en, this message translates to:
  /// **'Move in {distance}'**
  String adjustMoveIn(String distance);

  /// No description provided for @adjustUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach that by moving this alone — pick more sides'**
  String get adjustUnreachable;

  /// No description provided for @adjustSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String adjustSelectedCount(int count);

  /// No description provided for @actionClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClearSelection;

  /// No description provided for @adjustPickSlide.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get adjustPickSlide;

  /// No description provided for @adjustTapToSlide.
  ///
  /// In en, this message translates to:
  /// **'Tap a corner to slide it along a boundary'**
  String get adjustTapToSlide;

  /// No description provided for @adjustSlideAlong.
  ///
  /// In en, this message translates to:
  /// **'Along'**
  String get adjustSlideAlong;

  /// No description provided for @adjustSlideSwap.
  ///
  /// In en, this message translates to:
  /// **'Other side'**
  String get adjustSlideSwap;

  /// No description provided for @resultEditShape.
  ///
  /// In en, this message translates to:
  /// **'Edit shape'**
  String get resultEditShape;

  /// No description provided for @plotUpdated.
  ///
  /// In en, this message translates to:
  /// **'“{name}” updated'**
  String plotUpdated(String name);

  /// No description provided for @resultUnsaved.
  ///
  /// In en, this message translates to:
  /// **'NOT SAVED'**
  String get resultUnsaved;

  /// No description provided for @subdivideAddLot.
  ///
  /// In en, this message translates to:
  /// **'Add lot'**
  String get subdivideAddLot;

  /// No description provided for @subdivideRemoveLot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get subdivideRemoveLot;

  /// No description provided for @subdivideModeEqual.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get subdivideModeEqual;

  /// No description provided for @subdivideModePercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get subdivideModePercent;

  /// No description provided for @subdivideModeArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get subdivideModeArea;

  /// No description provided for @subdivideSavedLots.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} lots from “{name}”'**
  String subdivideSavedLots(int count, String name);

  /// No description provided for @subdivideLotsDontSum.
  ///
  /// In en, this message translates to:
  /// **'Lots add up to {total}, plot is {plot}'**
  String subdivideLotsDontSum(String total, String plot);

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get aboutDeveloper;

  /// No description provided for @aboutDeveloperName.
  ///
  /// In en, this message translates to:
  /// **'Zaman Sheikh'**
  String get aboutDeveloperName;

  /// No description provided for @aboutFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get aboutFacebook;

  /// No description provided for @aboutGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get aboutGithub;

  /// No description provided for @aboutOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get aboutOpenLinkFailed;

  /// No description provided for @historyTabPlots.
  ///
  /// In en, this message translates to:
  /// **'Plots'**
  String get historyTabPlots;

  /// No description provided for @historyTabSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get historyTabSheets;

  /// No description provided for @historySelectHint.
  ///
  /// In en, this message translates to:
  /// **'LONG-PRESS PLOTS TO SELECT'**
  String get historySelectHint;

  /// No description provided for @historyCompareShort.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get historyCompareShort;

  /// No description provided for @historySum.
  ///
  /// In en, this message translates to:
  /// **'Sum {count} plots'**
  String historySum(int count);

  /// No description provided for @sheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Land sheet'**
  String get sheetTitle;

  /// No description provided for @sheetNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this sheet'**
  String get sheetNameTitle;

  /// No description provided for @sheetDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Sheet {number}'**
  String sheetDefaultName(String number);

  /// No description provided for @sheetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL AREA'**
  String get sheetTotalLabel;

  /// No description provided for @sheetTotalArea.
  ///
  /// In en, this message translates to:
  /// **'Total · {count} plots'**
  String sheetTotalArea(int count);

  /// No description provided for @sheetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} plots'**
  String sheetCount(int count);

  /// No description provided for @sheetPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get sheetPriceLabel;

  /// No description provided for @sheetPricePer.
  ///
  /// In en, this message translates to:
  /// **'per {unit}'**
  String sheetPricePer(String unit);

  /// No description provided for @sheetRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get sheetRate;

  /// No description provided for @sheetTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get sheetTotalValue;

  /// No description provided for @sheetPlotsHeader.
  ///
  /// In en, this message translates to:
  /// **'PLOTS IN THIS SHEET'**
  String get sheetPlotsHeader;

  /// No description provided for @sheetAddPlots.
  ///
  /// In en, this message translates to:
  /// **'Add plots'**
  String get sheetAddPlots;

  /// No description provided for @sheetAllAdded.
  ///
  /// In en, this message translates to:
  /// **'Every saved plot is already in this sheet.'**
  String get sheetAllAdded;

  /// No description provided for @sheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plots in this sheet yet.'**
  String get sheetEmpty;

  /// No description provided for @sheetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sheets yet.\nLong-press plots to select them, then tap Sum.'**
  String get sheetsEmpty;

  /// No description provided for @sheetMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} plots in this sheet were deleted.'**
  String sheetMissing(int count);

  /// No description provided for @sheetDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete sheet?'**
  String get sheetDeleteTitle;

  /// No description provided for @sheetDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be deleted. Its plots stay saved.'**
  String sheetDeleteBody(String name);

  /// No description provided for @sheetColPlot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get sheetColPlot;

  /// No description provided for @sheetColShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sheetColShare;

  /// No description provided for @sheetColValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get sheetColValue;

  /// No description provided for @sheetPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared {date}'**
  String sheetPrepared(String date);

  /// No description provided for @sheetUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Read this sheet in'**
  String get sheetUnitTitle;

  /// No description provided for @sheetPriceUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Price is quoted per'**
  String get sheetPriceUnitTitle;

  /// No description provided for @sheetPlotRemoved.
  ///
  /// In en, this message translates to:
  /// **'“{name}” removed from the sheet'**
  String sheetPlotRemoved(String name);

  /// No description provided for @sheetLayoutHeader.
  ///
  /// In en, this message translates to:
  /// **'LAYOUT'**
  String get sheetLayoutHeader;

  /// No description provided for @sheetArrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get sheetArrange;

  /// No description provided for @sheetArrangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrange plots'**
  String get sheetArrangeTitle;

  /// No description provided for @sheetArrangeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a plot to move it · pinch to zoom'**
  String get sheetArrangeHint;

  /// No description provided for @sheetTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left'**
  String get sheetTurnLeft;

  /// No description provided for @sheetTurnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right'**
  String get sheetTurnRight;

  /// No description provided for @sheetFitView.
  ///
  /// In en, this message translates to:
  /// **'Fit to screen'**
  String get sheetFitView;

  /// No description provided for @sheetAutoArrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange automatically'**
  String get sheetAutoArrange;

  /// No description provided for @sheetLayoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Layout saved'**
  String get sheetLayoutSaved;

  /// No description provided for @sheetDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get sheetDiscardTitle;

  /// No description provided for @sheetDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'This arrangement has not been saved.'**
  String get sheetDiscardBody;

  /// No description provided for @sheetDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get sheetDiscard;

  /// No description provided for @sheetTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap a plot to select it'**
  String get sheetTapToSelect;

  /// No description provided for @mouzaEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Measure from a mouza map'**
  String get mouzaEntryTitle;

  /// No description provided for @mouzaEntrySub.
  ///
  /// In en, this message translates to:
  /// **'Photo → scale → tap the corners'**
  String get mouzaEntrySub;

  /// No description provided for @mouzaTitle.
  ///
  /// In en, this message translates to:
  /// **'Mouza map'**
  String get mouzaTitle;

  /// No description provided for @mouzaStepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get mouzaStepPhoto;

  /// No description provided for @mouzaStepScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get mouzaStepScale;

  /// No description provided for @mouzaStepCorners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get mouzaStepCorners;

  /// No description provided for @mouzaPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the map'**
  String get mouzaPickTitle;

  /// No description provided for @mouzaPickSub.
  ///
  /// In en, this message translates to:
  /// **'Then set its scale and tap the corners of your plot. The area is worked out for you.'**
  String get mouzaPickSub;

  /// No description provided for @mouzaPickCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get mouzaPickCamera;

  /// No description provided for @mouzaPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get mouzaPickGallery;

  /// No description provided for @mouzaTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'FOR AN ACCURATE RESULT'**
  String get mouzaTipsTitle;

  /// No description provided for @mouzaTip1.
  ///
  /// In en, this message translates to:
  /// **'Lay the map flat and shoot from straight above.'**
  String get mouzaTip1;

  /// No description provided for @mouzaTip2.
  ///
  /// In en, this message translates to:
  /// **'Keep the scale bar, or a side whose length you know, in the photo.'**
  String get mouzaTip2;

  /// No description provided for @mouzaTip3.
  ///
  /// In en, this message translates to:
  /// **'Use good light — no shadow, no glare.'**
  String get mouzaTip3;

  /// No description provided for @mouzaPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo.'**
  String get mouzaPickFailed;

  /// No description provided for @mouzaScaleHintFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap two points whose distance you know — like the two ends of the map\'s scale bar.'**
  String get mouzaScaleHintFirst;

  /// No description provided for @mouzaScaleHintSecond.
  ///
  /// In en, this message translates to:
  /// **'Now tap the second point.'**
  String get mouzaScaleHintSecond;

  /// No description provided for @mouzaScaleDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE BETWEEN THE TWO POINTS'**
  String get mouzaScaleDistance;

  /// No description provided for @mouzaScaleNoBar.
  ///
  /// In en, this message translates to:
  /// **'No scale bar? Use any side whose length is written in the deed.'**
  String get mouzaScaleNoBar;

  /// No description provided for @mouzaDragTip.
  ///
  /// In en, this message translates to:
  /// **'Drag a point to fine-tune it — a magnifier shows exactly where it is.'**
  String get mouzaDragTip;

  /// No description provided for @mouzaUnitFoot.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get mouzaUnitFoot;

  /// No description provided for @mouzaUnitMeter.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get mouzaUnitMeter;

  /// No description provided for @mouzaUnitChain.
  ///
  /// In en, this message translates to:
  /// **'chain'**
  String get mouzaUnitChain;

  /// No description provided for @mouzaUnitLink.
  ///
  /// In en, this message translates to:
  /// **'link'**
  String get mouzaUnitLink;

  /// No description provided for @mouzaNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get mouzaNext;

  /// No description provided for @mouzaStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get mouzaStartOver;

  /// No description provided for @mouzaTraceHintFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap each corner of the plot, one after another.'**
  String get mouzaTraceHintFirst;

  /// No description provided for @mouzaTraceHintMore.
  ///
  /// In en, this message translates to:
  /// **'{count} corners — keep going around the plot.'**
  String mouzaTraceHintMore(int count);

  /// No description provided for @mouzaNewPlot.
  ///
  /// In en, this message translates to:
  /// **'New plot'**
  String get mouzaNewPlot;

  /// No description provided for @mouzaChangeScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get mouzaChangeScale;

  /// No description provided for @mouzaSeeResult.
  ///
  /// In en, this message translates to:
  /// **'See result'**
  String get mouzaSeeResult;

  /// No description provided for @mouzaDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Mouza map plot'**
  String get mouzaDefaultName;

  /// No description provided for @mouzaLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the map?'**
  String get mouzaLeaveTitle;

  /// No description provided for @mouzaLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The corners you tapped will be lost.'**
  String get mouzaLeaveBody;

  /// No description provided for @mouzaAreaSoFar.
  ///
  /// In en, this message translates to:
  /// **'AREA'**
  String get mouzaAreaSoFar;

  /// No description provided for @overlayEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Pantograph'**
  String get overlayEntryTitle;

  /// No description provided for @overlayEntrySub.
  ///
  /// In en, this message translates to:
  /// **'CS ↔ RS overlay'**
  String get overlayEntrySub;

  /// No description provided for @mouzaCompareLink.
  ///
  /// In en, this message translates to:
  /// **'Have two surveys of this mouza? Lay them over each other with Pantograph'**
  String get mouzaCompareLink;

  /// No description provided for @overlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pantograph'**
  String get overlayTitle;

  /// No description provided for @overlayStepMaps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get overlayStepMaps;

  /// No description provided for @overlayStepMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get overlayStepMatch;

  /// No description provided for @overlayStepMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get overlayStepMeasure;

  /// No description provided for @overlayMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add both maps of the mouza'**
  String get overlayMapsTitle;

  /// No description provided for @overlayMapsSub.
  ///
  /// In en, this message translates to:
  /// **'Usually the old survey (CS or SA) and the newer one (RS or BS). Next you mark a few places found on both, and one map is laid over the other.'**
  String get overlayMapsSub;

  /// No description provided for @overlayMapOld.
  ///
  /// In en, this message translates to:
  /// **'OLD SURVEY'**
  String get overlayMapOld;

  /// No description provided for @overlayMapNew.
  ///
  /// In en, this message translates to:
  /// **'NEW SURVEY'**
  String get overlayMapNew;

  /// No description provided for @overlayAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get overlayAddPhoto;

  /// No description provided for @overlaySurveyOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get overlaySurveyOther;

  /// No description provided for @overlaySameSheet.
  ///
  /// In en, this message translates to:
  /// **'Both must be the same sheet of the same mouza (same J.L. no.).'**
  String get overlaySameSheet;

  /// No description provided for @overlayMatchStart.
  ///
  /// In en, this message translates to:
  /// **'Tap a place you can find on both maps — a road crossing, a corner of the mouza boundary, a pillar.'**
  String get overlayMatchStart;

  /// No description provided for @overlayMatchOther.
  ///
  /// In en, this message translates to:
  /// **'Now tap the very same place on the {map} map. The small circle shows where it was.'**
  String overlayMatchOther(String map);

  /// No description provided for @overlayMatchGuessed.
  ///
  /// In en, this message translates to:
  /// **'Placed where it should be — if it is not exactly on the spot, tap the right spot or drag it.'**
  String get overlayMatchGuessed;

  /// No description provided for @overlayMatchMore.
  ///
  /// In en, this message translates to:
  /// **'{count} matched. Add more, spread towards the corners of the sheet — four or more is best.'**
  String overlayMatchMore(int count);

  /// No description provided for @overlayNextPair.
  ///
  /// In en, this message translates to:
  /// **'Next place'**
  String get overlayNextPair;

  /// No description provided for @overlayRemovePair.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get overlayRemovePair;

  /// No description provided for @overlayQualityUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more to check the match'**
  String overlayQualityUnchecked(int count);

  /// No description provided for @overlayQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Match: good'**
  String get overlayQualityGood;

  /// No description provided for @overlayQualityFair.
  ///
  /// In en, this message translates to:
  /// **'Match: fair — look over the places'**
  String get overlayQualityFair;

  /// No description provided for @overlayQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Match: poor — a place is probably wrong'**
  String get overlayQualityPoor;

  /// No description provided for @overlayQualityPoorWhich.
  ///
  /// In en, this message translates to:
  /// **'Add one more place to find out which is wrong'**
  String get overlayQualityPoorWhich;

  /// No description provided for @overlaySuspect.
  ///
  /// In en, this message translates to:
  /// **'Place {n} looks wrong — check it'**
  String overlaySuspect(String n);

  /// No description provided for @overlayViewBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get overlayViewBoth;

  /// No description provided for @overlayColours.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get overlayColours;

  /// No description provided for @overlayScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Set the scale on either map\'s scale bar — both share it now.'**
  String get overlayScaleHint;

  /// No description provided for @overlayPlot.
  ///
  /// In en, this message translates to:
  /// **'plot'**
  String get overlayPlot;

  /// No description provided for @overlayTraceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the map, then tap the corners of one plot on it.'**
  String get overlayTraceHint;

  /// No description provided for @overlayFinishPlot.
  ///
  /// In en, this message translates to:
  /// **'Plot done'**
  String get overlayFinishPlot;

  /// No description provided for @overlayPlotNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Plot number'**
  String get overlayPlotNameTitle;

  /// No description provided for @overlayPlotsHeader.
  ///
  /// In en, this message translates to:
  /// **'PLOTS'**
  String get overlayPlotsHeader;

  /// No description provided for @overlayOverlapHeader.
  ///
  /// In en, this message translates to:
  /// **'SHARED AREA'**
  String get overlayOverlapHeader;

  /// No description provided for @overlayOverlapShare.
  ///
  /// In en, this message translates to:
  /// **'{pa} of {a} · {pb} of {b}'**
  String overlayOverlapShare(String pa, String a, String pb, String b);

  /// No description provided for @overlayNoOverlap.
  ///
  /// In en, this message translates to:
  /// **'The traced plots do not overlap.'**
  String get overlayNoOverlap;

  /// No description provided for @overlayOverlapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trace a plot on each map to see how much they share.'**
  String get overlayOverlapEmpty;

  /// No description provided for @overlayReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get overlayReport;

  /// No description provided for @overlayReportTitle.
  ///
  /// In en, this message translates to:
  /// **'PANTOGRAPH'**
  String get overlayReportTitle;

  /// No description provided for @overlayReportMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched at {count} places · {quality}'**
  String overlayReportMatched(int count, String quality);

  /// No description provided for @overlayReportMismatch.
  ///
  /// In en, this message translates to:
  /// **'Average mismatch {value}'**
  String overlayReportMismatch(String value);

  /// No description provided for @overlayReportMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get overlayReportMap;

  /// No description provided for @overlayLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The matching and the traced plots will be lost.'**
  String get overlayLeaveBody;

  /// No description provided for @overlayNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Match at least two places to continue.'**
  String get overlayNeedTwo;

  /// No description provided for @overlayMovePlace.
  ///
  /// In en, this message translates to:
  /// **'Place {n}: tap the right spot, or drag its mark, on either map.'**
  String overlayMovePlace(String n);

  /// No description provided for @divisionOwnersTab.
  ///
  /// In en, this message translates to:
  /// **'Owners'**
  String get divisionOwnersTab;

  /// No description provided for @divisionSidesTab.
  ///
  /// In en, this message translates to:
  /// **'Side & road'**
  String get divisionSidesTab;

  /// No description provided for @divisionBoundsTab.
  ///
  /// In en, this message translates to:
  /// **'Boundaries'**
  String get divisionBoundsTab;

  /// No description provided for @divisionHowLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW TO DIVIDE'**
  String get divisionHowLabel;

  /// No description provided for @divisionModeEqual.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get divisionModeEqual;

  /// No description provided for @divisionModeShares.
  ///
  /// In en, this message translates to:
  /// **'By share'**
  String get divisionModeShares;

  /// No description provided for @divisionModeAreas.
  ///
  /// In en, this message translates to:
  /// **'By area'**
  String get divisionModeAreas;

  /// No description provided for @divisionShareHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1/3'**
  String get divisionShareHint;

  /// No description provided for @divisionShareHelp.
  ///
  /// In en, this message translates to:
  /// **'Write shares as parts — 1/3, 6 anna, 25% — or as counts: 2 for a son, 1 for a daughter.'**
  String get divisionShareHelp;

  /// No description provided for @divisionAreaHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave an area blank and that owner shares what is left.'**
  String get divisionAreaHelp;

  /// No description provided for @divisionAreaHint.
  ///
  /// In en, this message translates to:
  /// **'rest'**
  String get divisionAreaHint;

  /// No description provided for @divisionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get divisionNameHint;

  /// No description provided for @divisionAddOwner.
  ///
  /// In en, this message translates to:
  /// **'Add one more'**
  String get divisionAddOwner;

  /// No description provided for @divisionRest.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get divisionRest;

  /// No description provided for @divisionRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get divisionRoad;

  /// No description provided for @divisionRoadWidth.
  ///
  /// In en, this message translates to:
  /// **'Road · {width}'**
  String divisionRoadWidth(String width);

  /// No description provided for @divisionIssueSharesOver.
  ///
  /// In en, this message translates to:
  /// **'Shares add up to more than the whole land.'**
  String get divisionIssueSharesOver;

  /// No description provided for @divisionIssueSharesMixed.
  ///
  /// In en, this message translates to:
  /// **'Write all shares the same way — either parts (1/3, 6 anna) or counts (2, 1).'**
  String get divisionIssueSharesMixed;

  /// No description provided for @divisionIssueShareUnreadable.
  ///
  /// In en, this message translates to:
  /// **'A share could not be read — write it like 1/3, 6 anna, 25% or 2.'**
  String get divisionIssueShareUnreadable;

  /// No description provided for @divisionIssueAreasOver.
  ///
  /// In en, this message translates to:
  /// **'The areas add up to more than the land.'**
  String get divisionIssueAreasOver;

  /// No description provided for @divisionIssueAreaUnreadable.
  ///
  /// In en, this message translates to:
  /// **'An area could not be read.'**
  String get divisionIssueAreaUnreadable;

  /// No description provided for @divisionIssueRoadTooWide.
  ///
  /// In en, this message translates to:
  /// **'The road is as deep as the whole plot.'**
  String get divisionIssueRoadTooWide;

  /// No description provided for @divisionRestNote.
  ///
  /// In en, this message translates to:
  /// **'{area} is not given to anyone yet.'**
  String divisionRestNote(String area);

  /// No description provided for @divisionGiveRest.
  ///
  /// In en, this message translates to:
  /// **'Add an owner for it'**
  String get divisionGiveRest;

  /// No description provided for @divisionFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'WHICH SIDE SHOULD EVERY LOT TOUCH?'**
  String get divisionFrontTitle;

  /// No description provided for @divisionFrontHint.
  ///
  /// In en, this message translates to:
  /// **'Usually the road side: every lot gets its own stretch of it. Tap a side on the drawing, or pick one here.'**
  String get divisionFrontHint;

  /// No description provided for @divisionFrontAny.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get divisionFrontAny;

  /// No description provided for @divisionSideN.
  ///
  /// In en, this message translates to:
  /// **'Side {n} · {length}'**
  String divisionSideN(String n, String length);

  /// No description provided for @divisionRoadTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMON ROAD ALONG THAT SIDE'**
  String get divisionRoadTitle;

  /// No description provided for @divisionRoadHint.
  ///
  /// In en, this message translates to:
  /// **'Taken out first; every lot opens onto it.'**
  String get divisionRoadHint;

  /// No description provided for @divisionRoadNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get divisionRoadNone;

  /// No description provided for @divisionRoadNeedsFront.
  ///
  /// In en, this message translates to:
  /// **'Choose the side first.'**
  String get divisionRoadNeedsFront;

  /// No description provided for @divisionStraighten.
  ///
  /// In en, this message translates to:
  /// **'Straighten dividers'**
  String get divisionStraighten;

  /// No description provided for @divisionFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get divisionFront;

  /// No description provided for @divisionNorth.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get divisionNorth;

  /// No description provided for @cardinalNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get cardinalNorth;

  /// No description provided for @cardinalEast.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get cardinalEast;

  /// No description provided for @cardinalSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get cardinalSouth;

  /// No description provided for @cardinalWest.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get cardinalWest;

  /// No description provided for @divisionOutside.
  ///
  /// In en, this message translates to:
  /// **'plot boundary'**
  String get divisionOutside;

  /// No description provided for @divisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as a sheet'**
  String get divisionSaved;

  /// No description provided for @divisionOpenSheet.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get divisionOpenSheet;

  /// No description provided for @divisionSheetName.
  ///
  /// In en, this message translates to:
  /// **'{name} — division'**
  String divisionSheetName(String name);

  /// No description provided for @divisionPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'DIVISION'**
  String get divisionPdfTitle;

  /// No description provided for @divisionPdfTotal.
  ///
  /// In en, this message translates to:
  /// **'Total land'**
  String get divisionPdfTotal;

  /// No description provided for @divisionPdfNorth.
  ///
  /// In en, this message translates to:
  /// **'The top of the drawing is north.'**
  String get divisionPdfNorth;

  /// No description provided for @divisionPdfDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Drawn for measurement — not a legal deed.'**
  String get divisionPdfDisclaimer;

  /// No description provided for @divisionColShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get divisionColShare;

  /// No description provided for @divisionColSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get divisionColSide;

  /// No description provided for @divisionColLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get divisionColLength;

  /// No description provided for @divisionColBeyond.
  ///
  /// In en, this message translates to:
  /// **'Beyond'**
  String get divisionColBeyond;

  /// No description provided for @divisionSlid.
  ///
  /// In en, this message translates to:
  /// **'Sizes changed to areas.'**
  String get divisionSlid;

  /// No description provided for @divisionEdit.
  ///
  /// In en, this message translates to:
  /// **'Change division'**
  String get divisionEdit;

  /// No description provided for @divisionParentGone.
  ///
  /// In en, this message translates to:
  /// **'The plot this was divided from has been deleted.'**
  String get divisionParentGone;

  /// No description provided for @divisionPeople.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count} owners'**
  String divisionPeople(String name, int count);

  /// No description provided for @divisionDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a divider to shift land, or its end to turn it.'**
  String get divisionDragHint;

  /// No description provided for @divisionBoundsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show until the division works out.'**
  String get divisionBoundsEmpty;

  /// No description provided for @divisionColLocal.
  ///
  /// In en, this message translates to:
  /// **'In local units'**
  String get divisionColLocal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
