import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar planos de escritórios
/// Mostra PARTNER_FIRM, PREMIUM_FIRM, ENTERPRISE_FIRM
class FirmPlanBadge extends StatelessWidget {
  final String firmPlan;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const FirmPlanBadge({
    super.key,
    required this.firmPlan,
    required this.viewerRole,
    this.onTap,
    this.showTooltip = true,
    this.enableHapticFeedback = true,
    this.padding,
    this.fontSize,
    this.icon,
  });

  /// Verifica se deve mostrar o badge baseado no plano e visualizador
  bool get _shouldShow {
    // Clientes veem badges de escritórios para identificar qualidade
    if (viewerRole == null || 
        !['client_pf', 'client_pj', 'lawyer_individual', 'lawyer_firm_member', 'admin'].contains(viewerRole)) {
      return false;
    }
    
    // Planos de escritório suportados
    return ['PARTNER_FIRM', 'PREMIUM_FIRM', 'ENTERPRISE_FIRM', 'PARTNER', 'PREMIUM', 'ENTERPRISE'].contains(firmPlan.toUpperCase());
  }

  /// Obtém a cor do badge baseada no plano
  Color get _badgeColor {
    switch (_normalizedPlan) {
      case 'PARTNER':
        return Colors.indigo.shade600; // Índigo para Partner
      case 'PREMIUM':
        return Colors.amber.shade600;  // Dourado para Premium
      case 'ENTERPRISE':
        return Colors.purple.shade600; // Roxo para Enterprise
      default:
        return Colors.grey.shade600;
    }
  }

  /// Obtém a cor de fundo do badge
  Color get _backgroundColor {
    switch (_normalizedPlan) {
      case 'PARTNER':
        return Colors.indigo.shade50;
      case 'PREMIUM':
        return Colors.amber.shade50;
      case 'ENTERPRISE':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  /// Obtém a cor da borda do badge
  Color get _borderColor {
    switch (_normalizedPlan) {
      case 'PARTNER':
        return Colors.indigo.shade300;
      case 'PREMIUM':
        return Colors.amber.shade300;
      case 'ENTERPRISE':
        return Colors.purple.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  /// Normaliza o nome do plano para exibição
  String get _normalizedPlan {
    final plan = firmPlan.toUpperCase();
    if (plan.contains('PARTNER')) return 'PARTNER';
    if (plan.contains('PREMIUM')) return 'PREMIUM';
    if (plan.contains('ENTERPRISE')) return 'ENTERPRISE';
    return plan;
  }

  /// Obtém o texto do badge
  String get _badgeText {
    switch (_normalizedPlan) {
      case 'PARTNER':
        return 'Partner';
      case 'PREMIUM':
        return 'Premium';
      case 'ENTERPRISE':
        return 'Enterprise';
      default:
        return _normalizedPlan;
    }
  }

  /// Obtém o ícone baseado no plano
  IconData get _badgeIcon {
    if (icon != null) return icon!;
    
    switch (_normalizedPlan) {
      case 'PARTNER':
        return LucideIcons.users;
      case 'PREMIUM':
        return LucideIcons.star;
      case 'ENTERPRISE':
        return LucideIcons.building2;
      default:
        return LucideIcons.building;
    }
  }

  /// Obtém a descrição completa
  String get _description {
    switch (_normalizedPlan) {
      case 'PARTNER':
        return 'Escritório Partner: Parceria estratégica, rede de especialistas e projetos colaborativos';
      case 'PREMIUM':
        return 'Escritório Premium: Serviços especializados, equipe sênior e atendimento diferenciado';
      case 'ENTERPRISE':
        return 'Escritório Enterprise: Soluções corporativas, equipe dedicada e SLA garantido';
      default:
        return 'Escritório com plano especial - Serviços diferenciados disponíveis';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Escritório $_badgeText',
      hint: showTooltip ? 'Toque para mais informações sobre o escritório' : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: showTooltip ? _description : '',
          child: Container(
            key: Key('firm_plan_badge_${_normalizedPlan.toLowerCase()}'),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _badgeIcon,
                  size: (fontSize ?? 12) + 2,
                  color: _badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _badgeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: fontSize ?? 12,
                    fontWeight: FontWeight.w600,
                    color: _badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extensão para facilitar o uso do FirmPlanBadge em diferentes contextos
extension FirmPlanBadgeExtensions on FirmPlanBadge {
  /// Cria um badge de escritório para uso em listas
  static Widget forList({
    required String firmPlan,
    required String? viewerRole,
    VoidCallback? onTap,
  }) {
    return FirmPlanBadge(
      firmPlan: firmPlan,
      viewerRole: viewerRole,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      fontSize: 10,
    );
  }

  /// Cria um badge de escritório compacto
  static Widget compact({
    required String firmPlan,
    required String? viewerRole,
  }) {
    return FirmPlanBadge(
      firmPlan: firmPlan,
      viewerRole: viewerRole,
      showTooltip: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      fontSize: 10,
    );
  }
} 