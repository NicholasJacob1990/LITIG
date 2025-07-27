import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar clientes PJ Business
/// Mostra o diferencial corporativo para advogados/escritórios
class BusinessClientBadge extends StatelessWidget {
  final String? clientPlan;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const BusinessClientBadge({
    super.key,
    required this.clientPlan,
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
    if (clientPlan == null) return false;
    
    // Apenas advogados e escritórios veem badges Business (para priorização B2B)
    if (viewerRole == null || 
        !['lawyer', 'lawyer_firm_member', 'firm', 'admin'].contains(viewerRole)) {
      return false;
    }
    
    // Planos Business suportados (PJ)
    return ['BUSINESS', 'BUSINESS_PJ'].contains(clientPlan?.toUpperCase());
  }

  /// Obtém o texto do badge
  String get _badgeText => 'Business';

  /// Obtém a descrição completa
  String get _description {
    return 'Cliente Business: Soluções corporativas, volume de casos e parcerias estratégicas';
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Cliente Business',
      hint: showTooltip ? 'Toque para mais informações sobre benefícios Business' : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: showTooltip ? _description : '',
          child: Container(
            key: const Key('business_client_badge'),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon ?? LucideIcons.briefcase,
                  size: (fontSize ?? 12) + 2,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  _badgeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: fontSize ?? 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
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

/// Extensão para facilitar o uso do BusinessClientBadge em diferentes contextos
extension BusinessClientBadgeExtensions on BusinessClientBadge {
  /// Cria um badge Business para uso em listas de casos
  static Widget forCaseList({
    required String? clientPlan,
    required String? viewerRole,
    VoidCallback? onTap,
  }) {
    return BusinessClientBadge(
      clientPlan: clientPlan,
      viewerRole: viewerRole,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      fontSize: 10,
    );
  }

  /// Cria um badge Business compacto para uso em headers
  static Widget compact({
    required String? clientPlan,
    required String? viewerRole,
  }) {
    return BusinessClientBadge(
      clientPlan: clientPlan,
      viewerRole: viewerRole,
      showTooltip: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      fontSize: 10,
    );
  }
} 