import 'package:flutter/material.dart';
import '../base_info_section.dart';
import '../../../domain/entities/case_detail.dart';

/// Seção de Equipe Interna para Advogados Associados
/// 
/// Substitui LawyerResponsibleSection quando o caso foi
/// delegado internamente, focando na hierarquia do escritório.
class InternalTeamSection extends BaseInfoSection {
  const InternalTeamSection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final delegatedByName = getContextualValue<String>('delegated_by_name') ?? 'Dr. Silva';
    final assignmentDate = getContextualValue<String>('assignment_date') ?? formatDate(DateTime.now());
    final internalDeadline = getContextualValue<String>('internal_deadline') ?? 'Não definido';
    final hierarchyLevel = getContextualValue<String>('hierarchy_level') ?? 'Júnior';
    
    return buildSectionCard(
      title: 'Equipe Interna',
      titleSuffix: buildStatusBadge(
        'Delegado',
        backgroundColor: Colors.orange.shade100,
        textColor: Colors.orange.shade800,
        icon: Icons.arrow_downward,
      ),
      children: [
        // Header da delegação
        buildSectionHeader(
          title: 'Informações da Delegação',
          icon: Icons.person_pin,
          subtitle: 'Caso delegado por sócio sênior',
        ),
        
        // Informações do delegador
        buildInfoRow(
          Icons.account_circle,
          'Delegado por',
          delegatedByName,
          trailing: IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _contactDelegator(context),
            tooltip: 'Enviar mensagem',
          ),
        ),
        
        buildInfoRow(
          Icons.calendar_today,
          'Data da Delegação',
          assignmentDate,
        ),
        
        buildInfoRow(
          Icons.schedule,
          'Prazo Interno',
          internalDeadline,
          iconColor: _getDeadlineColor(context),
        ),
        
        buildInfoRow(
          Icons.military_tech,
          'Seu Nível',
          hierarchyLevel,
          trailing: buildStatusBadge(
            hierarchyLevel,
            backgroundColor: _getHierarchyColor(context),
          ),
        ),
        
        buildDivider(),
        
        // KPIs de produtividade
        buildSectionHeader(
          title: 'Métricas de Produtividade',
          icon: Icons.trending_up,
        ),
        
        buildKPIsList([
          KPIItem(
            icon: '⏰',
            label: 'Prazo',
            value: _calculateDaysLeft(),
          ),
          KPIItem(
            icon: '📈',
            label: 'Horas',
            value: '${getContextualValue<int>('hours_budgeted', 40)}h',
          ),
          KPIItem(
            icon: '💼',
            label: 'Taxa',
            value: formatCurrency(getContextualValue<double>('hourly_rate', 150.0)),
          ),
        ]),
        
        buildDivider(),
        
        // Ações específicas
        buildSectionHeader(
          title: 'Ações Disponíveis',
          icon: Icons.task_alt,
        ),
        
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
                label: 'Contatar Delegador',
                icon: Icons.message,
                isOutlined: true,
                onPressed: () => _contactDelegator(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Atualizar Status',
                icon: Icons.update,
                isOutlined: true,
                onPressed: () => _updateStatus(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Escalar Problema',
                icon: Icons.priority_high,
                isOutlined: true,
                onPressed: () => _escalateIssue(context),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        
        // Nota sobre expectativas
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lembre-se de registrar todas as horas trabalhadas e comunicar eventuais impedimentos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS PRIVADOS ====================

  String _calculateDaysLeft() {
    final deadlineDays = getContextualValue<int>('deadline_days', 15);
    final assignmentDate = getContextualValue<DateTime>('assignment_date') ?? DateTime.now();
    final deadline = assignmentDate.add(Duration(days: deadlineDays));
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    
    if (daysLeft < 0) {
      return 'Atrasado';
    } else if (daysLeft == 0) {
      return 'Hoje';
    } else {
      return '$daysLeft dias';
    }
  }

  Color _getDeadlineColor(BuildContext context) {
    final deadlineDays = getContextualValue<int>('deadline_days', 15);
    final assignmentDate = getContextualValue<DateTime>('assignment_date') ?? DateTime.now();
    final deadline = assignmentDate.add(Duration(days: deadlineDays));
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    
    if (daysLeft < 0) {
      return Colors.red;
    } else if (daysLeft <= 3) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getHierarchyColor(BuildContext context) {
    final hierarchyLevel = getContextualValue<String>('hierarchy_level', 'Júnior');
    
    switch (hierarchyLevel.toLowerCase()) {
      case 'sênior':
        return Colors.purple.shade100;
      case 'pleno':
        return Colors.blue.shade100;
      case 'júnior':
      default:
        return Colors.green.shade100;
    }
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _logHours(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Horas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Horas trabalhadas',
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descrição das atividades',
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
                const SnackBar(content: Text('Horas registradas com sucesso!')),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _contactDelegator(BuildContext context) {
    final delegatedByName = getContextualValue<String>('delegated_by_name', 'Dr. Silva');
    
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
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar chat interno
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Solicitar reunião'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar agendamento
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Ligar'),
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

  void _updateStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Novo status',
              ),
              items: const [
                DropdownMenuItem(value: 'em_andamento', child: Text('Em Andamento')),
                DropdownMenuItem(value: 'aguardando_cliente', child: Text('Aguardando Cliente')),
                DropdownMenuItem(value: 'revisar', child: Text('Pronto para Revisão')),
                DropdownMenuItem(value: 'concluido', child: Text('Concluído')),
              ],
              onChanged: (value) {},
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
                const SnackBar(content: Text('Status atualizado com sucesso!')),
              );
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _escalateIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalar Problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deseja escalar este caso para o delegador?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descreva o problema',
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
                const SnackBar(content: Text('Problema escalado com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Escalar'),
          ),
        ],
      ),
    );
  }
} 
import '../base_info_section.dart';
import '../../../domain/entities/case_detail.dart';

/// Seção de Equipe Interna para Advogados Associados
/// 
/// Substitui LawyerResponsibleSection quando o caso foi
/// delegado internamente, focando na hierarquia do escritório.
class InternalTeamSection extends BaseInfoSection {
  const InternalTeamSection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final delegatedByName = getContextualValue<String>('delegated_by_name') ?? 'Dr. Silva';
    final assignmentDate = getContextualValue<String>('assignment_date') ?? formatDate(DateTime.now());
    final internalDeadline = getContextualValue<String>('internal_deadline') ?? 'Não definido';
    final hierarchyLevel = getContextualValue<String>('hierarchy_level') ?? 'Júnior';
    
    return buildSectionCard(
      title: 'Equipe Interna',
      titleSuffix: buildStatusBadge(
        'Delegado',
        backgroundColor: Colors.orange.shade100,
        textColor: Colors.orange.shade800,
        icon: Icons.arrow_downward,
      ),
      children: [
        // Header da delegação
        buildSectionHeader(
          title: 'Informações da Delegação',
          icon: Icons.person_pin,
          subtitle: 'Caso delegado por sócio sênior',
        ),
        
        // Informações do delegador
        buildInfoRow(
          Icons.account_circle,
          'Delegado por',
          delegatedByName,
          trailing: IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _contactDelegator(context),
            tooltip: 'Enviar mensagem',
          ),
        ),
        
        buildInfoRow(
          Icons.calendar_today,
          'Data da Delegação',
          assignmentDate,
        ),
        
        buildInfoRow(
          Icons.schedule,
          'Prazo Interno',
          internalDeadline,
          iconColor: _getDeadlineColor(context),
        ),
        
        buildInfoRow(
          Icons.military_tech,
          'Seu Nível',
          hierarchyLevel,
          trailing: buildStatusBadge(
            hierarchyLevel,
            backgroundColor: _getHierarchyColor(context),
          ),
        ),
        
        buildDivider(),
        
        // KPIs de produtividade
        buildSectionHeader(
          title: 'Métricas de Produtividade',
          icon: Icons.trending_up,
        ),
        
        buildKPIsList([
          KPIItem(
            icon: '⏰',
            label: 'Prazo',
            value: _calculateDaysLeft(),
          ),
          KPIItem(
            icon: '📈',
            label: 'Horas',
            value: '${getContextualValue<int>('hours_budgeted', 40)}h',
          ),
          KPIItem(
            icon: '💼',
            label: 'Taxa',
            value: formatCurrency(getContextualValue<double>('hourly_rate', 150.0)),
          ),
        ]),
        
        buildDivider(),
        
        // Ações específicas
        buildSectionHeader(
          title: 'Ações Disponíveis',
          icon: Icons.task_alt,
        ),
        
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
                label: 'Contatar Delegador',
                icon: Icons.message,
                isOutlined: true,
                onPressed: () => _contactDelegator(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Atualizar Status',
                icon: Icons.update,
                isOutlined: true,
                onPressed: () => _updateStatus(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Escalar Problema',
                icon: Icons.priority_high,
                isOutlined: true,
                onPressed: () => _escalateIssue(context),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        
        // Nota sobre expectativas
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lembre-se de registrar todas as horas trabalhadas e comunicar eventuais impedimentos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS PRIVADOS ====================

  String _calculateDaysLeft() {
    final deadlineDays = getContextualValue<int>('deadline_days', 15);
    final assignmentDate = getContextualValue<DateTime>('assignment_date') ?? DateTime.now();
    final deadline = assignmentDate.add(Duration(days: deadlineDays));
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    
    if (daysLeft < 0) {
      return 'Atrasado';
    } else if (daysLeft == 0) {
      return 'Hoje';
    } else {
      return '$daysLeft dias';
    }
  }

  Color _getDeadlineColor(BuildContext context) {
    final deadlineDays = getContextualValue<int>('deadline_days', 15);
    final assignmentDate = getContextualValue<DateTime>('assignment_date') ?? DateTime.now();
    final deadline = assignmentDate.add(Duration(days: deadlineDays));
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    
    if (daysLeft < 0) {
      return Colors.red;
    } else if (daysLeft <= 3) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getHierarchyColor(BuildContext context) {
    final hierarchyLevel = getContextualValue<String>('hierarchy_level', 'Júnior');
    
    switch (hierarchyLevel.toLowerCase()) {
      case 'sênior':
        return Colors.purple.shade100;
      case 'pleno':
        return Colors.blue.shade100;
      case 'júnior':
      default:
        return Colors.green.shade100;
    }
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _logHours(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Horas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Horas trabalhadas',
                suffixText: 'h',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descrição das atividades',
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
                const SnackBar(content: Text('Horas registradas com sucesso!')),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _contactDelegator(BuildContext context) {
    final delegatedByName = getContextualValue<String>('delegated_by_name', 'Dr. Silva');
    
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
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar chat interno
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Solicitar reunião'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar agendamento
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Ligar'),
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

  void _updateStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Novo status',
              ),
              items: const [
                DropdownMenuItem(value: 'em_andamento', child: Text('Em Andamento')),
                DropdownMenuItem(value: 'aguardando_cliente', child: Text('Aguardando Cliente')),
                DropdownMenuItem(value: 'revisar', child: Text('Pronto para Revisão')),
                DropdownMenuItem(value: 'concluido', child: Text('Concluído')),
              ],
              onChanged: (value) {},
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
                const SnackBar(content: Text('Status atualizado com sucesso!')),
              );
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _escalateIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalar Problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deseja escalar este caso para o delegador?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descreva o problema',
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
                const SnackBar(content: Text('Problema escalado com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Escalar'),
          ),
        ],
      ),
    );
  }
} 