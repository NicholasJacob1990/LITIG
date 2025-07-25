import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar casos premium
/// Deve ser exibido apenas para advogados/escritórios
class PremiumCaseBadge extends StatelessWidget {
  final bool isPremium;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const PremiumCaseBadge({
    super.key,
    required this.isPremium,
    this.padding,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Container(
      key: const Key('premium_case_badge'), // Para testes
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? LucideIcons.star,
            size: (fontSize ?? 12) + 2,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 