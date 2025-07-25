import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/badge_visibility_helper.dart';

/// Widget universal para badges que se adapta ao contexto B2B
/// Usa o BadgeVisibilityHelper para determinar o que mostrar
class UniversalBadge extends StatelessWidget {
  final BadgeContext context;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? customIcon;

  const UniversalBadge({
    super.key,
    required this.context,
    this.padding,
    this.fontSize,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (!this.context.showBadge) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = _getColors(this.context.badgeColor);
    
    return Container(
      key: Key('universal_badge_${this.context.badgeText.toLowerCase()}'),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            customIcon ?? _getIcon(this.context.badgeColor, this.context.badgeText),
            size: (fontSize ?? 12) + 2,
            color: colors.foreground,
          ),
          const SizedBox(width: 4),
          Text(
            this.context.badgeText,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna as cores baseadas no BadgeColor
  _BadgeColors _getColors(BadgeColor color) {
    switch (color) {
      case BadgeColor.green:
        return _BadgeColors(
          background: Colors.green.shade50,
          border: Colors.green.shade300,
          foreground: Colors.green.shade600,
        );
      case BadgeColor.amber:
        return _BadgeColors(
          background: Colors.amber.shade50,
          border: Colors.amber.shade300,
          foreground: Colors.amber.shade700,
        );
      case BadgeColor.indigo:
        return _BadgeColors(
          background: Colors.indigo.shade50,
          border: Colors.indigo.shade300,
          foreground: Colors.indigo.shade700,
        );
      case BadgeColor.orange:
        return _BadgeColors(
          background: Colors.orange.shade50,
          border: Colors.orange.shade300,
          foreground: Colors.orange.shade600,
        );
      case BadgeColor.purple:
        return _BadgeColors(
          background: Colors.purple.shade50,
          border: Colors.purple.shade300,
          foreground: Colors.purple.shade600,
        );
      case BadgeColor.blue:
        return _BadgeColors(
          background: Colors.blue.shade50,
          border: Colors.blue.shade300,
          foreground: Colors.blue.shade600,
        );
      case BadgeColor.grey:
      default:
        return _BadgeColors(
          background: Colors.grey.shade50,
          border: Colors.grey.shade300,
          foreground: Colors.grey.shade600,
        );
    }
  }

  /// Retorna o ícone baseado no contexto
  IconData _getIcon(BadgeColor color, String text) {
    // Ícones específicos por texto
    switch (text.toUpperCase()) {
      case 'PRO':
      case 'PRIORITÁRIO PRO':
        return LucideIcons.checkCircle;
      case 'PREMIUM':
        return LucideIcons.star;
      case 'ENTERPRISE':
        return LucideIcons.building;
      case 'SILVER':
        return LucideIcons.award;
      case 'GOLD':
        return LucideIcons.crown;
      case 'PLATINUM':
        return LucideIcons.gem;
      default:
        // Ícones por cor
        switch (color) {
          case BadgeColor.green:
            return LucideIcons.checkCircle;
          case BadgeColor.amber:
            return LucideIcons.star;
          case BadgeColor.indigo:
            return LucideIcons.building;
          default:
            return LucideIcons.tag;
        }
    }
  }
}

/// Widget para exibir múltiplos badges com espaçamento adequado
class UniversalBadgeGroup extends StatelessWidget {
  final List<BadgeContext> contexts;
  final double spacing;
  final EdgeInsets? padding;
  final double? fontSize;

  const UniversalBadgeGroup({
    super.key,
    required this.contexts,
    this.spacing = 6,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final visibleContexts = contexts.where((c) => c.showBadge).toList();
    
    if (visibleContexts.isEmpty) return const SizedBox.shrink();

    // Ordenar por prioridade (menor número = maior prioridade)
    visibleContexts.sort((a, b) => a.priority.compareTo(b.priority));
    
    return Wrap(
      spacing: spacing,
      children: visibleContexts.map((badgeContext) =>
        UniversalBadge(
          context: badgeContext,
          padding: padding,
          fontSize: fontSize,
        ),
      ).toList(),
    );
  }
}

/// Classe auxiliar para cores do badge
class _BadgeColors {
  final Color background;
  final Color border;
  final Color foreground;

  const _BadgeColors({
    required this.background,
    required this.border,
    required this.foreground,
  });
} 