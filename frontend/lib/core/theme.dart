import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_system.dart';

export 'design_system.dart';

class AppColors {
  static const Color primary = DesignSystem.primary;
  static const Color primaryLight = DesignSystem.primaryLight;
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color accent = DesignSystem.secondary;
  static const Color bgPage = DesignSystem.background;
  static const Color bgCard = DesignSystem.surface;
  static const Color textPrimary = DesignSystem.textPrimary;
  static const Color textSecondary = DesignSystem.textSecondary;
  static const Color textMuted = Color(0xFF9CA3AF); // Gray 400
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color divider = Color(0xFFF3F4F6); // Gray 100

  // Status colors
  static const Color running = DesignSystem.success;
  static const Color idle = DesignSystem.warning;
  static const Color breakdown = DesignSystem.danger;
  static const Color stoppage = Color(0xFF8B5CF6); // Violet 500
  static const Color danger = DesignSystem.danger;
  static const Color bgInput = Colors.white;
}

class AppTheme {
  static bool get isCompact => kIsWeb;
  static double get pagePadding => 12.0;
  static double get sectionSpacing => 10.0;
  static double get cardRadius => 8.0;
  static double get buttonHeight => 36.0;
  static double get fieldSpacing => 8.0;
  static double get cardPadding => 12.0;
  static double get inputHorizontalPadding => 10.0;
  static double get inputVerticalPadding => 8.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.bgCard,
        onSurface: AppColors.textPrimary,
        error: DesignSystem.danger,
        outline: AppColors.border,
        surfaceContainerHighest: AppColors.bgPage,
      ),
      scaffoldBackgroundColor: AppColors.bgPage,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: DesignSystem.inputDecorationTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: DesignSystem.primaryButtonStyle),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
