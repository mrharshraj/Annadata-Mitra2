import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monochrome Impact typography:
/// headlines Anton, body Poiret One, labels Bebas Neue.
/// Hindi locale falls back to Noto Sans Devanagari (same sizes/weights)
/// because Anton/Bebas/Poiret lack Devanagari glyphs.
abstract final class AppTextStyles {
  static bool _isHindi(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'hi';

  static TextStyle headlineLg(BuildContext context) {
    if (_isHindi(context)) {
      return GoogleFonts.notoSansDevanagari(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: 0.5,
      );
    }
    return GoogleFonts.anton(fontSize: 48, height: 1.1, letterSpacing: 0.5);
  }

  static TextStyle headlineSm(BuildContext context) {
    if (_isHindi(context)) {
      return GoogleFonts.notoSansDevanagari(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.15,
      );
    }
    return GoogleFonts.anton(fontSize: 24, height: 1.15);
  }

  static TextStyle bodyMd(BuildContext context) {
    if (_isHindi(context)) {
      return GoogleFonts.notoSansDevanagari(fontSize: 16, height: 1.5);
    }
    return GoogleFonts.poiretOne(fontSize: 16, height: 1.5);
  }

  static TextStyle labelMd(BuildContext context) {
    if (_isHindi(context)) {
      return GoogleFonts.notoSansDevanagari(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.8,
      );
    }
    return GoogleFonts.bebasNeue(
      fontSize: 14,
      height: 1.2,
      letterSpacing: 0.8,
    );
  }
}
