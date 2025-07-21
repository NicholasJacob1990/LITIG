import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_extensions.dart';
import 'package:meu_app/src/shared/constants/case_type_constants.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_social_links.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

class CaseListCard extends StatelessWidget {
  final String caseId;
  final String caseTitle;
  final String caseSubtitle;
  final String clientType;
  final String status;
  final String preAnalysisDate;
  final LawyerInfo lawyer;
  final VoidCallback onPressPreAnalysis;
  final Case? caseData; // Dados completos do caso para acessar o tipo

  const CaseListCard({
    super.key,
    required this.caseId,
    required this.caseTitle,
    required this.caseSubtitle,
    required this.clientType,
    required this.status,
    required this.preAnalysisDate,
    required this.lawyer,
    required this.onPressPreAnalysis,
    this.caseData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/cases/$caseId'),
        borderRadius: BorderRadius.circular(12),
      child: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              _buildCardHeader(),
              const SizedBox(height: 12),
              Text(caseTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
              Text(caseSubtitle, style: TextStyle(color: Colors.grey[600])),
              const Divider(height: 24),
              _buildLawyerInfo(),
              const SizedBox(height: 16),
              _buildCardFooter(context),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Indicador de tipo compacto
        if (caseData?.caseType != null)
          _buildListTypeIndicator(),
        // Status adaptativo
        Chip(
          label: Text(_getStatusDisplayText()),
          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
          labelStyle: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        // Tipo de cliente
        Chip(
          avatar: Icon(clientType == 'PF' ? LucideIcons.user : LucideIcons.building, size: 16),
          label: Text(clientType == 'PF' ? 'Pessoa Física' : 'Pessoa Jurídica'),
          backgroundColor: Colors.grey[200],
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildLawyerInfo() {
    return Row(
              children: [
                CircleAvatar(
          backgroundImage: NetworkImage(lawyer.avatarUrl),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(lawyer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
              Text(lawyer.specialty, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  // Ícones das redes sociais
                  LawyerSocialLinks(
                    linkedinUrl: 'https://linkedin.com/in/${lawyer.name.toLowerCase().replaceAll(' ', '-')}',
                    instagramUrl: 'https://instagram.com/${lawyer.name.toLowerCase().replaceAll(' ', '')}',
                    facebookUrl: 'https://facebook.com/${lawyer.name.toLowerCase().replaceAll(' ', '.')}',
                  ),
                ],
              ),
            ],
          ),
                    ),
                    if (lawyer.unreadMessages > 0)
                      Container(
            padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${lawyer.unreadMessages}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
    );
  }

  Widget _buildCardFooter(BuildContext context) {
    return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
        TextButton(
          onPressed: onPressPreAnalysis,
          child: const Text('Ver Pré-Análise da IA'),
        ),
                    Text(
          'Criado em: ${lawyer.createdDate}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
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

  // Indicador de tipo compacto para lista
  Widget _buildListTypeIndicator() {
    if (caseData?.caseType == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          Icon(caseData!.typeIcon, size: 10, color: caseData!.typeColor),
          const SizedBox(width: 4),
          Text(
            caseData!.typeDisplayName,
            style: TextStyle(
              fontSize: 9,
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
    return statusMapping[status] ?? status;
  }
} 