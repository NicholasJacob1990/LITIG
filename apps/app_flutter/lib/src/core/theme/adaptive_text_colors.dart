import 'package:flutter/material.dart';

/// Helper class para cores de texto adaptativas ao tema
class AdaptiveTextColors {
  /// Cor de texto secundário (labels, descrições)
  static Color secondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  }
  
  /// Cor de texto terciário (mais sutil)
  static Color tertiary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade500 : Colors.grey.shade500;
  }
  
  /// Cor de texto desabilitado
  static Color disabled(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
  }
  
  /// Cor para ícones secundários
  static Color iconSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  }
  
  /// Cor para bordas
  static Color border(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }
  
  /// Cor para backgrounds secundários
  static Color backgroundSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade200;
  }
}