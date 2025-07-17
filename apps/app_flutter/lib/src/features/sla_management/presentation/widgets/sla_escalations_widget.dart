import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_escalation_entity.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaEscalationsWidget extends StatefulWidget {
  const SlaEscalationsWidget({super.key});

  @override
  State<SlaEscalationsWidget> createState() => _SlaEscalationsWidgetState();
}

class _SlaEscalationsWidgetState extends State<SlaEscalationsWidget> {
  List<SlaEscalationEntity> _escalations = [];
  bool _enableAutoEscalation = true;
  int _defaultEscalationDelay = 30; // minutes
  String _selectedTriggerType = 'time_based';

  @override
  void initState() {
    super.initState();
    _loadDefaultEscalations();
  }

  void _loadDefaultEscalations() {
    _escalations = [
      SlaEscalationEntity.timeBasedEscalation(
        id: 'esc_1',
        name: 'Escalação Automática - Nível 1',
        description: 'Notificar supervisor quando 80% do prazo se esgotou',
        firmId: 'current_firm',
      ),
      SlaEscalationEntity.priorityBasedEscalation(
        id: 'esc_2', 
        name: 'Escalação por Prioridade',
        description: 'Escalação imediata para casos de emergência',
        firmId: 'current_firm',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildGlobalSettings(),
              const SizedBox(height: 24),
              _buildEscalationList(),
              const SizedBox(height: 24),
              _buildCreateEscalationSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Escalações SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure workflows de escalação automática para garantir que nenhum SLA seja violado.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações Globais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Habilitar Escalação Automática'),
              subtitle: const Text('Ativar escalações baseadas em regras'),
              value: _enableAutoEscalation,
              onChanged: (value) => setState(() => _enableAutoEscalation = value),
            ),
            if (_enableAutoEscalation) ...[
              const SizedBox(height: 16),
              Text(
                'Delay Padrão para Escalação (minutos)',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _defaultEscalationDelay.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$_defaultEscalationDelay min',
                      onChanged: (value) => setState(() => _defaultEscalationDelay = value.round()),
                    ),
                  ),
                  Text('$_defaultEscalationDelay min'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tempo aguardado antes de executar a próxima ação de escalação',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Workflows de Escalação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_escalations.length} workflows',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_escalations.isEmpty)
              _buildEmptyEscalations()
            else
              ..._escalations.map((escalation) => _buildEscalationCard(escalation)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEscalations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum workflow de escalação',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie workflows automáticos para escalar casos quando necessário.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationCard(SlaEscalationEntity escalation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getEscalationTypeColor(escalation.triggerType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEscalationTypeIcon(escalation.triggerType),
                      color: _getEscalationTypeColor(escalation.triggerType),
                      size: 20,
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
                                escalation.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: escalation.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                escalation.isActive ? 'ATIVO' : 'INATIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: escalation.isActive ? Colors.green[700] : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          escalation.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleEscalationAction(action, escalation),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'test',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 16),
                            SizedBox(width: 8),
                            Text('Testar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16),
                            SizedBox(width: 8),
                            Text('Duplicar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: escalation.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              escalation.isActive ? Icons.pause : Icons.play_arrow,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(escalation.isActive ? 'Desativar' : 'Ativar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildEscalationDetails(escalation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEscalationDetails(SlaEscalationEntity escalation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDetailChip(
              'Gatilho',
              _getEscalationTriggerLabel(escalation.triggerType),
              _getEscalationTypeColor(escalation.triggerType),
            ),
            const SizedBox(width: 8),
            _buildDetailChip(
              'Níveis',
              '${escalation.escalationLevels.length}',
              Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildDetailChip(
              'Ações',
              '${escalation.escalationLevels.fold<int>(0, (sum, level) => sum + level.actions.length)}',
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Níveis de Escalação:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...escalation.escalationLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          return _buildEscalationLevel(index + 1, level);
        }),
      ],
    );
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationLevel(int level, dynamic levelData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
                  'Nível $level',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ações: ${_getActionsDescription(levelData.actions ?? [])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEscalationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Criar Nova Escalação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Escolha um tipo de escalação para começar:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Baseada em Tempo',
                    'Escala baseado em % do prazo decorrido',
                    Icons.schedule,
                    Colors.blue,
                    'time_based',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Baseada em Prioridade',
                    'Escala baseado na prioridade do caso',
                    Icons.priority_high,
                    Colors.orange,
                    'priority_based',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Combinada',
                    'Combina tempo e prioridade',
                    Icons.merge,
                    Colors.purple,
                    'combined',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Manual',
                    'Escalação manual sob demanda',
                    Icons.pan_tool,
                    Colors.green,
                    'manual',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationTypeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String type,
  ) {
    final isSelected = _selectedTriggerType == type;
    return InkWell(
      onTap: () => setState(() => _selectedTriggerType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _createEscalation(),
            icon: const Icon(Icons.add),
            label: const Text('Criar Escalação'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _testAllEscalations(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Testar Todas'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveEscalationSettings(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getEscalationTypeColor(String type) {
    switch (type) {
      case 'time_based':
        return Colors.blue;
      case 'priority_based':
        return Colors.orange;
      case 'combined':
        return Colors.purple;
      case 'manual':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEscalationTypeIcon(String type) {
    switch (type) {
      case 'time_based':
        return Icons.schedule;
      case 'priority_based':
        return Icons.priority_high;
      case 'combined':
        return Icons.merge;
      case 'manual':
        return Icons.pan_tool;
      default:
        return Icons.trending_up;
    }
  }

  String _getEscalationTriggerLabel(String type) {
    switch (type) {
      case 'time_based':
        return 'Tempo';
      case 'priority_based':
        return 'Prioridade';
      case 'combined':
        return 'Combinado';
      case 'manual':
        return 'Manual';
      default:
        return 'Desconhecido';
    }
  }

  String _getActionsDescription(List<dynamic> actions) {
    if (actions.isEmpty) return 'Nenhuma ação';
    final types = actions.map((a) => a['type'] ?? 'unknown').toSet();
    return types.join(', ');
  }

  void _handleEscalationAction(String action, SlaEscalationEntity escalation) {
    switch (action) {
      case 'edit':
        _editEscalation(escalation);
        break;
      case 'test':
        _testEscalation(escalation);
        break;
      case 'duplicate':
        _duplicateEscalation(escalation);
        break;
      case 'activate':
      case 'deactivate':
        _toggleEscalation(escalation);
        break;
      case 'delete':
        _deleteEscalation(escalation);
        break;
    }
  }

  void _editEscalation(SlaEscalationEntity escalation) {
    // TODO: Implement escalation editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
    );
  }

  void _testEscalation(SlaEscalationEntity escalation) {
    context.read<SlaSettingsBloc>().add(
      TestSlaEscalationEvent(escalationId: escalation.id),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testando escalação "${escalation.name}"')),
    );
  }

  void _duplicateEscalation(SlaEscalationEntity escalation) {
    final duplicated = escalation.copyWith(
      id: 'esc_${DateTime.now().millisecondsSinceEpoch}',
      name: '${escalation.name} (Cópia)',
    );
    
    setState(() => _escalations.add(duplicated));
  }

  void _toggleEscalation(SlaEscalationEntity escalation) {
    final updated = escalation.copyWith(isActive: !escalation.isActive);
    final index = _escalations.indexWhere((e) => e.id == escalation.id);
    if (index != -1) {
      setState(() => _escalations[index] = updated);
    }
  }

  void _deleteEscalation(SlaEscalationEntity escalation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Escalação'),
        content: Text('Tem certeza que deseja excluir "${escalation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _escalations.removeWhere((e) => e.id == escalation.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _createEscalation() {
    // TODO: Implement escalation creation based on selected type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Criando escalação do tipo "$_selectedTriggerType"')),
    );
  }

  void _testAllEscalations() {
    for (final escalation in _escalations.where((e) => e.isActive)) {
      context.read<SlaSettingsBloc>().add(
        TestSlaEscalationEvent(escalationId: escalation.id),
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testando ${_escalations.where((e) => e.isActive).length} escalações ativas')),
    );
  }

  void _saveEscalationSettings() {
    final settings = {
      'enableAutoEscalation': _enableAutoEscalation,
      'defaultEscalationDelay': _defaultEscalationDelay,
      'escalations': _escalations.map((e) => e.toJson()).toList(),
    };

    context.read<SlaSettingsBloc>().add(
      UpdateSlaEscalationSettingsEvent(settings: settings),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações de escalação salvas com sucesso')),
    );
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_escalation_entity.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaEscalationsWidget extends StatefulWidget {
  const SlaEscalationsWidget({super.key});

  @override
  State<SlaEscalationsWidget> createState() => _SlaEscalationsWidgetState();
}

class _SlaEscalationsWidgetState extends State<SlaEscalationsWidget> {
  List<SlaEscalationEntity> _escalations = [];
  bool _enableAutoEscalation = true;
  int _defaultEscalationDelay = 30; // minutes
  String _selectedTriggerType = 'time_based';

  @override
  void initState() {
    super.initState();
    _loadDefaultEscalations();
  }

  void _loadDefaultEscalations() {
    _escalations = [
      SlaEscalationEntity.timeBasedEscalation(
        id: 'esc_1',
        name: 'Escalação Automática - Nível 1',
        description: 'Notificar supervisor quando 80% do prazo se esgotou',
        firmId: 'current_firm',
      ),
      SlaEscalationEntity.priorityBasedEscalation(
        id: 'esc_2', 
        name: 'Escalação por Prioridade',
        description: 'Escalação imediata para casos de emergência',
        firmId: 'current_firm',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildGlobalSettings(),
              const SizedBox(height: 24),
              _buildEscalationList(),
              const SizedBox(height: 24),
              _buildCreateEscalationSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Escalações SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure workflows de escalação automática para garantir que nenhum SLA seja violado.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações Globais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Habilitar Escalação Automática'),
              subtitle: const Text('Ativar escalações baseadas em regras'),
              value: _enableAutoEscalation,
              onChanged: (value) => setState(() => _enableAutoEscalation = value),
            ),
            if (_enableAutoEscalation) ...[
              const SizedBox(height: 16),
              Text(
                'Delay Padrão para Escalação (minutos)',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _defaultEscalationDelay.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$_defaultEscalationDelay min',
                      onChanged: (value) => setState(() => _defaultEscalationDelay = value.round()),
                    ),
                  ),
                  Text('$_defaultEscalationDelay min'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tempo aguardado antes de executar a próxima ação de escalação',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Workflows de Escalação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_escalations.length} workflows',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_escalations.isEmpty)
              _buildEmptyEscalations()
            else
              ..._escalations.map((escalation) => _buildEscalationCard(escalation)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEscalations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum workflow de escalação',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie workflows automáticos para escalar casos quando necessário.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationCard(SlaEscalationEntity escalation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getEscalationTypeColor(escalation.triggerType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEscalationTypeIcon(escalation.triggerType),
                      color: _getEscalationTypeColor(escalation.triggerType),
                      size: 20,
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
                                escalation.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: escalation.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                escalation.isActive ? 'ATIVO' : 'INATIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: escalation.isActive ? Colors.green[700] : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          escalation.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleEscalationAction(action, escalation),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'test',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 16),
                            SizedBox(width: 8),
                            Text('Testar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16),
                            SizedBox(width: 8),
                            Text('Duplicar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: escalation.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              escalation.isActive ? Icons.pause : Icons.play_arrow,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(escalation.isActive ? 'Desativar' : 'Ativar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildEscalationDetails(escalation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEscalationDetails(SlaEscalationEntity escalation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDetailChip(
              'Gatilho',
              _getEscalationTriggerLabel(escalation.triggerType),
              _getEscalationTypeColor(escalation.triggerType),
            ),
            const SizedBox(width: 8),
            _buildDetailChip(
              'Níveis',
              '${escalation.escalationLevels.length}',
              Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildDetailChip(
              'Ações',
              '${escalation.escalationLevels.fold<int>(0, (sum, level) => sum + level.actions.length)}',
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Níveis de Escalação:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...escalation.escalationLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          return _buildEscalationLevel(index + 1, level);
        }),
      ],
    );
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationLevel(int level, dynamic levelData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
                  'Nível $level',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ações: ${_getActionsDescription(levelData.actions ?? [])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEscalationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Criar Nova Escalação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Escolha um tipo de escalação para começar:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Baseada em Tempo',
                    'Escala baseado em % do prazo decorrido',
                    Icons.schedule,
                    Colors.blue,
                    'time_based',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Baseada em Prioridade',
                    'Escala baseado na prioridade do caso',
                    Icons.priority_high,
                    Colors.orange,
                    'priority_based',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Combinada',
                    'Combina tempo e prioridade',
                    Icons.merge,
                    Colors.purple,
                    'combined',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEscalationTypeCard(
                    'Manual',
                    'Escalação manual sob demanda',
                    Icons.pan_tool,
                    Colors.green,
                    'manual',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationTypeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String type,
  ) {
    final isSelected = _selectedTriggerType == type;
    return InkWell(
      onTap: () => setState(() => _selectedTriggerType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _createEscalation(),
            icon: const Icon(Icons.add),
            label: const Text('Criar Escalação'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _testAllEscalations(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Testar Todas'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveEscalationSettings(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getEscalationTypeColor(String type) {
    switch (type) {
      case 'time_based':
        return Colors.blue;
      case 'priority_based':
        return Colors.orange;
      case 'combined':
        return Colors.purple;
      case 'manual':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEscalationTypeIcon(String type) {
    switch (type) {
      case 'time_based':
        return Icons.schedule;
      case 'priority_based':
        return Icons.priority_high;
      case 'combined':
        return Icons.merge;
      case 'manual':
        return Icons.pan_tool;
      default:
        return Icons.trending_up;
    }
  }

  String _getEscalationTriggerLabel(String type) {
    switch (type) {
      case 'time_based':
        return 'Tempo';
      case 'priority_based':
        return 'Prioridade';
      case 'combined':
        return 'Combinado';
      case 'manual':
        return 'Manual';
      default:
        return 'Desconhecido';
    }
  }

  String _getActionsDescription(List<dynamic> actions) {
    if (actions.isEmpty) return 'Nenhuma ação';
    final types = actions.map((a) => a['type'] ?? 'unknown').toSet();
    return types.join(', ');
  }

  void _handleEscalationAction(String action, SlaEscalationEntity escalation) {
    switch (action) {
      case 'edit':
        _editEscalation(escalation);
        break;
      case 'test':
        _testEscalation(escalation);
        break;
      case 'duplicate':
        _duplicateEscalation(escalation);
        break;
      case 'activate':
      case 'deactivate':
        _toggleEscalation(escalation);
        break;
      case 'delete':
        _deleteEscalation(escalation);
        break;
    }
  }

  void _editEscalation(SlaEscalationEntity escalation) {
    // TODO: Implement escalation editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
    );
  }

  void _testEscalation(SlaEscalationEntity escalation) {
    context.read<SlaSettingsBloc>().add(
      TestSlaEscalationEvent(escalationId: escalation.id),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testando escalação "${escalation.name}"')),
    );
  }

  void _duplicateEscalation(SlaEscalationEntity escalation) {
    final duplicated = escalation.copyWith(
      id: 'esc_${DateTime.now().millisecondsSinceEpoch}',
      name: '${escalation.name} (Cópia)',
    );
    
    setState(() => _escalations.add(duplicated));
  }

  void _toggleEscalation(SlaEscalationEntity escalation) {
    final updated = escalation.copyWith(isActive: !escalation.isActive);
    final index = _escalations.indexWhere((e) => e.id == escalation.id);
    if (index != -1) {
      setState(() => _escalations[index] = updated);
    }
  }

  void _deleteEscalation(SlaEscalationEntity escalation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Escalação'),
        content: Text('Tem certeza que deseja excluir "${escalation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _escalations.removeWhere((e) => e.id == escalation.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _createEscalation() {
    // TODO: Implement escalation creation based on selected type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Criando escalação do tipo "$_selectedTriggerType"')),
    );
  }

  void _testAllEscalations() {
    for (final escalation in _escalations.where((e) => e.isActive)) {
      context.read<SlaSettingsBloc>().add(
        TestSlaEscalationEvent(escalationId: escalation.id),
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testando ${_escalations.where((e) => e.isActive).length} escalações ativas')),
    );
  }

  void _saveEscalationSettings() {
    final settings = {
      'enableAutoEscalation': _enableAutoEscalation,
      'defaultEscalationDelay': _defaultEscalationDelay,
      'escalations': _escalations.map((e) => e.toJson()).toList(),
    };

    context.read<SlaSettingsBloc>().add(
      UpdateSlaEscalationSettingsEvent(settings: settings),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações de escalação salvas com sucesso')),
    );
  }
} 