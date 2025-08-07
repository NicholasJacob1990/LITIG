import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_social_links.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_extensions.dart';
import 'package:meu_app/src/shared/constants/case_type_constants.dart';
import 'package:meu_app/src/shared/widgets/badges/universal_badge.dart';
import 'package:meu_app/src/shared/utils/badge_visibility_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/shared/widgets/instrumented_widgets.dart';
import 'package:meu_app/src/core/theme/adaptive_colors.dart';

class CaseCard extends StatelessWidget {
  final String caseId;
  final String title;
  final String subtitle;
  final String clientType;
  final String status;
  final String preAnalysisDate;
  final LawyerInfo? lawyer;
  final Case? caseData; // Dados completos do caso para acessar recommendedFirm
  // Novos parâmetros para instrumentação
  final String? sourceContext;
  final String? listContext;
  final double? listRank;

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
    this.sourceContext,
    this.listContext,
    this.listRank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InstrumentedContentCard(
      contentId: caseId,
      contentType: 'case',
      sourceContext: sourceContext ?? 'case_list',
      listContext: listContext,
      listRank: listRank,
      onTap: () => context.push('/case-detail/$caseId'),
      additionalData: {
        'case_status': status,
        'case_title': title,
        'client_type': clientType,
        'has_lawyer': lawyer != null,
      },
      child: Card(
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
                // NOVO: Badge Cliente VIP/Enterprise (apenas para advogados)
                BlocBuilder<AuthBloc, auth_states.AuthState>(
                builder: (context, authState) {
                  if (authState is auth_states.Authenticated) {
                    final clientBadgeContext = BadgeVisibilityHelper.getVipClientContext(
                      authState.user.role,
                      caseData?.clientPlan,
                    );
                    
                    return UniversalBadge(
                      context: clientBadgeContext,
                      fontSize: 10,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
              Text(
                subtitle, 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
                )
              ),
              const SizedBox(height: 16),
              // Mostra pré-análise apenas para tipos relevantes
              if (caseData?.shouldShowPreAnalysis ?? true)
                _buildPreAnalysisSection(context),
              
              // Seções específicas por tipo de caso
              if (caseData?.isConsultivo == true)
                _buildConsultancySpecificSection(context),
              if (caseData?.isContencioso == true)
                _buildLitigationSpecificSection(context),
              if (caseData?.isContrato == true)
                _buildContractSpecificSection(context),
              if (caseData?.isCompliance == true)
                _buildComplianceSpecificSection(context),
              if (caseData?.isDueDiligence == true)
                _buildDueDiligenceSpecificSection(context),
              if (caseData?.isMA == true)
                _buildMASpecificSection(context),
              if (caseData?.isIP == true)
                _buildIPSpecificSection(context),
              if (caseData?.isCorporativo == true && !caseData!.isMA && !caseData!.isDueDiligence)
                _buildCorporateSpecificSection(context),
              if (caseData?.isCustom == true)
                _buildCustomSpecificSection(context),
              
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                                     // Botão da agenda do caso - Instrumentado
                   InstrumentedNavigationAction(
                     routeName: '/case-detail/$caseId/agenda',
                     actionType: 'push',
                     onPressed: () => context.push('/case-detail/$caseId/agenda'),
                     additionalData: {
                       'case_id': caseId,
                       'action_source': 'case_card_agenda_button',
                       'case_status': status,
                     },
                                          child: InstrumentedButton(
                       elementId: 'case_agenda_$caseId',
                       context: 'case_card',
                       onPressed: () => context.push('/case-detail/$caseId/agenda'),
                       additionalData: {
                         'case_id': caseId,
                         'action_type': 'view_agenda',
                         'case_status': status,
                       },
                       child: const Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(LucideIcons.calendar, size: 16, color: AppColors.success),
                           SizedBox(width: 4),
                           Text('Agenda', style: TextStyle(color: AppColors.success)),
                         ],
                       ),
                     ),
                   ),
                  const SizedBox(width: 8),
                  // Botão ver detalhes - Instrumentado
                  InstrumentedButton(
                    elementId: 'case_details_$caseId',
                    context: 'case_card',
                    onPressed: () => context.push('/case-detail/$caseId'),
                    additionalData: {
                      'case_id': caseId,
                      'action_type': 'view_details',
                      'case_status': status,
                      'has_lawyer': lawyer != null,
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.eye, size: 16, color: AppColors.primaryBlue),
                        SizedBox(width: 4),
                        Text('Ver Detalhes', style: TextStyle(color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                ],
              )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    // NOVO: Adiciona o badge de alocação, se existir
    final allocationBadge = _buildAllocationBadge(context);
    // Badge de tipo de caso
    final typeBadge = _buildTypeBadge(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            // NOVO: Badges universais B2B (casos Premium/Enterprise)
            BlocBuilder<AuthBloc, auth_states.AuthState>(
              builder: (context, authState) {
                if (authState is auth_states.Authenticated) {
                  final badgeContext = BadgeVisibilityHelper.getPremiumCaseContext(
                    authState.user.role,
                    caseData?.isPremium ?? false,
                    caseData?.isEnterprise ?? false,
                  );
                  
                  return UniversalBadge(
                    context: badgeContext,
                    fontSize: 11,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Badge do tipo de caso
            if (typeBadge != null) typeBadge,
            // Badge de alocação
            if (allocationBadge != null) allocationBadge,
            // Indicador de complexidade para casos corporativos
            if (caseData?.isHighComplexity == true) ...[
              Chip(
                avatar: Icon(
                  LucideIcons.briefcase, 
                  size: 14, 
                  color: theme.colorScheme.tertiary
                ),
                label: Text(
                  'Alta Complexidade', 
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
          Chip(
            label: Text(
              _getStatusDisplayText(), 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500, 
              color: _getStatusColor(status, context)
            )
          ),
          backgroundColor: context.getBadgeBackground(_getStatusColor(status, context)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), 
            side: BorderSide.none
          ),
          ),
          ],
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
          if (lawyer!.avatarUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: lawyer!.avatarUrl,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                backgroundImage: imageProvider,
                radius: 24,
              ),
              placeholder: (context, url) => const CircleAvatar(
                radius: 24,
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => InitialsAvatar(
                text: lawyer!.name,
                radius: 24,
              ),
            )
          else
            InitialsAvatar(
              text: lawyer!.name,
              radius: 24,
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
                    const SizedBox(width: 8),
                    // NOVO: Badge PRO universal (apenas para clientes)
                    BlocBuilder<AuthBloc, auth_states.AuthState>(
                      builder: (context, authState) {
                        if (authState is auth_states.Authenticated) {
                          final badgeContext = BadgeVisibilityHelper.getProLawyerContext(
                            authState.user.role,
                            lawyer!.plan,
                            caseData?.isPremium ?? false,
                          );
                          
                          return UniversalBadge(
                            context: badgeContext,
                            fontSize: 10,
                          );
                        }
                        return const SizedBox.shrink();
                      },
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

  Color _getStatusColor(String status, BuildContext context) {
    return context.getStatusColor(status);
  }

  // Novo: Badge de tipo de caso
  Widget? _buildTypeBadge(BuildContext context) {
    if (caseData?.caseType == null) return null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Icon(
            caseData!.typeIcon,
            size: 14,
            color: caseData!.typeColor,
          ),
          const SizedBox(width: 4),
          Text(
            caseData!.typeDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: caseData!.typeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Obter texto de status adaptativo
  String _getStatusDisplayText() {
    final statusMapping = CaseTypeConstants.getStatusMapping(caseData?.caseType);
    return statusMapping[status] ?? status;
  }

  // Seções específicas por tipo de caso
  Widget _buildConsultancySpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.target,
      color: AppColors.info,
      title: 'Entregáveis do Projeto',
      description: 'Acompanhe o progresso das entregas previstas para este projeto de consultoria.',
    );
  }

  Widget _buildLitigationSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.gavel,
      color: AppColors.error,
      title: 'Acompanhamento Processual',
      description: 'Monitore prazos processuais, audiências e movimentações do processo judicial.',
    );
  }

  Widget _buildContractSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.fileText,
      color: AppColors.success,
      title: 'Cláusulas e Negociação',
      description: 'Acompanhe as cláusulas em análise e o status da negociação.',
    );
  }

  Widget _buildComplianceSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.shield,
      color: AppColors.warning,
      title: 'Adequação Regulatória',
      description: 'Monitore o progresso da adequação às normas e regulamentos.',
    );
  }

  Widget _buildDueDiligenceSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.search,
      color: AppColors.primaryBlue,
      title: 'Investigação e Análise',
      description: 'Acompanhe o progresso da investigação e análise de riscos.',
    );
  }

  Widget _buildMASpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.building2,
      color: AppColors.secondaryPurple,
      title: 'Estruturação M&A',
      description: 'Monitore as etapas de estruturação da transação.',
    );
  }

  Widget _buildIPSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.copyright,
      color: AppColors.secondaryGreen,
      title: 'Proteção Intelectual',
      description: 'Acompanhe o registro e proteção dos direitos intelectuais.',
    );
  }

  Widget _buildCorporateSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.building,
      color: AppColors.secondaryYellow,
      title: 'Governança Corporativa',
      description: 'Monitore as práticas de governança e compliance corporativo.',
    );
  }

  Widget _buildCustomSpecificSection(BuildContext context) {
    return _buildTypeSpecificSection(
      context: context,
      icon: LucideIcons.settings,
      color: AppColors.lightText2,
      title: 'Caso Especializado',
      description: 'Acompanhe o desenvolvimento deste caso jurídico personalizado.',
    );
  }

  // Helper para construir seções específicas
  Widget _buildTypeSpecificSection({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.adaptiveTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }


} 