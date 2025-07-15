import 'package:flutter/material.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/allocation_type.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../../core/utils/logger.dart';

/// Fábrica principal de componentes contextuais
/// Implementa o sistema de Contextual Case View conforme ARQUITETURA_GERAL_DO_SISTEMA.md
class ContextualCaseCard extends StatelessWidget {
  const ContextualCaseCard({
    super.key,
    required this.caseData,
    required this.contextualData,
    required this.kpis,
    required this.actions,
    required this.highlight,
    required this.currentUser,
    this.onActionTap,
  });

  final Case caseData;
  final ContextualCaseData contextualData;
  final List<ContextualKPI> kpis;
  final ContextualActions actions;
  final ContextualHighlight highlight;
  final User currentUser;
  final Function(String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building ContextualCaseCard for case ${caseData.id} with allocation type ${contextualData.allocationType}');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContextualHighlight(),
            const SizedBox(height: 12),
            _buildHeaderKPIs(),
            const SizedBox(height: 12),
            _buildCaseInfo(),
            const SizedBox(height: 12),
            _buildContextualActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualHighlight() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getHighlightColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getHighlightColor().withValues(alpha: 0.3)),
      ),
      child: Text(
        highlight.text,
        style: TextStyle(
          color: _getHighlightColor(),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeaderKPIs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getHeaderColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: kpis.map((kpi) => _buildKPIItem(kpi)).toList(),
      ),
    );
  }

  Widget _buildKPIItem(ContextualKPI kpi) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kpi.icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          kpi.label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          kpi.value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCaseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caseData.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Caso ${caseData.caseType ?? 'Geral'} • ${caseData.status}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(caseData.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              _getStatusIcon(),
              size: 16,
              color: _getStatusColor(),
            ),
            const SizedBox(width: 4),
            Text(
              _formatStatus(caseData.status),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextualActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ...actions.secondaryActions.map((action) => 
          TextButton(
            onPressed: () => onActionTap?.call(action.action),
            child: Text(action.label),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onActionTap?.call(actions.primaryAction.action),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(),
          ),
          child: Text(actions.primaryAction.label),
        ),
      ],
    );
  }

  Color _getHighlightColor() {
    switch (highlight.color) {
      case 'blue':
        return AppColors.primaryBlue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getHeaderColor() {
    switch (contextualData.allocationType) {
      case AllocationType.platformMatchDirect:
        return AppColors.primaryBlue;
      case AllocationType.platformMatchPartnership:
        return Colors.purple;
      case AllocationType.partnershipProactiveSearch:
        return Colors.green;
      case AllocationType.partnershipPlatformSuggestion:
        return Colors.teal;
      case AllocationType.internalDelegation:
        return Colors.orange;
    }
  }

  Color _getActionColor() {
    return _getHeaderColor();
  }

  IconData _getStatusIcon() {
    switch (caseData.status) {
      case 'pending_assignment':
        return Icons.hourglass_empty;
      case 'assigned':
        return Icons.person_add;
      case 'in_progress':
        return Icons.work;
      case 'closed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor() {
    switch (caseData.status) {
      case 'pending_assignment':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending_assignment':
        return 'Aguardando Atribuição';
      case 'assigned':
        return 'Atribuído';
      case 'in_progress':
        return 'Em Andamento';
      case 'closed':
        return 'Finalizado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Factory para criar diferentes tipos de cards contextuais
class ContextualCaseCardFactory {
  static Widget create({
    required Case caseData,
    required ContextualCaseData contextualData,
    required List<ContextualKPI> kpis,
    required ContextualActions actions,
    required ContextualHighlight highlight,
    required User currentUser,
    Function(String action)? onActionTap,
  }) {
    switch (contextualData.allocationType) {
      case AllocationType.internalDelegation:
        return DelegatedCaseCard(
          caseData: caseData,
          contextualData: contextualData,
          onActionTap: onActionTap,
        );
      case AllocationType.partnershipProactiveSearch:
        return CapturedCaseCard(
          caseData: caseData,
          contextualData: contextualData,
          onActionTap: onActionTap,
        );
      case AllocationType.platformMatchDirect:
        return PlatformCaseCard(
          caseData: caseData,
          contextualData: contextualData,
          onActionTap: onActionTap,
        );
      default:
        return ContextualCaseCard(
          caseData: caseData,
          contextualData: contextualData,
          kpis: kpis,
          actions: actions,
          highlight: highlight,
          currentUser: currentUser,
          onActionTap: onActionTap,
        );
    }
  }
}

/// Card especializado para delegação interna
class DelegatedCaseCard extends StatelessWidget {
  const DelegatedCaseCard({
    super.key,
    required this.caseData,
    required this.contextualData,
    required this.onActionTap,
  });

  final Case caseData;
  final ContextualCaseData contextualData;
  final Function(String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDelegationHeader(),
            const SizedBox(height: 12),
            _buildDelegationKPIs(),
            const SizedBox(height: 12),
            _buildDelegationActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDelegationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Text(
        '👨‍💼 Delegado por ${contextualData.delegatedByName ?? 'N/A'}',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDelegationKPIs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildKPI('⏰', 'Prazo', '${contextualData.deadlineDays ?? 0} dias'),
          _buildKPI('📈', 'Horas Orçadas', '${contextualData.hoursBudgeted ?? 0}h'),
          _buildKPI('💼', 'Valor/h', 'R\$ ${contextualData.hourlyRate ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildKPI(String icon, String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDelegationActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => onActionTap?.call('update_status'),
          child: const Text('Atualizar Status'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onActionTap?.call('log_hours'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Registrar Horas'),
        ),
      ],
    );
  }
}

/// Card especializado para casos capturados via parceria
class CapturedCaseCard extends StatelessWidget {
  const CapturedCaseCard({
    super.key,
    required this.caseData,
    required this.contextualData,
    required this.onActionTap,
  });

  final Case caseData;
  final ContextualCaseData contextualData;
  final Function(String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapturedHeader(),
            const SizedBox(height: 12),
            _buildCapturedKPIs(),
            const SizedBox(height: 12),
            _buildCapturedActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: const Text(
        '🤝 Caso captado via parceria',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCapturedKPIs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildKPI('🤝', 'Parceiro', contextualData.partnerName ?? 'N/A'),
          _buildKPI('📋', 'Divisão', '${contextualData.yourShare ?? 0}/${contextualData.partnerShare ?? 0}%'),
          _buildKPI('⭐', 'Rating', '${contextualData.partnerRating ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildKPI(String icon, String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => onActionTap?.call('contact_partner'),
          child: const Text('Contatar Parceiro'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onActionTap?.call('align_strategy'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Alinhar Estratégia'),
        ),
      ],
    );
  }
}

/// Card especializado para casos de plataforma (Super Associado)
class PlatformCaseCard extends StatelessWidget {
  const PlatformCaseCard({
    super.key,
    required this.caseData,
    required this.contextualData,
    required this.onActionTap,
  });

  final Case caseData;
  final ContextualCaseData contextualData;
  final Function(String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformHeader(),
            const SizedBox(height: 12),
            _buildPlatformKPIs(),
            const SizedBox(height: 12),
            _buildPlatformActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: const Text(
        '🎯 Match direto para você',
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPlatformKPIs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildKPI('🎯', 'Prioridade', 'ALTA'),
          _buildKPI('📊', 'Complexidade', '${contextualData.complexityScore ?? 0}/10'),
          _buildKPI('🎖️', 'Conversão', '${contextualData.conversionRate ?? 0}%'),
        ],
      ),
    );
  }

  Widget _buildKPI(String icon, String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => onActionTap?.call('view_client_profile'),
          child: const Text('Ver Perfil'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onActionTap?.call('accept_case'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
          ),
          child: const Text('Aceitar Caso'),
        ),
      ],
    );
  }
} 