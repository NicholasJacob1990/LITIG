import 'package:flutter/material.dart';
import '../../shared/utils/app_colors.dart';

/// Extensão para cores adaptáveis ao tema escuro e claro
extension AdaptiveColors on BuildContext {
  /// Verifica se o tema atual é escuro
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
  
  /// Cores de status que se adaptam ao tema
  Color getStatusColor(String status) {
    final isDark = isDarkTheme;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'ativo':
      case 'em andamento':
        return isDark ? const Color(0xFF22C55E) : AppColors.success;
      case 'pending':
      case 'pendente':
      case 'aguardando':
        return isDark ? const Color(0xFFFBBF24) : AppColors.warning;
      case 'blocked':
      case 'bloqueado':
      case 'cancelado':
        return isDark ? const Color(0xFFF87171) : AppColors.error;
      case 'completed':
      case 'concluído':
        return isDark ? const Color(0xFF10B981) : AppColors.success;
      default:
        return isDark ? const Color(0xFF60A5FA) : AppColors.info;
    }
  }
  
  /// Cores para tipos de caso que se adaptam ao tema
  Color getCaseTypeColor(String caseType) {
    final isDark = isDarkTheme;
    
    switch (caseType.toLowerCase()) {
      case 'consultancy':
      case 'consultivo':
        return isDark ? const Color(0xFF60A5FA) : AppColors.info;
      case 'litigation':
      case 'contencioso':
        return isDark ? const Color(0xFFF87171) : AppColors.error;
      case 'contract':
      case 'contratos':
        return isDark ? const Color(0xFF22C55E) : AppColors.success;
      case 'compliance':
        return isDark ? const Color(0xFFFBBF24) : AppColors.warning;
      case 'due_diligence':
        return isDark ? const Color(0xFF8B5CF6) : AppColors.primaryPurple;
      case 'ma':
      case 'm&a':
        return isDark ? const Color(0xFFA855F7) : AppColors.secondaryPurple;
      case 'ip':
      case 'propriedade intelectual':
        return isDark ? const Color(0xFF22C55E) : AppColors.success;
      case 'corporate':
      case 'corporativo':
        return isDark ? const Color(0xFFFBBF24) : AppColors.secondaryYellow;
      default:
        return isDark ? const Color(0xFF60A5FA) : AppColors.primaryBlue;
    }
  }
  
  /// Cores para alocação que se adaptam ao tema
  Color getAllocationColor(String allocationType) {
    final isDark = isDarkTheme;
    
    switch (allocationType.toLowerCase()) {
      case 'internal_delegation':
      case 'delegation':
        return isDark ? const Color(0xFFFB7185) : const Color(0xFFFF6B6B);
      case 'platform_match':
      case 'platform_match_direct':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      case 'partnership':
      case 'partnership_proactive_search':
      case 'partnership_platform_suggestion':
        return isDark ? const Color(0xFF22C55E) : const Color(0xFF10B981);
      case 'direct':
      case 'direct_client':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      default:
        return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    }
  }
  
  /// Cores para status de cliente que se adaptam ao tema
  Color getClientStatusColor(String status) {
    final isDark = isDarkTheme;
    
    switch (status.toLowerCase()) {
      case 'vip':
        return isDark ? const Color(0xFFA855F7) : const Color(0xFF8B5CF6);
      case 'problematic':
        return isDark ? const Color(0xFFFB7185) : const Color(0xFFEF4444);
      case 'active':
      default:
        return isDark ? const Color(0xFF22C55E) : const Color(0xFF10B981);
    }
  }
  
  /// Background adaptável para badges
  Color getBadgeBackground(Color primaryColor) {
    final isDark = isDarkTheme;
    return isDark 
      ? primaryColor.withValues(alpha: 0.2)
      : primaryColor.withValues(alpha: 0.1);
  }
  
  /// Cor de texto que contrasta com o background do badge
  Color getBadgeTextColor(Color backgroundColor) {
    final isDark = isDarkTheme;
    // Se o background é muito escuro, usar texto claro
    // Se o background é muito claro, usar texto escuro
    final luminance = backgroundColor.computeLuminance();
    
    if (isDark) {
      return luminance > 0.3 ? Colors.black87 : Colors.white;
    } else {
      return luminance > 0.5 ? Colors.black87 : backgroundColor;
    }
  }
  
  /// Cor de divider adaptável
  Color get adaptiveDividerColor {
    return isDarkTheme ? AppColors.darkBorder : AppColors.lightBorder;
  }
  
  /// Cor de surface adaptável
  Color get adaptiveSurfaceColor {
    return isDarkTheme ? AppColors.darkCard : AppColors.lightCard;
  }
  
  /// Cor de texto primário adaptável
  Color get adaptiveTextColor {
    return isDarkTheme ? AppColors.darkText : AppColors.lightText;
  }
  
  /// Cor de texto secundário adaptável
  Color get adaptiveTextSecondaryColor {
    return isDarkTheme ? AppColors.darkText2 : AppColors.lightText2;
  }
}

/// Classe utilitária para cores de elementos específicos
class CaseColors {
  /// Cores para indicadores de prioridade
  static Color getPriorityColor(String priority, bool isDark) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'alta':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      case 'medium':
      case 'média':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      case 'low':
      case 'baixa':
        return isDark ? const Color(0xFF22C55E) : const Color(0xFF10B981);
      default:
        return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    }
  }
  
  /// Cores para diferentes especialidades jurídicas
  static Color getSpecialtyColor(String specialty, bool isDark) {
    final baseColors = {
      'trabalhista': isDark ? const Color(0xFF22C55E) : const Color(0xFF10B981),
      'civil': isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
      'criminal': isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
      'tributário': isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
      'família': isDark ? const Color(0xFFA855F7) : const Color(0xFF8B5CF6),
      'empresarial': isDark ? const Color(0xFF06B6D4) : const Color(0xFF0891B2),
      'consumidor': isDark ? const Color(0xFFEC4899) : const Color(0xFFDB2777),
      'previdenciário': isDark ? const Color(0xFF84CC16) : const Color(0xFF65A30D),
    };
    
    return baseColors[specialty.toLowerCase()] ?? 
           (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
  }
}
