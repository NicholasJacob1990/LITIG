import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/app_colors.dart';

/// Widget de card customizado reutilizável
/// 
/// Oferece diferentes variações de estilo e comportamento
/// mantendo consistência visual em todo o aplicativo
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool isSelected;
  final Widget? header;
  final Widget? footer;
  final bool showBorder;
  final CustomCardVariant variant;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isSelected = false,
    this.header,
    this.footer,
    this.showBorder = true,
    this.variant = CustomCardVariant.normal,
  });

  /// Construtor para card elevado
  const CustomCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isSelected = false,
    this.header,
    this.footer,
    this.showBorder = true,
  }) : elevation = 8.0,
       variant = CustomCardVariant.elevated;

  /// Construtor para card plano
  const CustomCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isSelected = false,
    this.header,
    this.footer,
    this.showBorder = false,
  }) : elevation = 0.0,
       variant = CustomCardVariant.flat;

  /// Construtor para card premium
  const CustomCard.premium({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.isSelected = false,
    this.header,
    this.footer,
    this.showBorder = true,
  }) : backgroundColor = null,
       elevation = 4.0,
       border = null,
       variant = CustomCardVariant.premium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final effectiveBackgroundColor = _getBackgroundColor(context, isDark);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveMargin = margin ?? EdgeInsets.zero;
    final effectiveElevation = elevation ?? (variant == CustomCardVariant.flat ? 0.0 : 2.0);

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 12),
        ],
        child,
        if (footer != null) ...[
          const SizedBox(height: 12),
          footer!,
        ],
      ],
    );

    Widget cardWidget = Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        border: _getBorder(context, isDark),
        gradient: variant == CustomCardVariant.premium ? _getPremiumGradient() : null,
      ),
      child: Material(
        color: variant == CustomCardVariant.premium ? Colors.transparent : effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        elevation: effectiveElevation,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: Padding(
            padding: effectivePadding,
            child: cardContent,
          ),
        ),
      ),
    );

    if (isSelected) {
      cardWidget = Container(
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          border: Border.all(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Color _getBackgroundColor(BuildContext context, bool isDark) {
    if (backgroundColor != null) return backgroundColor!;
    
    switch (variant) {
      case CustomCardVariant.normal:
      case CustomCardVariant.elevated:
      case CustomCardVariant.flat:
        return isDark ? AppColors.darkCard : AppColors.lightCard;
      case CustomCardVariant.premium:
        return Colors.transparent;
    }
  }

  Border? _getBorder(BuildContext context, bool isDark) {
    if (border != null) return border;
    if (!showBorder) return null;
    
    switch (variant) {
      case CustomCardVariant.normal:
      case CustomCardVariant.flat:
        return Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        );
      case CustomCardVariant.elevated:
      case CustomCardVariant.premium:
        return null;
    }
  }

  LinearGradient? _getPremiumGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF8FAFC),
      ],
      stops: [0.0, 1.0],
    );
  }
}

/// Enumeração para diferentes variantes do CustomCard
enum CustomCardVariant {
  normal,
  elevated,
  flat,
  premium,
}

/// Widget de card específico para informações
class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ] else if (onTap != null)
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

/// Widget de card para estatísticas
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppColors.primaryBlue;
    
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 12,
                        color: isPositiveTrend ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPositiveTrend ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: effectiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}