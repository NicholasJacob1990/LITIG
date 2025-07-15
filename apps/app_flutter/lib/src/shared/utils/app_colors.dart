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
  
  // Cores de status com opacidade
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // Cores específicas para casos jurídicos
  static const Color caseActive = Color(0xFF10B981);
  static const Color casePending = Color(0xFFF59E0B);
  static const Color caseClosed = Color(0xFF6B7280);
  static const Color caseUrgent = Color(0xFFEF4444);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryDark],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryGreen, Color(0xFF059669)],
  );
  
  // Métodos utilitários
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
  
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
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