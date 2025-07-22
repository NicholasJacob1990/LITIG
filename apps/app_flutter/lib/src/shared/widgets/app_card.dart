import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Enum para variantes do card
enum AppCardVariant {
  default_,
  elevated,
  outlined,
  filled,
  gradient
}

/// Widget de card personalizado do app
/// 
/// Implementa o design system com variantes e estilos consistentes
class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isDisabled;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.default_,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.gradient,
    this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
    this.width,
    this.height,
  });

  /// Factory constructor para card elevado
  factory AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isDisabled = false,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.elevated,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      isSelected: isSelected,
      isDisabled: isDisabled,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor para card com borda
  factory AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isDisabled = false,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.outlined,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      onTap: onTap,
      isSelected: isSelected,
      isDisabled: isDisabled,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor para card preenchido
  factory AppCard.filled({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isDisabled = false,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.filled,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      isSelected: isSelected,
      isDisabled: isDisabled,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory constructor para card com gradiente
  factory AppCard.gradient({
    Key? key,
    required Widget child,
    required Gradient gradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isDisabled = false,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.gradient,
      gradient: gradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      isSelected: isSelected,
      isDisabled: isDisabled,
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = padding ?? _getDefaultPadding();
    final cardMargin = margin ?? EdgeInsets.zero;
    final cardBorderRadius = borderRadius ?? _getDefaultBorderRadius();
    final cardBackgroundColor = _getBackgroundColor(theme);
    final cardShadows = _getShadows();
    final cardBorder = _getBorder();

    Widget cardChild = Container(
      width: width,
      height: height,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: gradient == null ? cardBackgroundColor : null,
        gradient: gradient,
        borderRadius: cardBorderRadius,
        boxShadow: cardShadows,
        border: cardBorder,
      ),
      child: child,
    );

    if (onTap != null && !isDisabled) {
      cardChild = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          child: cardChild,
        ),
      );
    }

    return Container(
      margin: cardMargin,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: cardChild,
      ),
    );
  }

  EdgeInsetsGeometry _getDefaultPadding() {
    switch (variant) {
      case AppCardVariant.elevated:
        return const EdgeInsets.all(20);
      case AppCardVariant.filled:
        return const EdgeInsets.all(18);
      case AppCardVariant.gradient:
        return const EdgeInsets.all(20);
      default:
        return const EdgeInsets.all(16);
    }
  }

  BorderRadius _getDefaultBorderRadius() {
    switch (variant) {
      case AppCardVariant.elevated:
        return BorderRadius.circular(12);
      case AppCardVariant.gradient:
        return BorderRadius.circular(16);
      default:
        return BorderRadius.circular(8);
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (backgroundColor != null) return backgroundColor!;

    if (isSelected) {
      return AppColors.primaryBlue.withValues(alpha: 0.1);
    }

    switch (variant) {
      case AppCardVariant.filled:
        return theme.brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightBackground;
      case AppCardVariant.outlined:
        return Colors.transparent;
      case AppCardVariant.gradient:
        return Colors.transparent;
      default:
        return theme.brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard;
    }
  }

  List<BoxShadow>? _getShadows() {
    if (shadows != null) return shadows;

    switch (variant) {
      case AppCardVariant.elevated:
        return [
          BoxShadow(
            color: AppColors.lightText.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.lightText.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ];
      case AppCardVariant.default_:
        return [
          BoxShadow(
            color: AppColors.lightText.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case AppCardVariant.gradient:
        return [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      default:
        return null;
    }
  }

  Border? _getBorder() {
    if (isSelected && variant != AppCardVariant.outlined) {
      return Border.all(
        color: AppColors.primaryBlue,
        width: 2,
      );
    }

    switch (variant) {
      case AppCardVariant.outlined:
        return Border.all(
          color: borderColor ?? AppColors.lightBorder,
          width: borderWidth ?? 1,
        );
      default:
        return null;
    }
  }
}

/// Widget especializado para cards de lista
class AppListCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const AppListCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.showDivider = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          variant: AppCardVariant.outlined,
          borderColor: Colors.transparent,
          backgroundColor: isSelected 
              ? AppColors.primaryBlue.withValues(alpha: 0.05)
              : null,
          padding: padding ?? const EdgeInsets.all(16),
          onTap: onTap,
          isSelected: isSelected,
          child: child,
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.lightBorder.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

/// Widget especializado para cards de estatísticas
class AppStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const AppStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightText2,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.primaryBlue,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.lightText,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}