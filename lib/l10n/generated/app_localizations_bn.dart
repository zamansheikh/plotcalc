// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get actionCancel => 'বাতিল';

  @override
  String get actionSave => 'সংরক্ষণ';

  @override
  String get actionDelete => 'মুছুন';

  @override
  String get actionDone => 'সম্পন্ন';

  @override
  String get actionApply => 'প্রয়োগ';

  @override
  String get actionReset => 'রিসেট';

  @override
  String get actionClose => 'বন্ধ';

  @override
  String get actionClear => 'পরিষ্কার';

  @override
  String get actionRename => 'নাম বদলান';

  @override
  String get actionChange => 'পরিবর্তন';

  @override
  String get actionUndo => 'ফেরান';

  @override
  String get actionRemove => 'সরান';

  @override
  String get actionCalculate => 'গণনা';

  @override
  String get actionGenerate => 'তৈরি করুন';

  @override
  String get labelAll => 'সব';

  @override
  String get labelOr => 'অথবা';

  @override
  String get appName => 'প্লটক্যালক';

  @override
  String get tabPlots => 'প্লট';

  @override
  String get tabHistory => 'ইতিহাস';

  @override
  String get tabSubdivide => 'বিভাজন';

  @override
  String get tabInfo => 'তথ্য';

  @override
  String routeNotFound(String uri) {
    return 'পথ পাওয়া যায়নি: $uri';
  }

  @override
  String get defaultPlotLabel => 'প্লট';

  @override
  String get unitSqftLabel => 'বর্গফুট';

  @override
  String get unitSqftName => 'বর্গফুট';

  @override
  String get unitSqmLabel => 'বর্গমি';

  @override
  String get unitSqmName => 'বর্গমিটার';

  @override
  String get unitAcreLabel => 'একর';

  @override
  String get unitAcreName => 'একর';

  @override
  String get unitHectareLabel => 'হেক্টর';

  @override
  String get unitHectareName => 'হেক্টর';

  @override
  String get unitBighaLabel => 'বিঘা';

  @override
  String get unitBighaName => 'বিঘা';

  @override
  String get unitKathaLabel => 'কাঠা';

  @override
  String get unitKathaName => 'কাঠা';

  @override
  String get unitChatakLabel => 'ছটাক';

  @override
  String get unitChatakName => 'ছটাক';

  @override
  String get unitShotokLabel => 'শতক';

  @override
  String get unitShotokName => 'শতক';

  @override
  String get unitMeters => 'মিটার';

  @override
  String get unitFeet => 'ফুট';

  @override
  String get unitMeterShort => 'মি';

  @override
  String get unitFeetShort => 'ফুট';

  @override
  String get tagAgricultural => 'কৃষি';

  @override
  String get tagResidential => 'আবাসিক';

  @override
  String get tagCommercial => 'বাণিজ্যিক';

  @override
  String get tagForest => 'বনভূমি';

  @override
  String get tagOther => 'অন্যান্য';

  @override
  String get presetRectangle => 'আয়তক্ষেত্র';

  @override
  String get presetSquare => 'বর্গক্ষেত্র';

  @override
  String get presetTriangle => 'ত্রিভুজ';

  @override
  String get presetTrapezoid => 'ট্রাপিজিয়াম';

  @override
  String get presetPentagon => 'পঞ্চভুজ';

  @override
  String get presetFreeform => 'মুক্ত আকৃতি';

  @override
  String get methodDraw => 'আঁকুন';

  @override
  String get methodTap => 'ট্যাপ';

  @override
  String get methodType => 'লিখুন';

  @override
  String get methodDrawSub => 'ট্যাপ ও টানুন';

  @override
  String get methodTapSub => 'কোণ বসান';

  @override
  String get methodTypeSub => 'বাহু ও কোণ';

  @override
  String get homeTitle => 'প্লট';

  @override
  String get homeBuildBy => 'তৈরি করেছেন · জামান শেখ';

  @override
  String get homeThisMonth => 'এই মাসে · পরিমাপ করা';

  @override
  String homePlusPlots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '+$countStringটি প্লট';
  }

  @override
  String get homeMeasurePlot => 'প্লট পরিমাপ করুন';

  @override
  String get homeMeasureSub => 'আঁকুন বা বাহু লিখুন';

  @override
  String get homeBadgeNew => 'নতুন';

  @override
  String get homeToolLabel => 'টুল';

  @override
  String get homeAllUnits => 'সব একক';

  @override
  String homeRecent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'সাম্প্রতিক · $countString';
  }

  @override
  String get homeSeeAll => 'সব দেখুন';

  @override
  String get pickerStep => 'ধাপ ১ / ৩';

  @override
  String get pickerQuestion => 'আপনি কীভাবে শুরু করতে চান?';

  @override
  String get pickerSubtitle => 'একটি পদ্ধতি বেছে নিন, তারপর একটি আকৃতি।';

  @override
  String get pickerShapePresets => 'আকৃতির নমুনা';

  @override
  String get pickerStartDrawing => 'আঁকা শুরু করুন';

  @override
  String get pickerPlaceVertices => 'কোণ বসান';

  @override
  String get pickerEnterDimensions => 'মাপ লিখুন';

  @override
  String pickerSidesN(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString–N বাহু';
  }

  @override
  String get pickerTapEachCorner => 'ক্যানভাসে প্রতিটি কোণে ট্যাপ করুন';

  @override
  String get drawTitle => 'প্লট আঁকুন';

  @override
  String get drawTitleTap => 'কোণ বসাতে ট্যাপ করুন';

  @override
  String get drawTitleEdit => 'প্লট সম্পাদনা';

  @override
  String drawVerticesUnsaved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি কোণ · অসংরক্ষিত';
  }

  @override
  String get drawArea => 'ক্ষেত্রফল';

  @override
  String get drawPerimeter => 'পরিসীমা';

  @override
  String get drawSides => 'বাহু';

  @override
  String get drawDiag => 'কর্ণ';

  @override
  String get drawHintDone => '“সম্পন্ন” চাপুন বা আরও কোণ যোগ করুন';

  @override
  String get drawHintMin => 'অন্তত ৩টি কোণ বসান';

  @override
  String drawHintPlaced(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি বসানো · আরও যোগ করতে ক্যানভাসে ট্যাপ করুন';
  }

  @override
  String drawVertexOf(int index, int total) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'কোণ $indexString / $totalString';
  }

  @override
  String drawVertexInfo(String x, String y, String angle) {
    return 'x: $xমি · y: $yমি · ∠ $angle°';
  }

  @override
  String drawSavedToast(String name, String tag) {
    return '“$name” সংরক্ষিত · $tag';
  }

  @override
  String drawDefaultName(String time) {
    return 'প্লট · $time';
  }

  @override
  String get edgeAdjustDiagonal => 'কর্ণ সমন্বয়';

  @override
  String get edgeAdjustSide => 'বাহু সমন্বয়';

  @override
  String edgeNowLength(String value, String unit) {
    return 'বর্তমানে $value $unit';
  }

  @override
  String get edgeNewLength => 'নতুন দৈর্ঘ্য';

  @override
  String get edgeWhichEndpoint => 'কোন প্রান্ত সরবে?';

  @override
  String edgeMoveEndpoint(String label) {
    return '$label সরান';
  }

  @override
  String get edgeInsertMidpoint => 'মধ্যবিন্দুতে কোণ যোগ করুন';

  @override
  String get saveSheetTitle => 'প্লট সংরক্ষণ';

  @override
  String get saveSheetName => 'নাম';

  @override
  String get saveSheetNameHint => 'প্লটের নাম';

  @override
  String get saveSheetCategory => 'শ্রেণি';

  @override
  String get typeTitle => 'মাপ লিখুন';

  @override
  String typeSubtitle(String shape, String unit) {
    return '$shape · মান $unit-এ';
  }

  @override
  String get typeWidth => 'প্রস্থ';

  @override
  String get typeHeight => 'উচ্চতা';

  @override
  String get typeSide => 'বাহু';

  @override
  String get typeSideA => 'বাহু ক';

  @override
  String get typeSideB => 'বাহু খ';

  @override
  String get typeSideC => 'বাহু গ';

  @override
  String get typeTop => 'উপরের বাহু';

  @override
  String get typeBottom => 'নিচের বাহু';

  @override
  String get typeSideLength => 'বাহুর দৈর্ঘ্য';

  @override
  String get typeSidesCount => 'বাহুর সংখ্যা';

  @override
  String get typeTriangle3 => 'ত্রিভুজ (৩ বাহু)';

  @override
  String get typeRegularPentagon => 'সুষম পঞ্চভুজ';

  @override
  String get typeRegularPolygon => 'সুষম বহুভুজ';

  @override
  String get typeErrPositive => 'প্রতিটি মান ধনাত্মক সংখ্যা হতে হবে।';

  @override
  String get typeErrTriangle =>
      'এই বাহুগুলো ত্রিভুজ তৈরি করে না (দুই বাহুর যোগফল তৃতীয়টির চেয়ে বড় হতে হবে)।';

  @override
  String get typeErrMinSides => 'বহুভুজের জন্য অন্তত ৩টি বাহু দরকার।';

  @override
  String get historyTitle => 'ইতিহাস';

  @override
  String historySubtitle(int count, String area) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি প্লট · মোট $area একর';
  }

  @override
  String get historySearch => 'প্লট খুঁজুন…';

  @override
  String get historyFilter => 'ছাঁকনি';

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

    return 'তুলনার জন্য $countStringটি নির্বাচিত';
  }

  @override
  String get historyEmpty => 'এখনো কোনো প্লট নেই — হোম থেকে একটি পরিমাপ করুন।';

  @override
  String historyPlotMeta(int sides, String when) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return ' · $sidesString বাহু · $when';
  }

  @override
  String historyToday(String time) {
    return 'আজ · $time';
  }

  @override
  String get historyYesterday => 'গতকাল';

  @override
  String get historyCompare2 => '২টি প্লট তুলনা করুন';

  @override
  String get filterTitle => 'শ্রেণি অনুযায়ী ছাঁকুন';

  @override
  String get filterAllPlots => 'সব প্লট';

  @override
  String plotTagSides(String tag, int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return '$tag · $sidesString বাহু';
  }

  @override
  String get plotRenameTitle => 'প্লটের নাম বদলান';

  @override
  String get plotDeleteTitle => 'প্লট মুছবেন?';

  @override
  String plotDeleteBody(String name) {
    return '“$name” স্থায়ীভাবে মুছে যাবে।';
  }

  @override
  String get plotClearAllTitle => 'সব ইতিহাস মুছবেন?';

  @override
  String plotClearAllBody(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'সব $countStringটি সংরক্ষিত প্লট মুছে যাবে। এটি ফেরানো যাবে না।',
      one: '১টি সংরক্ষিত প্লট মুছে যাবে। এটি ফেরানো যাবে না।',
    );
    return '$_temp0';
  }

  @override
  String get plotClearAll => 'সব মুছুন';

  @override
  String get compareTitle => 'তুলনা';

  @override
  String get comparePlotA => 'প্লট ক';

  @override
  String get comparePlotB => 'প্লট খ';

  @override
  String get compareNameA => 'প্লট ক';

  @override
  String get compareNameB => 'প্লট খ';

  @override
  String get compareDemoPlot => 'নমুনা প্লট';

  @override
  String get compareOverlay => 'ওভারলে · কেন্দ্রায়িত';

  @override
  String get compareRatio => 'ক ÷ খ';

  @override
  String get compareDelta => 'ক − খ';

  @override
  String get compareTotal => 'মোট';

  @override
  String get compareRelative => 'আপেক্ষিক আকার';

  @override
  String compareUnitSides(String unit, int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return '$unit · $sidesString বাহু';
  }

  @override
  String get adjustTitle => 'আকারে সমন্বয়';

  @override
  String get adjustTargetArea => 'লক্ষ্য ক্ষেত্রফল';

  @override
  String adjustPctFromBase(String pct) {
    return 'ভিত্তি থেকে $pct%';
  }

  @override
  String adjustBaseValue(String value, String unit) {
    return 'ভিত্তি · $value $unit';
  }

  @override
  String get adjustBase => 'ভিত্তি';

  @override
  String get adjustAdjusted => 'সমন্বিত';

  @override
  String get adjustAnchor => 'অ্যাংকর';

  @override
  String get adjustUniform => 'সমানুপাতিক';

  @override
  String get adjustWidth => 'প্রস্থ';

  @override
  String get adjustHeight => 'উচ্চতা';

  @override
  String get adjustExpandDirection => 'প্রসারণের দিক';

  @override
  String get adjustAnchorFrom => 'অ্যাংকর কোথা থেকে';

  @override
  String get adjustApply => 'সমন্বয় প্রয়োগ করুন';

  @override
  String get converterTitle => 'রূপান্তরকারী';

  @override
  String get converterSubtitle => 'একটি সংখ্যা লিখুন, একক বাছুন';

  @override
  String get converterValue => 'মান';

  @override
  String get converterConvertsTo => 'রূপান্তরিত হয়';

  @override
  String get resultTitle => 'প্লট সারসংক্ষেপ';

  @override
  String resultTotalArea(String unit) {
    return 'মোট ক্ষেত্রফল · $unit';
  }

  @override
  String get resultSaved => 'সংরক্ষিত';

  @override
  String get resultEquivalent => 'সমতুল্য';

  @override
  String get resultValuation => 'মূল্যায়ন';

  @override
  String resultRatePer(String unit) {
    return 'দর / $unit';
  }

  @override
  String get resultCurrency => 'টাকা';

  @override
  String get resultEstValue => 'আনুমানিক মূল্য';

  @override
  String get resultExportPdf => 'পিডিএফ';

  @override
  String get resultShareImage => 'ছবি শেয়ার';

  @override
  String get resultAdjust => 'সমন্বয়';

  @override
  String get subdivideTitle => 'বিভাজন';

  @override
  String get subdivideSubtitle => 'লটে ভাগ করতে একটি সংরক্ষিত প্লট বাছুন';

  @override
  String subdivideSaved(String name) {
    return '“$name”-এর বিভাজন সংরক্ষিত';
  }

  @override
  String get subdivideSaveAction => 'বিভাজন সংরক্ষণ';

  @override
  String subdivideSummary(String name, int lots) {
    final intl.NumberFormat lotsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lotsString = lotsNumberFormat.format(lots);

    return '$name · $lotsStringটি লট · ১০০%';
  }

  @override
  String subdivideMeta(String area, String unit, int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return '$area $unit · $sidesString বাহু';
  }

  @override
  String get subdivideEmpty => 'এখনো কোনো সংরক্ষিত প্লট নেই';

  @override
  String get subdivideEmptyBody =>
      'আগে একটি প্লট পরিমাপ করুন, তারপর এখানে ফিরে এসে লটে ভাগ করুন।';

  @override
  String get subdivideGoHome => 'হোমে যান';

  @override
  String subdivideLot(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'লট $nString';
  }

  @override
  String get khotiyanTitle => 'খতিয়ান';

  @override
  String get khotiyanSubtitle => 'অংশ ক্যালকুলেটর · আনা · গণ্ডা · কড়া';

  @override
  String get khotiyanHissya => 'হিস্যা';

  @override
  String khotiyanTilFraction(String selected, String total) {
    return '$selected / $total তিল';
  }

  @override
  String get khotiyanSelectUnits => 'একক বাছুন';

  @override
  String get khotiyanAna => 'আনা';

  @override
  String get khotiyanGonda => 'গণ্ডা';

  @override
  String get khotiyanKora => 'কড়া';

  @override
  String get khotiyanKranti => 'ক্রান্তি';

  @override
  String get khotiyanTil => 'তিল';

  @override
  String get khotiyanTotalLand => 'মোট জমি';

  @override
  String get khotiyanYourLand => 'আপনার জমি';

  @override
  String get infoTitle => 'ভূমি পরিচিতি';

  @override
  String get infoSubtitle => 'একক, পরিমাপ, জরিপ — এবং বাংলাদেশের ভূমি রেকর্ড';

  @override
  String get infoArticle => 'প্রবন্ধ';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsSubtitle => 'চেহারা, অনুভব ও একক পরিবর্তন করুন';

  @override
  String get settingsLanguage => 'ভাষা';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBengali => 'বাংলা';

  @override
  String get settingsTheme => 'থিম';

  @override
  String get settingsAccent => 'অ্যাকসেন্ট রঙ';

  @override
  String get settingsGridStyle => 'গ্রিড ধরন';

  @override
  String get settingsGridDots => 'বিন্দু';

  @override
  String get settingsGridLines => 'রেখা';

  @override
  String get settingsGridBlueprint => 'ব্লুপ্রিন্ট';

  @override
  String get settingsAreaUnit => 'ক্ষেত্রফলের একক';

  @override
  String get settingsLengthUnit => 'দৈর্ঘ্যের একক';

  @override
  String get settingsUnderlay => 'আন্ডারলে';

  @override
  String get settingsMapUnderlay => 'মানচিত্র আন্ডারলে';

  @override
  String get settingsMapUnderlaySub =>
      'ক্যানভাসের পেছনে রাস্তা ও প্লটের ইঙ্গিত দেখান';

  @override
  String get drawerMenu => 'মেনু';

  @override
  String get drawerMenuSub => 'সেটিংস, তথ্য ও আরও';

  @override
  String get drawerKhotiyanSub => 'আনা, গণ্ডা, কড়ায় অংশ গণনা করুন';

  @override
  String get drawerSettingsSub => 'থিম, একক, গ্রিড ধরন';

  @override
  String get drawerAboutSub => 'সংস্করণ, কৃতজ্ঞতা, প্লটক্যালক কী করে';

  @override
  String drawerVersion(String version) {
    return 'প্লটক্যালক · v$version';
  }

  @override
  String get aboutTitle => 'পরিচিতি';

  @override
  String get aboutTagline => 'অফলাইন ভূমি পরিমাপ, আপনার মতো করে';

  @override
  String get aboutWhatItDoes => 'এটি যা করে';

  @override
  String get aboutDraw =>
      'কোণে ট্যাপ করে, নমুনা টেনে, বা সঠিক মাপ লিখে প্লট আঁকুন।';

  @override
  String get aboutConvert =>
      '১০টি ক্ষেত্রফলের এককের মধ্যে রূপান্তর করুন, ময়মনসিংহের আঞ্চলিক বিঘা ও কাঠাসহ।';

  @override
  String get aboutAdjust =>
      'আকৃতি বজায় রেখে বহুভুজকে লক্ষ্য ক্ষেত্রফলে সমন্বয় করুন।';

  @override
  String get aboutCompare => 'দুটি সংরক্ষিত প্লট পাশাপাশি তুলনা করুন।';

  @override
  String get aboutSubdivide => 'একটি প্লটকে আনুপাতিক লটে ভাগ করুন।';

  @override
  String get aboutOffline => 'অফলাইনে কাজ করে';

  @override
  String get aboutOfflineBody =>
      'প্রতিটি পরিমাপ, রূপান্তর ও সংরক্ষিত প্লট আপনার ডিভাইসেই থাকে। কোনো অ্যাকাউন্ট বা ইন্টারনেট লাগে না।';

  @override
  String get aboutBuild => 'বিল্ড';

  @override
  String get aboutVersion => 'সংস্করণ';

  @override
  String get aboutBuildLabel => 'বিল্ড';

  @override
  String get aboutPlatform => 'প্ল্যাটফর্ম';

  @override
  String get aboutPlatformValue => 'অ্যান্ড্রয়েড · আইওএস';

  @override
  String get aboutCredits => 'কৃতজ্ঞতা';

  @override
  String get aboutCreditsBody =>
      'তৈরি করেছেন জামান শেখ।\nক্লদ ডিজাইনের প্লটক্যালক হ্যান্ডঅফ বান্ডেল দিয়ে ডিজাইন করা।';

  @override
  String get pickerQuestionAccent => 'শুরু';

  @override
  String get historyEmptyFiltered =>
      'এই ছাঁকনিতে কোনো প্লট মেলেনি।\nমুছতে “সব” চাপুন।';

  @override
  String get adjustAnchorN => 'উ';

  @override
  String get adjustAnchorE => 'পূ';

  @override
  String get adjustAnchorW => 'প';

  @override
  String get adjustAnchorS => 'দ';

  @override
  String homeSides(int sides) {
    final intl.NumberFormat sidesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sidesString = sidesNumberFormat.format(sides);

    return ' · $sidesString বাহু';
  }

  @override
  String get drawFirstVertexHint =>
      'প্রথম কোণ বসাতে ক্যানভাসের\nযেকোনো জায়গায় ট্যাপ করুন';

  @override
  String get drawCompassN => 'উ';

  @override
  String get unitBighaMymensinghLabel => 'বিঘা (ময়)';

  @override
  String get unitBighaMymensinghName => 'বিঘা — ময়মনসিংহ';

  @override
  String get unitKathaMymensinghLabel => 'কাঠা (ময়)';

  @override
  String get unitKathaMymensinghName => 'কাঠা — ময়মনসিংহ';

  @override
  String get breakdownTitle => 'বিভাজন হিসাব';

  @override
  String get breakdownSectionLabel => 'বিভাজন হিসাব';

  @override
  String get settingsBreakdown => 'বিভাজনের একক';

  @override
  String get settingsBreakdownSub => 'যৌগিক হিসাবে কোন কোন একক থাকবে বেছে নিন';

  @override
  String get breakdownConfigTitle => 'বিভাজনের একক';

  @override
  String get breakdownConfigSubtitle =>
      'সাজাতে টানুন, চালু/বন্ধ করতে ট্যাপ করুন';

  @override
  String get breakdownConfigHint =>
      'বড় একক আগে ব্যবহার হয়, আর আপনার চালু করা সবচেয়ে ছোট এককটি বাকি অংশ বহন করে।';

  @override
  String get breakdownEmpty => 'বিভাজন দেখতে অন্তত একটি একক চালু করুন।';

  @override
  String get breakdownNone => 'কোনো একক চালু নেই';

  @override
  String get actionResetDefaults => 'ডিফল্টে ফেরান';

  @override
  String breakdownOf(int count, int total) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalStringটির মধ্যে $countStringটি একক চালু';
  }

  @override
  String get calcTitle => 'জমির ক্যালকুলেটর';

  @override
  String get calcSubtitle => 'মোট, সমন্বয় ও একত্র করুন';

  @override
  String get calcTotalLabel => 'মোট ক্ষেত্রফল';

  @override
  String get calcAdjustTitle => 'ক্ষেত্রফল সমন্বয়';

  @override
  String get calcAdd => 'যোগ';

  @override
  String get calcSubtract => 'বিয়োগ';

  @override
  String get calcCombineTitle => 'একক একত্র করুন';

  @override
  String get calcClear => 'মুছুন';

  @override
  String get calcEmpty => 'বিভাজন দেখতে একটি ক্ষেত্রফল লিখুন।';

  @override
  String get calcCannotGoNegative => 'মোট শূন্যের নিচে যেতে পারে না।';

  @override
  String get homeCalculatorSub => 'যোগ, বিয়োগ, বিভাজন';

  @override
  String get calcModeTotal => 'একক মান';

  @override
  String get calcModeParts => 'একক অনুযায়ী';

  @override
  String get calcPartsHint =>
      'যেকোনো একক বদলান — লেখার সঙ্গে সঙ্গে মোট বদলাবে।';

  @override
  String get calcAdjustLabel => 'মোট সমন্বয়';

  @override
  String get calcResultLabel => 'বিভাজন';

  @override
  String get calcAmountLabel => 'পরিমাণ';

  @override
  String get actionCopy => 'কপি';

  @override
  String get copiedToClipboard => 'ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String get resultShare => 'শেয়ার';

  @override
  String get exportFailed => 'রপ্তানি করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get plotDisplayUnit => 'প্রদর্শনের একক';

  @override
  String get plotUnitFollowsSettings => 'অ্যাপের সেটিং অনুসরণ করুন';

  @override
  String get plotUnitTitle => 'এই প্লট যে এককে দেখাবে';

  @override
  String plotUnitSaved(String name, String unit) {
    return '“$name” এখন $unit-এ দেখাবে';
  }
}
