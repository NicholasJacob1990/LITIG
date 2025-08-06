import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_social_links.dart';
import 'package:meu_app/src/shared/widgets/instrumented_widgets.dart';

class DetailedCaseCard extends StatelessWidget {
  final String caseId;
  final String title;
  final String status;
  final double progress;
  final String nextStep;
  final LawyerInfo lawyer;
  // Novos parâmetros para instrumentação
  final String? sourceContext;
  final String? listContext;
  final double? listRank;

  const DetailedCaseCard({
    super.key,
    required this.caseId,
    required this.title,
    required this.status,
    required this.progress,
    required this.nextStep,
    required this.lawyer,
    this.sourceContext,
    this.listContext,
    this.listRank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InstrumentedContentCard(
      contentId: caseId,
      contentType: 'detailed_case',
      sourceContext: sourceContext ?? 'detailed_case_list',
      listContext: listContext,
      listRank: listRank,
      onTap: () => context.go('/case-detail/$caseId'),
      additionalData: {
        'case_status': status,
        'progress_percentage': progress,
        'lawyer_name': lawyer.name,
        'has_next_step': nextStep.isNotEmpty,
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black26,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => context.go('/case-detail/$caseId'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLawyerHeader(context),
                const SizedBox(height: 16),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                _buildProgressSection(context),
                const SizedBox(height: 12),
                _buildNextStepSection(context),
                const Divider(height: 24),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CachedNetworkImage(
          imageUrl: lawyer.avatarUrl,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            backgroundImage: imageProvider,
            radius: 20,
          ),
          placeholder: (context, url) => const CircleAvatar(radius: 20, child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => InitialsAvatar(text: lawyer.name, radius: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lawyer.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Row(
                children: [
                  Text(lawyer.specialty, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
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
        Chip(
          label: Text(status),
          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
          labelStyle: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progresso', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildNextStepSection(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(LucideIcons.flag, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text('Próxima etapa: ', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        Expanded(child: Text(nextStep, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InstrumentedButton(
          elementId: 'detailed_case_ai_summary_$caseId',
          context: 'detailed_case_card',
          onPressed: () {}, // TODO: Implementar ação
          additionalData: {
            'case_id': caseId,
            'action_type': 'ai_summary',
            'case_status': status,
            'progress': progress,
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bot, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text('Resumo IA', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
        InstrumentedButton(
          elementId: 'detailed_case_chat_$caseId',
          context: 'detailed_case_card',
          onPressed: () {}, // TODO: Implementar ação
          additionalData: {
            'case_id': caseId,
            'action_type': 'chat',
            'lawyer_name': lawyer.name,
            'case_status': status,
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.messageCircle, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text('Chat', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
        InstrumentedButton(
          elementId: 'detailed_case_documents_$caseId',
          context: 'detailed_case_card',
          onPressed: () {}, // TODO: Implementar ação
          additionalData: {
            'case_id': caseId,
            'action_type': 'documents',
            'case_status': status,
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.folder, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text('Documentos', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Em Andamento':
        return AppColors.warning;
      case 'Concluído':
        return AppColors.success;
      case 'Aguardando':
        return AppColors.info;
      default:
        return AppColors.info; // Fallback
    }
  }
} 
