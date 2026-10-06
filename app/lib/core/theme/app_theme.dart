import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material theme reproducing the Monochrome Impact tokens.
/// No default Material purple — every surface comes from [AppColors].
ThemeData buildAppTheme() {
  final scheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceHighest,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerLow: AppColors.surfaceLow,
    surfaceContainerLowest: AppColors.surfaceLowest,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceTint: AppColors.surfaceTint,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    // NOTE: google_fonts 9 resolves TextTheme via package:material_ui, which
    // is not assignable to Flutter's TextTheme. Apply the family onto the
    // Flutter TextTheme instead; per-style GoogleFonts TextStyles stay.
    textTheme: base.textTheme.apply(fontFamily: 'Poiret One'),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.onSurface,
        foregroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceHighest,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.bebasNeue(fontSize: 12, letterSpacing: 0.6),
      ),
    ),
  );
}
