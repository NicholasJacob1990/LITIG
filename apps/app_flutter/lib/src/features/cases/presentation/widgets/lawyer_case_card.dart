import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LawyerCaseCard extends StatelessWidget {
  final String caseId;
  final String clientName;
  final String caseTitle;
  final String caseStatus;
  final double fees;
  final int unreadMessages;

  const LawyerCaseCard({
    super.key,
    required this.caseId,
    required this.clientName,
    required this.caseTitle,
    required this.caseStatus,
    required this.fees,
    required this.unreadMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/cases/$caseId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (unreadMessages > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadMessages',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(caseTitle, style: TextStyle(color: Colors.grey[600])),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(caseStatus),
                    backgroundColor: _getStatusColor(caseStatus).withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: _getStatusColor(caseStatus), fontWeight: FontWeight.bold),
                    side: BorderSide.none,
                  ),
                  Text(
                    'R\$ ${fees.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Em Andamento':
        return Colors.orange.shade700;
      case 'Concluído':
        return Colors.green.shade700;
      case 'Aguardando':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
} 