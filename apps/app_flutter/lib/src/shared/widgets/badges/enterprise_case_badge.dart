import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Badge discreto para identificar casos corporativos/enterprise
/// Deve ser exibido apenas para advogados/escritórios em contexto B2B
class EnterpriseCaseBadge extends StatelessWidget {
  final bool isEnterprise;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const EnterpriseCaseBadge({
    super.key,
    required this.isEnterprise,
    this.padding,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEnterprise) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Container(
      key: const Key('enterprise_case_badge'), // Para testes
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? LucideIcons.building,
            size: (fontSize ?? 12) + 2,
            color: Colors.indigo.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Enterprise',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 