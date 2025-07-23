import 'package:flutter/material.dart';

/// Classe que define todas as cores utilizadas no aplicativo
/// 
/// Mantém consistência visual em todo o app e facilita manutenção
class AppColors {
  // Cores primárias
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  
  // Cores secundárias
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color secondaryRed = Color(0xFFEF4444);
  static const Color secondaryYellow = Color(0xFFF59E0B);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPurple = Color(0xFF8B5CF6); // Alias para secondaryPurple
  
  // Cores de acentos para gradientes
  static const Color accentPurpleStart = Color(0xFF8B5CF6);
  static const Color accentPurpleEnd = Color(0xFF7C3AED);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  
  // Cores de fundo - Light Theme
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // Cores de texto - Light Theme
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightText2 = Color(0xFF64748B);
  static const Color lightTextSecondary = Color(0xFF94A3B8);
  
  // Aliases for backwards compatibility
  static const Color textPrimary = lightText;
  static const Color textSecondary = lightTextSecondary;
  static const Color primary = primaryBlue;
  static const Color border = lightBorder;
  static const Color background = lightBackground;
  
  // Cores Material Design compatíveis
  static const Color surface = lightCard;
  static const Color outline = lightBorder;
  static const Color onSurface = lightText;
  
  // Cores de fundo - Dark Theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  
  // Cores de texto - Dark Theme
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkText2 = Color(0xFFCBD5E1);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Cores de status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Cores para elementos específicos
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);

  // Cores específicas do app legal
  static const Color lawyerBlue = Color(0xFF1E40AF);
  static const Color clientGreen = Color(0xFF10B981);
  static const Color urgent = Color(0xFFEF4444);
  static const Color pending = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF10B981);

  // Cores para providers sociais
  static const Color linkedInBlue = Color(0xFF0077B5);
  static const Color whatsAppGreen = Color(0xFF25D366);
  static const Color instagramPurple = Color(0xFFE4405F);
  static const Color gmailRed = Color(0xFFEA4335);
  static const Color outlookBlue = Color(0xFF0078D4);

  // Helper para obter cores baseadas no tema
  static Color getTextColor(bool isDark) {
    return isDark ? darkText : lightText;
  }

  static Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackground : lightBackground;
  }

  static Color getCardColor(bool isDark) {
    return isDark ? darkCard : lightCard;
  }

  static Color getBorderColor(bool isDark) {
    return isDark ? darkBorder : lightBorder;
  }
}

/// Classe que define cores específicas para status de casos
class AppStatusColors {
  static const Map<String, Color> status = {
    'active': AppColors.caseActive,
    'pending': AppColors.casePending,
    'closed': AppColors.caseClosed,
    'urgent': AppColors.caseUrgent,
    'awaiting_payment': AppColors.warning,
    'in_progress': AppColors.info,
    'completed': AppColors.success,
    'cancelled': AppColors.error,
  };
  
  static Color getStatusColor(String status) {
    return AppStatusColors.status[status] ?? AppColors.lightText2;
  }
}

/// Classe que define cores específicas para tipos de usuário
class AppUserColors {
  static const Color client = Color(0xFF3B82F6);
  static const Color lawyer = Color(0xFF10B981);
  static const Color admin = Color(0xFF8B5CF6);
  static const Color firm = Color(0xFFF59E0B);
}

/// Classe que define cores específicas para áreas jurídicas
class AppAreaColors {
  static const Map<String, Color> areas = {
    'civil': Color(0xFF3B82F6),
    'criminal': Color(0xFFEF4444),
    'trabalhista': Color(0xFF10B981),
    'tributario': Color(0xFFF59E0B),
    'familia': Color(0xFF8B5CF6),
    'empresarial': Color(0xFF06B6D4),
    'consumidor': Color(0xFFEC4899),
    'previdenciario': Color(0xFF84CC16),
  };
  
  static Color getAreaColor(String area) {
    return areas[area.toLowerCase()] ?? AppColors.primaryBlue;
  }
} 