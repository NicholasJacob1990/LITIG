import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar escritórios parceiros
/// Mostra o tier de parceria (SILVER, GOLD, PLATINUM) e plano PRO
class PartnerFirmBadge extends StatelessWidget {
  final String plan;
  final String partnerTier;
  final bool showPlan;
  final bool showTier;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const PartnerFirmBadge({
    super.key,
    required this.plan,
    required this.partnerTier,
    this.showPlan = true,
    this.showTier = true,
    this.padding,
    this.fontSize,
    this.icon,
  });

  /// Verifica se deve exibir o badge PRO
  bool get shouldShowPlan => showPlan && plan.toUpperCase() == 'PRO';

  /// Verifica se deve exibir o badge de tier
  bool get shouldShowTier => showTier && partnerTier.toUpperCase() != 'STANDARD';

  /// Verifica se deve exibir algum badge
  bool get shouldShow => shouldShowPlan || shouldShowTier;

  /// Retorna a cor baseada no tier
  Color get tierColor {
    switch (partnerTier.toUpperCase()) {
      case 'SILVER':
        return Colors.grey.shade600;
      case 'GOLD':
        return Colors.orange.shade600;
      case 'PLATINUM':
        return Colors.purple.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  /// Retorna a cor de fundo baseada no tier
  Color get tierBackgroundColor {
    switch (partnerTier.toUpperCase()) {
      case 'SILVER':
        return Colors.grey.shade50;
      case 'GOLD':
        return Colors.orange.shade50;
      case 'PLATINUM':
        return Colors.purple.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  /// Retorna a cor da borda baseada no tier
  Color get tierBorderColor {
    switch (partnerTier.toUpperCase()) {
      case 'SILVER':
        return Colors.grey.shade300;
      case 'GOLD':
        return Colors.orange.shade300;
      case 'PLATINUM':
        return Colors.purple.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  /// Retorna o ícone baseado no tier
  IconData get tierIcon {
    switch (partnerTier.toUpperCase()) {
      case 'SILVER':
        return LucideIcons.award;
      case 'GOLD':
        return LucideIcons.crown;
      case 'PLATINUM':
        return LucideIcons.gem;
      default:
        return LucideIcons.briefcase;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 6,
      children: [
        // Badge PRO
        if (shouldShowPlan)
          Container(
            key: const Key('firm_pro_badge'), // Para testes
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  size: (fontSize ?? 12) + 2,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'PRO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: fontSize ?? 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        
        // Badge do Tier
        if (shouldShowTier)
          Container(
            key: Key('firm_tier_badge_${partnerTier.toLowerCase()}'), // Para testes
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tierBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tierBorderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon ?? tierIcon,
                  size: (fontSize ?? 12) + 2,
                  color: tierColor,
                ),
                const SizedBox(width: 4),
                Text(
                  partnerTier.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: fontSize ?? 12,
                    fontWeight: FontWeight.w600,
                    color: tierColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 