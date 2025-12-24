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
