import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/cases/domain/entities/process_status.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProcessStatusSection extends StatelessWidget {
  final ProcessStatus? processStatus;
  final String? caseId;

  const ProcessStatusSection({
    super.key,
    this.processStatus,
    this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    if (processStatus == null) {
      return Card(
        elevation: 2,
        shadowColor: Colors.black26,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Andamento Processual',
                  style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.fileClock, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum andamento disponível no momento.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, t),
            const SizedBox(height: 16),
            Text(processStatus!.description,
                style: t.bodyMedium!.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 12),
            _buildProgressBar(theme),
            const SizedBox(height: 16),
            Text('Fases do Processo',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...processStatus!.phases.take(3).map((phase) => _buildPhaseItem(phase, theme)),
            const Divider(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Andamento Processual',
            style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _getStatusColor(processStatus!.currentPhase).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatPhaseName(processStatus!.currentPhase),
            style: TextStyle(
              color: _getStatusColor(processStatus!.currentPhase),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: processStatus!.progressPercentage / 100,
          backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(processStatus!.currentPhase)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text('${processStatus!.progressPercentage.toStringAsFixed(0)}% concluído',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/cases/${caseId ?? 'unknown'}/documents'),
            icon: const Icon(LucideIcons.folder, size: 18),
            label: const Text('Documentos'),
             style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {}, // TODO: Navegar para a tela de status completo
            icon: const Icon(LucideIcons.ganttChart, size: 18),
            label: const Text('Ver Completo'),
             style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPhaseItem(ProcessPhase phase, ThemeData theme) {
    Color statusColor = phase.isCompleted
        ? AppColors.success
        : phase.isCurrent
            ? AppColors.warning
            : theme.colorScheme.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: phase.isCompleted ? AppColors.success : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phase.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (phase.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Concluído em: ${_formatDate(phase.completedAt!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
                    ),
                  )
                else if (phase.isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Em andamento',
                        style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
                  ),
                if (phase.documents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...phase.documents.map((doc) =>
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fileText, size: 14, color: AppColors.lightText2),
                          const SizedBox(width: 6),
                          Expanded(child: Text(doc.name, style: const TextStyle(fontSize: 13, color: AppColors.lightText2), overflow: TextOverflow.ellipsis,)),
                        ],
                      ),
                    )
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatPhaseName(String phaseName) {
    return phaseName.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');
  }

  Color _getStatusColor(String status) {
    // Simplificado. Pode ser expandido para mais status.
    switch (status.toLowerCase()) {
      case 'em andamento':
        return AppColors.warning;
      case 'concluído':
        return AppColors.success;
      case 'aguardando':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }
} 