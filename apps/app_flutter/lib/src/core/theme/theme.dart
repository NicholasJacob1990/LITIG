import 'package:flutter/material.dart';

class AppColors {
  // Fundos e superfícies
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);

  // Texto
  static const Color primaryText = Color(0xFF1C1C1E);
  static const Color secondaryText = Color(0xFF6E6E73);

  // Primárias / Institucionais
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color darkBlue = Color(0xFF005AE0);

  // Acessórios / Destaques
  static const Color highlightPurple = Color(0xFF7E57C2);
  static const Color urgencyHigh = Color(0xFFEF6C00);
  static const Color urgencyMedium = Color(0xFFFFB300);
  static const Color inProgress = Color(0xFFF9A825);
  static const Color chatNotification = Color(0xFFFF3B30);

  // Gradientes (usados via LinearGradient)
  static const List<Color> gradientTop = [primaryBlue, darkBlue];
  static const List<Color> gradientPurple = [Color(0xFF8E2DE2), Color(0xFF4A00E0)];
}

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryBlue,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: AppColors.primaryBlue,
    secondary: AppColors.highlightPurple,
    surface: AppColors.surface,
    onSurface: AppColors.primaryText,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.primaryText),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.secondaryText),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    iconTheme: IconThemeData(color: AppColors.primaryText),
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      side: const BorderSide(color: AppColors.primaryBlue),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondaryText)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
    labelStyle: const TextStyle(color: AppColors.secondaryText),
  ),
); 