import 'package:flutter/material.dart';

/// Design Tokens centralizados para LITIG-1
class LitigDesignTokens {
  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;
  static const double space4xl = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 999.0;

  // Elevations
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // Font Sizes
  static const double fontXs = 12.0;
  static const double fontSm = 14.0;
  static const double fontMd = 16.0;
  static const double fontLg = 18.0;
  static const double fontXl = 20.0;
  static const double font2xl = 24.0;
  static const double font3xl = 30.0;
  static const double font4xl = 36.0;

  // Font Weights
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontRegular = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemiBold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;

  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 48.0;

  // Component Heights
  static const double buttonSm = 32.0;
  static const double buttonMd = 40.0;
  static const double buttonLg = 48.0;
  static const double inputHeight = 48.0;
  static const double cardMinHeight = 80.0;
  static const double touchTarget = 44.0; // WCAG mínimo

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Z-Index
  static const double zIndexDropdown = 1000;
  static const double zIndexModal = 1500;
  static const double zIndexTooltip = 2000;
  static const double zIndexSnackbar = 2500;

  // Semantic Colors (além do ColorScheme)
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF388E3C);

  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color info = Color(0xFF2196F3);
  static const Color infoDark = Color(0xFF1976D2);

  // Status Colors
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusError = Color(0xFFF44336);

  // Legal Area Colors
  static const Map<String, Color> legalAreaColors = {
    'civil': Color(0xFF2196F3),
    'criminal': Color(0xFFF44336),
    'corporate': Color(0xFF673AB7),
    'labor': Color(0xFF009688),
    'tax': Color(0xFFFF9800),
    'family': Color(0xFFE91E63),
    'intellectual': Color(0xFF3F51B5),
    'environmental': Color(0xFF4CAF50),
    'constitutional': Color(0xFF795548),
    'administrative': Color(0xFF607D8B),
  };
}

/// Extensões para usar os tokens facilmente
extension LitigSpacing on double {
  SizedBox get verticalSpace => SizedBox(height: this);
  SizedBox get horizontalSpace => SizedBox(width: this);
  EdgeInsets get allPadding => EdgeInsets.all(this);
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: this);
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: this);
  BorderRadius get circularRadius => BorderRadius.circular(this);
}

extension LitigColor on Color {
  /// Converte para MaterialColor se necessário
  MaterialColor get materialColor {
    return MaterialColor(value, <int, Color>{
      50: withOpacity(0.1),
      100: withOpacity(0.2),
      200: withOpacity(0.3),
      300: withOpacity(0.4),
      400: withOpacity(0.6),
      500: this,
      600: withOpacity(0.8),
      700: withOpacity(0.9),
      800: withOpacity(0.95),
      900: withOpacity(1.0),
    });
  }
}

/// Widgets pré-configurados com design tokens
class LitigCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;

  const LitigCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? LitigDesignTokens.elevationMd,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: LitigDesignTokens.radiusMd.circularRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: LitigDesignTokens.radiusMd.circularRadius,
        child: Padding(
          padding: padding ?? LitigDesignTokens.spaceLg.allPadding,
          child: child,
        ),
      ),
    );
  }
}

class LitigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LitigButtonSize size;
  final LitigButtonVariant variant;
  final bool isDestructive;

  const LitigButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = LitigButtonSize.medium,
    this.variant = LitigButtonVariant.primary,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = _getHeight();
    final textStyle = _getTextStyle(context);
    
    Widget button;
    
    switch (variant) {
      case LitigButtonVariant.primary:
        button = ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: _getIconSize()) : null,
          label: Text(label, style: textStyle),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, height),
            backgroundColor: isDestructive 
                ? Theme.of(context).colorScheme.error 
                : Theme.of(context).colorScheme.primary,
          ),
        );
        break;
      case LitigButtonVariant.secondary:
        button = OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: _getIconSize()) : null,
          label: Text(label, style: textStyle),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, height),
            foregroundColor: isDestructive 
                ? Theme.of(context).colorScheme.error 
                : Theme.of(context).colorScheme.primary,
          ),
        );
        break;
      case LitigButtonVariant.text:
        button = TextButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: _getIconSize()) : null,
          label: Text(label, style: textStyle),
          style: TextButton.styleFrom(
            minimumSize: Size(double.infinity, height),
            foregroundColor: isDestructive 
                ? Theme.of(context).colorScheme.error 
                : Theme.of(context).colorScheme.primary,
          ),
        );
        break;
    }

    return SizedBox(height: height, child: button);
  }

  double _getHeight() {
    switch (size) {
      case LitigButtonSize.small:
        return LitigDesignTokens.buttonSm;
      case LitigButtonSize.medium:
        return LitigDesignTokens.buttonMd;
      case LitigButtonSize.large:
        return LitigDesignTokens.buttonLg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case LitigButtonSize.small:
        return LitigDesignTokens.iconSm;
      case LitigButtonSize.medium:
        return LitigDesignTokens.iconMd;
      case LitigButtonSize.large:
        return LitigDesignTokens.iconLg;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge!;
    
    switch (size) {
      case LitigButtonSize.small:
        return base.copyWith(fontSize: LitigDesignTokens.fontSm);
      case LitigButtonSize.medium:
        return base.copyWith(fontSize: LitigDesignTokens.fontMd);
      case LitigButtonSize.large:
        return base.copyWith(fontSize: LitigDesignTokens.fontLg);
    }
  }
}

enum LitigButtonSize { small, medium, large }
enum LitigButtonVariant { primary, secondary, text }

class LitigChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  const LitigChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    
    return Material(
      color: selected 
          ? effectiveColor.withOpacity(0.1)
          : theme.colorScheme.surface,
      borderRadius: LitigDesignTokens.radiusFull.circularRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: LitigDesignTokens.radiusFull.circularRadius,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: LitigDesignTokens.spaceMd,
            vertical: LitigDesignTokens.spaceXs,
          ),
          decoration: BoxDecoration(
            borderRadius: LitigDesignTokens.radiusFull.circularRadius,
            border: Border.all(
              color: selected ? effectiveColor : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: LitigDesignTokens.iconSm,
                  color: selected ? effectiveColor : theme.colorScheme.onSurface,
                ),
                LitigDesignTokens.spaceXs.horizontalSpace,
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? effectiveColor : theme.colorScheme.onSurface,
                  fontWeight: selected 
                      ? LitigDesignTokens.fontSemiBold 
                      : LitigDesignTokens.fontRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 