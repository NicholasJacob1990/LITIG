import 'package:flutter/material.dart';

/// Um widget para exibir um estado vazio de forma amigável.
///
/// Usado quando uma lista está vazia ou nenhum resultado de busca é encontrado.
class EmptyStateWidget extends StatelessWidget {
  /// O ícone a ser exibido acima da mensagem.
  final IconData icon;
  /// A mensagem principal a ser exibida.
  final String message;
  /// O texto do botão de ação opcional.
  final String? actionText;
  /// O callback a ser executado quando o botão de ação for pressionado.
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: textTheme.bodyLarge?.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 