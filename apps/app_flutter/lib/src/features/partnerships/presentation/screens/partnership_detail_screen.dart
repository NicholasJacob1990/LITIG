import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

class PartnershipDetailScreen extends StatelessWidget {
  final String partnershipId;
  final Partnership? initialData;

  const PartnershipDetailScreen({
    super.key,
    required this.partnershipId,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Parceria'),
        actions: [
          IconButton(
            tooltip: 'Ir para conversa',
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              if (data != null && data.partnerType == PartnerEntityType.lawyer && data.partnerAsLawyer != null) {
                final partner = data.partnerAsLawyer!;
                context.go('/internal-chat/${partner.id}?recipientName=${Uri.encodeComponent(partner.name)}');
              }
            },
          )
        ],
      ),
      body: data == null
          ? _buildLoadingPlaceholder(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, data),
                  const SizedBox(height: 16),
                  _buildOverviewCards(context, data),
                  const SizedBox(height: 16),
                  _buildActions(context, data),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 24, width: 160, color: theme.colorScheme.surfaceVariant),
          const SizedBox(height: 12),
          Container(height: 16, width: 220, color: theme.colorScheme.surfaceVariant),
          const SizedBox(height: 24),
          Container(height: 120, color: theme.colorScheme.surfaceVariant),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Partnership partnership) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partnership.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(partnership.type.toString().split('.').last)),
                const SizedBox(width: 8),
                Chip(label: Text(partnership.status.toString().split('.').last)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    partnership.partnerName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, Partnership partnership) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Honorários', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text('A definir', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data de Início', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text('${partnership.createdAt.day}/${partnership.createdAt.month}/${partnership.createdAt.year}', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Partnership partnership) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/partnerships/${partnership.id}'),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Ver Contrato'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/chat/${partnership.id}?otherPartyName=${Uri.encodeComponent(partnership.partnerName)}'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Abrir Chat'),
          ),
        ),
      ],
    );
  }
}


