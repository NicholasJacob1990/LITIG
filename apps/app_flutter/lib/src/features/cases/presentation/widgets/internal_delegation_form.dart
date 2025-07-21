import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../sla_settings/presentation/bloc/sla_settings_bloc.dart';
import '../../../sla_settings/domain/entities/sla_settings_entity.dart';
import '../../../../injection_container.dart';

class InternalDelegationForm extends StatefulWidget {
  final String caseId;
  final Function(Map<String, dynamic>) onDelegationSubmitted;

  const InternalDelegationForm({
    super.key,
    required this.caseId,
    required this.onDelegationSubmitted,
  });

  @override
  State<InternalDelegationForm> createState() => _InternalDelegationFormState();
}

class _InternalDelegationFormState extends State<InternalDelegationForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPriority = 'normal';
  String? _selectedLawyerId;
  int? _slaOverrideHours;
  DateTime? _customDeadline;
  bool _useSlaOverride = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SlaSettingsBloc>()
        ..add(const SlaSettingsLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delegação Interna'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings),
              onPressed: () {
                Navigator.of(context).pushNamed('/sla-settings');
              },
              tooltip: 'Configurar SLAs',
            ),
          ],
        ),
        body: BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
          builder: (context, slaState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do caso
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.briefcase, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Caso: ${widget.caseId}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Delegando caso para advogado interno do escritório',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Configurações de prioridade e SLA
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Configurações de Prazo',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Seletor de prioridade
                            Text(
                              'Prioridade',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Selecione a prioridade',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'normal',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.circle, size: 16, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Normal'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'urgent',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.alertTriangle, size: 16, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Urgente'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'emergency',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.alertCircle, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Emergência'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value!;
                                  _calculateDeadline();
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Visualização de SLA baseado nas configurações
                            _buildSlaPreview(slaState),
                            const SizedBox(height: 16),

                            // Override de SLA (se habilitado)
                            if (slaState is SlaSettingsLoaded && 
                                slaState.settings.enableSlaOverride)
                              _buildSlaOverrideSection(slaState.settings),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Formulário de delegação
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.user, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Detalhes da Delegação',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Seleção do advogado
                            Text(
                              'Advogado Responsável',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedLawyerId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Selecione o advogado',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione um advogado';
                                }
                                return null;
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'lawyer1',
                                  child: Text('Dr. João Silva'),
                                ),
                                DropdownMenuItem(
                                  value: 'lawyer2',
                                  child: Text('Dra. Maria Santos'),
                                ),
                                DropdownMenuItem(
                                  value: 'lawyer3',
                                  child: Text('Dr. Pedro Costa'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedLawyerId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Descrição
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descrição da Delegação',
                                border: OutlineInputBorder(),
                                hintText: 'Descreva o que deve ser feito...',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'A descrição é obrigatória';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Observações
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Observações (opcional)',
                                border: OutlineInputBorder(),
                                hintText: 'Informações adicionais...',
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitDelegation,
                            child: const Text('Delegar Caso'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlaPreview(SlaSettingsState slaState) {
    if (slaState is SlaSettingsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (slaState is SlaSettingsLoaded) {
      final settings = slaState.settings;
      int slaHours;
      
      switch (_selectedPriority) {
        case 'urgent':
          slaHours = settings.urgentInternalDelegationHours;
          break;
        case 'emergency':
          slaHours = settings.emergencyInternalDelegationHours;
          break;
        default:
          slaHours = settings.defaultInternalDelegationHours;
      }

      final deadline = DateTime.now().add(Duration(hours: slaHours));
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'SLA Calculado: $slaHours horas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Deadline: ${_formatDateTime(deadline)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (slaState is SlaSettingsError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erro ao carregar configurações SLA',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSlaOverrideSection(SlaSettingsEntity settings) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Usar SLA Customizado'),
          subtitle: Text(
            'Máximo: ${settings.maxSlaOverrideHours} horas',
          ),
          value: _useSlaOverride,
          onChanged: (value) {
            setState(() {
              _useSlaOverride = value;
              if (!value) {
                _slaOverrideHours = null;
                _customDeadline = null;
              }
            });
          },
        ),
        if (_useSlaOverride) ...[
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'SLA Customizado (horas)',
              border: OutlineInputBorder(),
              hintText: 'Ex: 12',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_useSlaOverride) {
                if (value == null || value.isEmpty) {
                  return 'Informe o SLA customizado';
                }
                final hours = int.tryParse(value);
                if (hours == null || hours <= 0) {
                  return 'Informe um valor válido';
                }
                if (hours > settings.maxSlaOverrideHours) {
                  return 'Máximo: ${settings.maxSlaOverrideHours} horas';
                }
              }
              return null;
            },
            onChanged: (value) {
              final hours = int.tryParse(value);
              if (hours != null) {
                setState(() {
                  _slaOverrideHours = hours;
                  _customDeadline = DateTime.now().add(Duration(hours: hours));
                });
              }
            },
          ),
          if (_customDeadline != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Novo deadline: ${_formatDateTime(_customDeadline!)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} às '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _calculateDeadline() {
    // Trigger recálculo do SLA quando a prioridade muda
    if (mounted) {
      setState(() {});
    }
  }

  void _submitDelegation() {
    if (_formKey.currentState!.validate()) {
      final delegationData = {
        'case_id': widget.caseId,
        'lawyer_id': _selectedLawyerId!,
        'priority_level': _selectedPriority,
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        if (_useSlaOverride && _slaOverrideHours != null)
          'sla_override_hours': _slaOverrideHours,
        'allocation_type': 'internal_delegation',
      };

      widget.onDelegationSubmitted(delegationData);
      Navigator.of(context).pop();
    }
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../sla_settings/presentation/bloc/sla_settings_bloc.dart';
import '../../../sla_settings/domain/entities/sla_settings_entity.dart';
import '../../../../injection_container.dart';

class InternalDelegationForm extends StatefulWidget {
  final String caseId;
  final Function(Map<String, dynamic>) onDelegationSubmitted;

  const InternalDelegationForm({
    super.key,
    required this.caseId,
    required this.onDelegationSubmitted,
  });

  @override
  State<InternalDelegationForm> createState() => _InternalDelegationFormState();
}

class _InternalDelegationFormState extends State<InternalDelegationForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPriority = 'normal';
  String? _selectedLawyerId;
  int? _slaOverrideHours;
  DateTime? _customDeadline;
  bool _useSlaOverride = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SlaSettingsBloc>()
        ..add(const SlaSettingsLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delegação Interna'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings),
              onPressed: () {
                Navigator.of(context).pushNamed('/sla-settings');
              },
              tooltip: 'Configurar SLAs',
            ),
          ],
        ),
        body: BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
          builder: (context, slaState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do caso
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.briefcase, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Caso: ${widget.caseId}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Delegando caso para advogado interno do escritório',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Configurações de prioridade e SLA
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Configurações de Prazo',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Seletor de prioridade
                            Text(
                              'Prioridade',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Selecione a prioridade',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'normal',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.circle, size: 16, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Normal'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'urgent',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.alertTriangle, size: 16, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Urgente'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'emergency',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.alertCircle, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Emergência'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value!;
                                  _calculateDeadline();
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Visualização de SLA baseado nas configurações
                            _buildSlaPreview(slaState),
                            const SizedBox(height: 16),

                            // Override de SLA (se habilitado)
                            if (slaState is SlaSettingsLoaded && 
                                slaState.settings.enableSlaOverride)
                              _buildSlaOverrideSection(slaState.settings),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Formulário de delegação
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.user, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Detalhes da Delegação',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Seleção do advogado
                            Text(
                              'Advogado Responsável',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedLawyerId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Selecione o advogado',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecione um advogado';
                                }
                                return null;
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'lawyer1',
                                  child: Text('Dr. João Silva'),
                                ),
                                DropdownMenuItem(
                                  value: 'lawyer2',
                                  child: Text('Dra. Maria Santos'),
                                ),
                                DropdownMenuItem(
                                  value: 'lawyer3',
                                  child: Text('Dr. Pedro Costa'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedLawyerId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Descrição
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descrição da Delegação',
                                border: OutlineInputBorder(),
                                hintText: 'Descreva o que deve ser feito...',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'A descrição é obrigatória';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Observações
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Observações (opcional)',
                                border: OutlineInputBorder(),
                                hintText: 'Informações adicionais...',
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitDelegation,
                            child: const Text('Delegar Caso'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlaPreview(SlaSettingsState slaState) {
    if (slaState is SlaSettingsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (slaState is SlaSettingsLoaded) {
      final settings = slaState.settings;
      int slaHours;
      
      switch (_selectedPriority) {
        case 'urgent':
          slaHours = settings.urgentInternalDelegationHours;
          break;
        case 'emergency':
          slaHours = settings.emergencyInternalDelegationHours;
          break;
        default:
          slaHours = settings.defaultInternalDelegationHours;
      }

      final deadline = DateTime.now().add(Duration(hours: slaHours));
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'SLA Calculado: $slaHours horas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Deadline: ${_formatDateTime(deadline)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (slaState is SlaSettingsError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erro ao carregar configurações SLA',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSlaOverrideSection(SlaSettingsEntity settings) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Usar SLA Customizado'),
          subtitle: Text(
            'Máximo: ${settings.maxSlaOverrideHours} horas',
          ),
          value: _useSlaOverride,
          onChanged: (value) {
            setState(() {
              _useSlaOverride = value;
              if (!value) {
                _slaOverrideHours = null;
                _customDeadline = null;
              }
            });
          },
        ),
        if (_useSlaOverride) ...[
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'SLA Customizado (horas)',
              border: OutlineInputBorder(),
              hintText: 'Ex: 12',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_useSlaOverride) {
                if (value == null || value.isEmpty) {
                  return 'Informe o SLA customizado';
                }
                final hours = int.tryParse(value);
                if (hours == null || hours <= 0) {
                  return 'Informe um valor válido';
                }
                if (hours > settings.maxSlaOverrideHours) {
                  return 'Máximo: ${settings.maxSlaOverrideHours} horas';
                }
              }
              return null;
            },
            onChanged: (value) {
              final hours = int.tryParse(value);
              if (hours != null) {
                setState(() {
                  _slaOverrideHours = hours;
                  _customDeadline = DateTime.now().add(Duration(hours: hours));
                });
              }
            },
          ),
          if (_customDeadline != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Novo deadline: ${_formatDateTime(_customDeadline!)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} às '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _calculateDeadline() {
    // Trigger recálculo do SLA quando a prioridade muda
    if (mounted) {
      setState(() {});
    }
  }

  void _submitDelegation() {
    if (_formKey.currentState!.validate()) {
      final delegationData = {
        'case_id': widget.caseId,
        'lawyer_id': _selectedLawyerId!,
        'priority_level': _selectedPriority,
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        if (_useSlaOverride && _slaOverrideHours != null)
          'sla_override_hours': _slaOverrideHours,
        'allocation_type': 'internal_delegation',
      };

      widget.onDelegationSubmitted(delegationData);
      Navigator.of(context).pop();
    }
  }
} 