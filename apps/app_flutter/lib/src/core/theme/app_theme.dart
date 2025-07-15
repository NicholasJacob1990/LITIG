import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/utils/app_colors.dart';

class AppTheme {
  // LIGHT -------------------------------------------------------------------
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: false);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: base.colorScheme.copyWith(
        primary:    AppColors.primaryBlue,
        secondary:  AppColors.primaryBlue,
        surface:    AppColors.lightCard,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.lightText,
        displayColor: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color:  AppColors.lightCard,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBorder,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.lightText2,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // DARK --------------------------------------------------------------------
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: false);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary:    AppColors.primaryBlue,
        secondary:  AppColors.primaryBlue,
        surface:    AppColors.darkCard,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color:  AppColors.darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBorder,
        labelStyle: GoogleFonts.inter(
          color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.darkText2,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 