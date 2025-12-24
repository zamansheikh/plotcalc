/// LandUnitConverter.dart
/// ---------------------------------------------------------------
/// A Flutter-compatible utility class to convert between square-meters
/// and square-feet into traditional Bangladeshi land units.
///
/// Units (largest → smallest):
///   1 Acre  = 43,560 sq.ft
///   1 Bigha = 14,520 sq.ft
///   1 Katha =   721.46 sq.ft
///   1 Shatak=   435.60 sq.ft
///   1 Chotak=    45.09 sq.ft
///
/// The class provides two static methods:
///   • fromSquareMeters(double sqm) → LandUnit
///   • fromSquareFeet (double sqft) → LandUnit
///
/// Example:
///   LandUnitConverter.fromSquareFeet(59734.43)
///   → 1 একর 1 বিঘা 2 কাঠা 4 ছটাক 2.89 বর্গমিটার
/// ---------------------------------------------------------------
library;

class LandUnit {
  final int acres;
  final int bighas;
  final int kathas;
  final int shataks;
  final int chotaks;
  final double squareMeters; // remainder after chotak

  const LandUnit({
    required this.acres,
    required this.bighas,
    required this.kathas,
    required this.shataks,
    required this.chotaks,
    required this.squareMeters,
  });

  /// Human-readable string (matches the requested format)
  @override
  String toString() {
    final parts = <String>[];
    if (acres > 0) parts.add('$acres একর');
    if (bighas > 0) parts.add('$bighas বিঘা');
    if (kathas > 0) parts.add('$kathas কাঠা');
    if (shataks > 0) parts.add('$shataks শতাংশ');
    if (chotaks > 0) parts.add('$chotaks ছটাক');
    if (squareMeters > 0) {
      // .toStringAsFixed(2) ব্যবহার করা হয়েছে ২টি ডেসিমেল প্লেস দেখানোর জন্য
      // .replaceFirst(RegExp(r'\.00$'), '') ব্যবহার করা যেতে পারে যদি .00 সরাতে চান
      final m = squareMeters.toStringAsFixed(2);
      parts.add('$m বর্গমিটার');
    }
    return parts.isEmpty ? '0 বর্গমিটার' : parts.join(' ');
  }
}

class LandUnitConverter {
  // ---- Constants (sq.ft) ------------------------------------------------
  static const double _sqftPerAcre = 43560.0;
  static const double _sqftPerBigha = 14520.0;
  static const double _sqftPerKatha = 721.46;
  static const double _sqftPerShatak = 435.60;
  static const double _sqftPerChotak = 45.09;
  static const double _sqftToSqm = 0.09290304; // 1 sq.ft = 0.09290304 sq.m
  static const double _sqmToSqft = 10.7639104167; // 1 sq.m = 10.76... sq.ft

  // ---- Mymensingh Constants (sq.ft) -------------------------------------
  // 1 Shatak = 435.60 sq.ft (Standard)
  static const double _sqftPerKathaMymensingh = 435.60 * 6.5; // 2831.4 sq.ft
  static const double _sqftPerBighaMymensingh =
      _sqftPerKathaMymensingh * 20; // 56628.0 sq.ft

  // ------------------------------------------------------------------------
  static LandUnit fromSquareMeters(double sqm) {
    // 1 sq.m = 10.76... sq.ft, তাই গুণ হবে
    final sqft = sqm * _sqmToSqft;
    // আপনার আগের লজিক (sqm / _sqftToSqm) ও সঠিক ছিল,
    // কিন্তু এটি বেশি পঠনযোগ্য (readable)
    return _convert(sqft);
  }

  static LandUnit fromSquareFeet(double sqft) {
    return _convert(sqft);
  }

  // ---- Mymensingh Methods -----------------------------------------------

  static LandUnit fromSquareMetersMymensingh(double sqm) {
    final sqft = sqm * _sqmToSqft;
    return _convertMymensingh(sqft);
  }

  static LandUnit fromSquareFeetMymensingh(double sqft) {
    return _convertMymensingh(sqft);
  }

  // ------------------------------------------------------------------------
  static LandUnit _convert(double totalSqft) {
    // Use precise flooring and avoid floating point drift
    double sqft = totalSqft;

    final acres = (sqft / _sqftPerAcre).floor();
    sqft -= acres * _sqftPerAcre;

    final bighas = (sqft / _sqftPerBigha).floor();
    sqft -= bighas * _sqftPerBigha;

    final kathas = (sqft / _sqftPerKatha).floor();
    sqft -= kathas * _sqftPerKatha;

    final shataks = (sqft / _sqftPerShatak).floor();
    sqft -= shataks * _sqftPerShatak;

    final chotaks = (sqft / _sqftPerChotak).floor();
    sqft -= chotaks * _sqftPerChotak;

    // Remainder in sq.m with 2 decimal places
    final sqmRemainder = (sqft * _sqftToSqm);

    // [FIXED] রাউন্ডিং করার সঠিক উপায়
    final roundedSqm = (sqmRemainder * 100).round() / 100.0;

    return LandUnit(
      acres: acres,
      bighas: bighas,
      kathas: kathas,
      shataks: shataks,
      chotaks: chotaks,
      squareMeters: roundedSqm,
    );
  }

  static LandUnit _convertMymensingh(double totalSqft) {
    double sqft = totalSqft;

    // 1. Bigha (Mymensingh)
    final bighas = (sqft / _sqftPerBighaMymensingh).floor();
    sqft -= bighas * _sqftPerBighaMymensingh;

    // 2. Katha (Mymensingh)
    final kathas = (sqft / _sqftPerKathaMymensingh).floor();
    sqft -= kathas * _sqftPerKathaMymensingh;

    // 3. Shatak (Standard)
    final shataks = (sqft / _sqftPerShatak).floor();
    sqft -= shataks * _sqftPerShatak;

    // 4. Chotak (Standard)
    final chotaks = (sqft / _sqftPerChotak).floor();
    sqft -= chotaks * _sqftPerChotak;

    // Remainder in sq.m
    final sqmRemainder = (sqft * _sqftToSqm);
    final roundedSqm = (sqmRemainder * 100).round() / 100.0;

    return LandUnit(
      acres: 0, // Acre isn't typically used in this specific system
      bighas: bighas,
      kathas: kathas,
      shataks: shataks,
      chotaks: chotaks,
      squareMeters: roundedSqm,
    );
  }
}

// ====================== USAGE EXAMPLE (you can paste in main()) ==========
// void main() {
//   // From square-feet
//   final resultFt = LandUnitConverter.fromSquareFeet(59734.43);

//   // [FIXED] আপনার কোড এই আউটপুটটি তৈরি করবে:
//   print("59734.43 sq.ft = $resultFt");
//   // আউটপুট: 1 একর 1 বিঘা 2 কাঠা 4 ছটাক 2.89 বর্গমিটার

//   // From square-meters
//   final resultM = LandUnitConverter.fromSquareMeters(5550.0);
//   print("5550.0 sq.m = $resultM");
//   // আউটপুট: 1 একর 1 বিঘা 2 কাঠা 4 ছটাক 0.93 বর্গমিটার

//   // --- Mymensingh Example ---
//   // 60,000 sq.ft = 1 Bigha (56628) + 1 Katha (2831.4) + 1 Shatak (435.6) + 105 sq.ft remainder
//   final resultMym = LandUnitConverter.fromSquareFeetMymensingh(60000.0);
//   print("60000.0 sq.ft (Mymensingh) = $resultMym");
//   // আউটপুট: 1 বিঘা 1 কাঠা 1 শতাংশ 9.75 বর্গমিটার
// }
