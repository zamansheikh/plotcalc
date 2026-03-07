import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations({required this.locale});

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale: locale);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isEnglish => locale.languageCode == 'en';
  bool get isBengali => locale.languageCode == 'bn';

  // Home & Navigation
  String get appTitle => isEnglish ? 'PlotCalc' : 'প্লটক্যালক';
  String get homeTitle => isEnglish ? 'Land Measurements' : 'ভূমি পরিমাপ';
  String get drawingTitle => isEnglish ? 'Draw Shape' : 'আকৃতি আঁকুন';
  String get historyTitle => isEnglish ? 'History' : 'ইতিহাস';

  // Shapes
  String get selectShape => isEnglish ? 'Select Shape' : 'আকৃতি নির্বাচন করুন';
  String get triangle => isEnglish ? 'Triangle' : 'ত্রিভুজ';
  String get polygon => isEnglish ? 'Polygon' : 'বহুভুজ';
  String get circle => isEnglish ? 'Circle' : 'বৃত্ত';
  String get rectangle => isEnglish ? 'Rectangle' : 'আয়তক্ষেত্র';

  // Measurements
  String get enterMeasurement =>
      isEnglish ? 'Enter Measurement' : 'পরিমাপ লিখুন';
  String get sideLengthInMeters =>
      isEnglish ? 'Enter the length in meters' : 'মিটারে দৈর্ঘ্য লিখুন';
  String get width => isEnglish ? 'Width' : 'প্রস্থ';
  String get height => isEnglish ? 'Height' : 'উচ্চতা';
  String get radius => isEnglish ? 'Radius' : 'ব্যাসার্ধ';
  String get area => isEnglish ? 'Area' : 'ক্ষেত্রফল';
  String get squareMeters => isEnglish ? 'm²' : 'বর্গমিটার';

  // Buttons
  String get calculate => isEnglish ? 'Calculate' : 'গণনা করুন';
  String get complete => isEnglish ? 'Complete' : 'সম্পূর্ণ করুন';
  String get undo => isEnglish ? 'Undo' : 'পূর্ববর্তী';
  String get clear => isEnglish ? 'Clear' : 'পরিষ্কার করুন';
  String get infoPortal => isEnglish ? 'Information Portal' : 'তথ্য বাতায়ন';
  String get landKhatiyan => isEnglish ? 'Land Khatiyan' : 'জমির খতিয়ান';
  String get ok => isEnglish ? 'OK' : 'ঠিক আছে';
  String get skip => isEnglish ? 'Skip' : 'এড়িয়ে যান';
  String get cancel => isEnglish ? 'Cancel' : 'বাতিল করুন';
  String get delete => isEnglish ? 'Delete' : 'মুছুন';
  String get save => isEnglish ? 'Save' : 'সংরক্ষণ করুন';

  // Messages
  String get enterValidWidthHeight => isEnglish
      ? 'Please enter valid width and height'
      : 'অনুগ্রহ করে বৈধ প্রস্থ এবং উচ্চতা লিখুন';
  String get enterValidRadius => isEnglish
      ? 'Please enter valid radius'
      : 'অনুগ্রহ করে বৈধ ব্যাসার্ধ লিখুন';
  String get addThreePoints => isEnglish
      ? 'Please add at least 3 points'
      : 'অনুগ্রহ করে কমপক্ষে ৩টি পয়েন্ট যোগ করুন';
  String get noPoints =>
      isEnglish ? 'No points provided' : 'কোনো পয়েন্ট প্রদান করা হয়নি';
  String get triangleRequires3Points => isEnglish
      ? 'Triangle requires 3 points'
      : 'ত্রিভুজের জন্য ৩টি পয়েন্ট প্রয়োজন';
  String get polygonRequires3Points => isEnglish
      ? 'Polygon requires at least 3 points'
      : 'বহুভুজের জন্য কমপক্ষে ৩টি পয়েন্ট প্রয়োজন';
  String get rectangleRequiresWidthHeight => isEnglish
      ? 'Rectangle requires width and height'
      : 'আয়তক্ষেত্রের জন্য প্রস্থ এবং উচ্চতা প্রয়োজন';
  String get circleRequiresRadius =>
      isEnglish ? 'Circle requires radius' : 'বৃত্তের জন্য ব্যাসার্ধ প্রয়োজন';
  String get areaTooSmall => isEnglish ? 'Area too small' : 'ক্ষেত্রফল খুব ছোট';
  String get failedToCalculateArea =>
      isEnglish ? 'Failed to calculate area' : 'ক্ষেত্রফল গণনা করতে ব্যর্থ';
  String get measurementSaved =>
      isEnglish ? 'Measurement saved' : 'পরিমাপ সংরক্ষিত হয়েছে';
  String get measurementDeleted =>
      isEnglish ? 'Measurement deleted' : 'পরিমাপ মুছে ফেলা হয়েছে';
  String get noMeasurements =>
      isEnglish ? 'No measurements yet' : 'এখনো কোনো পরিমাপ নেই';

  // Land Units
  String get acre => isEnglish ? 'Acre' : 'একর';
  String get bigha => isEnglish ? 'Bigha' : 'বিঘা';
  String get katha => isEnglish ? 'Katha' : 'কাঠা';
  String get shatak => isEnglish ? 'Shatak' : 'শতাংশ';
  String get shotok => isEnglish ? 'Shotok' : 'শতক';
  String get lessThan1Shotok =>
      isEnglish ? 'Less than 1 shotok' : 'শতকের চেয়ে কম';

  // Additional Land Units
  String get bighaMymensingh =>
      isEnglish ? 'Bigha (Mymensingh)' : 'বিঘা (ময়মনসিংহ)';
  String get kathaMymensingh =>
      isEnglish ? 'Katha (Mymensingh)' : 'কাঠা (ময়মনসিংহ)';
  String get bighaStandard =>
      isEnglish ? 'Bigha (Standard)' : 'বিঘা (স্ট্যান্ডার্ড)';
  String get kathaStandard =>
      isEnglish ? 'Katha (Standard)' : 'কাঠা (স্ট্যান্ডার্ড)';
  String get chotak => isEnglish ? 'Chotak' : 'ছটাক';
  String get gonda => isEnglish ? 'Gonda' : 'গণ্ডা';
  String get kora => isEnglish ? 'Kora' : 'কড়া';
  String get kranti => isEnglish ? 'Kranti' : 'ক্রান্তি';
  String get til => isEnglish ? 'Til' : 'তিল';

  // Land Calculator Page
  String get landCalculator =>
      isEnglish ? 'Land Calculator' : 'ভূমি ক্যালকুলেটর';
  String get resetUnits => isEnglish ? 'Reset Units' : 'ইউনিট রিসেট করুন';
  String get totalArea => isEnglish ? 'Total Area' : 'মোট এলাকা';
  String get enterValue => isEnglish ? 'Enter value...' : 'মান লিখুন...';
  String get convertBetweenUnits => isEnglish
      ? 'Convert between different area units'
      : 'বিভিন্ন এলাকা ইউনিটের মধ্যে রূপান্তর করুন';
  String get convertInstantly => isEnglish
      ? 'Convert area units instantly'
      : 'তাত্ক্ষণিকভাবে এলাকা ইউনিট রূপান্তর করুন';

  // Drawing Page
  String get editSideMeasurements =>
      isEnglish ? 'Edit Side Measurements' : 'পাশের পরিমাপ সম্পাদনা করুন';
  String get addAtLeast2Points => isEnglish
      ? 'Add at least 2 points to see sides'
      : 'পাশগুলি দেখতে কমপক্ষে ২টি পয়েন্ট যোগ করুন';
  String get done => isEnglish ? 'Done' : 'সম্পন্ন';
  String get completePolygon =>
      isEnglish ? 'Complete Polygon' : 'বহুভুজ সম্পূর্ণ করুন';

  // History Page
  String get measurementHistory =>
      isEnglish ? 'Measurement History' : 'পরিমাপ ইতিহাস';
  String get startMeasuring => isEnglish
      ? 'Start measuring to see your history'
      : 'আপনার ইতিহাস দেখতে পরিমাপ শুরু করুন';
  String get newMeasurement => isEnglish ? 'New Measurement' : 'নতুন পরিমাপ';
  String get retry => isEnglish ? 'Retry' : 'পুনরায় চেষ্টা করুন';
  String get view => isEnglish ? 'View' : 'দেখুন';
  String get yesterday => isEnglish ? 'Yesterday' : 'গতকাল';
  String get created => isEnglish ? 'Created' : 'তৈরি';
  String get points => isEnglish ? 'Points' : 'পয়েন্ট';
  String get close => isEnglish ? 'Close' : 'বন্ধ করুন';
  String get areaInDifferentUnits =>
      isEnglish ? 'Area in different units:' : 'বিভিন্ন ইউনিটে ক্ষেত্রফল:';
  String get breakdown => isEnglish ? 'Breakdown:' : 'বিশ্লেষণ:';
  String get deleteMeasurement =>
      isEnglish ? 'Delete Measurement' : 'পরিমাপ মুছুন';
  String get deleteConfirmation => isEnglish
      ? 'Are you sure you want to delete this measurement? This action cannot be undone.'
      : 'আপনি কি এই পরিমাপটি মুছতে নিশ্চিত? এই কর্ম পূর্বাবস্থায় ফেরানো যাবে না।';

  // Settings
  String get settings => isEnglish ? 'Settings' : 'সেটিংস';
  String get language => isEnglish ? 'Language' : 'ভাষা';
  String get english => isEnglish ? 'English' : 'ইংরেজি';
  String get bengali => isEnglish ? 'Bengali' : 'বাংলা';

  // Measurement Unit
  String get measurementUnit => isEnglish ? 'Measurement Unit' : 'পরিমাপ ইউনিট';
  String get metersTitle => isEnglish ? 'Meters (m)' : 'মিটার (মি)';
  String get feetTitle => isEnglish ? 'Feet (ft)' : 'ফুট (ফি)';
  String get useMetersDescription => isEnglish
      ? 'Use meters for all measurements'
      : 'সমস্ত পরিমাপের জন্য মিটার ব্যবহার করুন';
  String get useFeetDescription => isEnglish
      ? 'Use feet for all measurements'
      : 'সমস্ত পরিমাপের জন্য ফুট ব্যবহার করুন';
  String get languageChangedTo =>
      isEnglish ? 'Language changed to' : 'ভাষা পরিবর্তিত হয়েছে';
  String get measurementUnitChanged => isEnglish
      ? 'Measurement unit changed to'
      : 'পরিমাপ ইউনিট পরিবর্তিত হয়েছে';

  // Additional Dialog & Button Texts
  String get viewShape => isEnglish ? 'View Shape' : 'আকৃতি দেখুন';
  String get diagonalMeasurementsTitle =>
      isEnglish ? 'Diagonal Measurements' : 'কর্ণ পরিমাপ';
  String get diagonalMeasurementsRequired =>
      isEnglish ? 'Required' : 'প্রয়োজনীয়';

  // Calculator & Converter
  String get calculator => isEnglish ? 'Calculator' : 'ক্যালকুলেটর';
  String get unitConverter => isEnglish ? 'Unit Converter' : 'ইউনিট কনভার্টার';
  String get enterAreaValue =>
      isEnglish ? 'Enter area value' : 'এলাকার মান লিখুন';
  String get convertFrom => isEnglish ? 'Convert From' : 'থেকে রূপান্তর করুন';
  String get convertTo => isEnglish ? 'Convert To' : 'এতে রূপান্তর করুন';
  String get result => isEnglish ? 'Result' : 'ফলাফল';
  String get selectUnit => isEnglish ? 'Select Unit' : 'ইউনিট নির্বাচন করুন';
  String get squareFeet => isEnglish ? 'Square Feet (ft²)' : 'বর্গফুট (ফি²)';
  String get hectares => isEnglish ? 'Hectares (ha)' : 'হেক্টর (হে)';
  String get acres => isEnglish ? 'Acres (ac)' : 'একর (ac)';

  // Resize Feature
  String get resizeArea => isEnglish ? 'Resize Area' : 'এলাকা পরিবর্তন করুন';
  String get enterTargetArea => isEnglish
      ? 'Enter target area (combine multiple units if needed):'
      : 'লক্ষ্য এলাকা লিখুন (প্রয়োজনে একাধিক ইউনিট একত্রিত করুন):';
  String get resize => isEnglish ? 'Resize' : 'পরিবর্তন করুন';
  String get targetAreaAdjustment =>
      isEnglish ? 'Target Area Adjustment' : 'লক্ষ্য এলাকা সমন্বয়';
  String get adjustShapeDescription => isEnglish
      ? 'Adjust shape to a specific area (e.g., 1 Acre).'
      : 'একটি নির্দিষ্ট এলাকায় আকৃতি সমন্বয় করুন (যেমন, ১ একর)।';
  String get expandShrinkToTarget => isEnglish
      ? 'Expand/Shrink to Target Area'
      : 'লক্ষ্য এলাকায় প্রসারিত/সংকুচিত করুন';
  String get resizeMode => isEnglish ? 'Resize Mode' : 'পরিবর্তন মোড';
  String get applyResize =>
      isEnglish ? 'Apply Resize' : 'পরিবর্তন প্রয়োগ করুন';
  String get resizeInstruction => isEnglish
      ? 'Select points to move. Unselected points will stay fixed.'
      : 'সরানোর জন্য পয়েন্ট নির্বাচন করুন। অনির্বাচিত পয়েন্ট স্থির থাকবে।';
  String get apply => isEnglish ? 'Apply' : 'প্রয়োগ করুন';
  String get circleResized => isEnglish
      ? 'Circle resized successfully.'
      : 'বৃত্ত সফলভাবে পরিবর্তন করা হয়েছে।';

  // Unit Configuration
  String get unitConfiguration =>
      isEnglish ? 'Unit Configuration' : 'ইউনিট কনফিগারেশন';
  String get dragToReorder => isEnglish
      ? 'Drag to reorder. Uncheck to hide.'
      : 'পুনরায় সাজাতে টেনে আনুন। লুকাতে আনচেক করুন।';

  // Instructions
  String get tapToAdd3Points => isEnglish
      ? 'Tap to add 3 points for'
      : 'এর জন্য ৩টি পয়েন্ট যোগ করতে ট্যাপ করুন';
  String get tapCompleteToClose => isEnglish
      ? 'Tap "Complete" to close the polygon, or keep adding points'
      : '"সম্পূর্ণ করুন" ট্যাপ করে বহুভুজ বন্ধ করুন, অথবা পয়েন্ট যোগ করা চালিয়ে যান';
  String get tapToAddPointsMin3 => isEnglish
      ? 'Tap to add points (minimum 3)'
      : 'পয়েন্ট যোগ করতে ট্যাপ করুন (কমপক্ষে ৩টি)';

  // Khotiyan Calculator
  String get khotiyanCalculator =>
      isEnglish ? 'Khotiyan Calculator' : 'খতিয়ান ক্যালকুলেটর';
  String get selectUnits => isEnglish ? 'Select Units' : 'একক নির্বাচন করুন';
  String get totalLand => isEnglish ? 'Total Land' : 'মোট জমি';
  String get amount => isEnglish ? 'Amount' : 'পরিমাণ';
  String get unit => isEnglish ? 'Unit' : 'একক';
  String get calculateShare =>
      isEnglish ? 'Calculate Land Share' : 'জমির হিস্যা গণনা করুন';
  String get selectUnitsSubtitle => isEnglish
      ? 'Select units to find Hissya & Land Amount'
      : 'হিস্যা এবং জমির পরিমাণ বের করতে একক নির্বাচন করুন';
  String get results => isEnglish ? 'Results' : 'ফলাফল';
  String get hissya => isEnglish ? 'Hissya (Share)' : 'হিস্যা (অংশ)';
  String get yourLand => isEnglish ? 'Your Land Share' : 'আপনার প্রাপ্ত জমি';
  String get ana => isEnglish ? 'Ana' : 'আনা';

  // Compound Units & New UI
  String get feet => isEnglish ? 'Feet' : 'ফুট';
  String get inches => isEnglish ? 'Inches' : 'ইঞ্চি';
  String get meters => isEnglish ? 'Meters' : 'মিটার';
  String get cm => isEnglish ? 'Cm' : 'সেমি';
  String get switchedToCompound => isEnglish
      ? 'Switched to Compound Units (e.g. 5\' 6")'
      : 'যৌগিক এককে পরিবর্তিত হয়েছে (যেমন ৫\' ৬")';
  String get switchedToDecimal => isEnglish
      ? 'Switched to Decimal Units (e.g. 5.5)'
      : 'দশমিক এককে পরিবর্তিত হয়েছে (যেমন ৫.৫)';
  String get point => isEnglish ? 'Point' : 'পয়েন্ট';
  String get to => isEnglish ? 'to' : 'থেকে';
  String get count => isEnglish ? 'Count' : 'সংখ্যা';
  String get measurements => isEnglish ? 'Measurements' : 'পরিমাপ';
  String get toggleUnitFormat =>
      isEnglish ? 'Toggle Unit Format' : 'একক বিন্যাস পরিবর্তন করুন';

  // Move Mode (Legacy)
  String get movePointsSides =>
      isEnglish ? 'Move Points/Sides' : 'বিন্দু/বাহু সরান';
  String get selectCornerToMove =>
      isEnglish ? 'Select Corner to Move:' : 'সরানোর জন্য কোণ নির্বাচন করুন:';
  String get range => isEnglish ? 'Range:' : 'সীমা:';
  String get horizontal =>
      isEnglish ? 'Horizontal (Left/Right)' : 'অনুভূমিক (বাম/ডান)';
  String get vertical => isEnglish ? 'Vertical (Up/Down)' : 'উল্লম্ব (উপর/নিচ)';
  String get applyMove => isEnglish ? 'Apply Move' : 'সরানো প্রয়োগ করুন';
  String get moveApplied => isEnglish
      ? 'Move applied. Measurements updated.'
      : 'সরানো হয়েছে। পরিমাপ আপডেট করা হয়েছে।';
  String get autoCalculatedDiagonals => isEnglish
      ? 'Auto-calculated missing diagonals from shape.'
      : 'আকৃতি থেকে অনুপস্থিত কর্ণ স্বয়ংক্রিয়ভাবে গণনা করা হয়েছে।';

  // Edit Side Mode (kept for side tap editing)
  String get editSide => isEnglish ? 'Edit Side' : 'বাহু সম্পাদনা';
  String get editSideLength =>
      isEnglish ? 'Edit Side Length' : 'বাহুর দৈর্ঘ্য সম্পাদনা';
  String get currentLength => isEnglish ? 'Current Length' : 'বর্তমান দৈর্ঘ্য';
  String get newLength => isEnglish ? 'New Length' : 'নতুন দৈর্ঘ্য';
  String get sideUpdated => isEnglish
      ? 'Side updated successfully.'
      : 'বাহু সফলভাবে আপডেট করা হয়েছে।';
  String get doneEditing => isEnglish ? 'Done Editing' : 'সম্পাদনা সম্পন্ন';

  // Adjust Mode (Land Adjustment)
  String get adjustMode => isEnglish ? 'Adjust Land' : 'জমি সমন্বয়';
  String get tapPointToMove => isEnglish
      ? 'Tap a corner point to move it'
      : 'সরাতে একটি কোণার পয়েন্টে ট্যাপ করুন';
  String get movePoint => isEnglish ? 'Move Point' : 'পয়েন্ট সরান';
  String get direction => isEnglish ? 'Direction' : 'দিক';
  String get distance => isEnglish ? 'Distance' : 'দূরত্ব';
  String get targetArea => isEnglish ? 'Target Area' : 'লক্ষ্য এলাকা';
  String get setTargetArea =>
      isEnglish ? 'Set Target Area' : 'লক্ষ্য এলাকা সেট করুন';
  String get currentArea => isEnglish ? 'Current Area' : 'বর্তমান এলাকা';
  String get remaining => isEnglish ? 'Remaining' : 'বাকি';
  String get exceeded => isEnglish ? 'Exceeded' : 'অতিক্রম';
  String get pointMoved => isEnglish
      ? 'Point moved. Measurements updated.'
      : 'পয়েন্ট সরানো হয়েছে। পরিমাপ আপডেট করা হয়েছে।';
  String get targetReached =>
      isEnglish ? 'Target area reached!' : 'লক্ষ্য এলাকায় পৌঁছেছে!';
  String get up => isEnglish ? 'Up' : 'উপরে';
  String get down => isEnglish ? 'Down' : 'নিচে';
  String get left => isEnglish ? 'Left' : 'বাম';
  String get right => isEnglish ? 'Right' : 'ডান';
  String get upLeft => isEnglish ? 'Up-Left' : 'উপর-বাম';
  String get upRight => isEnglish ? 'Up-Right' : 'উপর-ডান';
  String get downLeft => isEnglish ? 'Down-Left' : 'নিচ-বাম';
  String get downRight => isEnglish ? 'Down-Right' : 'নিচ-ডান';
  String get enterTargetAreaValue =>
      isEnglish ? 'Enter target area' : 'লক্ষ্য এলাকা লিখুন';
  String get optional => isEnglish ? 'Optional' : 'ঐচ্ছিক';
  String get adjustDone => isEnglish ? 'Done Adjusting' : 'সমন্বয় সম্পন্ন';
  String get autoCompleteSide => isEnglish
      ? 'Tap a side to auto-complete to target'
      : 'লক্ষ্যে পৌঁছাতে একটি বাহুতে ট্যাপ করুন';
  String get autoComplete =>
      isEnglish ? 'Auto-Complete' : 'স্বয়ংক্রিয় সম্পূর্ণ';
  String get sideAutoCompleted => isEnglish
      ? 'Side adjusted to reach target area.'
      : 'লক্ষ্য এলাকায় পৌঁছাতে বাহু সমন্বয় করা হয়েছে।';
  String get nearTarget => isEnglish
      ? 'Almost there! Tap a side to auto-complete.'
      : 'প্রায় পৌঁছে গেছে! স্বয়ংক্রিয় সম্পূর্ণ করতে একটি বাহুতে ট্যাপ করুন।';
  String get selectAutoCompleteDirection => isEnglish
      ? 'Select direction to auto-adjust'
      : 'স্বয়ংক্রিয় সমন্বয়ের দিক নির্বাচন করুন';
  String get breakdownInput =>
      isEnglish ? 'Breakdown Input' : 'ব্রেকডাউন ইনপুট';
  String get compoundTarget => isEnglish
      ? 'Set target using multiple units'
      : 'একাধিক ইউনিট ব্যবহার করে লক্ষ্য সেট করুন';
  String get areaDetails => isEnglish ? 'Area Details' : 'এলাকার বিবরণ';
  String get standardUnits => isEnglish ? 'Standard' : 'স্ট্যান্ডার্ড';
  String get mymensinghUnits => isEnglish ? 'Mymensingh' : 'ময়মনসিংহ';
  String get enterShatakValue =>
      isEnglish ? 'Enter target in Shatak' : 'শতাংশে লক্ষ্য দিন';
  String get tapToSeeDetails =>
      isEnglish ? 'Tap to see details' : 'বিস্তারিত দেখতে ট্যাপ করুন';

  // Home Page
  String get quickStart => isEnglish ? 'Quick Start' : 'দ্রুত শুরু';
  String get tools => isEnglish ? 'Tools' : 'টুলস';
  String get drawShapeDesc => isEnglish
      ? 'Draw & measure any land shape'
      : 'যেকোনো জমির আকৃতি আঁকুন ও পরিমাপ করুন';
  String get unitConverterDesc =>
      isEnglish ? 'Convert between area units' : 'এলাকা ইউনিট রূপান্তর করুন';
  String get landCalculatorDesc =>
      isEnglish ? 'Calculate land area breakdown' : 'জমির ক্ষেত্রফল বিশ্লেষণ';
  String get khotiyanDesc =>
      isEnglish ? 'Calculate land shares' : 'জমির হিস্যা গণনা করুন';
  String get infoPortalDesc =>
      isEnglish ? 'Land information & guides' : 'জমির তথ্য ও নির্দেশিকা';

  // History & Save
  String get rename => isEnglish ? 'Rename' : 'নাম পরিবর্তন';
  String get renameMeasurement =>
      isEnglish ? 'Rename Measurement' : 'পরিমাপের নাম পরিবর্তন';
  String get enterName => isEnglish ? 'Enter name' : 'নাম লিখুন';
  String get measurementName => isEnglish ? 'Measurement Name' : 'পরিমাপের নাম';
  String get saveMeasurement =>
      isEnglish ? 'Save Measurement' : 'পরিমাপ সংরক্ষণ';
  String get nameOptional => isEnglish ? 'Name (optional)' : 'নাম (ঐচ্ছিক)';
  String get measurementRenamed =>
      isEnglish ? 'Measurement renamed' : 'পরিমাপের নাম পরিবর্তিত হয়েছে';
  String get aboutDeveloper =>
      isEnglish ? 'About Developer' : 'ডেভেলপার সম্পর্কে';
  String get appInfoContact => isEnglish
      ? 'App info & developer contact'
      : 'অ্যাপ তথ্য ও ডেভেলপার যোগাযোগ';
  String get fullStackDeveloper =>
      isEnglish ? 'Full Stack Developer' : 'ফুল স্ট্যাক ডেভেলপার';

  String missingDiagonalsMessage(int sides, int required, int measured) =>
      isEnglish
      ? 'For a $sides-sided polygon, you need $required diagonal(s) for exact calculation. You have measured $measured.'
      : '$sides-বাহু বিশিষ্ট বহুভুজের সঠিক গণনার জন্য $required টি কর্ণের পরিমাপ প্রয়োজন। আপনি $measured টি পরিমাপ করেছেন।';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'bn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
