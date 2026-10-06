import 'package:flutter/material.dart';

/// Monochrome Impact palette — exact values from
/// `stitch_new_project_setup/.../monochrome_impact/DESIGN.md`.
abstract final class AppColors {
  static const Color surface = Color(0xFFFBF9F9);
  static const Color surfaceBright = Color(0xFFFBF9F9);
  static const Color background = Color(0xFFFBF9F9);
  static const Color surfaceDim = Color(0xFFDBDAD9);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF5F3F3);
  static const Color surfaceContainer = Color(0xFFEFEDED);
  static const Color surfaceHigh = Color(0xFFE9E8E7);
  static const Color surfaceHighest = Color(0xFFE3E2E2);
  static const Color surfaceVariant = Color(0xFFE3E2E2);

  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF444748);
  static const Color onBackground = Color(0xFF1B1C1C);
  static const Color inverseSurface = Color(0xFF303031);
  static const Color inverseOnSurface = Color(0xFFF2F0F0);

  static const Color outline = Color(0xFF747878);
  static const Color outlineVariant = Color(0xFFC4C7C7);
  static const Color surfaceTint = Color(0xFF5E5E5E);

  static const Color primary = Color(0xFF5C5C5C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF747474);
  static const Color onPrimaryContainer = Color(0xFFFEFCFC);
  static const Color inversePrimary = Color(0xFFC7C6C6);

  static const Color secondary = Color(0xFF5E5E5E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE3E2E2);
  static const Color onSecondaryContainer = Color(0xFF646464);

  static const Color tertiary = Color(0xFF5C5C5C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF747474);
  static const Color onTertiaryContainer = Color(0xFFFEFCFC);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}
