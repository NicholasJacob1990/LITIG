import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/client_info.dart';
import '../../domain/entities/business_context.dart';
import '../../domain/entities/match_analysis.dart';
import '../../domain/entities/lawyer_metrics.dart';
import '../../../../shared/widgets/atoms/initials_avatar.dart';

/// Card de caso aprimorado para advogados com espelhamento completo
/// Contraparte do CaseCard do cliente com informações simétricas
/// Inclui ClientInfo detalhado, BusinessContext e MatchAnalysis
class LawyerCaseCardEnhanced extends StatelessWidget {
  final String caseId;
  final String title;
  final String status;
  final String caseType;
  final ClientInfo clientInfo;
  // Mantidos para compatibilidade com fontes de chamada existentes
  final BusinessContext? businessContext;
  final MatchAnalysis? matchAnalysis;
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
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
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
              const SizedBox(height: 16),
              _buildActionButtonsMinimal(theme),
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
              Builder(
                builder: (context) => Row(
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
              ),
              const SizedBox(height: 4),
              Text(
                'ID: $caseId',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(theme, context),
              const SizedBox(height: 4),
              _buildCaseTypeBadge(theme, context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickClientInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: clientInfo.avatarUrl != null && clientInfo.avatarUrl!.isNotEmpty
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
                Builder(
                  builder: (context) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientInfo.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildClientStatusBadge(theme, context),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      clientInfo.isCorporate ? LucideIcons.building2 : LucideIcons.user,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      clientInfo.isCorporate ? 'Pessoa Jurídica' : 'Pessoa Física',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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

  Widget _buildActionButtonsMinimal(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: onViewDetails,
        icon: const Icon(LucideIcons.eye, size: 16),
        label: const Text('Ver Detalhes'),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, BuildContext context) {
    final statusColor = _getStatusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildCaseTypeBadge(ThemeData theme, BuildContext context) {
    final ctColor = _getCaseTypeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ctColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ctColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getCaseTypeDisplayName(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ctColor,
        ),
      ),
    );
  }

  Widget _buildClientStatusBadge(ThemeData theme, BuildContext context) {
    final statusColor = _getClientStatusColor(clientInfo.status.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
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

  Color _getStatusColor(BuildContext context) {
    // cores essenciais por status
    switch (status.toLowerCase()) {
      case 'em andamento':
        return Colors.orange;
      case 'concluído':
        return Colors.green;
      case 'aguardando':
        return Colors.blue;
      default:
        return Colors.grey;
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
        return Colors.blue;
      case 'litigation':
        return Colors.red;
      case 'contract':
        return Colors.teal;
      case 'compliance':
        return Colors.orange;
      case 'due_diligence':
        return Colors.indigo;
      case 'ma':
        return Colors.purple;
      case 'ip':
        return Colors.brown;
      case 'corporate':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Color _getClientStatusColor(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'new':
      case 'lead':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'vip':
        return Colors.amber.shade800;
      case 'inactive':
      case 'churned':
        return Colors.grey;
      default:
        return Colors.blueGrey;
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

  // Ícone de contato removido em versão essencial
}
