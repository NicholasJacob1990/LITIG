import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/contract.dart';

class ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback? onTap;
  final VoidCallback? onSign;
  final VoidCallback? onCancel;
  final VoidCallback? onDownload;

  const ContractCard({
    super.key,
    required this.contract,
    this.onTap,
    this.onSign,
    this.onCancel,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.caseTitle ?? 'Contrato',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.lawyerName ?? 'Advogado não especificado',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),
              _buildFeeModelInfo(context),
              const SizedBox(height: 12),
              _buildContractInfo(context),
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String label;

    switch (contract.status) {
      case 'pending-signature':
        color = Colors.orange;
        label = 'Aguardando';
        break;
      case 'active':
        color = Colors.green;
        label = 'Ativo';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Encerrado';
        break;
      case 'canceled':
        color = Colors.red;
        label = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        label = contract.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFeeModelInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_money,
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              contract.feeModelDescription,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            context,
            'Criado em',
            DateFormat('dd/MM/yyyy').format(contract.createdAt),
            Icons.calendar_today,
          ),
        ),
        if (contract.signedClient != null)
          Expanded(
            child: _buildInfoItem(
              context,
              'Assinado pelo Cliente',
              DateFormat('dd/MM/yyyy').format(contract.signedClient!),
              Icons.person,
            ),
          ),
        if (contract.signedLawyer != null)
          Expanded(
            child: _buildInfoItem(
              context,
              'Assinado pelo Advogado',
              DateFormat('dd/MM/yyyy').format(contract.signedLawyer!),
              Icons.gavel,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (contract.isPendingSignature && onSign != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSign,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Assinar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        if (contract.isPendingSignature && onCancel != null) ...[
          if (onSign != null) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        if (contract.docUrl != null && onDownload != null) ...[
          if (contract.isPendingSignature) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Baixar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}