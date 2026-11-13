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
  String get historyFilter => 'ফিল্টার';

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

    return '$countStringটি নির্বাচিত';
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
  String get filterTitle => 'শ্রেণি অনুযায়ী ফিল্টার করুন';

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
  String get infoTitle => 'জমির তথ্য';

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
  String get pickerQuestionAccent => 'শুরু';

  @override
  String get historyEmptyFiltered =>
      'এই ফিল্টারে কোনো প্লট মেলেনি।\nমুছতে “সব” চাপুন।';

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

  @override
  String get breakdownEditUnits => 'একক';

  @override
  String get adjustMethodScale => 'আকার বদলান';

  @override
  String get adjustMethodBoundary => 'সীমানা সরান';

  @override
  String get adjustPickSides => 'বাহু';

  @override
  String get adjustPickCorners => 'কোণ';

  @override
  String get adjustTapToPick => 'সরাতে নকশায় একটি বাহুতে ট্যাপ করুন';

  @override
  String get adjustTapToPickCorner => 'সরাতে নকশায় একটি কোণে ট্যাপ করুন';

  @override
  String adjustMoveOut(String distance) {
    return '$distance বাইরে সরান';
  }

  @override
  String adjustMoveIn(String distance) {
    return '$distance ভিতরে সরান';
  }

  @override
  String get adjustUnreachable => 'শুধু এটি সরিয়ে সম্ভব নয় — আরও বাহু বাছুন';

  @override
  String adjustSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি নির্বাচিত';
  }

  @override
  String get actionClearSelection => 'বাদ দিন';

  @override
  String get adjustPickSlide => 'পিছলে সরান';

  @override
  String get adjustTapToSlide => 'সীমানা বরাবর সরাতে একটি কোণে ট্যাপ করুন';

  @override
  String get adjustSlideAlong => 'বরাবর';

  @override
  String get adjustSlideSwap => 'অন্য বাহু';

  @override
  String get resultEditShape => 'আকৃতি সম্পাদনা';

  @override
  String plotUpdated(String name) {
    return '“$name” হালনাগাদ হয়েছে';
  }

  @override
  String get resultUnsaved => 'সংরক্ষিত নয়';

  @override
  String get subdivideAddLot => 'লট যোগ';

  @override
  String get subdivideRemoveLot => 'সরান';

  @override
  String get subdivideModeEqual => 'সমান';

  @override
  String get subdivideModePercent => 'শতাংশ';

  @override
  String get subdivideModeArea => 'ক্ষেত্রফল';

  @override
  String subdivideSavedLots(int count, String name) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '“$name” থেকে $countStringটি লট সংরক্ষিত';
  }

  @override
  String subdivideLotsDontSum(String total, String plot) {
    return 'লটের যোগফল $total, প্লট $plot';
  }

  @override
  String get aboutDeveloper => 'ডেভেলপার';

  @override
  String get aboutDeveloperName => 'জামান শেখ';

  @override
  String get aboutFacebook => 'ফেসবুক';

  @override
  String get aboutGithub => 'গিটহাব';

  @override
  String get aboutOpenLinkFailed => 'লিংকটি খোলা যায়নি';

  @override
  String get historyTabPlots => 'প্লট';

  @override
  String get historyTabSheets => 'শিট';

  @override
  String get historySelectHint => 'বাছাই করতে প্লটে লম্বা চাপ দিন';

  @override
  String get historyCompareShort => 'তুলনা';

  @override
  String historySum(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি প্লট যোগ';
  }

  @override
  String get sheetTitle => 'জমির শিট';

  @override
  String get sheetNameTitle => 'শিটের নাম দিন';

  @override
  String sheetDefaultName(String number) {
    return 'শিট $number';
  }

  @override
  String get sheetTotalLabel => 'মোট জমি';

  @override
  String sheetTotalArea(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'মোট · $countStringটি প্লট';
  }

  @override
  String sheetCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি প্লট';
  }

  @override
  String get sheetPriceLabel => 'দর';

  @override
  String sheetPricePer(String unit) {
    return 'প্রতি $unit';
  }

  @override
  String get sheetRate => 'দর';

  @override
  String get sheetTotalValue => 'মোট মূল্য';

  @override
  String get sheetPlotsHeader => 'এই শিটের প্লট';

  @override
  String get sheetAddPlots => 'প্লট যোগ করুন';

  @override
  String get sheetAllAdded => 'সব প্লট ইতিমধ্যে এই শিটে আছে।';

  @override
  String get sheetEmpty => 'এই শিটে এখনো কোনো প্লট নেই।';

  @override
  String get sheetsEmpty =>
      'এখনো কোনো শিট নেই।\nপ্লটে লম্বা চাপ দিয়ে বাছাই করুন, তারপর ‘যোগ’ চাপুন।';

  @override
  String sheetMissing(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'এই শিটের $countStringটি প্লট মুছে ফেলা হয়েছে।';
  }

  @override
  String get sheetDeleteTitle => 'শিট মুছবেন?';

  @override
  String sheetDeleteBody(String name) {
    return '“$name” মুছে যাবে। প্লটগুলো সংরক্ষিত থাকবে।';
  }

  @override
  String get sheetColPlot => 'প্লট';

  @override
  String get sheetColShare => 'অংশ';

  @override
  String get sheetColValue => 'মূল্য';

  @override
  String sheetPrepared(String date) {
    return 'তৈরি: $date';
  }

  @override
  String get sheetUnitTitle => 'শিটটি কোন এককে দেখাবে';

  @override
  String get sheetPriceUnitTitle => 'দর কোন এককে';

  @override
  String sheetPlotRemoved(String name) {
    return '“$name” শিট থেকে সরানো হয়েছে';
  }

  @override
  String get sheetLayoutHeader => 'নকশা';

  @override
  String get sheetArrange => 'সাজান';

  @override
  String get sheetArrangeTitle => 'প্লট সাজান';

  @override
  String get sheetArrangeHint => 'প্লট টেনে সরান · দুই আঙুলে জুম';

  @override
  String get sheetTurnLeft => 'বামে ঘোরান';

  @override
  String get sheetTurnRight => 'ডানে ঘোরান';

  @override
  String get sheetFitView => 'পুরোটা দেখুন';

  @override
  String get sheetAutoArrange => 'নিজে থেকে সাজান';

  @override
  String get sheetLayoutSaved => 'নকশা সংরক্ষিত হয়েছে';

  @override
  String get sheetDiscardTitle => 'পরিবর্তন বাদ দেবেন?';

  @override
  String get sheetDiscardBody => 'এই সাজানো নকশা সংরক্ষণ করা হয়নি।';

  @override
  String get sheetDiscard => 'বাদ দিন';

  @override
  String get sheetTapToSelect => 'বাছতে একটি প্লটে চাপ দিন';

  @override
  String get mouzaEntryTitle => 'মৌজা ম্যাপ থেকে মাপুন';

  @override
  String get mouzaEntrySub => 'ছবি → স্কেল → কোণায় চাপ';

  @override
  String get mouzaTitle => 'মৌজা ম্যাপ';

  @override
  String get mouzaStepPhoto => 'ছবি';

  @override
  String get mouzaStepScale => 'স্কেল';

  @override
  String get mouzaStepCorners => 'কোণ';

  @override
  String get mouzaPickTitle => 'ম্যাপের ছবি নিন';

  @override
  String get mouzaPickSub =>
      'তারপর স্কেল ঠিক করে প্লটের কোণাগুলোতে চাপ দিন — ক্ষেত্রফল নিজে থেকেই বের হবে।';

  @override
  String get mouzaPickCamera => 'ছবি তুলুন';

  @override
  String get mouzaPickGallery => 'গ্যালারি থেকে বাছুন';

  @override
  String get mouzaTipsTitle => 'সঠিক মাপের জন্য';

  @override
  String get mouzaTip1 => 'ম্যাপটি সমান জায়গায় রেখে ঠিক উপর থেকে ছবি তুলুন।';

  @override
  String get mouzaTip2 =>
      'স্কেল বার, অথবা যে বাহুর মাপ জানেন, তা যেন ছবিতে থাকে।';

  @override
  String get mouzaTip3 => 'পর্যাপ্ত আলো রাখুন — ছায়া বা ঝলক যেন না থাকে।';

  @override
  String get mouzaPickFailed => 'ছবিটি খোলা যায়নি।';

  @override
  String get mouzaScaleHintFirst =>
      'এমন দুটি বিন্দুতে চাপ দিন যাদের মাঝের দূরত্ব আপনি জানেন — যেমন স্কেল বারের দুই মাথা।';

  @override
  String get mouzaScaleHintSecond => 'এবার দ্বিতীয় বিন্দুতে চাপ দিন।';

  @override
  String get mouzaScaleDistance => 'দুই বিন্দুর মাঝের দূরত্ব';

  @override
  String get mouzaScaleNoBar =>
      'স্কেল বার নেই? দলিলে লেখা যেকোনো বাহুর মাপ ব্যবহার করুন।';

  @override
  String get mouzaDragTip =>
      'বিন্দু টেনে ঠিক জায়গায় বসান — বড় করে দেখাবে কোথায় আছে।';

  @override
  String get mouzaUnitFoot => 'ফুট';

  @override
  String get mouzaUnitMeter => 'মিটার';

  @override
  String get mouzaUnitChain => 'চেইন (জরীপ)';

  @override
  String get mouzaUnitLink => 'লিংক (কড়ি)';

  @override
  String get mouzaNext => 'পরের ধাপ';

  @override
  String get mouzaStartOver => 'আবার শুরু';

  @override
  String get mouzaTraceHintFirst => 'প্লটের প্রতিটি কোণায় পরপর চাপ দিন।';

  @override
  String mouzaTraceHintMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি কোণ — প্লটের চারপাশ ঘুরে চাপ দিতে থাকুন।';
  }

  @override
  String get mouzaNewPlot => 'নতুন প্লট';

  @override
  String get mouzaChangeScale => 'স্কেল';

  @override
  String get mouzaSeeResult => 'ফলাফল দেখুন';

  @override
  String get mouzaDefaultName => 'মৌজা ম্যাপের প্লট';

  @override
  String get mouzaLeaveTitle => 'ম্যাপ ছেড়ে যাবেন?';

  @override
  String get mouzaLeaveBody => 'যে কোণাগুলো দিয়েছেন তা হারিয়ে যাবে।';

  @override
  String get mouzaAreaSoFar => 'ক্ষেত্রফল';

  @override
  String get overlayEntryTitle => 'প্যান্টোগ্রাফ';

  @override
  String get overlayEntrySub => 'CS ↔ RS মিলিয়ে মাপুন';

  @override
  String get mouzaCompareLink =>
      'একই মৌজার দুই জরিপের ম্যাপ আছে? প্যান্টোগ্রাফে মিলিয়ে দেখুন';

  @override
  String get overlayTitle => 'প্যান্টোগ্রাফ';

  @override
  String get overlayStepMaps => 'ম্যাপ';

  @override
  String get overlayStepMatch => 'মিলান';

  @override
  String get overlayStepMeasure => 'মাপ';

  @override
  String get overlayMapsTitle => 'মৌজার দুটি ম্যাপ দিন';

  @override
  String get overlayMapsSub =>
      'সাধারণত পুরনো জরিপ (CS বা SA) আর নতুন জরিপ (RS বা BS)। এরপর দুই ম্যাপেই আছে এমন কয়েকটি জায়গা চিহ্নিত করলে একটির উপর আরেকটি বসে যাবে।';

  @override
  String get overlayMapOld => 'পুরনো জরিপ';

  @override
  String get overlayMapNew => 'নতুন জরিপ';

  @override
  String get overlayAddPhoto => 'ছবি দিন';

  @override
  String get overlaySurveyOther => 'অন্য';

  @override
  String get overlaySameSheet =>
      'দুটিই একই মৌজার একই সিটের ম্যাপ হতে হবে (একই জে.এল. নং)।';

  @override
  String get overlayMatchStart =>
      'দুই ম্যাপেই খুঁজে পাওয়া যায় এমন একটি জায়গায় চাপুন — রাস্তার মোড়, মৌজা সীমানার কোণা বা পিলার।';

  @override
  String overlayMatchOther(String map) {
    return 'এবার $map ম্যাপে ঠিক সেই জায়গায় চাপুন। ছোট বৃত্তে আগের জায়গাটি দেখুন।';
  }

  @override
  String get overlayMatchGuessed =>
      'যেখানে হওয়ার কথা সেখানে বসানো হয়েছে — ঠিক না থাকলে সঠিক জায়গায় চাপুন বা টেনে মেলান।';

  @override
  String overlayMatchMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি মিলেছে। আরও দিন, সিটের চার কোণার দিকে ছড়িয়ে — ৪টি বা বেশি হলে সবচেয়ে ভালো।';
  }

  @override
  String get overlayNextPair => 'পরের জায়গা';

  @override
  String get overlayRemovePair => 'মুছুন';

  @override
  String overlayQualityUnchecked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'মিল যাচাই করতে আরও $countStringটি দিন';
  }

  @override
  String get overlayQualityGood => 'মিল: ভালো';

  @override
  String get overlayQualityFair => 'মিল: মোটামুটি — জায়গাগুলো দেখে নিন';

  @override
  String get overlayQualityPoor => 'মিল: খারাপ — কোনো জায়গা সম্ভবত ভুল';

  @override
  String get overlayQualityPoorWhich => 'কোনটি ভুল জানতে আরও একটি জায়গা দিন';

  @override
  String overlaySuspect(String n) {
    return '$n নম্বর জায়গাটি সম্ভবত ভুল — দেখে নিন';
  }

  @override
  String get overlayViewBoth => 'দুটো';

  @override
  String get overlayColours => 'রঙ';

  @override
  String get overlayScaleHint =>
      'যেকোনো ম্যাপের স্কেল বারে স্কেল দিন — দুটি ম্যাপ এখন একই মাপে।';

  @override
  String get overlayPlot => 'দাগ';

  @override
  String get overlayTraceHint =>
      'ম্যাপ বেছে নিন, তারপর তার একটি দাগের কোণাগুলোতে চাপ দিন।';

  @override
  String get overlayFinishPlot => 'দাগ শেষ';

  @override
  String get overlayPlotNameTitle => 'দাগ নম্বর';

  @override
  String get overlayPlotsHeader => 'দাগসমূহ';

  @override
  String get overlayOverlapHeader => 'যতটুকু মিলেছে';

  @override
  String overlayOverlapShare(String pa, String a, String pb, String b) {
    return '$a-এর $pa · $b-এর $pb';
  }

  @override
  String get overlayNoOverlap => 'আঁকা দাগগুলো একটি আরেকটির উপর পড়েনি।';

  @override
  String get overlayOverlapEmpty =>
      'দুই ম্যাপ থেকে একটি করে দাগ আঁকুন — কতটুকু মিলে তা দেখাবে।';

  @override
  String get overlayReport => 'রিপোর্ট';

  @override
  String get overlayReportTitle => 'প্যান্টোগ্রাফ';

  @override
  String overlayReportMatched(int count, String quality) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি জায়গায় মিলানো · $quality';
  }

  @override
  String overlayReportMismatch(String value) {
    return 'গড় অমিল $value';
  }

  @override
  String get overlayReportMap => 'ম্যাপ';

  @override
  String get overlayLeaveBody => 'মিলানো জায়গা ও আঁকা দাগ হারিয়ে যাবে।';

  @override
  String get overlayNeedTwo => 'এগোতে অন্তত দুটি জায়গা মিলান।';

  @override
  String overlayMovePlace(String n) {
    return '$n নম্বর জায়গা: যেকোনো ম্যাপে সঠিক জায়গায় চাপুন, বা চিহ্নটি টেনে মেলান।';
  }

  @override
  String get divisionOwnersTab => 'মালিক';

  @override
  String get divisionSidesTab => 'দিক ও রাস্তা';

  @override
  String get divisionBoundsTab => 'চৌহদ্দি';

  @override
  String get divisionHowLabel => 'কীভাবে ভাগ';

  @override
  String get divisionModeEqual => 'সমান';

  @override
  String get divisionModeShares => 'অংশে';

  @override
  String get divisionModeAreas => 'মাপে';

  @override
  String get divisionShareHint => 'যেমন ১/৩';

  @override
  String get divisionShareHelp =>
      'অংশ লিখুন ভাগ হিসেবে — ১/৩, ৬ আনা, ২৫% — অথবা সংখ্যায়: ছেলের ২, মেয়ের ১।';

  @override
  String get divisionAreaHelp =>
      'কারো মাপ খালি রাখলে বাকি জমি তারা ভাগ করে নেবেন।';

  @override
  String get divisionAreaHint => 'বাকি';

  @override
  String get divisionNameHint => 'নাম';

  @override
  String get divisionAddOwner => 'আরও একজন';

  @override
  String get divisionRest => 'অবণ্টিত';

  @override
  String get divisionRoad => 'রাস্তা';

  @override
  String divisionRoadWidth(String width) {
    return 'রাস্তা · $width';
  }

  @override
  String get divisionIssueSharesOver => 'অংশের যোগফল পুরো জমির চেয়ে বেশি।';

  @override
  String get divisionIssueSharesMixed =>
      'সব অংশ একইভাবে লিখুন — হয় ভাগ (১/৩, ৬ আনা), নয় সংখ্যা (২, ১)।';

  @override
  String get divisionIssueShareUnreadable =>
      'একটি অংশ বোঝা যায়নি — ১/৩, ৬ আনা, ২৫% বা ২ এভাবে লিখুন।';

  @override
  String get divisionIssueAreasOver => 'মাপের যোগফল জমির চেয়ে বেশি।';

  @override
  String get divisionIssueAreaUnreadable => 'একটি মাপ বোঝা যায়নি।';

  @override
  String get divisionIssueRoadTooWide => 'রাস্তা পুরো জমির সমান গভীর।';

  @override
  String divisionRestNote(String area) {
    return '$area এখনো কাউকে দেওয়া হয়নি।';
  }

  @override
  String get divisionGiveRest => 'এর জন্য একজন যোগ করুন';

  @override
  String get divisionFrontTitle => 'সব লট কোন বাহু ছুঁয়ে থাকবে?';

  @override
  String get divisionFrontHint =>
      'সাধারণত রাস্তার দিক — প্রত্যেকে সেই দিকে নিজের অংশ পাবেন। নকশায় বাহুতে চাপ দিন, বা এখান থেকে বাছুন।';

  @override
  String get divisionFrontAny => 'যেকোনো';

  @override
  String divisionSideN(String n, String length) {
    return 'বাহু $n · $length';
  }

  @override
  String get divisionRoadTitle => 'সেই বাহু ঘেঁষে চলাচলের রাস্তা';

  @override
  String get divisionRoadHint =>
      'আগে রাস্তা আলাদা হবে, প্রতিটি লট রাস্তায় মুখ করে থাকবে।';

  @override
  String get divisionRoadNone => 'নেই';

  @override
  String get divisionRoadNeedsFront => 'আগে বাহু বাছুন।';

  @override
  String get divisionStraighten => 'রেখা সোজা করুন';

  @override
  String get divisionFront => 'সামনে';

  @override
  String get divisionNorth => 'উ';

  @override
  String get cardinalNorth => 'উত্তর';

  @override
  String get cardinalEast => 'পূর্ব';

  @override
  String get cardinalSouth => 'দক্ষিণ';

  @override
  String get cardinalWest => 'পশ্চিম';

  @override
  String get divisionOutside => 'জমির সীমানা';

  @override
  String get divisionSaved => 'শিট হিসেবে সংরক্ষিত';

  @override
  String get divisionOpenSheet => 'খুলুন';

  @override
  String divisionSheetName(String name) {
    return '$name — বণ্টন';
  }

  @override
  String get divisionPdfTitle => 'বণ্টননামা';

  @override
  String get divisionPdfTotal => 'মোট জমি';

  @override
  String get divisionPdfNorth => 'নকশার উপরের দিক উত্তর।';

  @override
  String get divisionPdfDisclaimer => 'মাপের জন্য আঁকা — আইনি দলিল নয়।';

  @override
  String get divisionColShare => 'অংশ';

  @override
  String get divisionColSide => 'দিক';

  @override
  String get divisionColLength => 'দৈর্ঘ্য';

  @override
  String get divisionColBeyond => 'পাশে';

  @override
  String get divisionSlid => 'মাপ অনুযায়ী বদলানো হলো।';

  @override
  String get divisionEdit => 'বিভাজন বদলান';

  @override
  String get divisionParentGone =>
      'যে প্লট ভাগ করা হয়েছিল সেটি মুছে ফেলা হয়েছে।';

  @override
  String divisionPeople(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$name · $countString জনে';
  }

  @override
  String get divisionDragHint => 'রেখা টেনে জমি সরান, রেখার মাথা টেনে ঘোরান।';

  @override
  String get divisionBoundsEmpty => 'ভাগ ঠিক হলে এখানে দেখাবে।';

  @override
  String get divisionColLocal => 'স্থানীয় মাপে';

  @override
  String get inheritTitle => 'ওয়ারিশ হিসাব';

  @override
  String get inheritDrawerSub => 'কে কত অংশ পাবেন · ফারায়েজ';

  @override
  String inheritStep(int step, String name) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);

    return 'ধাপ $stepString/৩ · $name';
  }

  @override
  String get inheritStepDeceased => 'কে মারা গেছেন?';

  @override
  String get inheritStepFamily => 'কে কে বেঁচে আছেন?';

  @override
  String get inheritStepResult => 'কে কত পান';

  @override
  String get inheritMan => 'পুরুষ';

  @override
  String get inheritWoman => 'নারী';

  @override
  String get inheritNameHint => 'নাম (ঐচ্ছিক)';

  @override
  String get inheritLand => 'জমির পরিমাণ (ঐচ্ছিক)';

  @override
  String get inheritLandHint => 'ফাঁকা রাখলে শুধু অংশ দেখাবে।';

  @override
  String get inheritFromSaved => 'অথবা সংরক্ষিত জমি বেছে নিন';

  @override
  String get inheritSeeResult => 'ফলাফল দেখুন';

  @override
  String get inheritNeedHeir => 'অন্তত একজন ওয়ারিশ যোগ করুন';

  @override
  String get inheritFamily => 'পরিবার';

  @override
  String get inheritMore => 'আরও আত্মীয়';

  @override
  String get inheritPredeceasedAdd => 'আগে মারা যাওয়া সন্তান';

  @override
  String get inheritPredeceasedAddSub => 'তাঁর ছেলেমেয়েরা তাঁর অংশ পান';

  @override
  String inheritPredeceasedTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'আগে মারা যাওয়া সন্তান · $nString';
  }

  @override
  String get inheritPredeceasedNote =>
      'তিনি বেঁচে থাকলে যা পেতেন, তাঁর ছেলেমেয়েরা তা পান (মুসলিম পারিবারিক আইন অধ্যাদেশ ১৯৬১, ধারা ৪)।';

  @override
  String get inheritTheirSons => 'তাঁর ছেলে';

  @override
  String get inheritTheirDaughters => 'তাঁর মেয়ে';

  @override
  String get inheritNoChildrenNote =>
      'নিজের সন্তান না থাকলে তিনি কোনো অংশ পান না।';

  @override
  String get inheritHalfSiblings => 'সৎ ভাই-বোন';

  @override
  String get inheritMaleLine => 'ভাতিজা, চাচা ও চাচাতো ভাই';

  @override
  String get inheritSubGrandfather => 'বাবার বাবা';

  @override
  String get inheritSubPaternalGrandmother => 'বাবার মা';

  @override
  String get inheritSubMaternalGrandmother => 'মায়ের মা';

  @override
  String get inheritSubFull => 'একই বাবা-মা';

  @override
  String get inheritSubPaternal => 'বাবা এক, মা ভিন্ন';

  @override
  String get inheritSubMaternal => 'মা এক, বাবা ভিন্ন';

  @override
  String get inheritSubFullNephew => 'আপন ভাইয়ের ছেলে';

  @override
  String get inheritSubPaternalNephew => 'বৈমাত্রেয় ভাইয়ের ছেলে';

  @override
  String get inheritSubFullUncle => 'বাবার আপন ভাই';

  @override
  String get inheritSubPaternalUncle => 'বাবার বৈমাত্রেয় ভাই';

  @override
  String get inheritSubFullCousin => 'আপন চাচার ছেলে';

  @override
  String get inheritSubPaternalCousin => 'বৈমাত্রেয় চাচার ছেলে';

  @override
  String get inheritWivesMax => 'সর্বোচ্চ চারজন।';

  @override
  String inheritHiddenBy(String who) {
    return '$who থাকায় ভাই-বোন, চাচা ও অন্যরা কিছু পান না, তাই তাঁদের কথা জিজ্ঞেস করা হচ্ছে না।';
  }

  @override
  String get inheritSiblingsForMother =>
      'এখানে ভাই-বোনেরা কিছু পান না, তবে দুই বা বেশি থাকলে মায়ের অংশ ১/৬ হয়।';

  @override
  String get inheritDistant =>
      'দূরের আত্মীয়রা (মামা, খালা, ফুফু, নানা, বোনের সন্তান…) পান কেবল যখন কোনো অংশীদার বা আসাবা থাকে না — তখন এখানে তাঁদের কথা জিজ্ঞেস করা হবে।';

  @override
  String get inheritHeirHusband => 'স্বামী';

  @override
  String get inheritHeirWife => 'স্ত্রী';

  @override
  String get inheritHeirSon => 'ছেলে';

  @override
  String get inheritHeirDaughter => 'মেয়ে';

  @override
  String get inheritHeirGrandson => 'ছেলে';

  @override
  String get inheritHeirGranddaughter => 'মেয়ে';

  @override
  String get inheritHeirFather => 'বাবা';

  @override
  String get inheritHeirMother => 'মা';

  @override
  String get inheritHeirGrandfather => 'দাদা';

  @override
  String get inheritHeirPaternalGrandmother => 'দাদি';

  @override
  String get inheritHeirMaternalGrandmother => 'নানি';

  @override
  String get inheritHeirFullBrother => 'আপন ভাই';

  @override
  String get inheritHeirFullSister => 'আপন বোন';

  @override
  String get inheritHeirPaternalBrother => 'বৈমাত্রেয় ভাই';

  @override
  String get inheritHeirPaternalSister => 'বৈমাত্রেয় বোন';

  @override
  String get inheritHeirMaternalBrother => 'বৈপিত্রেয় ভাই';

  @override
  String get inheritHeirMaternalSister => 'বৈপিত্রেয় বোন';

  @override
  String get inheritHeirFullNephew => 'ভাতিজা';

  @override
  String get inheritHeirPaternalNephew => 'ভাতিজা (বৈমাত্রেয়)';

  @override
  String get inheritHeirFullUncle => 'চাচা';

  @override
  String get inheritHeirPaternalUncle => 'চাচা (বৈমাত্রেয়)';

  @override
  String get inheritHeirFullCousin => 'চাচাতো ভাই';

  @override
  String get inheritHeirPaternalCousin => 'চাচাতো ভাই (বৈমাত্রেয়)';

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
    return '$parent-এর $child';
  }

  @override
  String get inheritWhyHusbandHalf => 'সন্তান না থাকায় স্বামী পান ১/২।';

  @override
  String get inheritWhyHusbandQuarter => 'সন্তান থাকায় স্বামী পান ১/৪।';

  @override
  String get inheritWhyWifeQuarter =>
      'সন্তান না থাকায় স্ত্রী পান ১/৪; একাধিক হলে সমান ভাগে।';

  @override
  String get inheritWhyWifeEighth =>
      'সন্তান থাকায় স্ত্রী পান ১/৮; একাধিক হলে সমান ভাগে।';

  @override
  String get inheritWhySonResidue =>
      'নির্ধারিত অংশগুলোর পর বাকি সবটা ছেলে-মেয়েরা পান, ছেলে মেয়ের দ্বিগুণ।';

  @override
  String get inheritWhyDaughterWithSon => 'ছেলে থাকায় মেয়ে ছেলের অর্ধেক পান।';

  @override
  String get inheritWhyDaughterHalf => 'ছেলে না থাকায় একমাত্র মেয়ে পান ১/২।';

  @override
  String get inheritWhyDaughtersTwoThirds =>
      'ছেলে না থাকায় মেয়েরা মিলে পান ২/৩, সমান ভাগে।';

  @override
  String get inheritWhyFatherSixth => 'ছেলে থাকায় বাবা পান ১/৬।';

  @override
  String get inheritWhyFatherSixthAndRest =>
      'ছেলে নেই, মেয়ে আছে: বাবা পান ১/৬ আর বাকি অংশ।';

  @override
  String get inheritWhyFatherRest =>
      'সন্তান না থাকায় বাবা নির্ধারিত অংশগুলোর পর বাকি সবটা পান।';

  @override
  String get inheritWhyGrandfatherSixth =>
      'বাবা না থাকায় দাদা তাঁর জায়গায়; ছেলে থাকায় পান ১/৬।';

  @override
  String get inheritWhyGrandfatherSixthAndRest =>
      'বাবা না থাকায় দাদা তাঁর জায়গায়: ১/৬ আর বাকি অংশ।';

  @override
  String get inheritWhyGrandfatherRest =>
      'বাবা না থাকায় দাদা তাঁর জায়গায়: বাকি সবটা।';

  @override
  String get inheritWhyMotherSixthChild => 'সন্তান থাকায় মা পান ১/৬।';

  @override
  String get inheritWhyMotherSixthSiblings =>
      'দুই বা বেশি ভাই-বোন থাকায় মা পান ১/৬।';

  @override
  String get inheritWhyMotherThird =>
      'সন্তান নেই, ভাই-বোন দুইজনের কম: মা পান ১/৩।';

  @override
  String get inheritWhyMotherThirdOfRest =>
      'শুধু স্বামী/স্ত্রী ও বাবা-মা: স্বামী/স্ত্রীর অংশের পর যা থাকে, মা পান তার ১/৩।';

  @override
  String get inheritWhyGrandmotherSixth =>
      'মা না থাকায় দাদি/নানি পান ১/৬; দুজন হলে সমান ভাগে।';

  @override
  String get inheritWhyUterineSixth =>
      'সন্তান, বাবা বা দাদা না থাকায় একজন বৈপিত্রেয় ভাই/বোন পান ১/৬।';

  @override
  String get inheritWhyUterineThird =>
      'বৈপিত্রেয় ভাই-বোনেরা মিলে পান ১/৩; ভাই-বোন সমান।';

  @override
  String get inheritWhySisterHalf => 'ভাই না থাকায় একমাত্র বোন পান ১/২।';

  @override
  String get inheritWhySistersTwoThirds => 'ভাই না থাকায় বোনেরা মিলে পান ২/৩।';

  @override
  String get inheritWhyPaternalSisterSixth =>
      'একজন আপন বোন ১/২ পাওয়ায় বৈমাত্রেয় বোনেরা পান ১/৬ (মিলে ২/৩)।';

  @override
  String get inheritWhySiblingsResidue =>
      'বাকি সবটা ভাই-বোনেরা পান, ভাই বোনের দ্বিগুণ।';

  @override
  String get inheritWhySisterWithDaughters => 'মেয়ে থাকায় বোন বাকি সবটা পান।';

  @override
  String get inheritWhyAgnateResidue =>
      'সবচেয়ে কাছের পুরুষ আত্মীয় হিসেবে বাকি সবটা পান।';

  @override
  String get inheritWhyRepresented =>
      'আগে মারা যাওয়া বাবা/মায়ের অংশ, ছেলে মেয়ের দ্বিগুণ (অধ্যাদেশ ১৯৬১)।';

  @override
  String get inheritWhySole => 'অন্য কোনো ওয়ারিশ না থাকায় পুরো সম্পত্তি পান।';

  @override
  String get inheritAwl =>
      'নির্ধারিত অংশগুলোর যোগফল পুরো সম্পত্তির চেয়ে বেশি হওয়ায় সবার অংশ একই হারে কমেছে (আওল)।';

  @override
  String get inheritRadd =>
      'সবাইকে দেওয়ার পর যা বাকি ছিল, তা স্বামী/স্ত্রী ছাড়া অন্যদের মধ্যে তাঁদের অংশের অনুপাতে ভাগ হয়েছে (রাদ)।';

  @override
  String get inheritSpouseRest =>
      'অন্য কোনো ওয়ারিশ না থাকায় বাকিটাও স্বামী/স্ত্রী পান। খালা, মামা, ফুফুর মতো দূরের আত্মীয় থাকলে বিশেষজ্ঞের পরামর্শ নিন।';

  @override
  String get inheritExcludedTitle => 'যাঁরা পান না';

  @override
  String inheritOut(String heir, String reason) {
    return '$heir পান না — $reason';
  }

  @override
  String get inheritOutSon => 'ছেলে থাকায়';

  @override
  String get inheritOutFather => 'বাবা থাকায়';

  @override
  String get inheritOutGrandfather => 'দাদা থাকায়';

  @override
  String get inheritOutMother => 'মা থাকায়';

  @override
  String get inheritOutChild => 'সন্তান থাকায়';

  @override
  String get inheritOutFullBrother => 'আপন ভাই থাকায়';

  @override
  String get inheritOutPaternalBrother => 'বৈমাত্রেয় ভাই থাকায়';

  @override
  String get inheritOutSisterWithDaughters => 'মেয়ের সাথে বোন বাকিটা নেওয়ায়';

  @override
  String get inheritOutTwoFullSisters => 'দুই আপন বোন ২/৩ নেওয়ায়';

  @override
  String get inheritOutCloser => 'আরও কাছের আত্মীয় থাকায়';

  @override
  String get inheritOutNothingLeft => 'নির্ধারিত অংশের পর কিছু বাকি না থাকায়';

  @override
  String get inheritWhoSon => 'ছেলে';

  @override
  String get inheritWhoFather => 'বাবা';

  @override
  String get inheritWhoGrandfather => 'দাদা';

  @override
  String get inheritMotherCut =>
      'তাঁরা কিছু না পেলেও তাঁদের কারণে মায়ের অংশ ১/৬।';

  @override
  String inheritBase(String n) {
    return 'মাসআলা $n';
  }

  @override
  String inheritParts(String parts, String base) {
    return '$base ভাগের $parts ভাগ';
  }

  @override
  String inheritEstate(String name) {
    return '$name-এর সম্পত্তি';
  }

  @override
  String get inheritDeceasedMan => 'মৃত ব্যক্তি (পুরুষ)';

  @override
  String get inheritDeceasedWoman => 'মৃত ব্যক্তি (নারী)';

  @override
  String get inheritSharesOnly => 'পুরো সম্পত্তির অংশ';

  @override
  String get inheritDivide => 'এই ভাগে জমি ভাগ করুন';

  @override
  String get inheritShare => 'শেয়ার';

  @override
  String get inheritDisclaimer =>
      'হানাফি নিয়ম ও মুসলিম পারিবারিক আইন অধ্যাদেশ ১৯৬১ অনুযায়ী হিসাব। দলিল বা আদালতের আগে একজন বিশেষজ্ঞের সাথে মিলিয়ে নিন।';

  @override
  String get inheritPickPlot => 'কোন জমি ভাগ হবে?';

  @override
  String get inheritEdit => 'পরিবার বদলান';

  @override
  String get inheritReligion => 'মৃত ব্যক্তির ধর্ম';

  @override
  String get inheritMuslim => 'মুসলিম';

  @override
  String get inheritHindu => 'হিন্দু';

  @override
  String get inheritChristian => 'খ্রিস্টান';

  @override
  String get inheritHinduWoman =>
      'হিন্দু নারীর সম্পত্তির নিয়ম আলাদা। স্ত্রী, মেয়ে বা মা হিসেবে যা পেয়েছিলেন, তাঁর মৃত্যুর পর তা ফেরত যায় যাঁর কাছ থেকে পেয়েছিলেন সেই পুরুষের উত্তরাধিকারীদের কাছে — তাই সেই পুরুষকে মৃত ব্যক্তি ধরে হিসাব করুন। নারীর নিজস্ব সম্পত্তি (স্ত্রীধন) প্রথমে পান তাঁর সন্তানেরা; এর বাইরে হিন্দু আইনজীবীর পরামর্শ নিন।';

  @override
  String inheritLate(String heir, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'মৃত $heir $nString';
  }

  @override
  String get inheritViaWife => 'স্ত্রী';

  @override
  String get inheritHeirSonsWidow => 'পুত্রবধূ';

  @override
  String get inheritHeirUnmarriedDaughter => 'অবিবাহিত মেয়ে';

  @override
  String get inheritHeirMarriedDaughter => 'বিবাহিত মেয়ে';

  @override
  String get inheritHeirDaughtersSon => 'মেয়ের ছেলে';

  @override
  String get inheritHeirDaughtersDaughter => 'মেয়ের মেয়ে';

  @override
  String get inheritHeirBrother => 'ভাই';

  @override
  String get inheritHeirSister => 'বোন';

  @override
  String get inheritHeirGrandNephew => 'ভাতিজার ছেলে';

  @override
  String get inheritHeirSistersSon => 'ভাগ্নে';

  @override
  String get inheritHeirSistersDaughter => 'ভাগ্নি';

  @override
  String get inheritHeirBrothersDaughter => 'ভাতিজি';

  @override
  String get inheritHeirMaternalGrandfather => 'নানা';

  @override
  String get inheritHeirPaternalAunt => 'ফুফু';

  @override
  String get inheritHeirMaternalUncle => 'মামা';

  @override
  String get inheritHeirMaternalAunt => 'খালা';

  @override
  String get inheritHeirCousin => 'কাজিন';

  @override
  String get inheritSubWidows => 'একাধিক হলে মিলে একজন ছেলের সমান ভাগ।';

  @override
  String get inheritSubUnmarried => 'বিয়ে হয়নি';

  @override
  String get inheritSubMarriedWithSon => 'ছেলে আছে বা হতে পারে';

  @override
  String get inheritHinduDaughterNote =>
      'ছেলে নেই এবং হওয়ার সম্ভাবনাও নেই — এমন বিধবা বা নিঃসন্তান মেয়ে উত্তরাধিকার পান না।';

  @override
  String get inheritDeadSonAdd => 'আগে মারা যাওয়া ছেলে';

  @override
  String get inheritDeadSonAddSub => 'তাঁর ছেলে ও স্ত্রী তাঁর ভাগ পান';

  @override
  String inheritDeadSonTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'আগে মারা যাওয়া ছেলে · $nString';
  }

  @override
  String get inheritTheirWidow => 'তাঁর স্ত্রী জীবিত';

  @override
  String get inheritSubBrothersSon => 'ভাইয়ের ছেলে';

  @override
  String get inheritSubSistersSon => 'বোনের ছেলে';

  @override
  String get inheritSubUnclesSon => 'চাচার ছেলে';

  @override
  String get inheritSubHalfBrotherHindu => 'বাবা এক, মা ভিন্ন';

  @override
  String get inheritHinduHiddenMale =>
      'ছেলে, নাতি বা পুত্রবধূ থাকায় মেয়ে ও অন্য কেউ কিছু পান না, তাই তাঁদের কথা জিজ্ঞেস করা হচ্ছে না।';

  @override
  String get inheritHinduHiddenWidow =>
      'স্ত্রী জীবিত থাকায় মেয়ে ও অন্যরা এখন কিছু পান না; তাঁর মৃত্যুর পর সম্পত্তি তাঁদের কাছে যায়।';

  @override
  String get inheritHinduDistant =>
      'এর পরের আত্মীয়দের দীর্ঘ শাস্ত্রীয় ক্রম এখানে নেই; উইল, দান বা আগের বণ্টন থাকলেও হিসাব বদলায় — হিন্দু আইনজীবীর পরামর্শ নিন।';

  @override
  String get inheritSpouseChristian => 'স্বামী বা স্ত্রী';

  @override
  String get inheritChristianDeadNote =>
      'তাঁর ছেলেমেয়েরা তাঁর ভাগ সমানভাবে পান (উত্তরাধিকার আইন ১৯২৫, ধারা ৪০)।';

  @override
  String get inheritDeadSiblingAdd => 'আগে মারা যাওয়া ভাই বা বোন';

  @override
  String get inheritDeadSiblingAddSub => 'তাঁর ছেলেমেয়েরা তাঁর ভাগ পান';

  @override
  String inheritDeadSiblingTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'আগে মারা যাওয়া ভাই/বোন · $nString';
  }

  @override
  String get inheritSubAnyBlood => 'আপন বা সৎ — একই';

  @override
  String get inheritChristianHiddenDesc =>
      'সন্তান বা নাতি-নাতনি থাকায় বাবা-মা, ভাই-বোন ও অন্য আত্মীয়রা কিছু পান না।';

  @override
  String get inheritChristianHiddenFather =>
      'বাবা থাকায় মা, ভাই-বোন ও অন্য আত্মীয়রা কিছু পান না।';

  @override
  String get inheritChristianDistant =>
      'কাজিনের চেয়ে দূরের আত্মীয়ের জন্য আইনজীবীর পরামর্শ নিন। কোনো আত্মীয় না থাকলে সম্পত্তি সরকারের।';

  @override
  String get inheritLifeInterest => 'জীবনস্বত্ব';

  @override
  String get inheritDisclaimerHindu =>
      'বাংলাদেশে প্রচলিত দায়ভাগ আইন ও হিন্দু নারীর সম্পত্তির অধিকার আইন ১৯৩৭ অনুযায়ী হিসাব। দলিল বা আদালতের আগে একজন বিশেষজ্ঞের সাথে মিলিয়ে নিন।';

  @override
  String get inheritDisclaimerChristian =>
      'উত্তরাধিকার আইন ১৯২৫ (পঞ্চম ভাগ) অনুযায়ী হিসাব। উইল, বিয়ের আগের চুক্তি বা প্রথা থাকলে হিসাব বদলায়। দলিল বা আদালতের আগে একজন বিশেষজ্ঞের সাথে মিলিয়ে নিন।';

  @override
  String get inheritWhyHinduSons => 'ছেলেরা সমান ভাগ পান।';

  @override
  String get inheritWhyHinduWidow =>
      'স্ত্রী একজন ছেলের সমান ভাগ পান (একাধিক হলে মিলে একটি), জীবনস্বত্ব হিসেবে (১৯৩৭ আইন)।';

  @override
  String get inheritWhyHinduSonsLine => 'মৃত বাবার ভাগ, তাঁর ছেলেরা মিলে পান।';

  @override
  String get inheritWhyHinduSonsWidowAsSon =>
      'ছেলে না থাকায় পুত্রবধূ একজন ছেলের সমান ভাগ পান, জীবনস্বত্ব হিসেবে (১৯৩৭ আইন)।';

  @override
  String get inheritWhyHinduSonsWidowAsGrandson =>
      'নিজের ছেলেদের সাথে তিনি তাঁদের একজনের সমান পান, জীবনস্বত্ব হিসেবে (১৯৩৭ আইন)।';

  @override
  String get inheritWhyHinduUnmarriedDaughters =>
      'ছেলে, নাতি বা স্ত্রী না থাকায় অবিবাহিত মেয়েরা সমান ভাগ পান, জীবনস্বত্ব হিসেবে।';

  @override
  String get inheritWhyHinduMarriedDaughters =>
      'অবিবাহিত মেয়ে না থাকায় ছেলে আছে বা হতে পারে এমন বিবাহিত মেয়েরা সমান ভাগ পান, জীবনস্বত্ব হিসেবে।';

  @override
  String get inheritWhyHinduDaughtersSons =>
      'মেয়ের ছেলেরা মাথাপিছু সমান ভাগ পান।';

  @override
  String get inheritWhyHinduFather =>
      'পরবর্তী উত্তরাধিকারী হিসেবে বাবা পুরোটা পান।';

  @override
  String get inheritWhyHinduMother =>
      'পরবর্তী উত্তরাধিকারী হিসেবে মা পুরোটা পান, জীবনস্বত্ব হিসেবে।';

  @override
  String get inheritWhyHinduBrothers =>
      'পরবর্তী উত্তরাধিকারী হিসেবে ভাইয়েরা সমান ভাগ পান (আপন ভাই আগে, সৎ ভাই পরে)।';

  @override
  String get inheritWhyHinduNephews =>
      'পরবর্তী উত্তরাধিকারী হিসেবে ভাতিজারা সমান ভাগ পান।';

  @override
  String get inheritWhyHinduGrandNephews =>
      'পরবর্তী উত্তরাধিকারী হিসেবে ভাতিজার ছেলেরা সমান ভাগ পান।';

  @override
  String get inheritWhyHinduSistersSons =>
      'পরবর্তী উত্তরাধিকারী হিসেবে ভাগ্নেরা সমান ভাগ পান।';

  @override
  String get inheritWhyHinduGrandfather =>
      'পরবর্তী উত্তরাধিকারী হিসেবে দাদা পুরোটা পান।';

  @override
  String get inheritWhyHinduGrandmother =>
      'পরবর্তী উত্তরাধিকারী হিসেবে দাদি পুরোটা পান, জীবনস্বত্ব হিসেবে।';

  @override
  String get inheritWhyHinduUncles =>
      'পরবর্তী উত্তরাধিকারী হিসেবে চাচারা সমান ভাগ পান।';

  @override
  String get inheritWhyHinduCousins =>
      'পরবর্তী উত্তরাধিকারী হিসেবে চাচাতো ভাইয়েরা সমান ভাগ পান।';

  @override
  String get inheritWhyChristianSpouseThird =>
      'সন্তান বা নাতি-নাতনি থাকায় স্বামী/স্ত্রী পান ১/৩ (ধারা ৩৩)।';

  @override
  String get inheritWhyChristianSpouseHalf =>
      'বংশধর নেই, অন্য আত্মীয় আছে: স্বামী/স্ত্রী পান ১/২ (ধারা ৩৩)।';

  @override
  String get inheritWhyChristianSpouseAll =>
      'কোনো আত্মীয় না থাকায় স্বামী/স্ত্রী পুরোটা পান (ধারা ৩৩)।';

  @override
  String get inheritWhyChristianChildren =>
      'ছেলে ও মেয়ে সমান ভাগ পান (ধারা ৩৭)।';

  @override
  String get inheritWhyChristianChildOfDead =>
      'মৃত বাবা/মায়ের ভাগ, সমানভাবে (ধারা ৪০)।';

  @override
  String get inheritWhyChristianGrandchildrenPerHead =>
      'কোনো সন্তান বেঁচে না থাকায় নাতি-নাতনিরা মাথাপিছু সমান পান (ধারা ৩৮)।';

  @override
  String get inheritWhyChristianFather =>
      'বংশধর না থাকায় বাবা বাকি সবটা পান (ধারা ৪২)।';

  @override
  String get inheritWhyChristianMotherAndSiblings =>
      'বাবা না থাকায় মা ও প্রত্যেক ভাই-বোন সমান ভাগ পান (ধারা ৪৩-৪৫)।';

  @override
  String get inheritWhyChristianMother =>
      'বাবা ও ভাই-বোন না থাকায় মা বাকি সবটা পান (ধারা ৪৬)।';

  @override
  String get inheritWhyChristianSiblings =>
      'বাবা-মা না থাকায় ভাই-বোনেরা সমান ভাগ পান, আপন বা সৎ একই (ধারা ৪৭)।';

  @override
  String get inheritWhyChristianSiblingsChildren =>
      'মৃত বাবা/মায়ের ভাগ, সমানভাবে (ধারা ৪৪-৪৭)।';

  @override
  String get inheritWhyChristianNearest =>
      'সবচেয়ে কাছের আত্মীয়েরা মাথাপিছু সমান ভাগ পান (ধারা ৪৮)।';

  @override
  String get inheritNoteHinduLimited =>
      'জীবনস্বত্ব: তিনি ভোগ-দখল করবেন, প্রকৃত প্রয়োজন ছাড়া বিক্রি করতে পারবেন না; তাঁর মৃত্যুর পর সম্পত্তি যায় মৃত ব্যক্তির তখনকার উত্তরাধিকারীদের কাছে, তাঁর নিজের উত্তরাধিকারীদের কাছে নয়।';

  @override
  String get inheritNoteHinduSonsWidow =>
      'মৃত ছেলের স্ত্রী নিজের ছেলেদের পাশে কীভাবে ভাগ পাবেন, তা কোনো মামলায় নিষ্পত্তি হয়নি; এখানে তাঁকে ছেলেদের একজনের সমান ধরা হয়েছে।';

  @override
  String get inheritNoteChristianSpouseAll =>
      'কোনো দূরত্বের কোনো আত্মীয় জীবিত না থাকলেই কেবল স্বামী/স্ত্রী পুরোটা পান; কোনো আত্মীয় থাকলে পান ১/২।';

  @override
  String get inheritNoteChristianPerHead =>
      'কোনো সন্তান বেঁচে না থাকায় নাতি-নাতনিরা পরিবারভিত্তিক নয়, মাথাপিছু সমান পান (ধারা ৩৮)।';

  @override
  String get inheritNoteNoHeirs =>
      'কোনো উত্তরাধিকারী না থাকলে সম্পত্তি সরকারের কাছে যায়।';

  @override
  String get inheritOutMaleLine => 'ছেলে, নাতি বা পুত্রবধূ থাকায়';

  @override
  String get inheritOutWidowFirst =>
      'স্ত্রী জীবিত থাকায় (তাঁর পরে পেতে পারেন)';

  @override
  String get inheritOutUnmarriedDaughter => 'অবিবাহিত মেয়ে থাকায়';

  @override
  String get inheritOutCloserKin => 'আরও কাছের উত্তরাধিকারী থাকায়';

  @override
  String get inheritHeirPaternalAuntConsanguine => 'ফুফু (বৈমাত্রেয়)';

  @override
  String get inheritHeirPaternalAuntUterine => 'ফুফু (বৈপিত্রেয়)';

  @override
  String get inheritHeirFatherUterineBrother => 'বাবার বৈপিত্রেয় ভাই';

  @override
  String get inheritHeirMaternalUncleConsanguine => 'মামা (বৈমাত্রেয়)';

  @override
  String get inheritHeirMaternalUncleUterine => 'মামা (বৈপিত্রেয়)';

  @override
  String get inheritHeirMaternalAuntConsanguine => 'খালা (বৈমাত্রেয়)';

  @override
  String get inheritHeirMaternalAuntUterine => 'খালা (বৈপিত্রেয়)';

  @override
  String inheritChildrenOf(String parent) {
    return '$parent-এর সন্তান';
  }

  @override
  String get inheritDistantTitle => 'দূরের আত্মীয়';

  @override
  String get inheritDistantIntro =>
      'স্বামী/স্ত্রী ছাড়া কোনো অংশীদার বা আসাবা না থাকায় দূরের আত্মীয়রা (যাবিল আরহাম) পান। স্বামী/স্ত্রী নিজের সাধারণ অংশ রাখেন, বাকিটা তাঁদের।';

  @override
  String get inheritSubMaternalGrandfather => 'মায়ের বাবা';

  @override
  String get inheritLineAdd => 'সন্তান রেখে মারা যাওয়া ভাই বা বোন';

  @override
  String get inheritLineAddSub => 'তাঁর সন্তানেরা এখানে পেতে পারেন';

  @override
  String inheritLineTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'মৃত ভাই/বোন · $nString';
  }

  @override
  String get inheritBloodFull => 'আপন';

  @override
  String get inheritBloodConsanguine => 'বৈমাত্রেয়';

  @override
  String get inheritBloodUterine => 'বৈপিত্রেয়';

  @override
  String get inheritLineBrotherSons =>
      'তাঁর ছেলেরা ভাতিজা (আসাবা), এখানের সবার আগে পান — উপরে ভাতিজা হিসেবে যোগ করুন।';

  @override
  String get inheritAuntsHalf => 'সৎ ফুফু, মামা, খালা';

  @override
  String get inheritDistantBeyond =>
      'ফুফাতো, মামাতো, খালাতো ভাই-বোন, চাচাতো বোন বা মেয়ের মেয়ের সন্তানের মতো আরও দূরের আত্মীয় হলে বিশেষজ্ঞের পরামর্শ নিন।';

  @override
  String get inheritWhyDistantKindred =>
      'সবচেয়ে কাছের দূরের আত্মীয় হিসেবে স্বামী/স্ত্রীর অংশের পর বাকিটা পান।';

  @override
  String get inheritWhyDistantSiblingLine =>
      'মৃত বাবা/মা যেভাবে পেতেন সেভাবে, ছেলে মেয়ের দ্বিগুণ (বৈপিত্রেয় ভাই-বোনের সন্তানেরা সমান)।';

  @override
  String get inheritWhyDistantUnclesAunts =>
      'বাবার দিক ২/৩, মায়ের দিক ১/৩; আপন আগে, পুরুষ নারীর দ্বিগুণ।';

  @override
  String get inheritNoteDistantKindred =>
      'স্বামী/স্ত্রী ছাড়া কোনো অংশীদার বা আসাবা না থাকায় দূরের আত্মীয়রা পান — মোল্লার মুসলিম আইন অনুযায়ী (ইমাম মুহাম্মদের নিয়মে)।';

  @override
  String get inheritNoteDistantGrandfather =>
      'মোল্লার বই অনুযায়ী নানাকে ভাই-বোনের সন্তানদের আগে ধরা হয়েছে; একটি পুরোনো গ্রন্থে ভিন্ন ইঙ্গিত আছে। এই ক্ষেত্রে বিশেষজ্ঞের পরামর্শ নিন।';

  @override
  String get inheritNoteDistantAwl =>
      'স্বামী/স্ত্রী ও ভাই-বোনের সন্তানদের অংশ মিলে পুরো সম্পত্তির বেশি হয়েছে; এই ক্ষেত্রের নিয়ম বইয়ে পাওয়া যায়নি। বিশেষজ্ঞের পরামর্শ নিন।';

  @override
  String inheritBaseParts(String n) {
    return 'মোট $n ভাগ';
  }
}
