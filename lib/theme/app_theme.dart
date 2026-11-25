import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores oficial "Retail Pulse" extraida de DESIGN.md y Stitch.
class AppColors {
  AppColors._();

  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD2D9F4);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);

  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF444651);
  static const Color inverseSurface = Color(0xFF283044);
  static const Color inverseOnSurface = Color(0xFFEEF0FF);
  static const Color outline = Color(0xFF757682);
  static const Color outlineVariant = Color(0xFFC5C5D3);

  static const Color primary = Color(0xFF00236F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color onPrimaryContainer = Color(0xFF90A8FF);
  static const Color primaryFixed = Color(0xFFDCE1FF);
  static const Color primaryFixedDim = Color(0xFFB6C4FF);

  static const Color secondary = Color(0xFF006C49);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color secondaryFixed = Color(0xFF6FFBBE);
  static const Color onSecondaryFixed = Color(0xFF002113);

  static const Color tertiary = Color(0xFF3E2400);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF5C3800);
  static const Color onTertiaryContainer = Color(0xFFEF9900);
  static const Color tertiaryFixed = Color(0xFFFFDDB8);
  static const Color tertiaryFixedDim = Color(0xFFFFB95F);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
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
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.inverseOnSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextStyle displayLgMobile({Color color = AppColors.primary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 36 / 28,
        letterSpacing: -0.56,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.24,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        letterSpacing: -0.20,
        color: color,
      );

  static TextStyle titleLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle titleMd({
    Color color = AppColors.onSurface,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: fontWeight,
        height: 22 / 16,
        color: color,
      );

  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  static TextStyle bodyMd({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: color,
      );

  static TextStyle labelLg({Color color = AppColors.onPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.14,
        color: color,
      );

  static TextStyle labelMd({
    Color color = AppColors.onSurfaceVariant,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: fontWeight,
        height: 16 / 12,
        letterSpacing: 0.24,
        color: color,
      );

  static TextStyle labelSm({
    Color color = AppColors.outline,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: fontWeight,
        height: 14 / 11,
        letterSpacing: 0.33,
        color: color,
      );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}
