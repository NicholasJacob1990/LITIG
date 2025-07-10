import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExplanationModal extends StatelessWidget {
  final String explanation; // A explicação gerada pela IA
  final Map<String, dynamic> lawyer; // Dados do advogado

  const ExplanationModal({
    super.key,
    required this.explanation,
    required this.lawyer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Análise do Match',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'Por que recomendamos ${lawyer['nome'] ?? 'este advogado'}?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            explanation,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ),
        ],
      ),
    );
  }
} 