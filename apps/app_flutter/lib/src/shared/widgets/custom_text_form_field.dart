import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget customizado para campos de formulário com recursos avançados
class CustomTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final IconData? suffixIconData;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final Color? fillColor;
  final bool filled;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool isDense;
  final String? initialValue;
  final bool showCounter;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.suffixIconData,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.contentPadding,
    this.border,
    this.fillColor,
    this.filled = true,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.isDense = false,
    this.initialValue,
    this.showCounter = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          initialValue: widget.initialValue,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: _buildPrefixIcon(),
            suffixIcon: _buildSuffixIcon(),
            filled: widget.filled,
            fillColor: widget.fillColor ?? _getFillColor(colorScheme),
            border: widget.border ?? _getBorder(colorScheme),
            enabledBorder: _getEnabledBorder(colorScheme),
            focusedBorder: _getFocusedBorder(colorScheme),
            errorBorder: _getErrorBorder(colorScheme),
            focusedErrorBorder: _getFocusedErrorBorder(colorScheme),
            disabledBorder: _getDisabledBorder(colorScheme),
            contentPadding: widget.contentPadding ?? _getContentPadding(),
            isDense: widget.isDense,
            counterText: widget.showCounter ? null : "",
            labelStyle: widget.labelStyle,
            hintStyle: widget.hintStyle ?? theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          style: widget.style ?? theme.textTheme.bodyLarge,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onSaved: widget.onSaved,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: _obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
        ),
      ],
    );
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixWidget != null) {
      return widget.prefixWidget;
    }
    
    if (widget.prefixIcon != null) {
      return Icon(
        widget.prefixIcon,
        color: _hasFocus 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
      );
    }
    
    return null;
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    List<Widget> suffixIcons = [];

    // Ícone de toggle para senha
    if (widget.obscureText) {
      suffixIcons.add(
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }

    // Ícone personalizado
    if (widget.suffixIconData != null) {
      suffixIcons.add(
        IconButton(
          icon: Icon(
            widget.suffixIconData,
            color: _hasFocus 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          onPressed: widget.onSuffixIconTap,
        ),
      );
    }

    if (suffixIcons.isEmpty) return null;

    if (suffixIcons.length == 1) {
      return suffixIcons.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: suffixIcons,
    );
  }

  Color _getFillColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }
    
    if (_hasFocus) {
      return colorScheme.surfaceContainerHighest.withOpacity(0.3);
    }
    
    return colorScheme.surfaceContainerHighest.withOpacity(0.1);
  }

  OutlineInputBorder _getBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.outline.withOpacity(0.5),
        width: 1,
      ),
    );
  }

  OutlineInputBorder _getEnabledBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.outline.withOpacity(0.5),
        width: 1,
      ),
    );
  }

  OutlineInputBorder _getFocusedBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.primary,
        width: 2,
      ),
    );
  }

  OutlineInputBorder _getErrorBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 1,
      ),
    );
  }

  OutlineInputBorder _getFocusedErrorBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 2,
      ),
    );
  }

  OutlineInputBorder _getDisabledBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.outline.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  EdgeInsetsGeometry _getContentPadding() {
    if (widget.isDense) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    
    if (widget.maxLines > 1) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    }
    
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
  }
}

/// Variantes específicas de campos

/// Campo para CPF com formatação automática
class CPFFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const CPFFormField({
    super.key,
    this.controller,
    this.labelText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText ?? 'CPF',
      hintText: '000.000.000-00',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CPFInputFormatter(),
      ],
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: Icons.person,
    );
  }
}

/// Campo para CNPJ com formatação automática
class CNPJFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const CNPJFormField({
    super.key,
    this.controller,
    this.labelText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText ?? 'CNPJ',
      hintText: '00.000.000/0000-00',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CNPJInputFormatter(),
      ],
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: Icons.business,
    );
  }
}

/// Campo para telefone com formatação automática
class PhoneFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const PhoneFormField({
    super.key,
    this.controller,
    this.labelText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText ?? 'Telefone',
      hintText: '(11) 99999-9999',
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        PhoneInputFormatter(),
      ],
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: Icons.phone,
    );
  }
}

// Formatadores de entrada

/// Formatador para CPF
class CPFInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formatador para CNPJ
class CNPJInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formatador para telefone
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if ((text.length == 10 && i == 6) || (text.length == 11 && i == 7)) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}