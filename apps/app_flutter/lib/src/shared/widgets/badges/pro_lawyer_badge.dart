import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar advogados PRO
/// Deve ser exibido apenas para clientes escolhendo advogados
class ProLawyerBadge extends StatelessWidget {
  final String plan;
  final bool isPremiumCase;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const ProLawyerBadge({
    super.key,
    required this.plan,
    this.isPremiumCase = false,
    this.padding,
    this.fontSize,
    this.icon,
  });

  /// Verifica se deve exibir o badge
  bool get shouldShow => plan.toUpperCase() == 'PRO';

  /// Retorna o texto do badge baseado no contexto
  String get badgeText {
    if (isPremiumCase && shouldShow) {
      return 'Prioritário PRO';
    } else if (shouldShow) {
      return 'PRO';
    }
    return '';
  }

  /// Retorna a cor do badge baseada no contexto
  Color get badgeColor {
    if (isPremiumCase && shouldShow) {
      return Colors.amber.shade600; // Dourado para contexto premium
    } else if (shouldShow) {
      return Colors.green.shade600; // Verde para PRO normal
    }
    return Colors.grey;
  }

  /// Retorna a cor de fundo do badge
  Color get backgroundColor {
    if (isPremiumCase && shouldShow) {
      return Colors.amber.shade50;
    } else if (shouldShow) {
      return Colors.green.shade50;
    }
    return Colors.grey.shade50;
  }

  /// Retorna a cor da borda do badge
  Color get borderColor {
    if (isPremiumCase && shouldShow) {
      return Colors.amber.shade300;
    } else if (shouldShow) {
      return Colors.green.shade300;
    }
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Container(
      key: Key('pro_lawyer_badge_${isPremiumCase ? "premium" : "normal"}'), // Para testes
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? (isPremiumCase ? LucideIcons.crown : LucideIcons.checkCircle),
            size: (fontSize ?? 12) + 2,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
} 