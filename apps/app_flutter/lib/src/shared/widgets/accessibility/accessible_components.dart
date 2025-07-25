import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Componentes acessíveis para o LITIG-1
/// 
/// Seguem diretrizes WCAG 2.1 AA para:
/// - Screen readers
/// - Alto contraste
/// - Navegação por teclado
/// - Tamanhos mínimos de toque

/// Card acessível para perfis de advogados e escritórios
class AccessibleProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final Widget? avatar;
  final List<AccessibleAction> actions;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleProfileCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.description,
    this.avatar,
    this.actions = const [],
    this.onTap,
    this.isHighlighted = false,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Cores com alto contraste
    final backgroundColor = isHighlighted 
        ? colorScheme.primaryContainer 
        : colorScheme.surface;
    final foregroundColor = isHighlighted 
        ? colorScheme.onPrimaryContainer 
        : colorScheme.onSurface;

    return Semantics(
      label: semanticLabel ?? _buildSemanticLabel(),
      hint: semanticHint ?? 'Toque duas vezes para abrir',
      button: onTap != null,
      enabled: onTap != null,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted 
                    ? colorScheme.primary 
                    : colorScheme.outline.withOpacity(0.2),
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, foregroundColor),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  _buildDescription(theme, foregroundColor),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildActions(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color foregroundColor) {
    return Row(
      children: [
        if (avatar != null) ...[
          SizedBox(
            width: 48,
            height: 48,
            child: avatar!,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme, Color foregroundColor) {
    return Text(
      description!,
      style: theme.textTheme.bodySmall?.copyWith(
        color: foregroundColor.withOpacity(0.7),
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) => AccessibleButton(
        onPressed: action.onPressed,
        label: action.label,
        icon: action.icon,
        type: action.type,
        size: AccessibleButtonSize.small,
      )).toList(),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>[title, subtitle];
    if (description != null) parts.add(description!);
    return parts.join(', ');
  }
}

/// Ação acessível para cards
class AccessibleAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final AccessibleButtonType type;

  const AccessibleAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = AccessibleButtonType.secondary,
  });
}

/// Botão acessível com tamanho mínimo de toque
class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final AccessibleButtonType type;
  final AccessibleButtonSize size;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isDestructive;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.type = AccessibleButtonType.primary,
    this.size = AccessibleButtonSize.medium,
    this.semanticLabel,
    this.semanticHint,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Tamanho mínimo de toque (44px conforme WCAG)
    final minSize = size == AccessibleButtonSize.small ? 36.0 : 44.0;
    
    // Cores baseadas no tipo e estado
    final colors = _getButtonColors(colorScheme);

    return Semantics(
      label: semanticLabel ?? label,
      hint: semanticHint ?? (onPressed != null ? 'Botão' : 'Botão desabilitado'),
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        height: minSize,
        child: _buildButtonByType(theme, colors, minSize),
      ),
    );
  }

  Widget _buildButtonByType(ThemeData theme, _ButtonColors colors, double minSize) {
    switch (type) {
      case AccessibleButtonType.primary:
        return ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : null,
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            minimumSize: Size(minSize, minSize),
          ),
        );
      
      case AccessibleButtonType.secondary:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : null,
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.foreground,
            side: BorderSide(color: colors.border),
            minimumSize: Size(minSize, minSize),
          ),
        );
      
      case AccessibleButtonType.text:
        return TextButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : null,
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: colors.foreground,
            minimumSize: Size(minSize, minSize),
          ),
        );
      
      case AccessibleButtonType.icon:
        return IconButton(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.touch_app),
          tooltip: label,
          style: IconButton.styleFrom(
            foregroundColor: colors.foreground,
            backgroundColor: colors.background,
            minimumSize: Size(minSize, minSize),
          ),
        );
    }
  }

  _ButtonColors _getButtonColors(ColorScheme colorScheme) {
    if (isDestructive) {
      return _ButtonColors(
        background: colorScheme.error,
        foreground: colorScheme.onError,
        border: colorScheme.error,
      );
    }

    switch (type) {
      case AccessibleButtonType.primary:
        return _ButtonColors(
          background: colorScheme.primary,
          foreground: colorScheme.onPrimary,
          border: colorScheme.primary,
        );
      
      case AccessibleButtonType.secondary:
        return _ButtonColors(
          background: colorScheme.surface,
          foreground: colorScheme.primary,
          border: colorScheme.primary,
        );
      
      case AccessibleButtonType.text:
      case AccessibleButtonType.icon:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: colorScheme.primary,
          border: Colors.transparent,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

enum AccessibleButtonType { primary, secondary, text, icon }
enum AccessibleButtonSize { small, medium, large }

/// Input acessível com validação e feedback
class AccessibleInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool required;
  final String? semanticLabel;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const AccessibleInput({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.required = false,
    this.semanticLabel,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;
    
    return Semantics(
      label: semanticLabel ?? _buildSemanticLabel(),
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label com indicador de obrigatório
          RichText(
            text: TextSpan(
              text: label,
              style: theme.textTheme.labelMedium,
              children: required ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ] : null,
            ),
          ),
          const SizedBox(height: 8),
          
          // Campo de texto
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2,
                ),
              ),
            ),
          ),
          
          // Texto de ajuda ou erro
          if (hint != null && !hasError) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>[label];
    if (required) parts.add('obrigatório');
    if (hint != null) parts.add(hint!);
    if (errorText != null) parts.add('erro: $errorText');
    return parts.join(', ');
  }
}

/// Chip acessível com contraste melhorado
class AccessibleChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool selected;
  final String? semanticLabel;

  const AccessibleChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
    this.onDeleted,
    this.selected = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Cores com alto contraste
    final effectiveBackgroundColor = backgroundColor ?? 
        (selected ? colorScheme.primaryContainer : colorScheme.surfaceVariant);
    final effectiveTextColor = textColor ?? 
        (selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant);

    return Semantics(
      label: semanticLabel ?? label,
      button: onTap != null,
      selected: selected,
      child: Material(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colorScheme.primary : Colors.transparent,
                width: selected ? 1.5 : 0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: effectiveTextColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: effectiveTextColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (onDeleted != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDeleted,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: effectiveTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para anúncios ao screen reader
class AccessibleAnnouncement extends StatelessWidget {
  final String message;
  final Widget child;

  const AccessibleAnnouncement({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Semantics(
        label: message,
        child: child,
      ),
    );
  }

  /// Anuncia uma mensagem para screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}

/// Indicador de carregamento acessível
class AccessibleLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? value;
  final bool showMessage;

  const AccessibleLoadingIndicator({
    super.key,
    this.message,
    this.value,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMessage = message ?? 'Carregando';
    
    return Semantics(
      label: effectiveMessage,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            value: value,
            semanticsLabel: effectiveMessage,
          ),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              effectiveMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin para adicionar comportamentos acessíveis a widgets
mixin AccessibilityMixin<T extends StatefulWidget> on State<T> {
  
  /// Anuncia uma mudança de estado para screen readers
  void announceStateChange(String message) {
    AccessibleAnnouncement.announce(context, message);
  }
  
  /// Foca em um widget específico
  void focusNode(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      node.requestFocus();
    });
  }
  
  /// Scroll para tornar um elemento visível
  void ensureVisible(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
} 