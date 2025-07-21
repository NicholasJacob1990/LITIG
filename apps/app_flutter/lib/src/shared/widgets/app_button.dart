import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_colors.dart';

/// Enum para variantes do botão
enum AppButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
  success,
  warning,
  ghost,
  outline
}

/// Enum para tamanhos do botão
enum AppButtonSize {
  small,
  medium,
  large,
  extraLarge
}

/// Widget de botão personalizado do app
/// 
/// Implementa o design system com variantes e tamanhos consistentes
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.suffixIcon,
    this.fullWidth = false,
    this.padding,
    this.borderRadius,
  });

  /// Factory constructor para botão primário
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    IconData? suffixIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      suffixIcon: suffixIcon,
      fullWidth: fullWidth,
    );
  }

  /// Factory constructor para botão secundário
  factory AppButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    IconData? suffixIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      suffixIcon: suffixIcon,
      fullWidth: fullWidth,
    );
  }

  /// Factory constructor para botão outline
  factory AppButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    IconData? suffixIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      suffixIcon: suffixIcon,
      fullWidth: fullWidth,
    );
  }

  /// Factory constructor para botão ghost
  factory AppButton.ghost({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    IconData? suffixIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.ghost,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      suffixIcon: suffixIcon,
      fullWidth: fullWidth,
    );
  }

  /// Factory constructor para botão de perigo
  factory AppButton.danger({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    IconData? suffixIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      suffixIcon: suffixIcon,
      fullWidth: fullWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = _getButtonStyle(theme);
    final textStyle = _getTextStyle();
    final buttonPadding = padding ?? _getPadding();
    final buttonBorderRadius = borderRadius ?? _getBorderRadius();

    Widget buttonChild = _buildButtonContent(textStyle);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: buttonStyle.copyWith(
          padding: WidgetStateProperty.all(buttonPadding),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: buttonBorderRadius),
          ),
        ),
        child: buttonChild,
      ),
    );
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }

    final widgets = <Widget>[];

    if (icon != null) {
      widgets.add(Icon(icon, size: _getIconSize()));
      widgets.add(SizedBox(width: _getIconSpacing()));
    }

    widgets.add(
      Text(
        text,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );

    if (suffixIcon != null) {
      widgets.add(SizedBox(width: _getIconSpacing()));
      widgets.add(Icon(suffixIcon, size: _getIconSize()));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final colors = _getColors();
    
    return ElevatedButton.styleFrom(
      backgroundColor: colors['background'],
      foregroundColor: colors['foreground'],
      disabledBackgroundColor: colors['disabledBackground'],
      disabledForegroundColor: colors['disabledForeground'],
      elevation: _getElevation(),
      side: _getBorderSide(),
    );
  }

  Map<String, Color> _getColors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return {
          'background': AppColors.primaryBlue,
          'foreground': Colors.white,
          'disabledBackground': AppColors.lightBorder,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.secondary:
        return {
          'background': AppColors.lightCard,
          'foreground': AppColors.primaryBlue,
          'disabledBackground': AppColors.lightBorder,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.tertiary:
        return {
          'background': AppColors.lightBackground,
          'foreground': AppColors.lightText,
          'disabledBackground': AppColors.lightBorder,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.danger:
        return {
          'background': AppColors.error,
          'foreground': Colors.white,
          'disabledBackground': AppColors.lightBorder,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.success:
        return {
          'background': AppColors.success,
          'foreground': Colors.white,
          'disabledBackground': AppColors.lightBorder,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.warning:
        return {
          'background': AppColors.warning,
          'foreground': Colors.white,
          'disabledBackground': AppColors.lightBorder,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.ghost:
        return {
          'background': Colors.transparent,
          'foreground': AppColors.primaryBlue,
          'disabledBackground': Colors.transparent,
          'disabledForeground': AppColors.lightTextSecondary,
        };
      case AppButtonVariant.outline:
        return {
          'background': Colors.transparent,
          'foreground': AppColors.primaryBlue,
          'disabledBackground': Colors.transparent,
          'disabledForeground': AppColors.lightTextSecondary,
        };
    }
  }

  BorderSide? _getBorderSide() {
    switch (variant) {
      case AppButtonVariant.outline:
        return const BorderSide(
          color: AppColors.primaryBlue,
          width: 1,
        );
      case AppButtonVariant.secondary:
        return const BorderSide(
          color: AppColors.lightBorder,
          width: 1,
        );
      default:
        return null;
    }
  }

  double _getElevation() {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.success:
      case AppButtonVariant.warning:
        return 2;
      case AppButtonVariant.secondary:
        return 1;
      default:
        return 0;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall;
      case AppButtonSize.large:
        return AppTextStyles.buttonLarge;
      case AppButtonSize.extraLarge:
        return AppTextStyles.buttonLarge.copyWith(fontSize: 18);
      default:
        return AppTextStyles.buttonMedium;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      case AppButtonSize.extraLarge:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  BorderRadius _getBorderRadius() {
    switch (size) {
      case AppButtonSize.small:
        return BorderRadius.circular(6);
      case AppButtonSize.large:
      case AppButtonSize.extraLarge:
        return BorderRadius.circular(12);
      default:
        return BorderRadius.circular(8);
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.large:
        return 20;
      case AppButtonSize.extraLarge:
        return 24;
      default:
        return 18;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case AppButtonSize.small:
        return 6;
      case AppButtonSize.large:
      case AppButtonSize.extraLarge:
        return 10;
      default:
        return 8;
    }
  }
}