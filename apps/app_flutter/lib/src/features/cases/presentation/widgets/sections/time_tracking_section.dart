import 'package:flutter/material.dart';
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Controle de Tempo para advogados associados
/// 
/// **Contexto:** Advogados associados (lawyer_associated)
/// **Substituição:** ProcessStatusSection (experiência do cliente)
/// **Foco:** Controle de tempo, produtividade e métricas de trabalho
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir ProcessStatusSection para advogados associados
/// - Foco em produtividade e registro de tempo trabalhado
class TimeTrackingSection extends BaseInfoSection {
  final Map<String, dynamic>? contextualData;

  const TimeTrackingSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Controle de Tempo',
      children: [
        _buildActiveTimer(context),
        const SizedBox(height: 16),
        _buildTimeMetrics(context),
        const SizedBox(height: 16),
        _buildDailyBreakdown(context),
        const SizedBox(height: 16),
        _buildProductivityInsights(context),
        const SizedBox(height: 20),
        _buildTimeActions(context),
      ],
    );
  }

  Widget _buildActiveTimer(BuildContext context) {
    final isTimerActive = contextualData?['timer_active'] ?? false;
    final currentSession = contextualData?['current_session_minutes'] ?? 0;
    final currentTask = contextualData?['current_task'] ?? 'Elaboração da petição inicial';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessão Atual',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTimerActive 
                ? [Colors.green[50]!, Colors.blue[50]!]
                : [Colors.grey[50]!, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTimerActive 
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Status do timer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isTimerActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isTimerActive ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTimerActive ? 'Timer Ativo' : 'Timer Pausado',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isTimerActive ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          currentTask,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tempo da sessão atual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTimerActive 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatMinutes(currentSession),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isTimerActive ? Colors.green[700] : Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Controles do timer
              Row(
                children: [
                  Expanded(
                    child: buildActionButton(
                      label: isTimerActive ? 'Pausar' : 'Iniciar',
                      icon: isTimerActive ? Icons.pause : Icons.play_arrow,
                      onPressed: () => _toggleTimer(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildActionButton(
                      label: 'Finalizar',
                      icon: Icons.stop,
                      onPressed: () => _stopTimer(context),
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeMetrics(BuildContext context) {
    final todayHours = contextualData?['today_hours'] ?? 4.5;
    final weekHours = contextualData?['week_hours'] ?? 18.5;
    final monthHours = contextualData?['month_hours'] ?? 42.0;
    final billablePercentage = contextualData?['billable_percentage'] ?? 85.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas de Tempo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid de métricas
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              context,
              'Hoje',
              '${todayHours.toStringAsFixed(1)}h',
              Icons.today,
              Colors.blue,
              'Meta: 8h',
            ),
            _buildMetricCard(
              context,
              'Esta Semana',
              '${weekHours.toStringAsFixed(1)}h',
              Icons.calendar_view_week,
              Colors.green,
              'Meta: 40h',
            ),
            _buildMetricCard(
              context,
              'Este Mês',
              '${monthHours.toStringAsFixed(0)}h',
              Icons.calendar_month,
              Colors.orange,
              'Meta: 160h',
            ),
            _buildMetricCard(
              context,
              'Faturável',
              '${billablePercentage.toStringAsFixed(0)}%',
              Icons.monetization_on,
              Colors.purple,
              'Meta: 80%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(BuildContext context) {
    final dailyEntries = contextualData?['daily_entries'] ?? [
      {
        'time': '09:00 - 10:30',
        'duration': 90,
        'task': 'Análise de documentos',
        'billable': true,
      },
      {
        'time': '10:45 - 12:00',
        'duration': 75,
        'task': 'Pesquisa jurisprudencial',
        'billable': true,
      },
      {
        'time': '14:00 - 15:30',
        'duration': 90,
        'task': 'Elaboração da petição',
        'billable': true,
      },
      {
        'time': '15:45 - 16:15',
        'duration': 30,
        'task': 'Reunião de alinhamento',
        'billable': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Registro de Hoje',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDetailedHistory(context),
              icon: const Icon(Icons.history, size: 16),
              label: const Text(
                'Ver Histórico',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de entradas
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: dailyEntries.map<Widget>((entry) {
              final duration = entry['duration'] as int;
              final billable = entry['billable'] as bool;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Horário
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry['time'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Duração
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: billable ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatMinutes(duration),
                        style: TextStyle(
                          color: billable ? Colors.green[700] : Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Tarefa
                    Expanded(
                      child: Text(
                        entry['task'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    // Ícone faturável
                    Icon(
                      billable ? Icons.monetization_on : Icons.schedule,
                      color: billable ? Colors.green[600] : Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityInsights(BuildContext context) {
    final focusScore = contextualData?['focus_score'] ?? 8.5;
    final efficiencyTrend = contextualData?['efficiency_trend'] ?? 'up';
    final mostProductiveHour = contextualData?['most_productive_hour'] ?? '10:00';
    final averageSessionLength = contextualData?['average_session_length'] ?? 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights de Produtividade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              // Score de foco
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score de Foco Hoje',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${focusScore.toStringAsFixed(1)}/10',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getFocusScoreColor(focusScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTrendColor(efficiencyTrend).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTrendIcon(efficiencyTrend),
                          color: _getTrendColor(efficiencyTrend),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTrendLabel(efficiencyTrend),
                          style: TextStyle(
                            color: _getTrendColor(efficiencyTrend),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Insights adicionais
              Row(
                children: [
                  Expanded(
                    child: _buildInsightItem(
                      context,
                      'Horário Produtivo',
                      mostProductiveHour,
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightItem(
                      context,
                      'Sessão Média',
                      _formatMinutes(averageSessionLength),
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Novo Registro',
                icon: Icons.add_alarm,
                onPressed: () => _addTimeEntry(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Relatório',
                icon: Icons.analytics,
                onPressed: () => _generateReport(context),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(
            label: 'Exportar Timesheet para Cobrança',
            icon: Icons.file_download,
            onPressed: () => _exportTimesheet(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _toggleTimer(BuildContext context) {
    final isActive = contextualData?['timer_active'] ?? false;
    final action = isActive ? 'pausado' : 'iniciado';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timer $action com sucesso!'),
        backgroundColor: isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  void _stopTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Sessão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tempo trabalhado nesta sessão:'),
            const SizedBox(height: 8),
            Text(
              _formatMinutes(contextualData?['current_session_minutes'] ?? 0),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Observações da sessão (opcional)',
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
                  content: Text('Sessão finalizada e registrada!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _addTimeEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Registro Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tarefa',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'analysis', child: Text('Análise de documentos')),
                DropdownMenuItem(value: 'petition', child: Text('Elaboração da petição')),
                DropdownMenuItem(value: 'research', child: Text('Pesquisa jurisprudencial')),
                DropdownMenuItem(value: 'meeting', child: Text('Reunião')),
                DropdownMenuItem(value: 'other', child: Text('Outro')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Horário início',
                      border: OutlineInputBorder(),
                      hintText: '14:00',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Horário fim',
                      border: OutlineInputBorder(),
                      hintText: '15:30',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(value: true, onChanged: (value) {}),
                const Text('Tempo faturável'),
              ],
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
                  content: Text('Registro adicionado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerar Relatório'),
        content: const Text(
          'Selecione o período para o relatório de tempo:',
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
                  content: Text('Gerando relatório...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Esta Semana'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gerando relatório mensal...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Este Mês'),
          ),
        ],
      ),
    );
  }

  void _exportTimesheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando timesheet para o sistema de cobrança...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewDetailedHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo histórico detalhado de tempo...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Métodos de apoio
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h${mins.toString().padLeft(2, '0')}min';
  }

  Color _getFocusScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up': return Colors.green;
      case 'down': return Colors.red;
      case 'stable': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up': return Icons.trending_up;
      case 'down': return Icons.trending_down;
      case 'stable': return Icons.trending_flat;
      default: return Icons.help;
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'up': return 'Melhorando';
      case 'down': return 'Declínio';
      case 'stable': return 'Estável';
      default: return 'N/A';
    }
  }
} 
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Controle de Tempo para advogados associados
/// 
/// **Contexto:** Advogados associados (lawyer_associated)
/// **Substituição:** ProcessStatusSection (experiência do cliente)
/// **Foco:** Controle de tempo, produtividade e métricas de trabalho
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir ProcessStatusSection para advogados associados
/// - Foco em produtividade e registro de tempo trabalhado
class TimeTrackingSection extends BaseInfoSection {
  final Map<String, dynamic>? contextualData;

  const TimeTrackingSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Controle de Tempo',
      children: [
        _buildActiveTimer(context),
        const SizedBox(height: 16),
        _buildTimeMetrics(context),
        const SizedBox(height: 16),
        _buildDailyBreakdown(context),
        const SizedBox(height: 16),
        _buildProductivityInsights(context),
        const SizedBox(height: 20),
        _buildTimeActions(context),
      ],
    );
  }

  Widget _buildActiveTimer(BuildContext context) {
    final isTimerActive = contextualData?['timer_active'] ?? false;
    final currentSession = contextualData?['current_session_minutes'] ?? 0;
    final currentTask = contextualData?['current_task'] ?? 'Elaboração da petição inicial';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessão Atual',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTimerActive 
                ? [Colors.green[50]!, Colors.blue[50]!]
                : [Colors.grey[50]!, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTimerActive 
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Status do timer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isTimerActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isTimerActive ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTimerActive ? 'Timer Ativo' : 'Timer Pausado',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isTimerActive ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          currentTask,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tempo da sessão atual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTimerActive 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatMinutes(currentSession),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isTimerActive ? Colors.green[700] : Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Controles do timer
              Row(
                children: [
                  Expanded(
                    child: buildActionButton(
                      label: isTimerActive ? 'Pausar' : 'Iniciar',
                      icon: isTimerActive ? Icons.pause : Icons.play_arrow,
                      onPressed: () => _toggleTimer(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildActionButton(
                      label: 'Finalizar',
                      icon: Icons.stop,
                      onPressed: () => _stopTimer(context),
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeMetrics(BuildContext context) {
    final todayHours = contextualData?['today_hours'] ?? 4.5;
    final weekHours = contextualData?['week_hours'] ?? 18.5;
    final monthHours = contextualData?['month_hours'] ?? 42.0;
    final billablePercentage = contextualData?['billable_percentage'] ?? 85.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas de Tempo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid de métricas
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              context,
              'Hoje',
              '${todayHours.toStringAsFixed(1)}h',
              Icons.today,
              Colors.blue,
              'Meta: 8h',
            ),
            _buildMetricCard(
              context,
              'Esta Semana',
              '${weekHours.toStringAsFixed(1)}h',
              Icons.calendar_view_week,
              Colors.green,
              'Meta: 40h',
            ),
            _buildMetricCard(
              context,
              'Este Mês',
              '${monthHours.toStringAsFixed(0)}h',
              Icons.calendar_month,
              Colors.orange,
              'Meta: 160h',
            ),
            _buildMetricCard(
              context,
              'Faturável',
              '${billablePercentage.toStringAsFixed(0)}%',
              Icons.monetization_on,
              Colors.purple,
              'Meta: 80%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(BuildContext context) {
    final dailyEntries = contextualData?['daily_entries'] ?? [
      {
        'time': '09:00 - 10:30',
        'duration': 90,
        'task': 'Análise de documentos',
        'billable': true,
      },
      {
        'time': '10:45 - 12:00',
        'duration': 75,
        'task': 'Pesquisa jurisprudencial',
        'billable': true,
      },
      {
        'time': '14:00 - 15:30',
        'duration': 90,
        'task': 'Elaboração da petição',
        'billable': true,
      },
      {
        'time': '15:45 - 16:15',
        'duration': 30,
        'task': 'Reunião de alinhamento',
        'billable': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Registro de Hoje',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDetailedHistory(context),
              icon: const Icon(Icons.history, size: 16),
              label: const Text(
                'Ver Histórico',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de entradas
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: dailyEntries.map<Widget>((entry) {
              final duration = entry['duration'] as int;
              final billable = entry['billable'] as bool;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Horário
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry['time'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Duração
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: billable ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatMinutes(duration),
                        style: TextStyle(
                          color: billable ? Colors.green[700] : Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Tarefa
                    Expanded(
                      child: Text(
                        entry['task'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    // Ícone faturável
                    Icon(
                      billable ? Icons.monetization_on : Icons.schedule,
                      color: billable ? Colors.green[600] : Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityInsights(BuildContext context) {
    final focusScore = contextualData?['focus_score'] ?? 8.5;
    final efficiencyTrend = contextualData?['efficiency_trend'] ?? 'up';
    final mostProductiveHour = contextualData?['most_productive_hour'] ?? '10:00';
    final averageSessionLength = contextualData?['average_session_length'] ?? 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights de Produtividade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              // Score de foco
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score de Foco Hoje',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${focusScore.toStringAsFixed(1)}/10',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getFocusScoreColor(focusScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTrendColor(efficiencyTrend).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTrendIcon(efficiencyTrend),
                          color: _getTrendColor(efficiencyTrend),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTrendLabel(efficiencyTrend),
                          style: TextStyle(
                            color: _getTrendColor(efficiencyTrend),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Insights adicionais
              Row(
                children: [
                  Expanded(
                    child: _buildInsightItem(
                      context,
                      'Horário Produtivo',
                      mostProductiveHour,
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightItem(
                      context,
                      'Sessão Média',
                      _formatMinutes(averageSessionLength),
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Novo Registro',
                icon: Icons.add_alarm,
                onPressed: () => _addTimeEntry(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Relatório',
                icon: Icons.analytics,
                onPressed: () => _generateReport(context),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(
            label: 'Exportar Timesheet para Cobrança',
            icon: Icons.file_download,
            onPressed: () => _exportTimesheet(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _toggleTimer(BuildContext context) {
    final isActive = contextualData?['timer_active'] ?? false;
    final action = isActive ? 'pausado' : 'iniciado';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timer $action com sucesso!'),
        backgroundColor: isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  void _stopTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Sessão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tempo trabalhado nesta sessão:'),
            const SizedBox(height: 8),
            Text(
              _formatMinutes(contextualData?['current_session_minutes'] ?? 0),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Observações da sessão (opcional)',
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
                  content: Text('Sessão finalizada e registrada!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _addTimeEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Registro Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tarefa',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'analysis', child: Text('Análise de documentos')),
                DropdownMenuItem(value: 'petition', child: Text('Elaboração da petição')),
                DropdownMenuItem(value: 'research', child: Text('Pesquisa jurisprudencial')),
                DropdownMenuItem(value: 'meeting', child: Text('Reunião')),
                DropdownMenuItem(value: 'other', child: Text('Outro')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Horário início',
                      border: OutlineInputBorder(),
                      hintText: '14:00',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Horário fim',
                      border: OutlineInputBorder(),
                      hintText: '15:30',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(value: true, onChanged: (value) {}),
                const Text('Tempo faturável'),
              ],
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
                  content: Text('Registro adicionado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerar Relatório'),
        content: const Text(
          'Selecione o período para o relatório de tempo:',
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
                  content: Text('Gerando relatório...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Esta Semana'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gerando relatório mensal...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Este Mês'),
          ),
        ],
      ),
    );
  }

  void _exportTimesheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando timesheet para o sistema de cobrança...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewDetailedHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo histórico detalhado de tempo...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Métodos de apoio
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h${mins.toString().padLeft(2, '0')}min';
  }

  Color _getFocusScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up': return Colors.green;
      case 'down': return Colors.red;
      case 'stable': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up': return Icons.trending_up;
      case 'down': return Icons.trending_down;
      case 'stable': return Icons.trending_flat;
      default: return Icons.help;
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'up': return 'Melhorando';
      case 'down': return 'Declínio';
      case 'stable': return 'Estável';
      default: return 'N/A';
    }
  }
} 