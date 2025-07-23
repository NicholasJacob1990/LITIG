import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/client_info.dart';
import '../../domain/entities/business_context.dart';
import '../../domain/entities/match_analysis.dart';
import '../../domain/entities/lawyer_metrics.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../../shared/widgets/atoms/initials_avatar.dart';

/// Card de caso aprimorado para advogados com espelhamento completo
/// Contraparte do CaseCard do cliente com informações simétricas
/// Inclui ClientInfo detalhado, BusinessContext e MatchAnalysis
class LawyerCaseCardEnhanced extends StatelessWidget {
  final String caseId;
  final String title;
  final String status;
  final String caseType;
  final ClientInfo clientInfo; // ✅ Ao invés de String clientName
  final BusinessContext? businessContext; // ✅ Análise comercial completa
  final MatchAnalysis? matchAnalysis; // ✅ Análise de match específica
  final LawyerMetrics? metrics;
  final String userRole;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onContactClient;

  const LawyerCaseCardEnhanced({
    super.key,
    required this.caseId,
    required this.title,
    required this.status,
    required this.caseType,
    required this.clientInfo,
    this.businessContext,
    this.matchAnalysis,
    this.metrics,
    required this.userRole,
    this.onTap,
    this.onViewDetails,
    this.onContactClient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 16),
              _buildQuickClientInfo(theme),
              if (businessContext != null) ...[
                const SizedBox(height: 16),
                _buildBusinessSummary(theme),
              ],
              if (matchAnalysis != null) ...[
                const SizedBox(height: 16),
                _buildMatchSummary(theme),
              ],
              const SizedBox(height: 16),
              _buildMetrics(theme),
              const SizedBox(height: 16),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCaseTypeIcon(),
                    size: 16,
                    color: _getCaseTypeColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ID: $caseId',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusBadge(theme),
            const SizedBox(height: 4),
            _buildCaseTypeBadge(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickClientInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar do cliente
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: clientInfo.avatarUrl != null
                  ? Image.network(
                      clientInfo.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => InitialsAvatar(
                        text: clientInfo.name,
                      ),
                    )
                  : InitialsAvatar(
                      text: clientInfo.name,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clientInfo.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildClientStatusBadge(theme),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      clientInfo.isCorporate ? LucideIcons.building2 : LucideIcons.user,
                      size: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      clientInfo.isCorporate ? 'Pessoa Jurídica' : 'Pessoa Física',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      LucideIcons.star,
                      size: 12,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      clientInfo.averageRating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSummary(ThemeData theme) {
    final business = businessContext!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                'Análise Comercial',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: business.isProfitable ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  business.isProfitable ? 'Viável' : 'Avaliar',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: business.isProfitable ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBusinessMetric(
                theme,
                label: 'Valor',
                value: 'R\$ ${business.estimatedValue.toStringAsFixed(2)}',
                icon: LucideIcons.dollarSign,
              ),
              const SizedBox(width: 12),
              _buildBusinessMetric(
                theme,
                label: 'ROI',
                value: '${business.roiProjection.toStringAsFixed(1)}%',
                icon: LucideIcons.trendingUp,
              ),
              const SizedBox(width: 12),
              _buildBusinessMetric(
                theme,
                label: 'Risco',
                value: business.riskProfile.riskLevel,
                icon: LucideIcons.shield,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessMetric(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSummary(ThemeData theme) {
    final match = matchAnalysis!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: match.matchColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: match.matchColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: match.matchColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '${match.matchScore.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: match.matchColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match: ${match.matchLevel}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: match.matchColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.matchReason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    if (metrics == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (metrics is IndependentLawyerMetrics) ...[
            _buildMetricItem(
              theme,
              icon: LucideIcons.target,
              label: 'Match',
              value: '${(metrics as IndependentLawyerMetrics).matchScore.toInt()}%',
            ),
            _buildMetricItem(
              theme,
              icon: LucideIcons.trendingUp,
              label: 'Sucesso',
              value: '${((metrics as IndependentLawyerMetrics).successProbability * 100).toInt()}%',
            ),
            _buildMetricItem(
              theme,
              icon: LucideIcons.users,
              label: 'Competidores',
              value: '${(metrics as IndependentLawyerMetrics).competitorCount}',
            ),
          ] else if (metrics is AssociateLawyerMetrics) ...[
            _buildMetricItem(
              theme,
              icon: LucideIcons.clock,
              label: 'Progresso',
              value: '${(metrics as AssociateLawyerMetrics).completionPercentage.toInt()}%',
            ),
            _buildMetricItem(
              theme,
              icon: LucideIcons.star,
              label: 'Avaliação',
              value: (metrics as AssociateLawyerMetrics).supervisorRating.toStringAsFixed(1),
            ),
            _buildMetricItem(
              theme,
              icon: LucideIcons.target,
              label: 'Tarefas',
              value: '${(metrics as AssociateLawyerMetrics).tasksCompleted}/${(metrics as AssociateLawyerMetrics).tasksTotal}',
            ),
          ] else if (metrics is OfficeLawyerMetrics) ...[
            _buildMetricItem(
              theme,
              icon: LucideIcons.users,
              label: 'Colaboração',
              value: '${(metrics as OfficeLawyerMetrics).collaborationScore.toInt()}%',
            ),
            _buildMetricItem(
              theme,
              icon: LucideIcons.percent,
              label: 'Participação',
              value: '${(metrics as OfficeLawyerMetrics).revenueShare.toInt()}%',
            ),
            _buildMetricItem(
              theme,
              icon: LucideIcons.star,
              label: 'Satisfação',
              value: (metrics as OfficeLawyerMetrics).clientSatisfaction.toStringAsFixed(1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onContactClient,
            icon: Icon(_getContactIcon(), size: 16),
            label: const Text('Contatar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewDetails,
            icon: const Icon(LucideIcons.eye, size: 16),
            label: const Text('Detalhes'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Widget _buildCaseTypeBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getCaseTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCaseTypeColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getCaseTypeDisplayName(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _getCaseTypeColor(),
        ),
      ),
    );
  }

  Widget _buildClientStatusBadge(ThemeData theme) {
    Color statusColor;
    switch (clientInfo.status) {
      case ClientStatus.vip:
        statusColor = Colors.purple;
        break;
      case ClientStatus.problematic:
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        clientInfo.status.displayName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ativo':
        return Colors.green;
      case 'pending':
      case 'pendente':
        return Colors.orange;
      case 'blocked':
      case 'bloqueado':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getCaseTypeIcon() {
    switch (caseType) {
      case 'consultancy':
        return LucideIcons.lightbulb;
      case 'litigation':
        return LucideIcons.gavel;
      case 'contract':
        return LucideIcons.fileText;
      case 'compliance':
        return LucideIcons.shield;
      case 'due_diligence':
        return LucideIcons.search;
      case 'ma':
        return LucideIcons.building2;
      case 'ip':
        return LucideIcons.copyright;
      case 'corporate':
        return LucideIcons.building;
      default:
        return LucideIcons.briefcase;
    }
  }

  Color _getCaseTypeColor() {
    switch (caseType) {
      case 'consultancy':
        return AppColors.info;
      case 'litigation':
        return AppColors.error;
      case 'contract':
        return AppColors.success;
      case 'compliance':
        return AppColors.warning;
      case 'due_diligence':
        return AppColors.primaryBlue;
      case 'ma':
        return AppColors.primaryPurple;
      case 'ip':
        return AppColors.success;
      case 'corporate':
        return AppColors.secondaryYellow;
      default:
        return AppColors.primaryBlue;
    }
  }

  String _getCaseTypeDisplayName() {
    switch (caseType) {
      case 'consultancy':
        return 'Consultivo';
      case 'litigation':
        return 'Contencioso';
      case 'contract':
        return 'Contratos';
      case 'compliance':
        return 'Compliance';
      case 'due_diligence':
        return 'Due Diligence';
      case 'ma':
        return 'M&A';
      case 'ip':
        return 'Prop. Intelectual';
      case 'corporate':
        return 'Corporativo';
      default:
        return 'Jurídico';
    }
  }

  IconData _getContactIcon() {
    switch (clientInfo.preferredCommunication) {
      case 'whatsapp':
        return LucideIcons.messageCircle;
      case 'phone':
        return LucideIcons.phone;
      case 'teams':
        return LucideIcons.video;
      default:
        return LucideIcons.mail;
    }
  }
}
