import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/value_objects/sla_timeframe.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaBasicSettingsWidget extends StatefulWidget {
  final SlaSettingsEntity? settings;
  final Function(SlaSettingsEntity)? onSettingsChanged;

  const SlaBasicSettingsWidget({
    Key? key,
    this.settings,
    this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<SlaBasicSettingsWidget> createState() => _SlaBasicSettingsWidgetState();
}

class _SlaBasicSettingsWidgetState extends State<SlaBasicSettingsWidget> {
  late TextEditingController _normalHoursController;
  late TextEditingController _urgentHoursController;
  late TextEditingController _emergencyHoursController;
  late TextEditingController _complexHoursController;
  late TextEditingController _overrideLimitController;
  
  bool _enableBusinessHours = true;
  bool _enableWeekends = false;
  bool _enableOverrides = true;
  bool _enableAutoEscalation = true;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    final settings = widget.settings;
    _normalHoursController = TextEditingController(
      text: settings?.normalTimeframe?.hours.toString() ?? '48'
    );
    _urgentHoursController = TextEditingController(
      text: settings?.urgentTimeframe?.hours.toString() ?? '24'
    );
    _emergencyHoursController = TextEditingController(
      text: settings?.emergencyTimeframe?.hours.toString() ?? '6'
    );
    _complexHoursController = TextEditingController(
      text: settings?.complexTimeframe?.hours.toString() ?? '72'
    );
    _overrideLimitController = TextEditingController(
      text: settings?.overrideSettings['maxPerMonth']?.toString() ?? '5'
    );
    
    if (settings != null) {
      _enableBusinessHours = settings!.enableBusinessHoursOnly;
      _enableWeekends = settings!.includeWeekends;
      _enableOverrides = settings!.allowOverrides;
      _enableAutoEscalation = settings!.enableAutoEscalation;
    }
  }
  
  @override
  void dispose() {
    _normalHoursController.dispose();
    _urgentHoursController.dispose();
    _emergencyHoursController.dispose();
    _complexHoursController.dispose();
    _overrideLimitController.dispose();
    super.dispose();
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
              _buildTimeframesSection(),
              const SizedBox(height: 24),
              _buildBusinessRulesSection(),
              const SizedBox(height: 24),
              _buildOverrideSection(),
              const SizedBox(height: 24),
              _buildAdvancedSection(),
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
        Text(
          'Configurações Básicas SLA',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure os tempos padrão de resposta e regras básicas para cada tipo de prioridade.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeframesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Tempos de Resposta (horas)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeframeField(
                    'Normal',
                    _normalHoursController,
                    Icons.schedule,
                    Colors.green,
                    'Casos de prioridade normal',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeframeField(
                    'Urgente',
                    _urgentHoursController,
                    Icons.warning,
                    Colors.orange,
                    'Casos urgentes',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeframeField(
                    'Emergência',
                    _emergencyHoursController,
                    Icons.error,
                    Colors.red,
                    'Casos de emergência',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeframeField(
                    'Complexo',
                    _complexHoursController,
                    Icons.psychology,
                    Colors.purple,
                    'Casos complexos',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeframeField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Horas',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixText: 'h',
          ),
          onChanged: (value) => _validateAndUpdate(),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBusinessRulesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Regras de Negócio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Horário Comercial Apenas'),
              subtitle: const Text('Contar apenas horário comercial para prazos'),
              value: _enableBusinessHours,
              onChanged: (value) {
                setState(() => _enableBusinessHours = value);
                _validateAndUpdate();
              },
            ),
            SwitchListTile(
              title: const Text('Incluir Finais de Semana'),
              subtitle: const Text('Contar sábados e domingos nos prazos'),
              value: _enableWeekends,
              onChanged: (value) {
                setState(() => _enableWeekends = value);
                _validateAndUpdate();
              },
            ),
            SwitchListTile(
              title: const Text('Escalação Automática'),
              subtitle: const Text('Escalar automaticamente casos próximos ao vencimento'),
              value: _enableAutoEscalation,
              onChanged: (value) {
                setState(() => _enableAutoEscalation = value);
                _validateAndUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverrideSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Sistema de Override',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Permitir Overrides'),
              subtitle: const Text('Permitir alteração manual dos prazos SLA'),
              value: _enableOverrides,
              onChanged: (value) {
                setState(() => _enableOverrides = value);
                _validateAndUpdate();
              },
            ),
            if (_enableOverrides) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _overrideLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite de Overrides por Mês',
                  hintText: 'Número máximo permitido',
                  border: OutlineInputBorder(),
                  suffixText: '/mês',
                ),
                onChanged: (value) => _validateAndUpdate(),
              ),
              const SizedBox(height: 8),
              Text(
                'Limite recomendado: 3-5 overrides por mês por advogado',
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
  
  Widget _buildAdvancedSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações Avançadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Scoring Automático',
              'Sistema calcula score de 0-100 baseado em compliance',
              Icons.score,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Alertas Inteligentes',
              'Detecção automática de padrões e riscos',
              Icons.smart_button,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Auditoria Completa',
              'Trilha de auditoria com integridade verificável',
              Icons.security,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _resetToDefaults(),
            icon: const Icon(Icons.refresh),
            label: const Text('Restaurar Padrões'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _testConfiguration(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Testar Configuração'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveSettings(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }
  
  void _validateAndUpdate() {
    // Implementar validação e notificar mudanças
    final settings = _buildSettingsFromForm();
    if (widget.onSettingsChanged != null) {
      widget.onSettingsChanged!(settings);
    }
    
    // Trigger validation no BLoC
    context.read<SlaSettingsBloc>().add(
      ValidateSlaSettingsEvent(settings: settings),
    );
  }
  
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Configurações Padrão'),
        content: const Text(
          'Isso irá restaurar todas as configurações para os valores padrão. '
          'Suas alterações não salvas serão perdidas. Continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SlaSettingsBloc>().add(ResetSlaSettingsEvent());
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
  
  void _testConfiguration() {
    final settings = _buildSettingsFromForm();
    context.read<SlaSettingsBloc>().add(
      TestSlaSettingsEvent(settings: settings),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teste de Configuração'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Testando configurações SLA...'),
          ],
        ),
      ),
    );
  }
  
  void _saveSettings() {
    final settings = _buildSettingsFromForm();
    context.read<SlaSettingsBloc>().add(
      UpdateSlaSettingsEvent(settings: settings),
    );
  }
  
  SlaSettingsEntity _buildSettingsFromForm() {
    return SlaSettingsEntity(
      id: widget.settings?.id ?? '',
      firmId: widget.settings?.firmId ?? '',
      normalTimeframe: SlaTimeframe.normal().copyWith(
        hours: int.tryParse(_normalHoursController.text) ?? 48,
      ),
      urgentTimeframe: SlaTimeframe.urgent().copyWith(
        hours: int.tryParse(_urgentHoursController.text) ?? 24,
      ),
      emergencyTimeframe: SlaTimeframe.emergency().copyWith(
        hours: int.tryParse(_emergencyHoursController.text) ?? 6,
      ),
      complexTimeframe: SlaTimeframe.complex().copyWith(
        hours: int.tryParse(_complexHoursController.text) ?? 72,
      ),
      enableBusinessHoursOnly: _enableBusinessHours,
      includeWeekends: _enableWeekends,
      allowOverrides: _enableOverrides,
      enableAutoEscalation: _enableAutoEscalation,
      overrideSettings: {
        'maxPerMonth': int.tryParse(_overrideLimitController.text) ?? 5,
        'requireApproval': true,
        'auditTrail': true,
      },
      lastModified: DateTime.now(),
      lastModifiedBy: 'current_user', // TODO: Get from auth
    );
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/value_objects/sla_timeframe.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaBasicSettingsWidget extends StatefulWidget {
  final SlaSettingsEntity? settings;
  final Function(SlaSettingsEntity)? onSettingsChanged;

  const SlaBasicSettingsWidget({
    Key? key,
    this.settings,
    this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<SlaBasicSettingsWidget> createState() => _SlaBasicSettingsWidgetState();
}

class _SlaBasicSettingsWidgetState extends State<SlaBasicSettingsWidget> {
  late TextEditingController _normalHoursController;
  late TextEditingController _urgentHoursController;
  late TextEditingController _emergencyHoursController;
  late TextEditingController _complexHoursController;
  late TextEditingController _overrideLimitController;
  
  bool _enableBusinessHours = true;
  bool _enableWeekends = false;
  bool _enableOverrides = true;
  bool _enableAutoEscalation = true;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    final settings = widget.settings;
    _normalHoursController = TextEditingController(
      text: settings?.normalTimeframe?.hours.toString() ?? '48'
    );
    _urgentHoursController = TextEditingController(
      text: settings?.urgentTimeframe?.hours.toString() ?? '24'
    );
    _emergencyHoursController = TextEditingController(
      text: settings?.emergencyTimeframe?.hours.toString() ?? '6'
    );
    _complexHoursController = TextEditingController(
      text: settings?.complexTimeframe?.hours.toString() ?? '72'
    );
    _overrideLimitController = TextEditingController(
      text: settings?.overrideSettings['maxPerMonth']?.toString() ?? '5'
    );
    
    if (settings != null) {
      _enableBusinessHours = settings!.enableBusinessHoursOnly;
      _enableWeekends = settings!.includeWeekends;
      _enableOverrides = settings!.allowOverrides;
      _enableAutoEscalation = settings!.enableAutoEscalation;
    }
  }
  
  @override
  void dispose() {
    _normalHoursController.dispose();
    _urgentHoursController.dispose();
    _emergencyHoursController.dispose();
    _complexHoursController.dispose();
    _overrideLimitController.dispose();
    super.dispose();
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
              _buildTimeframesSection(),
              const SizedBox(height: 24),
              _buildBusinessRulesSection(),
              const SizedBox(height: 24),
              _buildOverrideSection(),
              const SizedBox(height: 24),
              _buildAdvancedSection(),
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
        Text(
          'Configurações Básicas SLA',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure os tempos padrão de resposta e regras básicas para cada tipo de prioridade.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeframesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Tempos de Resposta (horas)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeframeField(
                    'Normal',
                    _normalHoursController,
                    Icons.schedule,
                    Colors.green,
                    'Casos de prioridade normal',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeframeField(
                    'Urgente',
                    _urgentHoursController,
                    Icons.warning,
                    Colors.orange,
                    'Casos urgentes',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeframeField(
                    'Emergência',
                    _emergencyHoursController,
                    Icons.error,
                    Colors.red,
                    'Casos de emergência',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeframeField(
                    'Complexo',
                    _complexHoursController,
                    Icons.psychology,
                    Colors.purple,
                    'Casos complexos',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeframeField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Horas',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixText: 'h',
          ),
          onChanged: (value) => _validateAndUpdate(),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBusinessRulesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Regras de Negócio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Horário Comercial Apenas'),
              subtitle: const Text('Contar apenas horário comercial para prazos'),
              value: _enableBusinessHours,
              onChanged: (value) {
                setState(() => _enableBusinessHours = value);
                _validateAndUpdate();
              },
            ),
            SwitchListTile(
              title: const Text('Incluir Finais de Semana'),
              subtitle: const Text('Contar sábados e domingos nos prazos'),
              value: _enableWeekends,
              onChanged: (value) {
                setState(() => _enableWeekends = value);
                _validateAndUpdate();
              },
            ),
            SwitchListTile(
              title: const Text('Escalação Automática'),
              subtitle: const Text('Escalar automaticamente casos próximos ao vencimento'),
              value: _enableAutoEscalation,
              onChanged: (value) {
                setState(() => _enableAutoEscalation = value);
                _validateAndUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverrideSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Sistema de Override',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Permitir Overrides'),
              subtitle: const Text('Permitir alteração manual dos prazos SLA'),
              value: _enableOverrides,
              onChanged: (value) {
                setState(() => _enableOverrides = value);
                _validateAndUpdate();
              },
            ),
            if (_enableOverrides) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _overrideLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite de Overrides por Mês',
                  hintText: 'Número máximo permitido',
                  border: OutlineInputBorder(),
                  suffixText: '/mês',
                ),
                onChanged: (value) => _validateAndUpdate(),
              ),
              const SizedBox(height: 8),
              Text(
                'Limite recomendado: 3-5 overrides por mês por advogado',
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
  
  Widget _buildAdvancedSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações Avançadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Scoring Automático',
              'Sistema calcula score de 0-100 baseado em compliance',
              Icons.score,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Alertas Inteligentes',
              'Detecção automática de padrões e riscos',
              Icons.smart_button,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Auditoria Completa',
              'Trilha de auditoria com integridade verificável',
              Icons.security,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _resetToDefaults(),
            icon: const Icon(Icons.refresh),
            label: const Text('Restaurar Padrões'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _testConfiguration(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Testar Configuração'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveSettings(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }
  
  void _validateAndUpdate() {
    // Implementar validação e notificar mudanças
    final settings = _buildSettingsFromForm();
    if (widget.onSettingsChanged != null) {
      widget.onSettingsChanged!(settings);
    }
    
    // Trigger validation no BLoC
    context.read<SlaSettingsBloc>().add(
      ValidateSlaSettingsEvent(settings: settings),
    );
  }
  
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Configurações Padrão'),
        content: const Text(
          'Isso irá restaurar todas as configurações para os valores padrão. '
          'Suas alterações não salvas serão perdidas. Continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SlaSettingsBloc>().add(ResetSlaSettingsEvent());
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
  
  void _testConfiguration() {
    final settings = _buildSettingsFromForm();
    context.read<SlaSettingsBloc>().add(
      TestSlaSettingsEvent(settings: settings),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teste de Configuração'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Testando configurações SLA...'),
          ],
        ),
      ),
    );
  }
  
  void _saveSettings() {
    final settings = _buildSettingsFromForm();
    context.read<SlaSettingsBloc>().add(
      UpdateSlaSettingsEvent(settings: settings),
    );
  }
  
  SlaSettingsEntity _buildSettingsFromForm() {
    return SlaSettingsEntity(
      id: widget.settings?.id ?? '',
      firmId: widget.settings?.firmId ?? '',
      normalTimeframe: SlaTimeframe.normal().copyWith(
        hours: int.tryParse(_normalHoursController.text) ?? 48,
      ),
      urgentTimeframe: SlaTimeframe.urgent().copyWith(
        hours: int.tryParse(_urgentHoursController.text) ?? 24,
      ),
      emergencyTimeframe: SlaTimeframe.emergency().copyWith(
        hours: int.tryParse(_emergencyHoursController.text) ?? 6,
      ),
      complexTimeframe: SlaTimeframe.complex().copyWith(
        hours: int.tryParse(_complexHoursController.text) ?? 72,
      ),
      enableBusinessHoursOnly: _enableBusinessHours,
      includeWeekends: _enableWeekends,
      allowOverrides: _enableOverrides,
      enableAutoEscalation: _enableAutoEscalation,
      overrideSettings: {
        'maxPerMonth': int.tryParse(_overrideLimitController.text) ?? 5,
        'requireApproval': true,
        'auditTrail': true,
      },
      lastModified: DateTime.now(),
      lastModifiedBy: 'current_user', // TODO: Get from auth
    );
  }
} 