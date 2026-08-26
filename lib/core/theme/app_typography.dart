import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static String? _banglaFamily;

  /// Inter and JetBrains Mono carry no Bengali glyphs, so the Bengali
  /// land-record articles would render as tofu boxes. Registering Noto Sans
  /// Bengali once and appending it to every fallback chain fixes Bengali text
  /// app-wide without each call site having to know the script.
  static void registerBanglaFallback() {
    _banglaFamily = GoogleFonts.notoSansBengali().fontFamily;
  }

  static List<String>? get _fallback =>
      _banglaFamily == null ? null : [_banglaFamily!];

  /// Bengali-first face, for content known to be Bengali.
  static TextStyle bangla({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double letterSpacing = 0,
    double height = 1.7,
  }) {
    return GoogleFonts.notoSansBengali(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double letterSpacing = 0,
    double height = 1.2,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ).copyWith(fontFamilyFallback: _fallback);
  }

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double letterSpacing = 0,
    double height = 1.2,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ).copyWith(fontFamilyFallback: _fallback);
  }

  static TextStyle get displayMono => mono(
        size: 38,
        weight: FontWeight.w500,
        color: AppColors.lime,
        letterSpacing: -1.1,
      );

  static TextStyle get heroTitle => sans(
        size: 28,
        weight: FontWeight.w600,
        letterSpacing: -0.84,
      );

  static TextStyle get sectionTitle => sans(
        size: 24,
        weight: FontWeight.w600,
        letterSpacing: -0.72,
        height: 1.15,
      );

  static TextStyle get bodyDim => sans(
        size: 13,
        color: AppColors.textDim,
      );

  static TextStyle get monoCaption => mono(
        size: 11,
        color: AppColors.textFaint,
        letterSpacing: 1.32,
      );

  static TextStyle get monoLabel => mono(
        size: 10,
        color: AppColors.textFaint,
        letterSpacing: 1.2,
      );

  static TextStyle get monoSmall => mono(
        size: 9,
        color: AppColors.textFaint,
        letterSpacing: 0.9,
      );
}
