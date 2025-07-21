import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

/// Classe que define todos os estilos de texto utilizados no aplicativo
/// 
/// Mantém consistência tipográfica em todo o app e facilita manutenção
class AppTextStyles {
  // Font Family Base
  static final String _fontFamily = GoogleFonts.inter().fontFamily!;
  
  // Headings
  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.lightText,
    height: 1.2,
  );
  
  static final TextStyle h2 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
    height: 1.25,
  );
  
  static final TextStyle h3 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
    height: 1.3,
  );
  
  static final TextStyle h4 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
    height: 1.35,
  );
  
  static final TextStyle h5 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
    height: 1.4,
  );
  
  static final TextStyle h6 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
    height: 1.4,
  );
  
  // Alias for backwards compatibility
  static final TextStyle headingSmall = h6;
  
  // Body Text
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.lightText,
    height: 1.5,
  );
  
  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightText,
    height: 1.5,
  );
  
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.lightText2,
    height: 1.4,
  );
  
  // Labels
  static final TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
    height: 1.4,
  );
  
  static final TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
    height: 1.4,
  );
  
  static final TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText2,
    height: 1.3,
  );
  
  // Buttons
  static final TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
  );
  
  static final TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
  );
  
  static final TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
  );
  
  // Caption & Meta
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextSecondary,
    height: 1.3,
  );
  
  static final TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.lightTextSecondary,
    height: 1.3,
    letterSpacing: 0.5,
  );
  
  // Special Text Styles
  static final TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBlue,
    height: 1.4,
    decoration: TextDecoration.underline,
  );
  
  static final TextStyle error = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
    height: 1.3,
  );
  
  static final TextStyle success = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.success,
    height: 1.3,
  );
  
  static final TextStyle warning = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.warning,
    height: 1.3,
  );
  
  // Dark Theme Variants
  static final TextStyle h1Dark = h1.copyWith(color: AppColors.darkText);
  static final TextStyle h2Dark = h2.copyWith(color: AppColors.darkText);
  static final TextStyle h3Dark = h3.copyWith(color: AppColors.darkText);
  static final TextStyle h4Dark = h4.copyWith(color: AppColors.darkText);
  static final TextStyle h5Dark = h5.copyWith(color: AppColors.darkText);
  static final TextStyle h6Dark = h6.copyWith(color: AppColors.darkText);
  
  static final TextStyle bodyLargeDark = bodyLarge.copyWith(color: AppColors.darkText);
  static final TextStyle bodyMediumDark = bodyMedium.copyWith(color: AppColors.darkText);
  static final TextStyle bodySmallDark = bodySmall.copyWith(color: AppColors.darkText2);
  
  static final TextStyle labelLargeDark = labelLarge.copyWith(color: AppColors.darkText);
  static final TextStyle labelMediumDark = labelMedium.copyWith(color: AppColors.darkText);
  static final TextStyle labelSmallDark = labelSmall.copyWith(color: AppColors.darkText2);
  
  static final TextStyle captionDark = caption.copyWith(color: AppColors.darkTextSecondary);
  static final TextStyle overlineDark = overline.copyWith(color: AppColors.darkTextSecondary);
  
  // Utility Methods
  static TextStyle getHeadingStyle(int level, {bool isDark = false}) {
    switch (level) {
      case 1:
        return isDark ? h1Dark : h1;
      case 2:
        return isDark ? h2Dark : h2;
      case 3:
        return isDark ? h3Dark : h3;
      case 4:
        return isDark ? h4Dark : h4;
      case 5:
        return isDark ? h5Dark : h5;
      case 6:
        return isDark ? h6Dark : h6;
      default:
        return isDark ? bodyLargeDark : bodyLarge;
    }
  }
  
  static TextStyle getBodyStyle(String size, {bool isDark = false}) {
    switch (size.toLowerCase()) {
      case 'large':
        return isDark ? bodyLargeDark : bodyLarge;
      case 'small':
        return isDark ? bodySmallDark : bodySmall;
      default:
        return isDark ? bodyMediumDark : bodyMedium;
    }
  }
  
  static TextStyle getLabelStyle(String size, {bool isDark = false}) {
    switch (size.toLowerCase()) {
      case 'large':
        return isDark ? labelLargeDark : labelLarge;
      case 'small':
        return isDark ? labelSmallDark : labelSmall;
      default:
        return isDark ? labelMediumDark : labelMedium;
    }
  }
  
  static TextStyle getButtonStyle(String size) {
    switch (size.toLowerCase()) {
      case 'large':
        return buttonLarge;
      case 'small':
        return buttonSmall;
      default:
        return buttonMedium;
    }
  }
  
  /// Aplica cor específica mantendo outros atributos do estilo
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  /// Aplica peso de fonte específico mantendo outros atributos
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  /// Aplica tamanho específico mantendo outros atributos
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}

/// Extensão para facilitar aplicação de estilos
extension TextStyleExtension on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  
  TextStyle colored(Color color) => copyWith(color: color);
  TextStyle sized(double size) => copyWith(fontSize: size);
  TextStyle spaced(double spacing) => copyWith(letterSpacing: spacing);
}