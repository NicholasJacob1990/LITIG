import 'package:flutter/material.dart';
import '../base_info_section.dart';
import '../../../../../core/theme/adaptive_colors.dart';

/// Seção de Atribuição de Caso para Advogados Associados
/// 
/// Substitui ConsultationInfoSection quando o caso foi
/// delegado internamente, focando nas informações da atribuição.
class CaseAssignmentSection extends BaseInfoSection {
  const CaseAssignmentSection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final delegatedByName = getContextualValue<String>('delegated_by_name') ?? 'Dr. Silva';
    final assignmentDate = getContextualValue<String>('assignment_date') ?? formatDate(DateTime.now());
    final priority = getContextualValue<String>('priority') ?? 'Normal';
    final billableHours = getContextualValue<bool>('is_billable', true) ?? true;
    
    return buildSectionCard(
      context,
      title: 'Informações da Atribuição',
      titleSuffix: buildStatusBadge(
        context,
        _getPriorityBadge(),
        backgroundColor: _getPriorityColor(),
        textColor: Colors.white,
        icon: _getPriorityIcon(),
      ),
      children: [
        // Header da atribuição
        buildSectionHeader(
          context,
          title: 'Detalhes da Delegação',
          icon: Icons.assignment_ind,
          subtitle: 'Informações sobre como o caso foi atribuído',
        ),
        
        // Informações principais
        buildInfoRow(
          context,
          Icons.person,
          'Delegado por',
          delegatedByName,
          trailing: IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _contactDelegator(context),
            tooltip: 'Contatar delegador',
          ),
        ),
        
        buildInfoRow(
          context,
          Icons.access_time,
          'Data da Atribuição',
          assignmentDate,
        ),
        
        buildInfoRow(
          context,
          Icons.flag,
          'Prioridade',
          priority,
          iconColor: _getPriorityColor(),
        ),
        
        buildInfoRow(
          context,
          Icons.schedule,
          'Modalidade',
          _getAssignmentType(),
          trailing: buildStatusBadge(
        context,
            billableHours ? 'Faturável' : 'Pro Bono',
            backgroundColor: billableHours 
              ? (context.isDarkTheme ? Colors.green.shade200 : Colors.green.shade100)
              : (context.isDarkTheme ? Colors.blue.shade200 : Colors.blue.shade100),
          ),
        ),
        
        buildDivider(context),
        
        // Escopo do trabalho
        buildSectionHeader(
          context,
          title: 'Escopo do Trabalho',
          icon: Icons.task,
        ),
        
        buildInfoRow(
          context,
          Icons.access_time,
          'Estimativa de Horas',
          '${getContextualValue<int>('hours_budgeted', 40) ?? 40}h',
          iconColor: Colors.blue,
        ),
        
        buildInfoRow(
          context,
          Icons.attach_money,
          'Taxa por Hora',
          formatCurrency(getContextualValue<double>('hourly_rate', 150.0) ?? 150.0),
          iconColor: Colors.green,
        ),
        
        buildInfoRow(
          context,
          Icons.calendar_today,
          'Prazo Interno',
          _getInternalDeadline(),
          iconColor: _getDeadlineColor(context),
        ),
        
        buildInfoRow(
          context,
          Icons.person_outline,
          'Cliente Final',
          _getClientName(),
        ),
        
        buildDivider(context),
        
        // Responsabilidades
        buildSectionHeader(
          context,
          title: 'Suas Responsabilidades',
          icon: Icons.checklist,
        ),
        
                 ..._buildResponsibilitiesList(context),
        
        buildDivider(context),
        
        // Recursos disponíveis
        buildSectionHeader(
          context,
          title: 'Recursos Disponíveis',
          icon: Icons.support,
        ),
        
        buildInfoRow(
          context,
          Icons.folder,
          'Pasta de Trabalho',
          _getWorkFolder(),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openWorkFolder(context),
            tooltip: 'Abrir pasta',
          ),
        ),
        
        buildInfoRow(
          context,
          Icons.people,
          'Equipe de Suporte',
          _getSupportTeam(),
          trailing: IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => _viewSupportTeam(context),
            tooltip: 'Ver equipe',
          ),
        ),
        
        buildInfoRow(
          context,
          Icons.library_books,
          'Recursos Jurídicos',
          _getLegalResources(),
          trailing: IconButton(
            icon: const Icon(Icons.link),
            onPressed: () => _accessResources(context),
            tooltip: 'Acessar recursos',
          ),
        ),
        
        buildDivider(context),
        
        // KPIs de performance
        buildSectionHeader(
          context,
          title: 'Métricas de Performance',
          icon: Icons.analytics,
        ),
        
        buildKPIsList(
        context, [
          KPIItem(
            icon: '📊',
            label: 'Progresso',
            value: '${_getProgressPercentage()}%',
          ),
          KPIItem(
            icon: '⏱️',
            label: 'Tempo Gasto',
            value: '${_getTimeSpent()}h',
          ),
          KPIItem(
            icon: '🎯',
            label: 'Eficiência',
            value: '${_getEfficiencyRating()}%',
          ),
        ]),
        
        buildDivider(context),
        
        // Ações rápidas
        buildSectionHeader(
          context,
          title: 'Ações Rápidas',
          icon: Icons.flash_on,
        ),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context,
                label: 'Iniciar Trabalho',
                icon: Icons.play_arrow,
                onPressed: () => _startWork(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context,
                label: 'Registrar Progresso',
                icon: Icons.update,
                isOutlined: true,
                onPressed: () => _updateProgress(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context,
                label: 'Solicitar Reunião',
                icon: Icons.video_call,
                isOutlined: true,
                onPressed: () => _requestMeeting(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context,
                label: 'Relatar Problema',
                icon: Icons.report_problem,
                isOutlined: true,
                onPressed: () => _reportIssue(context),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        
        // Nota de orientação
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.isDarkTheme ? Colors.blue.shade300 : Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb,
                size: 20,
                color: context.isDarkTheme ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dica de Produtividade',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.isDarkTheme ? Colors.blue.shade300 : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getProductivityTip(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.isDarkTheme ? Colors.blue.shade300 : Colors.blue.shade700,
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

  // ==================== MÉTODOS PRIVADOS ====================

  String _getPriorityBadge() {
    final priority = getContextualValue<String>('priority', 'Normal') ?? 'Normal';
    return priority;
  }

  Color _getPriorityColor() {
    final priority = getContextualValue<String>('priority', 'Normal') ?? 'Normal';
    switch (priority.toLowerCase()) {
      case 'alta': return Colors.red;
      case 'média': return Colors.orange;
      case 'normal': return Colors.blue;
      case 'baixa': return Colors.green;
      default: return Colors.blue;
    }
  }

  IconData _getPriorityIcon() {
    final priority = getContextualValue<String>('priority', 'Normal') ?? 'Normal';
    switch (priority.toLowerCase()) {
      case 'alta': return Icons.priority_high;
      case 'média': return Icons.remove;
      case 'normal': return Icons.remove;
      case 'baixa': return Icons.low_priority;
      default: return Icons.flag;
    }
  }

  String _getAssignmentType() {
    final types = ['Delegação Direta', 'Apoio Técnico', 'Revisão de Pares', 'Supervisão'];
    final index = (getContextualValue<int>('assignment_type_index', 0) ?? 0) % types.length;
    return types[index];
  }

  String _getInternalDeadline() {
    final days = getContextualValue<int>('deadline_days', 15) ?? 15;
    final deadline = DateTime.now().add(Duration(days: days));
    return formatDate(deadline);
  }

  Color _getDeadlineColor(BuildContext context) {
    final days = getContextualValue<int>('deadline_days', 15) ?? 15;
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getClientName() {
    return getContextualValue<String>('client_name') ?? caseDetail.title.split(' ').first;
  }

  List<Widget> _buildResponsibilitiesList(BuildContext context) {
    final responsibilities = [
      'Análise detalhada dos documentos fornecidos',
      'Elaboração de petição inicial ou manifestação',
      'Pesquisa jurisprudencial e doutrinária',
      'Comunicação regular com o delegador',
      'Registro de horas trabalhadas no sistema',
    ];
    
    return responsibilities.map((responsibility) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              responsibility,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    )).toList();
  }

  String _getWorkFolder() {
    return 'Casos/${caseDetail.id}/Documentos';
  }

  String _getSupportTeam() {
    final teamSize = getContextualValue<int>('support_team_size', 2) ?? 2;
    return '$teamSize assistentes disponíveis';
  }

  String _getLegalResources() {
    return 'Biblioteca Jurídica Digital + Templates';
  }

  int _getProgressPercentage() {
    return getContextualValue<int>('progress_percentage', 25) ?? 25;
  }

  int _getTimeSpent() {
    return getContextualValue<int>('time_spent_hours', 8) ?? 8;
  }

  int _getEfficiencyRating() {
    final timeSpent = _getTimeSpent();
    final budgeted = getContextualValue<int>('hours_budgeted', 40) ?? 40;
    final progress = _getProgressPercentage();
    
    // Cálculo simples de eficiência: progresso vs tempo gasto
    if (timeSpent == 0) return 100;
    final efficiency = (progress / (timeSpent / budgeted * 100) * 100).clamp(0, 100);
    return efficiency.round();
  }

  String _getProductivityTip() {
    final tips = [
      'Use o sistema de timesheet para registrar o tempo com precisão.',
      'Mantenha comunicação regular com o delegador sobre o progresso.',
      'Organize os documentos na pasta de trabalho desde o início.',
      'Use os templates disponíveis para padronizar suas petições.',
    ];
    final index = (getContextualValue<int>('tip_index', 0) ?? 0) % tips.length;
    return tips[index];
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _contactDelegator(BuildContext context) {
    final delegatedByName = getContextualValue<String>('delegated_by_name', 'Dr. Silva') ?? 'Dr. Silva';
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contatar $delegatedByName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Enviar mensagem'),
              subtitle: const Text('Chat interno do escritório'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar chat
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Enviar e-mail'),
              subtitle: const Text('E-mail corporativo'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar e-mail
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Ligar'),
              subtitle: const Text('Ramal: 1234'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar chamada
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openWorkFolder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo pasta de trabalho...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar abertura da pasta
  }

  void _viewSupportTeam(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Equipe de Suporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Text('JS')),
              title: const Text('João Santos'),
              subtitle: const Text('Assistente Jurídico'),
              trailing: IconButton(
                icon: const Icon(Icons.message),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('MO')),
              title: const Text('Maria Oliveira'),
              subtitle: const Text('Estagiária'),
              trailing: IconButton(
                icon: const Icon(Icons.message),
                onPressed: () {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _accessResources(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca jurídica...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar acesso aos recursos
  }

  void _startWork(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Trabalho'),
        content: const Text('Isso vai registrar o início do trabalho neste caso. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cronômetro iniciado!')),
              );
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  void _updateProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Progresso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status atual',
              ),
              items: const [
                DropdownMenuItem(value: 'iniciado', child: Text('Iniciado')),
                DropdownMenuItem(value: 'em_progresso', child: Text('Em Progresso')),
                DropdownMenuItem(value: 'quase_concluido', child: Text('Quase Concluído')),
                DropdownMenuItem(value: 'concluido', child: Text('Concluído')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Horas trabalhadas hoje',
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observações',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progresso atualizado!')),
              );
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _requestMeeting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Reunião'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Motivo da reunião',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Urgência',
              ),
              items: const [
                DropdownMenuItem(value: 'baixa', child: Text('Baixa - Próximos dias')),
                DropdownMenuItem(value: 'media', child: Text('Média - Hoje')),
                DropdownMenuItem(value: 'alta', child: Text('Alta - Agora')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitação de reunião enviada!')),
              );
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatar Problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de problema',
              ),
              items: const [
                DropdownMenuItem(value: 'tecnico', child: Text('Problema técnico')),
                DropdownMenuItem(value: 'prazo', child: Text('Problema de prazo')),
                DropdownMenuItem(value: 'juridico', child: Text('Dúvida jurídica')),
                DropdownMenuItem(value: 'recurso', child: Text('Falta de recursos')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descrição do problema',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Problema relatado. Delegador será notificado.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Relatar'),
          ),
        ],
      ),
    );
  }
} 

/// Seção de Atribuição de Caso para Advogados Associados
/// 
/// Substitui ConsultationInfoSection quando o caso foi
/// delegado internamente, focando nas informações da atribuição.
