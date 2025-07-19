import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Breakdown de Tarefas para advogados associados
/// 
/// **Contexto:** Advogados associados (lawyer_associated)
/// **Substituição:** TaskBreakdownSection (placeholder anterior)
/// **Foco:** Detalhamento das tarefas delegadas, horas orçadas e responsabilidades
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir TaskBreakdownSection placeholder para advogados associados
/// - Foco em produtividade e execução de tarefas delegadas
class TaskBreakdownSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const TaskBreakdownSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Breakdown de Tarefas',
      children: [
        _buildTaskOverview(context),
        const SizedBox(height: 16),
        _buildTaskList(context),
        const SizedBox(height: 16),
        _buildTimeTracking(context),
        const SizedBox(height: 16),
        _buildDeadlines(context),
        const SizedBox(height: 20),
        _buildTaskActions(context),
      ],
    );
  }

  Widget _buildTaskOverview(BuildContext context) {
    final totalHours = contextualData?['hours_budgeted'] ?? 40.0;
    final completedHours = contextualData?['hours_completed'] ?? 12.0;
    final hourlyRate = contextualData?['hourly_rate'] ?? 150.0;
    final totalTasks = contextualData?['total_tasks'] ?? 5;
    final completedTasks = contextualData?['completed_tasks'] ?? 2;

    final progressPercentage = (completedHours / totalHours * 100).clamp(0.0, 100.0);
    final taskProgressPercentage = (completedTasks / totalTasks * 100).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visão Geral do Trabalho',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Cards de progresso
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                context,
                'Horas Trabalhadas',
                '${completedHours.toStringAsFixed(1)}h / ${totalHours.toStringAsFixed(0)}h',
                progressPercentage / 100,
                Icons.access_time,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressCard(
                context,
                'Tarefas Concluídas',
                '$completedTasks / $totalTasks tarefas',
                taskProgressPercentage / 100,
                Icons.task_alt,
                Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Informações financeiras
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Valor por Hora: R\$ ${hourlyRate.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Total Estimado: R\$ ${(totalHours * hourlyRate).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    String subtitle,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    final tasks = contextualData?['tasks'] ?? [
      {
        'name': 'Análise inicial dos documentos',
        'description': 'Revisar contratos e documentos fornecidos pelo cliente',
        'estimated_hours': 8.0,
        'completed_hours': 8.0,
        'status': 'completed',
        'deadline': '15/01/2025',
        'priority': 'high',
      },
      {
        'name': 'Elaboração da petição inicial',
        'description': 'Redigir petição com base na análise documental',
        'estimated_hours': 16.0,
        'completed_hours': 4.0,
        'status': 'in_progress',
        'deadline': '20/01/2025',
        'priority': 'high',
      },
      {
        'name': 'Pesquisa jurisprudencial',
        'description': 'Buscar precedentes similares para fundamentação',
        'estimated_hours': 6.0,
        'completed_hours': 0.0,
        'status': 'pending',
        'deadline': '18/01/2025',
        'priority': 'medium',
      },
      {
        'name': 'Preparação para audiência',
        'description': 'Organizar documentos e estratégia para audiência',
        'estimated_hours': 8.0,
        'completed_hours': 0.0,
        'status': 'pending',
        'deadline': '25/01/2025',
        'priority': 'medium',
      },
      {
        'name': 'Acompanhamento processual',
        'description': 'Monitorar andamentos e prazos processuais',
        'estimated_hours': 2.0,
        'completed_hours': 0.0,
        'status': 'pending',
        'deadline': 'Contínuo',
        'priority': 'low',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lista de Tarefas Delegadas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Lista de tarefas
        ...tasks.map<Widget>((task) => _buildTaskCard(context, task)).toList(),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final status = task['status'] as String;
    final priority = task['priority'] as String;
    final estimatedHours = task['estimated_hours'] as double;
    final completedHours = task['completed_hours'] as double;
    final progress = estimatedHours > 0 ? completedHours / estimatedHours : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTaskStatusColor(status).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTaskStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da tarefa
          Row(
            children: [
              // Ícone de status
              Icon(
                _getTaskStatusIcon(status),
                color: _getTaskStatusColor(status),
                size: 20,
              ),
              const SizedBox(width: 8),
              
              // Nome da tarefa
              Expanded(
                child: Text(
                  task['name'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Badge de prioridade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(priority),
                  style: TextStyle(
                    color: _getPriorityColor(priority),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Descrição
          Text(
            task['description'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progresso e horas
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progresso: ${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTaskStatusColor(status),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${completedHours.toStringAsFixed(1)}h / ${estimatedHours.toStringAsFixed(0)}h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Prazo: ${task['deadline']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Ações da tarefa
          if (status != 'completed') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _startTask(context, task['name']),
                    icon: Icon(
                      status == 'in_progress' ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      status == 'in_progress' ? 'Pausar' : 'Iniciar',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _updateProgress(context, task['name']),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      'Atualizar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTracking(BuildContext context) {
    final todayHours = contextualData?['today_hours'] ?? 3.5;
    final weekHours = contextualData?['week_hours'] ?? 12.0;
    final lastActivity = contextualData?['last_activity'] ?? 'Elaboração da petição - 14:30';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Controle de Tempo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      context,
                      'Hoje',
                      '${todayHours.toStringAsFixed(1)}h',
                      Icons.today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeCard(
                      context,
                      'Esta Semana',
                      '${weekHours.toStringAsFixed(1)}h',
                      Icons.calendar_view_week,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Última atividade
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Última atividade: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lastActivity,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlines(BuildContext context) {
    final urgentTasks = contextualData?['urgent_tasks'] ?? 2;
    final nextDeadline = contextualData?['next_deadline'] ?? '18/01/2025';
    final daysUntilDeadline = contextualData?['days_until_deadline'] ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prazos e Urgências',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: daysUntilDeadline <= 3 ? Colors.red[25] : Colors.yellow[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: daysUntilDeadline <= 3 ? Colors.red[100]! : Colors.yellow[100]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                daysUntilDeadline <= 3 ? Icons.warning : Icons.schedule,
                color: daysUntilDeadline <= 3 ? Colors.red[600] : Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximo prazo: $nextDeadline',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$urgentTasks tarefas urgentes • $daysUntilDeadline dias restantes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (daysUntilDeadline <= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Registrar Horas',
                icon: Icons.timer,
                onPressed: () => _logHours(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Atualizar Status',
                icon: Icons.edit,
                onPressed: () => _updateTaskStatus(context),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(
            label: 'Solicitar Reunião com Responsável',
            icon: Icons.video_call,
            onPressed: () => _requestMeeting(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _startTask(BuildContext context, String taskName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando tarefa: $taskName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateProgress(BuildContext context, String taskName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Progresso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tarefa: $taskName'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Horas trabalhadas hoje',
                border: OutlineInputBorder(),
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progresso atualizado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _logHours(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Horas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tarefa',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'peticion', child: Text('Elaboração da petição')),
                DropdownMenuItem(value: 'research', child: Text('Pesquisa jurisprudencial')),
                DropdownMenuItem(value: 'docs', child: Text('Análise de documentos')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Horas trabalhadas',
                border: OutlineInputBorder(),
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Horas registradas com sucesso!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo formulário de atualização de status...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _requestMeeting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Reunião'),
        content: const Text(
          'Deseja solicitar uma reunião com o responsável pela delegação deste caso?\n\n'
          'O Dr. Silva será notificado e poderá agendar um horário.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitação de reunião enviada!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  // Métodos de apoio para cores e ícones
  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getTaskStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'in_progress': return Icons.play_circle;
      case 'pending': return Icons.pending;
      default: return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high': return 'ALTA';
      case 'medium': return 'MÉDIA';
      case 'low': return 'BAIXA';
      default: return 'N/A';
    }
  }
} 

/// Seção de Breakdown de Tarefas para advogados associados
/// 
/// **Contexto:** Advogados associados (lawyer_associated)
/// **Substituição:** TaskBreakdownSection (placeholder anterior)
/// **Foco:** Detalhamento das tarefas delegadas, horas orçadas e responsabilidades
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir TaskBreakdownSection placeholder para advogados associados
/// - Foco em produtividade e execução de tarefas delegadas
class TaskBreakdownSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const TaskBreakdownSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Breakdown de Tarefas',
      children: [
        _buildTaskOverview(context),
        const SizedBox(height: 16),
        _buildTaskList(context),
        const SizedBox(height: 16),
        _buildTimeTracking(context),
        const SizedBox(height: 16),
        _buildDeadlines(context),
        const SizedBox(height: 20),
        _buildTaskActions(context),
      ],
    );
  }

  Widget _buildTaskOverview(BuildContext context) {
    final totalHours = contextualData?['hours_budgeted'] ?? 40.0;
    final completedHours = contextualData?['hours_completed'] ?? 12.0;
    final hourlyRate = contextualData?['hourly_rate'] ?? 150.0;
    final totalTasks = contextualData?['total_tasks'] ?? 5;
    final completedTasks = contextualData?['completed_tasks'] ?? 2;

    final progressPercentage = (completedHours / totalHours * 100).clamp(0.0, 100.0);
    final taskProgressPercentage = (completedTasks / totalTasks * 100).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visão Geral do Trabalho',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Cards de progresso
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                context,
                'Horas Trabalhadas',
                '${completedHours.toStringAsFixed(1)}h / ${totalHours.toStringAsFixed(0)}h',
                progressPercentage / 100,
                Icons.access_time,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressCard(
                context,
                'Tarefas Concluídas',
                '$completedTasks / $totalTasks tarefas',
                taskProgressPercentage / 100,
                Icons.task_alt,
                Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Informações financeiras
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Valor por Hora: R\$ ${hourlyRate.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Total Estimado: R\$ ${(totalHours * hourlyRate).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    String subtitle,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    final tasks = contextualData?['tasks'] ?? [
      {
        'name': 'Análise inicial dos documentos',
        'description': 'Revisar contratos e documentos fornecidos pelo cliente',
        'estimated_hours': 8.0,
        'completed_hours': 8.0,
        'status': 'completed',
        'deadline': '15/01/2025',
        'priority': 'high',
      },
      {
        'name': 'Elaboração da petição inicial',
        'description': 'Redigir petição com base na análise documental',
        'estimated_hours': 16.0,
        'completed_hours': 4.0,
        'status': 'in_progress',
        'deadline': '20/01/2025',
        'priority': 'high',
      },
      {
        'name': 'Pesquisa jurisprudencial',
        'description': 'Buscar precedentes similares para fundamentação',
        'estimated_hours': 6.0,
        'completed_hours': 0.0,
        'status': 'pending',
        'deadline': '18/01/2025',
        'priority': 'medium',
      },
      {
        'name': 'Preparação para audiência',
        'description': 'Organizar documentos e estratégia para audiência',
        'estimated_hours': 8.0,
        'completed_hours': 0.0,
        'status': 'pending',
        'deadline': '25/01/2025',
        'priority': 'medium',
      },
      {
        'name': 'Acompanhamento processual',
        'description': 'Monitorar andamentos e prazos processuais',
        'estimated_hours': 2.0,
        'completed_hours': 0.0,
        'status': 'pending',
        'deadline': 'Contínuo',
        'priority': 'low',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lista de Tarefas Delegadas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Lista de tarefas
        ...tasks.map<Widget>((task) => _buildTaskCard(context, task)).toList(),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final status = task['status'] as String;
    final priority = task['priority'] as String;
    final estimatedHours = task['estimated_hours'] as double;
    final completedHours = task['completed_hours'] as double;
    final progress = estimatedHours > 0 ? completedHours / estimatedHours : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTaskStatusColor(status).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTaskStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da tarefa
          Row(
            children: [
              // Ícone de status
              Icon(
                _getTaskStatusIcon(status),
                color: _getTaskStatusColor(status),
                size: 20,
              ),
              const SizedBox(width: 8),
              
              // Nome da tarefa
              Expanded(
                child: Text(
                  task['name'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Badge de prioridade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(priority),
                  style: TextStyle(
                    color: _getPriorityColor(priority),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Descrição
          Text(
            task['description'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progresso e horas
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progresso: ${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTaskStatusColor(status),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${completedHours.toStringAsFixed(1)}h / ${estimatedHours.toStringAsFixed(0)}h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Prazo: ${task['deadline']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Ações da tarefa
          if (status != 'completed') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _startTask(context, task['name']),
                    icon: Icon(
                      status == 'in_progress' ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      status == 'in_progress' ? 'Pausar' : 'Iniciar',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _updateProgress(context, task['name']),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      'Atualizar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTracking(BuildContext context) {
    final todayHours = contextualData?['today_hours'] ?? 3.5;
    final weekHours = contextualData?['week_hours'] ?? 12.0;
    final lastActivity = contextualData?['last_activity'] ?? 'Elaboração da petição - 14:30';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Controle de Tempo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      context,
                      'Hoje',
                      '${todayHours.toStringAsFixed(1)}h',
                      Icons.today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeCard(
                      context,
                      'Esta Semana',
                      '${weekHours.toStringAsFixed(1)}h',
                      Icons.calendar_view_week,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Última atividade
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Última atividade: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lastActivity,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlines(BuildContext context) {
    final urgentTasks = contextualData?['urgent_tasks'] ?? 2;
    final nextDeadline = contextualData?['next_deadline'] ?? '18/01/2025';
    final daysUntilDeadline = contextualData?['days_until_deadline'] ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prazos e Urgências',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: daysUntilDeadline <= 3 ? Colors.red[25] : Colors.yellow[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: daysUntilDeadline <= 3 ? Colors.red[100]! : Colors.yellow[100]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                daysUntilDeadline <= 3 ? Icons.warning : Icons.schedule,
                color: daysUntilDeadline <= 3 ? Colors.red[600] : Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximo prazo: $nextDeadline',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$urgentTasks tarefas urgentes • $daysUntilDeadline dias restantes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (daysUntilDeadline <= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Registrar Horas',
                icon: Icons.timer,
                onPressed: () => _logHours(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Atualizar Status',
                icon: Icons.edit,
                onPressed: () => _updateTaskStatus(context),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(
            label: 'Solicitar Reunião com Responsável',
            icon: Icons.video_call,
            onPressed: () => _requestMeeting(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _startTask(BuildContext context, String taskName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando tarefa: $taskName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateProgress(BuildContext context, String taskName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Progresso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tarefa: $taskName'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Horas trabalhadas hoje',
                border: OutlineInputBorder(),
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progresso atualizado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _logHours(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Horas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tarefa',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'peticion', child: Text('Elaboração da petição')),
                DropdownMenuItem(value: 'research', child: Text('Pesquisa jurisprudencial')),
                DropdownMenuItem(value: 'docs', child: Text('Análise de documentos')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Horas trabalhadas',
                border: OutlineInputBorder(),
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Horas registradas com sucesso!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo formulário de atualização de status...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _requestMeeting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Reunião'),
        content: const Text(
          'Deseja solicitar uma reunião com o responsável pela delegação deste caso?\n\n'
          'O Dr. Silva será notificado e poderá agendar um horário.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitação de reunião enviada!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  // Métodos de apoio para cores e ícones
  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getTaskStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'in_progress': return Icons.play_circle;
      case 'pending': return Icons.pending;
      default: return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high': return 'ALTA';
      case 'medium': return 'MÉDIA';
      case 'low': return 'BAIXA';
      default: return 'N/A';
    }
  }
} 