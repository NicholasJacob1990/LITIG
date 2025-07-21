import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_social_links.dart';

class CaseCard extends StatelessWidget {
  final String caseId;
  final String title;
  final String subtitle;
  final String clientType;
  final String status;
  final String preAnalysisDate;
  final LawyerInfo? lawyer;
  final Case? caseData; // Dados completos do caso para acessar recommendedFirm

  const CaseCard({
    super.key,
    required this.caseId,
    required this.title,
    required this.subtitle,
    required this.clientType,
    required this.status,
    required this.preAnalysisDate,
    this.lawyer,
    this.caseData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/case-detail/$caseId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Text(
                subtitle, 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
                )
              ),
              const SizedBox(height: 16),
              _buildPreAnalysisSection(context),
              
              // Seção de recomendação de escritório (para casos corporativos)
              if (caseData?.shouldShowFirmRecommendation == true) ...[
                Divider(height: 32, thickness: 1, color: theme.dividerColor),
                _buildFirmRecommendationSection(context),
              ],
              
              if (lawyer != null) ...[
                Divider(height: 32, thickness: 1, color: theme.dividerColor),
                _buildLawyerSection(),
              ] else ...[
                const SizedBox(height: 16),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push('/case-detail/$caseId'),
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: const Text('Ver Detalhes'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    // NOVO: Adiciona o badge de alocação, se existir
    final allocationBadge = _buildAllocationBadge(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title, 
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, 
              color: theme.colorScheme.onSurface
            )
          ),
        ),
        // NOVO: Renderiza o badge
        if (allocationBadge != null) ...[
          allocationBadge,
          const SizedBox(width: 8),
        ],
        // Indicador de complexidade para casos corporativos
        if (caseData?.isHighComplexity == true) ...[
          Chip(
            avatar: Icon(
              LucideIcons.briefcase, 
              size: 14, 
              color: theme.colorScheme.tertiary
            ),
            label: Text(
              'Corporativo', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500, 
                color: theme.colorScheme.onSurface
              )
            ),
            backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), 
              side: BorderSide.none
            ),
          ),
          const SizedBox(width: 8),
        ],
        Chip(
          avatar: Icon(
            clientType == 'PF' ? LucideIcons.user : LucideIcons.building, 
            size: 14, 
            color: theme.colorScheme.primary
          ),
          label: Text(
            clientType, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500, 
              color: theme.colorScheme.onSurface
            )
          ),
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), 
            side: BorderSide.none
          ),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(
            status, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500, 
              color: _getStatusColor(status)
            )
          ),
          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), 
            side: BorderSide.none
          ),
        ),
      ],
    );
  }

  // NOVO WIDGET PARA O BADGE DE ALOCAÇÃO
  Widget? _buildAllocationBadge(BuildContext context) {
    if (caseData?.allocationType == null || caseData!.allocationType!.isEmpty) {
      return null;
    }

    final theme = Theme.of(context);
    final type = caseData!.allocationType!;

    final Map<String, Map<String, dynamic>> badgeConfig = {
      'direct': {'label': 'Direto', 'icon': LucideIcons.userCheck, 'color': Colors.green},
      'partnership': {'label': 'Parceria', 'icon': LucideIcons.users, 'color': Colors.orange},
      'proactive': {'label': 'Proativo', 'icon': LucideIcons.zap, 'color': Colors.purple},
      'suggestion': {'label': 'Sugestão', 'icon': LucideIcons.sparkles, 'color': Colors.cyan},
      'delegation': {'label': 'Delegação', 'icon': LucideIcons.gitBranchPlus, 'color': Colors.blueGrey}, // Ícone corrigido
      'dual': {'label': 'Duplo', 'icon': LucideIcons.copy, 'color': Colors.indigo},
    };

    final config = badgeConfig[type] ?? {'label': type, 'icon': LucideIcons.file, 'color': Colors.grey};

    return Chip(
      key: Key('allocation_badge_$type'), // Chave para os testes de integração
      avatar: Icon(
        config['icon'], 
        size: 14, 
        color: config['color']
      ),
      label: Text(
        config['label'],
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: (config['color'] as Color).withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildPreAnalysisSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.colorScheme.secondary, width: 4)),
        color: theme.colorScheme.secondary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.bot, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pré-análise IA gerada em $preAnalysisDate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // TODO: Navigate to AI analysis screen
            },
            icon: Icon(LucideIcons.fileJson, size: 16, color: theme.colorScheme.secondary),
            label: Text(
              'Ver', 
              style: TextStyle(
                color: theme.colorScheme.secondary, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmRecommendationSection(BuildContext context) {
    final theme = Theme.of(context);
    final firm = caseData?.recommendedFirm;
    final matchScore = caseData?.firmMatchScore;

    if (firm == null) {
      return _buildFirmRecommendationPlaceholder(context);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.colorScheme.tertiary, width: 4)),
        color: theme.colorScheme.tertiary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.building2, color: theme.colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Escritório Recomendado',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (matchScore != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(matchScore * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.briefcase,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firm.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${firm.teamSize} advogados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (firm.kpis != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(firm.kpis!.successRate * 100).toInt()}% sucesso',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/firm/${firm.id}'),
                icon: const Icon(LucideIcons.externalLink, size: 16),
                label: const Text('Ver'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirmRecommendationPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.colorScheme.outline, width: 4)),
        color: theme.colorScheme.outline.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(LucideIcons.building2, color: theme.colorScheme.outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisando escritórios especializados...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recomendação será exibida após matching B2B',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerSection() {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      if (lawyer == null) return const SizedBox.shrink();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: lawyer!.avatarUrl,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              backgroundImage: imageProvider, 
              radius: 24
            ),
            placeholder: (context, url) => const CircleAvatar(
              radius: 24, 
              child: CircularProgressIndicator()
            ),
            errorWidget: (context, url, error) => InitialsAvatar(
              text: lawyer!.name, 
              radius: 24
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lawyer!.name, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.onSurface
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  lawyer!.specialty, 
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
                  )
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Criado em ${lawyer!.createdDate}', 
                      style: TextStyle(
                        fontSize: 12, 
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
                      )
                    ),
                    const Spacer(),
                    // Ícones das redes sociais
                    LawyerSocialLinks(
                      linkedinUrl: 'https://linkedin.com/in/${lawyer!.name.toLowerCase().replaceAll(' ', '-')}',
                      instagramUrl: 'https://instagram.com/${lawyer!.name.toLowerCase().replaceAll(' ', '')}',
                      facebookUrl: 'https://facebook.com/${lawyer!.name.toLowerCase().replaceAll(' ', '.')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (lawyer!.unreadMessages > 0)
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.messageCircle, 
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5), 
                  size: 28
                ),
                Positioned(
                  top: -2,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error, 
                      shape: BoxShape.circle
                    ),
                    child: Text(
                      '${lawyer!.unreadMessages}',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Em Andamento':
        return Colors.blue;
      case 'Concluído':
        return Colors.green;
      case 'Aguardando':
        return Colors.orange;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 