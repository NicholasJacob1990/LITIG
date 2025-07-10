import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/theme.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';

class CaseCard extends StatelessWidget {
  final String caseId;
  final String title;
  final String subtitle;
  final String clientType;
  final String status;
  final String preAnalysisDate;
  final LawyerInfo? lawyer;

  const CaseCard({
    super.key,
    required this.caseId,
    required this.title,
    required this.subtitle,
    required this.clientType,
    required this.status,
    required this.preAnalysisDate,
    this.lawyer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.go('/cases/$caseId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              _buildPreAnalysisSection(context),
              if (lawyer != null) ...[
                const SizedBox(height: 16),
                _buildLawyerSection(),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/cases/$caseId'),
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: const Text('Ver Detalhes'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: theme.textTheme.displayLarge?.copyWith(fontSize: 18)),
        ),
        Chip(
          avatar: Icon(clientType == 'PF' ? LucideIcons.user : LucideIcons.building, size: 16, color: AppColors.primaryBlue),
          label: Text(clientType, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        ),
        const SizedBox(width: 8),
        Chip(
          avatar: Icon(Icons.circle, size: 8, color: _getStatusColor(status)),
          label: Text(status, style: TextStyle(fontSize: 12, color: _getStatusColor(status))),
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildPreAnalysisSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.highlightPurple.withOpacity(0.2)),
        color: AppColors.highlightPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(LucideIcons.bot, color: AppColors.highlightPurple),
          const SizedBox(width: 8),
          Expanded(child: Text('Pré-análise IA gerada em $preAnalysisDate')),
          TextButton(
            onPressed: () {},
            child: const Text('Ver', style: TextStyle(color: AppColors.highlightPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerSection() {
    if (lawyer == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CachedNetworkImage(
          imageUrl: lawyer!.avatarUrl,
          imageBuilder: (context, imageProvider) => CircleAvatar(backgroundImage: imageProvider, radius: 24),
          placeholder: (context, url) => const CircleAvatar(radius: 24, child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => InitialsAvatar(text: lawyer!.name, radius: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lawyer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(lawyer!.specialty, style: const TextStyle(color: Colors.black54)),
              Text('Criado em ${lawyer!.createdDate}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ),
        if (lawyer!.unreadMessages > 0)
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(icon: const Icon(LucideIcons.messageCircle), onPressed: () {}),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${lawyer!.unreadMessages}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          )
      ],
    );
  }

   Color _getStatusColor(String status) {
    switch (status) {
      case 'Em Andamento':
        return AppColors.inProgress;
      case 'Concluído':
        return Colors.green.shade700; // Manter verde para concluído
      case 'Aguardando':
        return AppColors.primaryBlue; // Usar azul primário para aguardando
      default:
        return AppColors.secondaryText; // Usar cinza para outros status
    }
  }
} 