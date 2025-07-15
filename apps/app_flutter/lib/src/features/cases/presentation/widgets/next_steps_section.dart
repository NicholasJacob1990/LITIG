import 'package:flutter/material.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/utils/app_colors.dart';

class NextStepsSection extends StatelessWidget {
  final List<NextStep>? nextSteps;
  
  const NextStepsSection({
    super.key,
    this.nextSteps,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    
    if (nextSteps == null || nextSteps!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Próximos Passos',
              style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.checklist_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma etapa definida',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximos Passos',
            style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...nextSteps!.map((step) => _stepCard(step)),
      ],
    );
  }

  Widget _stepCard(NextStep step) {
    final priorityColor = _getPriorityColor(step.priority);
    final statusColor = step.isCompleted ? Colors.green : priorityColor;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(step.title, style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: step.isCompleted ? TextDecoration.lineThrough : null,
              color: step.isCompleted ? Colors.grey : null,
            ))),
            _badge(_getPriorityLabel(step.priority), priorityColor),
          ]),
          const SizedBox(height: 4),
          Text(step.description, style: TextStyle(
            color: step.isCompleted ? Colors.grey : null,
          )),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.lightText2),
            const SizedBox(width: 4),
            Text('Prazo: ${_formatDate(step.dueDate)}', style: const TextStyle(color: AppColors.lightText2)),
            const Spacer(),
            _badge(step.isCompleted ? 'CONCLUÍDO' : 'PENDENTE', statusColor),
          ]),
          ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person, size: 14, color: AppColors.lightText2),
            const SizedBox(width: 4),
            Text('Responsável: ${_getResponsibleLabel(step.responsibleParty)}', 
                 style: const TextStyle(color: AppColors.lightText2, fontSize: 12)),
          ]),
        ],
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
      );

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baixa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return 'ALTA';
      case 'media':
        return 'MÉDIA';
      case 'baixa':
        return 'BAIXA';
      default:
        return priority.toUpperCase();
    }
  }

  String _getResponsibleLabel(String responsible) {
    switch (responsible.toLowerCase()) {
      case 'cliente':
        return 'Cliente';
      case 'advogado':
        return 'Advogado';
      case 'ambos':
        return 'Cliente e Advogado';
      default:
        return responsible;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 