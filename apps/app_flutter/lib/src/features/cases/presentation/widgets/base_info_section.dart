import 'package:flutter/material.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../core/theme/adaptive_colors.dart';

/// Classe base abstrata para todas as seções contextuais
/// 
/// Fornece métodos reutilizáveis baseados na experiência original
/// do cliente, garantindo consistência visual e comportamental.
abstract class BaseInfoSection extends StatelessWidget {
  final CaseDetail caseDetail;
  final Map<String, dynamic>? contextualData;

  const BaseInfoSection({
    required this.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context);

  // ==================== WIDGETS REUTILIZÁVEIS ====================

  /// Cria uma linha de informação padronizada
  /// Baseado no padrão da experiência original do cliente
  Widget buildInfoRow(
    BuildContext context,
    IconData icon, 
    String label, 
    String value, {
    Color? iconColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.colorScheme.primary;
    final defaultLabelStyle = labelStyle ?? theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final defaultValueStyle = valueStyle ?? theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );

    Widget child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: defaultIconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: defaultLabelStyle),
                const SizedBox(height: 2),
                Text(value, style: defaultValueStyle),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    if (onTap != null) {
      child = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }

    return child;
  }

  /// Cria um card de seção padronizado
  /// Baseado no design system existente
  Widget buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    Widget? titleSuffix,
    EdgeInsets? padding,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (titleSuffix != null) titleSuffix,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Cria um badge de status padronizado
  Widget buildStatusBadge(
    BuildContext context,
    String text, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Cria uma lista de KPIs padronizada
  Widget buildKPIsList(BuildContext context, List<KPIItem> kpis) {
    return Row(
      children: kpis.map((kpi) => Expanded(
        child: _buildKPIItem(context, kpi),
      )).toList(),
    );
  }

  Widget _buildKPIItem(BuildContext context, KPIItem kpi) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                kpi.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  kpi.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            kpi.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Cria um botão de ação padronizado
  Widget buildActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isOutlined = false,
    bool isSecondary = false,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (isOutlined || isSecondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? (isSecondary ? backgroundColor : null),
          side: BorderSide(
            color: backgroundColor ?? Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }

  /// Cria uma linha divisória padronizada
  Widget buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  /// Cria um header de seção com ícone
  Widget buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ==================== MÉTODOS UTILITÁRIOS ====================

  /// Obtém valor contextual com fallback
  T? getContextualValue<T>(String key, [T? defaultValue]) {
    return contextualData?[key] as T? ?? defaultValue;
  }

  /// Formata datas de forma consistente
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formata valores monetários
  String formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formata porcentagens
  String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  /// Obtém cor baseada no tipo de alocação
  Color getAllocationColor(BuildContext context) {
    final allocationType = getContextualValue<String>('allocation_type') ?? 'direct';
    
    // Importar a extensão AdaptiveColors se ainda não foi importada
    switch (allocationType) {
      case 'internal_delegation':
        return context.isDarkTheme ? const Color(0xFFFB7185) : const Color(0xFFFF6B6B);
      case 'platform_match_direct':
        return context.isDarkTheme ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      case 'partnership_proactive_search':
      case 'partnership_platform_suggestion':
        return context.isDarkTheme ? const Color(0xFF22C55E) : const Color(0xFF10B981);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

/// Classe para representar um item de KPI
class KPIItem {
  final String icon;
  final String label;
  final String value;

  const KPIItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Extensão para facilitar o uso em temas
extension BaseInfoSectionTheme on BuildContext {
  /// Obtém o estilo padrão para títulos de seção
  TextStyle? get sectionTitleStyle => Theme.of(this).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w600,
  );

  /// Obtém o estilo padrão para subtítulos
  TextStyle? get sectionSubtitleStyle => Theme.of(this).textTheme.bodyMedium?.copyWith(
    color: Theme.of(this).colorScheme.onSurfaceVariant,
  );
} 
