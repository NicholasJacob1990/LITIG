import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_extensions.dart';
import 'package:meu_app/src/shared/constants/case_type_constants.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

class LawyerCaseCard extends StatelessWidget {
  final String caseId;
  final String clientName;
  final String caseTitle;
  final String caseStatus;
  final double fees;
  final int unreadMessages;
  final Case? caseData; // Dados completos do caso para acessar o tipo

  const LawyerCaseCard({
    super.key,
    required this.caseId,
    required this.clientName,
    required this.caseTitle,
    required this.caseStatus,
    required this.fees,
    required this.unreadMessages,
    this.caseData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/case-detail/$caseId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de tipo de caso compacto
              if (caseData?.caseType != null) ...[  
                _buildLawyerTypeHeader(context),
                const SizedBox(height: 8),
              ],
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
                    label: Text(_getStatusDisplayText()),
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
              // Informação contextual específica do tipo
              if (caseData?.caseType != null) ...[  
                const SizedBox(height: 8),
                _buildLawyerContextualInfo(context),
              ],
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

  // Badge de tipo compacto para advogados
  Widget _buildLawyerTypeHeader(BuildContext context) {
    if (caseData?.caseType == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: caseData!.typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: caseData!.typeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(caseData!.typeIcon, size: 12, color: caseData!.typeColor),
          const SizedBox(width: 4),
          Text(
            caseData!.typeDisplayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: caseData!.typeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Status adaptativo
  String _getStatusDisplayText() {
    final statusMapping = CaseTypeConstants.getStatusMapping(caseData?.caseType);
    return statusMapping[caseStatus] ?? caseStatus;
  }

  // Informação contextual para advogados
  Widget _buildLawyerContextualInfo(BuildContext context) {
    if (caseData?.caseType == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: caseData!.typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: caseData!.typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(caseData!.typeIcon, size: 12, color: caseData!.typeColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _getContextualMessage(caseData!.caseType),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getContextualMessage(String? caseType) {
    switch (caseType) {
      case 'consultancy':
        return 'Projeto de Consultoria - Foque nas entregas';
      case 'litigation':
        return 'Processo Judicial - Monitore prazos';
      case 'contract':
        return 'Elaboração Contratual - Acompanhe negociação';
      case 'compliance':
        return 'Adequação Regulatória - Monitore prazos';
      case 'due_diligence':
        return 'Due Diligence - Foque na investigação';
      case 'ma':
        return 'Fusão/Aquisição - Acompanhe estruturação';
      case 'ip':
        return 'Propriedade Intelectual - Monitore registros';
      case 'corporate':
        return 'Governança Corporativa - Foque em compliance';
      default:
        return 'Caso Jurídico - Acompanhe o andamento';
    }
  }
} 