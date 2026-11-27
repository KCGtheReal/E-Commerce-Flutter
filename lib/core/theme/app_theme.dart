import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  /// The top AnnouncementBar stays Onyx Black (#111111) behind the status bar
  /// in both light and dark modes, so system status icons must remain light.
  static SystemUiOverlayStyle systemOverlayStyle({
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? ResetPalette.dark : ResetPalette.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: palette.scaffoldBackground,
      systemNavigationBarDividerColor: palette.borderSubtle,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  static TextStyle displayStyle({
    required String locale,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    final isKm = locale == 'km';
    final effectiveHeight = height ?? (isKm ? 1.45 : 1.18);
    final effectiveSpacing = isKm ? 0.0 : letterSpacing;

    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: isKm ? 'Kantumruy Pro' : 'Space Grotesk',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: effectiveSpacing,
        height: effectiveHeight,
      );
    }

    return isKm
        ? GoogleFonts.kantumruyPro(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: effectiveSpacing,
            height: effectiveHeight,
          )
        : GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: effectiveSpacing,
            height: effectiveHeight,
          );
  }

  static TextStyle bodyStyle({
    required String locale,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    final isKm = locale == 'km';
    final effectiveHeight = height ?? (isKm ? 1.62 : 1.5);

    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'Kantumruy Pro',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: effectiveHeight,
      );
    }

    return GoogleFonts.kantumruyPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: effectiveHeight,
    );
  }

  static TextStyle monoStyle({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    const features = <FontFeature>[FontFeature.tabularFigures()];
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: features,
      );
    }
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: features,
    );
  }

  static ThemeData build({
    required Brightness brightness,
    required String locale,
  }) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? ResetPalette.dark : ResetPalette.light;
    final isKm = locale == 'km';

    final baseScheme = ColorScheme(
      brightness: brightness,
      primary: palette.buttonPrimaryBg,
      onPrimary: palette.buttonPrimaryFg,
      secondary: palette.accent,
      onSecondary: AppColors.pureWhite,
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      onError: AppColors.pureWhite,
      surface: palette.cardSurface,
      onSurface: palette.textPrimary,
      outline: palette.borderSubtle,
    );

    final baseTextTheme = TextTheme(
      displayLarge: displayStyle(
        locale: locale,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
        letterSpacing: -0.8,
      ),
      headlineLarge: displayStyle(
        locale: locale,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: displayStyle(
        locale: locale,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: displayStyle(
        locale: locale,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      titleMedium: displayStyle(
        locale: locale,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      bodyLarge: bodyStyle(
        locale: locale,
        fontSize: 15,
        color: palette.textPrimary,
      ),
      bodyMedium: bodyStyle(
        locale: locale,
        fontSize: 14,
        color: palette.textPrimary,
      ),
      bodySmall: bodyStyle(
        locale: locale,
        fontSize: 12,
        color: palette.textSecondary,
      ),
      labelLarge: displayStyle(
        locale: locale,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        letterSpacing: isKm ? 0.0 : 1.1,
      ),
      labelSmall: displayStyle(
        locale: locale,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: palette.textTertiary,
        letterSpacing: isKm ? 0.0 : 1.2,
      ),
    );

    final borderSide = BorderSide(color: palette.borderSubtle, width: 1);
    final focusedBorderSide = BorderSide(
      color: isDark ? palette.accent : palette.borderStrong,
      width: 1.5,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: palette.scaffoldBackground,
      textTheme: baseTextTheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      dividerColor: palette.borderSubtle,
      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.scaffoldBackground,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlayStyle(brightness: brightness),
        shape: Border(bottom: borderSide),
      ),
      cardTheme: CardThemeData(
        color: palette.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: borderSide,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.buttonPrimaryBg,
          foregroundColor: palette.buttonPrimaryFg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(44, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xs),
          ),
          textStyle: displayStyle(
            locale: locale,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: isKm ? 0 : 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          backgroundColor: palette.elevatedSurface,
          side: borderSide,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          minimumSize: const Size(44, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xs),
          ),
          textStyle: displayStyle(
            locale: locale,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: isKm ? 0 : 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          textStyle: displayStyle(
            locale: locale,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: isKm ? 0 : 0.6,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: bodyStyle(
          locale: locale,
          fontSize: 13,
          color: palette.textTertiary,
        ),
        labelStyle: bodyStyle(
          locale: locale,
          fontSize: 13,
          color: palette.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: focusedBorderSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: baseScheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: baseScheme.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.elevatedSurface,
        selectedColor: palette.buttonPrimaryBg,
        side: borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onyxBlack,
        contentTextStyle: bodyStyle(
          locale: locale,
          fontSize: 13,
          color: AppColors.boneWhite,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: borderSide,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}
