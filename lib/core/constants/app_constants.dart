class AppConstants {
  // App Info
  static const String appName = 'PlotCalc';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String measurementsBox = 'measurements_box';
  static const String settingsBox = 'settings_box';

  // Unit Conversions
  static const double sqMeterToSqFeet = 10.7639;
  static const double sqMeterToAcre = 0.000247105;
  static const double sqMeterToHectare = 0.0001;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const int animationDuration = 300;

  // Calculation Defaults
  static const int decimalPrecision = 2;
  static const double minShapeArea = 0.01; // sq meters
}

enum MeasurementUnit {
  squareMeters('m²'),
  squareFeet('ft²'),
  acres('acres'),
  hectares('ha');

  final String symbol;
  const MeasurementUnit(this.symbol);
}

enum ShapeType {
  rectangle('Rectangle'),
  triangle('Triangle'),
  circle('Circle'),
  polygon('Custom Polygon');

  final String displayName;
  const ShapeType(this.displayName);
}
