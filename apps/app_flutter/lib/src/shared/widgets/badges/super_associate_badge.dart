import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar Super Associates
/// Mostra planos PARTNER e PREMIUM para super_associate
class SuperAssociateBadge extends StatelessWidget {
  final String plan;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const SuperAssociateBadge({
    super.key,
    required this.plan,
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
    // Advogados contratantes veem badges de Super Associates para identificar especialistas da plataforma
    if (viewerRole == null || 
        !['lawyer_individual', 'firm', 'lawyer_firm_member', 'admin'].contains(viewerRole)) {
      return false;
    }
    
    // Planos de Super Associate suportados
    return ['PARTNER', 'PREMIUM'].contains(plan.toUpperCase());
  }

  /// Obtém a cor do badge baseada no plano
  Color get _badgeColor {
    switch (plan.toUpperCase()) {
      case 'PARTNER':
        return Colors.purple.shade600; // Roxo para Partner
      case 'PREMIUM':
        return Colors.amber.shade600;   // Dourado para Premium
      default:
        return Colors.grey.shade600;
    }
  }

  /// Obtém a cor de fundo do badge
  Color get _backgroundColor {
    switch (plan.toUpperCase()) {
      case 'PARTNER':
        return Colors.purple.shade50;
      case 'PREMIUM':
        return Colors.amber.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  /// Obtém a cor da borda do badge
  Color get _borderColor {
    switch (plan.toUpperCase()) {
      case 'PARTNER':
        return Colors.purple.shade300;
      case 'PREMIUM':
        return Colors.amber.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  /// Obtém o texto do badge
  String get _badgeText {
    switch (plan.toUpperCase()) {
      case 'PARTNER':
        return 'Super Partner';
      case 'PREMIUM':
        return 'Super Premium';
      default:
        return 'Super';
    }
  }

  /// Obtém o ícone baseado no plano
  IconData get _badgeIcon {
    if (icon != null) return icon!;
    
    switch (plan.toUpperCase()) {
      case 'PARTNER':
        return LucideIcons.crown;     // Coroa para Partner
      case 'PREMIUM':
        return LucideIcons.gem;       // Gema para Premium
      default:
        return LucideIcons.star;
    }
  }

  /// Obtém a descrição completa
  String get _description {
    switch (plan.toUpperCase()) {
      case 'PARTNER':
        return 'Super Associado Partner: Especialista da plataforma, acesso prioritário e ferramentas avançadas';
      case 'PREMIUM':
        return 'Super Associado Premium: Elite da plataforma, recursos exclusivos e suporte VIP';
      default:
        return 'Super Associado da plataforma - Benefícios especiais disponíveis';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Semantics(
      label: _badgeText,
      hint: showTooltip ? 'Toque para mais informações sobre o Super Associado' : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: showTooltip ? _description : '',
          child: Container(
            key: Key('super_associate_badge_${plan.toLowerCase()}'),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColor,
                width: 1,
              ),
              // Gradiente sutil para Super Associates
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColor,
                  _backgroundColor.withOpacity(0.8),
                ],
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
                    fontWeight: FontWeight.w700, // Mais bold para Super Associates
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

/// Extensão para facilitar o uso do SuperAssociateBadge em diferentes contextos
extension SuperAssociateBadgeExtensions on SuperAssociateBadge {
  /// Cria um badge Super Associate para uso em listas
  static Widget forList({
    required String plan,
    required String? viewerRole,
    VoidCallback? onTap,
  }) {
    return SuperAssociateBadge(
      plan: plan,
      viewerRole: viewerRole,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      fontSize: 10,
    );
  }

  /// Cria um badge Super Associate compacto
  static Widget compact({
    required String plan,
    required String? viewerRole,
  }) {
    return SuperAssociateBadge(
      plan: plan,
      viewerRole: viewerRole,
      showTooltip: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      fontSize: 10,
    );
  }

  /// Cria um badge Super Associate com animação (para destaque especial)
  static Widget animated({
    required String plan,
    required String? viewerRole,
    VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: SuperAssociateBadge(
        plan: plan,
        viewerRole: viewerRole,
        onTap: onTap,
        enableHapticFeedback: true,
      ),
    );
  }
} 