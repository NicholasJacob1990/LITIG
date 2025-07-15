import 'package:flutter/material.dart';
import '../../domain/entities/partnership.dart';

class PartnershipCard extends StatelessWidget {
  final Partnership partnership;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onAcceptContract;
  final VoidCallback? onGenerateContract;

  const PartnershipCard({
    super.key,
    required this.partnership,
    this.onAccept,
    this.onReject,
    this.onAcceptContract,
    this.onGenerateContract,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    partnership.partnerName ?? 'Parceiro',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              partnership.typeDisplayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Honorários: ${partnership.honorarios}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (partnership.proposalMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                partnership.proposalMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Criado em: ${_formatDate(partnership.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    switch (partnership.status) {
      case PartnershipStatus.pendente:
        color = Colors.orange;
        break;
      case PartnershipStatus.aceita:
        color = Colors.green;
        break;
      case PartnershipStatus.rejeitada:
        color = Colors.red;
        break;
      case PartnershipStatus.contratoPendente:
        color = Colors.blue;
        break;
      case PartnershipStatus.ativa:
        color = Colors.green;
        break;
      case PartnershipStatus.finalizada:
        color = Colors.grey;
        break;
      case PartnershipStatus.cancelada:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        partnership.statusDisplayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (partnership.status == PartnershipStatus.pendente) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onReject != null)
            TextButton(
              onPressed: onReject,
              child: const Text('Rejeitar'),
            ),
          const SizedBox(width: 8),
          if (onAccept != null)
            ElevatedButton(
              onPressed: onAccept,
              child: const Text('Aceitar'),
            ),
        ],
      );
    }

    if (partnership.status == PartnershipStatus.contratoPendente) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onGenerateContract != null)
            TextButton(
              onPressed: onGenerateContract,
              child: const Text('Gerar Contrato'),
            ),
          const SizedBox(width: 8),
          if (onAcceptContract != null)
            ElevatedButton(
              onPressed: onAcceptContract,
              child: const Text('Aceitar Contrato'),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 