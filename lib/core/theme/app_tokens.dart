import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Palette
  static const Color onyxBlack = Color(0xFF111111);
  static const Color softCharcoal = Color(0xFF1A1A1A);
  static const Color darkScaffold = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF161616);
  static const Color darkElevated = Color(0xFF1C1C1E);
  static const Color darkBorder = Color(0xFF262626);
  static const Color boneWhite = Color(0xFFF5F4F0);
  static const Color offWhite = Color(0xFFFAF9F5);
  static const Color cardSurface = Color(0xFFF9F8F5);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color warmBorder = Color(0xFFE8E7E3);
  static const Color terracotta = Color(0xFFE65100);
  static const Color terracottaHover = Color(0xFFCC4400);
  static const Color khqrRed = Color(0xFFE21A1A);
  static const Color khqrRedLogo = Color(0xFFE1251B);
  static const Color neutralGray = Color(0xFF737373);
  static const Color neutralSecondary = Color(0xFF525252);
  static const Color neutralMuted = Color(0xFFA3A3A3);
  static const Color skeletonLightBase = Color(0xFFEFECE6);
  static const Color skeletonDarkBase = Color(0xFF1A1A1A);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double pagePaddingMobile = 16;
  static const double pagePaddingTablet = 24;
  static const double pagePaddingDesktop = 32;
  static const double maxContentWidth = 1280;
  static const double cartDrawerWidth = 448;
  static const double filterSidebarWidth = 288;
}

class AppRadii {
  AppRadii._();

  static const double none = 0;
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 9999;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 767;
  static const double tabletMin = 768;
  static const double desktopMin = 1024;

  static bool isMobile(double width) => width < tabletMin;
  static bool isTablet(double width) =>
      width >= tabletMin && width < desktopMin;
  static bool isDesktop(double width) => width >= desktopMin;
}

class AppMotion {
  AppMotion._();

  static const Duration microTap = Duration(milliseconds: 180);
  static const Duration stateTransition = Duration(milliseconds: 220);
  static const Duration sheetAndDrawer = Duration(milliseconds: 280);
  static const Duration galleryZoom = Duration(milliseconds: 300);
  static const Duration searchDebounce = Duration(milliseconds: 250);
  static const Duration khqrPollInterval = Duration(seconds: 3);
  static const Duration khqrCountdownTick = Duration(seconds: 1);
  static const Curve curve = Curves.easeOutCubic;
}

class SemanticStatusColors {
  const SemanticStatusColors({
    required this.foreground,
    required this.background,
    required this.border,
    required this.dot,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final Color dot;

  static SemanticStatusColors fromKey(String key, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (key) {
      case 'success':
        return isDark
            ? const SemanticStatusColors(
                foreground: Color(0xFF4ADE80),
                background: Color(0x2915803D),
                border: Color(0x4D4ADE80),
                dot: Color(0xFF22C55E),
              )
            : const SemanticStatusColors(
                foreground: Color(0xFF15803D),
                background: Color(0xFFECFDF5),
                border: Color(0xFFA7F3D0),
                dot: Color(0xFF10B981),
              );
      case 'warning':
        return isDark
            ? const SemanticStatusColors(
                foreground: Color(0xFFFBBF24),
                background: Color(0x2EB45309),
                border: Color(0x4DFBBF24),
                dot: Color(0xFFF59E0B),
              )
            : const SemanticStatusColors(
                foreground: Color(0xFFB45309),
                background: Color(0xFFFFFBEB),
                border: Color(0xFFFCD34D),
                dot: Color(0xFFF59E0B),
              );
      case 'danger':
        return isDark
            ? const SemanticStatusColors(
                foreground: Color(0xFFF87171),
                background: Color(0x2EDC2626),
                border: Color(0x52F87171),
                dot: Color(0xFFEF4444),
              )
            : const SemanticStatusColors(
                foreground: Color(0xFFDC2626),
                background: Color(0xFFFEF2F2),
                border: Color(0xFFFECACA),
                dot: Color(0xFFEF4444),
              );
      case 'info':
        return isDark
            ? const SemanticStatusColors(
                foreground: Color(0xFFCBD5E1),
                background: Color(0x47334155),
                border: Color(0x4D94A3B8),
                dot: Color(0xFF94A3B8),
              )
            : const SemanticStatusColors(
                foreground: Color(0xFF334155),
                background: Color(0xFFF1F5F9),
                border: Color(0xFFCBD5E1),
                dot: Color(0xFF64748B),
              );
      case 'primary':
        return isDark
            ? const SemanticStatusColors(
                foreground: Color(0xFFFB923C),
                background: Color(0x2EE65100),
                border: Color(0x4DFB923C),
                dot: Color(0xFFE65100),
              )
            : const SemanticStatusColors(
                foreground: Color(0xFFE65100),
                background: Color(0x14E65100),
                border: Color(0x40E65100),
                dot: Color(0xFFE65100),
              );
      default:
        return isDark
            ? const SemanticStatusColors(
                foreground: Color(0xFFA3A3A3),
                background: Color(0xFF262626),
                border: Color(0xFF404040),
                dot: Color(0xFF737373),
              )
            : const SemanticStatusColors(
                foreground: Color(0xFF525252),
                background: Color(0xFFF5F5F5),
                border: Color(0xFFD4D4D4),
                dot: Color(0xFF737373),
              );
    }
  }
}

class ResetPalette extends ThemeExtension<ResetPalette> {
  const ResetPalette({
    required this.scaffoldBackground,
    required this.surfaceBone,
    required this.cardSurface,
    required this.elevatedSurface,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentHover,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryFg,
    required this.inputBackground,
    required this.skeletonBase,
  });

  final Color scaffoldBackground;
  final Color surfaceBone;
  final Color cardSurface;
  final Color elevatedSurface;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentHover;
  final Color buttonPrimaryBg;
  final Color buttonPrimaryFg;
  final Color inputBackground;
  final Color skeletonBase;

  static const ResetPalette light = ResetPalette(
    scaffoldBackground: AppColors.offWhite,
    surfaceBone: AppColors.boneWhite,
    cardSurface: AppColors.cardSurface,
    elevatedSurface: AppColors.pureWhite,
    borderSubtle: AppColors.warmBorder,
    borderStrong: AppColors.onyxBlack,
    textPrimary: AppColors.onyxBlack,
    textSecondary: AppColors.neutralSecondary,
    textTertiary: AppColors.neutralGray,
    accent: AppColors.terracotta,
    accentHover: AppColors.terracottaHover,
    buttonPrimaryBg: AppColors.onyxBlack,
    buttonPrimaryFg: AppColors.pureWhite,
    inputBackground: AppColors.pureWhite,
    skeletonBase: AppColors.skeletonLightBase,
  );

  static const ResetPalette dark = ResetPalette(
    scaffoldBackground: AppColors.darkScaffold,
    surfaceBone: AppColors.darkCard,
    cardSurface: AppColors.darkCard,
    elevatedSurface: AppColors.softCharcoal,
    borderSubtle: AppColors.darkBorder,
    borderStrong: AppColors.boneWhite,
    textPrimary: AppColors.boneWhite,
    textSecondary: AppColors.neutralMuted,
    textTertiary: AppColors.neutralGray,
    accent: AppColors.terracotta,
    accentHover: AppColors.terracottaHover,
    buttonPrimaryBg: AppColors.boneWhite,
    buttonPrimaryFg: AppColors.onyxBlack,
    inputBackground: AppColors.softCharcoal,
    skeletonBase: AppColors.skeletonDarkBase,
  );

  @override
  ResetPalette copyWith({
    Color? scaffoldBackground,
    Color? surfaceBone,
    Color? cardSurface,
    Color? elevatedSurface,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentHover,
    Color? buttonPrimaryBg,
    Color? buttonPrimaryFg,
    Color? inputBackground,
    Color? skeletonBase,
  }) {
    return ResetPalette(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surfaceBone: surfaceBone ?? this.surfaceBone,
      cardSurface: cardSurface ?? this.cardSurface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      buttonPrimaryBg: buttonPrimaryBg ?? this.buttonPrimaryBg,
      buttonPrimaryFg: buttonPrimaryFg ?? this.buttonPrimaryFg,
      inputBackground: inputBackground ?? this.inputBackground,
      skeletonBase: skeletonBase ?? this.skeletonBase,
    );
  }

  @override
  ResetPalette lerp(covariant ThemeExtension<ResetPalette>? other, double t) {
    if (other is! ResetPalette) {
      return this;
    }
    return ResetPalette(
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      surfaceBone: Color.lerp(surfaceBone, other.surfaceBone, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      buttonPrimaryBg: Color.lerp(buttonPrimaryBg, other.buttonPrimaryBg, t)!,
      buttonPrimaryFg: Color.lerp(buttonPrimaryFg, other.buttonPrimaryFg, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
    );
  }
}

extension ResetThemeContext on BuildContext {
  ResetPalette get palette =>
      Theme.of(this).extension<ResetPalette>() ?? ResetPalette.light;
}
