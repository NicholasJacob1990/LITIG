import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Cores do Tema Escuro
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkOnPrimary = Colors.white;
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkInputFill = Color(0xFF374151);
  static const Color darkBorder = Color(0xFF4B5563);

  // Cores do Tema Claro
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Colors.white;
  static const Color lightPrimary = Color(0xFF3B82F6);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightInputFill = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFD1D5DB);
}

// Tema Escuro
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  primaryColor: AppColors.darkPrimary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.darkPrimary,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onPrimary: AppColors.darkOnPrimary,
    onBackground: AppColors.darkText,
    onSurface: AppColors.darkText,
    error: Colors.redAccent,
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
    headlineMedium: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkInputFill,
    hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkPrimary)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: AppColors.darkOnPrimary,
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
  )),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.darkBorder)),
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.darkBorder)),
  ),
);

// Tema Claro
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  primaryColor: AppColors.lightPrimary,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightPrimary,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    onPrimary: AppColors.lightOnPrimary,
    onBackground: AppColors.lightText,
    onSurface: AppColors.lightText,
    error: Colors.red,
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
    headlineMedium: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightText),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightInputFill,
    hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightPrimary)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: AppColors.lightOnPrimary,
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
  )),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.lightBorder)),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    color: AppColors.lightSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.lightBorder)),
  ),
);

// Manter o nome antigo por compatibilidade até refatorar tudo
final ThemeData appTheme = darkTheme; 