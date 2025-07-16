import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/utils/app_colors.dart';

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
    
    if (processStatus == null) {
      return Card(
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
                    Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum andamento disponível',
                      style: TextStyle(color: Colors.grey[600]),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Andamento Processual',
                    style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    processStatus!.currentPhase.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Descrição do status atual
            Text(processStatus!.description,
                style: t.bodyMedium!.copyWith(color: AppColors.lightText2)),
            const SizedBox(height: 12),
            
            // Barra de progresso
            LinearProgressIndicator(
              value: processStatus!.progressPercentage / 100,
              backgroundColor: AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
            const SizedBox(height: 4),
            Text('${processStatus!.progressPercentage.toStringAsFixed(0)}% concluído',
                style: const TextStyle(fontSize: 12, color: AppColors.lightText2)),
            const SizedBox(height: 16),
            
            // Fases do processo
            Text('Fases do Processo',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            
            // Lista de fases (máximo 3 para preview)
            ...processStatus!.phases.take(3).map((phase) => _buildPhaseItem(phase)),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/cases/${caseId ?? 'unknown'}/documents'),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Ver todos os documentos'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/cases/${caseId ?? 'unknown'}/process-status'),
                icon: const Icon(Icons.timeline),
                label: const Text('Ver andamento completo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseItem(ProcessPhase phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de status
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: phase.isCompleted 
                    ? AppColors.green 
                    : phase.isCurrent 
                        ? AppColors.orange 
                        : AppColors.lightBorder,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Conteúdo da fase
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: phase.isCompleted ? AppColors.green : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phase.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.lightText2,
                  ),
                ),
                if (phase.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                    'Concluído em: ${_formatDate(phase.completedAt!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w500),
                    ),
                  )
                else if (phase.isCurrent)
                   const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Em andamento',
                        style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w500)),
                    ),
                
                // Preview dos documentos (NOVO)
                if (phase.documents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...phase.documents.map((doc) =>
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: AppColors.lightText2),
                          const SizedBox(width: 6),
                          Text(doc.name, style: const TextStyle(fontSize: 13, color: AppColors.lightText2)),
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
} 