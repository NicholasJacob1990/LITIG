import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Extension methods para adicionar funcionalidades relacionadas ao tipo de caso
extension CaseTypeHelpers on Case {
  // Identificadores de tipo (extensível)
  bool get isConsultivo => caseType == 'consultancy';
  bool get isContencioso => caseType == 'litigation';
  bool get isContrato => caseType == 'contract';
  bool get isCompliance => caseType == 'compliance';
  bool get isDueDiligence => caseType == 'due_diligence';
  bool get isMA => caseType == 'ma';
  bool get isIP => caseType == 'ip';
  bool get isCorporativo => caseType == 'corporate';
  bool get isCustom => caseType == 'custom';
  
  // Configurações visuais (usando AppColors existente)
  Color get typeColor {
    switch (caseType) {
      case 'consultancy':
        return AppColors.info;
      case 'litigation':
        return AppColors.error;
      case 'contract':
        return AppColors.success;
      case 'compliance':
        return AppColors.warning;
      case 'due_diligence':
        return AppColors.primaryBlue;
      case 'ma':
        return AppColors.secondaryPurple;
      case 'ip':
        return AppColors.secondaryGreen;
      case 'corporate':
        return AppColors.secondaryYellow;
      case 'custom':
        return AppColors.lightText2;
      default:
        return AppColors.primaryBlue;
    }
  }
  
  IconData get typeIcon {
    switch (caseType) {
      case 'consultancy':
        return LucideIcons.lightbulb;
      case 'litigation':
        return LucideIcons.gavel;
      case 'contract':
        return LucideIcons.fileText;
      case 'compliance':
        return LucideIcons.shield;
      case 'due_diligence':
        return LucideIcons.search;
      case 'ma':
        return LucideIcons.building2;
      case 'ip':
        return LucideIcons.copyright;
      case 'corporate':
        return LucideIcons.building;
      case 'custom':
        return LucideIcons.settings;
      default:
        return LucideIcons.briefcase;
    }
  }
  
  String get typeDisplayName {
    switch (caseType) {
      case 'consultancy':
        return 'Consultivo';
      case 'litigation':
        return 'Contencioso';
      case 'contract':
        return 'Contratos';
      case 'compliance':
        return 'Compliance';
      case 'due_diligence':
        return 'Due Diligence';
      case 'ma':
        return 'M&A';
      case 'ip':
        return 'Propriedade Intelectual';
      case 'corporate':
        return 'Corporativo';
      case 'custom':
        return 'Personalizado';
      default:
        return 'Jurídico';
    }
  }
  
  // Retorna se deve mostrar a seção de pré-análise da IA
  bool get shouldShowPreAnalysis {
    // Pré-análise é mais relevante para casos contenciosos e alguns corporativos
    return isContencioso || isMA || isDueDiligence;
  }
  
  // Retorna se deve mostrar seções específicas de consultoria
  bool get shouldShowConsultancySections {
    return isConsultivo || isCompliance || isContrato;
  }
}