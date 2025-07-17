import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/value_objects/business_hours.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaBusinessRulesWidget extends StatefulWidget {
  const SlaBusinessRulesWidget({Key? key}) : super(key: key);

  @override
  State<SlaBusinessRulesWidget> createState() => _SlaBusinessRulesWidgetState();
}

class _SlaBusinessRulesWidgetState extends State<SlaBusinessRulesWidget> {
  // Business Hours
  BusinessHours _businessHours = BusinessHours.standard();
  Map<int, bool> _workingDays = {
    1: true,  // Monday
    2: true,  // Tuesday
    3: true,  // Wednesday
    4: true,  // Thursday
    5: true,  // Friday
    6: false, // Saturday
    7: false, // Sunday
  };
  
  // Timezone
  String _selectedTimezone = 'America/Sao_Paulo';
  bool _enableDaylightSaving = true;
  
  // Holiday Settings
  bool _enableNationalHolidays = true;
  bool _enableRegionalHolidays = true;
  bool _enableCustomHolidays = true;
  String _selectedRegion = 'BR-SP'; // São Paulo
  
  // Weekend Policy
  bool _includeWeekends = false;
  bool _halfDayFriday = false;
  
  // Advanced Rules
  bool _enableOvertime = false;
  bool _enableFlexibleHours = false;
  int _bufferMinutes = 30;

  final List<Map<String, dynamic>> _customHolidays = [];

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
              _buildBusinessHoursSection(),
              const SizedBox(height: 24),
              _buildWorkingDaysSection(),
              const SizedBox(height: 24),
              _buildTimezoneSection(),
              const SizedBox(height: 24),
              _buildHolidaysSection(),
              const SizedBox(height: 24),
              _buildWeekendPolicySection(),
              const SizedBox(height: 24),
              _buildAdvancedRulesSection(),
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
            Icon(Icons.business, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Regras de Negócio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure horários comerciais, feriados e políticas específicas para cálculo preciso dos SLAs.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
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
                  'Horários Comerciais',
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
                  child: _buildBusinessHoursPreset(
                    'Padrão',
                    '09:00 - 18:00',
                    BusinessHours.standard(),
                    _businessHours.type == BusinessHours.standard().type,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBusinessHoursPreset(
                    'Estendido',
                    '08:00 - 20:00',
                    BusinessHours.extended(),
                    _businessHours.type == BusinessHours.extended().type,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBusinessHoursPreset(
                    '24/7',
                    'Sempre',
                    BusinessHours.fullTime(),
                    _businessHours.type == BusinessHours.fullTime().type,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_businessHours.type != 'full_time') ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      'Início',
                      _businessHours.startTime,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(startTime: time)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      'Fim',
                      _businessHours.endTime,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(endTime: time)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      'Início Almoço',
                      _businessHours.lunchStart,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(lunchStart: time)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      'Fim Almoço',
                      _businessHours.lunchEnd,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(lunchEnd: time)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursPreset(String title, String description, BusinessHours preset, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _businessHours = preset),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildTimeField(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(time.format(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingDaysSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dias Úteis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Selecione os dias da semana considerados úteis para cálculo de SLA:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildDayChip('Seg', 1),
                _buildDayChip('Ter', 2),
                _buildDayChip('Qua', 3),
                _buildDayChip('Qui', 4),
                _buildDayChip('Sex', 5),
                _buildDayChip('Sáb', 6),
                _buildDayChip('Dom', 7),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int dayOfWeek) {
    final isSelected = _workingDays[dayOfWeek] ?? false;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _workingDays[dayOfWeek] = selected);
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildTimezoneSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Fuso Horário',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTimezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'America/Sao_Paulo',
                  child: Text('São Paulo (GMT-3)'),
                ),
                DropdownMenuItem(
                  value: 'America/Manaus',
                  child: Text('Manaus (GMT-4)'),
                ),
                DropdownMenuItem(
                  value: 'America/Rio_Branco',
                  child: Text('Rio Branco (GMT-5)'),
                ),
                DropdownMenuItem(
                  value: 'America/Noronha',
                  child: Text('Fernando de Noronha (GMT-2)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTimezone = value);
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Horário de Verão'),
              subtitle: const Text('Ajustar automaticamente para horário de verão'),
              value: _enableDaylightSaving,
              onChanged: (value) => setState(() => _enableDaylightSaving = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Feriados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Feriados Nacionais'),
              subtitle: const Text('Incluir feriados nacionais brasileiros'),
              value: _enableNationalHolidays,
              onChanged: (value) => setState(() => _enableNationalHolidays = value),
            ),
            SwitchListTile(
              title: const Text('Feriados Regionais'),
              subtitle: const Text('Incluir feriados estaduais/municipais'),
              value: _enableRegionalHolidays,
              onChanged: (value) => setState(() => _enableRegionalHolidays = value),
            ),
            if (_enableRegionalHolidays) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: const InputDecoration(
                  labelText: 'Região',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'BR-SP', child: Text('São Paulo')),
                  DropdownMenuItem(value: 'BR-RJ', child: Text('Rio de Janeiro')),
                  DropdownMenuItem(value: 'BR-MG', child: Text('Minas Gerais')),
                  DropdownMenuItem(value: 'BR-RS', child: Text('Rio Grande do Sul')),
                  DropdownMenuItem(value: 'BR-SC', child: Text('Santa Catarina')),
                  DropdownMenuItem(value: 'BR-PR', child: Text('Paraná')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRegion = value);
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Feriados Personalizados'),
              subtitle: const Text('Adicionar feriados específicos da empresa'),
              value: _enableCustomHolidays,
              onChanged: (value) => setState(() => _enableCustomHolidays = value),
            ),
            if (_enableCustomHolidays) ...[
              const SizedBox(height: 16),
              _buildCustomHolidaysSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHolidaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Feriados Personalizados',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addCustomHoliday,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_customHolidays.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              'Nenhum feriado personalizado adicionado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ..._customHolidays.map((holiday) => _buildCustomHolidayItem(holiday)),
      ],
    );
  }

  Widget _buildCustomHolidayItem(Map<String, dynamic> holiday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday['name'] ?? 'Feriado',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  holiday['date'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeCustomHoliday(holiday),
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendPolicySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.weekend, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Política de Finais de Semana',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Incluir Finais de Semana'),
              subtitle: const Text('Contar sábados e domingos nos prazos SLA'),
              value: _includeWeekends,
              onChanged: (value) => setState(() => _includeWeekends = value),
            ),
            SwitchListTile(
              title: const Text('Meio Período Sexta'),
              subtitle: const Text('Sexta-feira até meio-dia apenas'),
              value: _halfDayFriday,
              onChanged: (value) => setState(() => _halfDayFriday = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedRulesSection() {
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
                  'Regras Avançadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Permitir Horas Extras'),
              subtitle: const Text('Contar trabalho após horário comercial'),
              value: _enableOvertime,
              onChanged: (value) => setState(() => _enableOvertime = value),
            ),
            SwitchListTile(
              title: const Text('Horários Flexíveis'),
              subtitle: const Text('Permitir variação nos horários de trabalho'),
              value: _enableFlexibleHours,
              onChanged: (value) => setState(() => _enableFlexibleHours = value),
            ),
            const SizedBox(height: 16),
            Text(
              'Buffer de Tempo (minutos)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _bufferMinutes.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: 24,
                    label: '$_bufferMinutes min',
                    onChanged: (value) => setState(() => _bufferMinutes = value.round()),
                  ),
                ),
                Text('$_bufferMinutes min'),
              ],
            ),
            Text(
              'Buffer aplicado automaticamente nos cálculos de deadline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
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
            onPressed: () => _previewCalculation(),
            icon: const Icon(Icons.calculate),
            label: const Text('Testar Cálculo'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportSettings(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveBusinessRules(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  void _addCustomHoliday() {
    showDialog(
      context: context,
      builder: (context) => _CustomHolidayDialog(
        onAdd: (holiday) {
          setState(() => _customHolidays.add(holiday));
        },
      ),
    );
  }

  void _removeCustomHoliday(Map<String, dynamic> holiday) {
    setState(() => _customHolidays.remove(holiday));
  }

  void _previewCalculation() {
    // TODO: Implement calculation preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de teste de cálculo em desenvolvimento')),
    );
  }

  void _exportSettings() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações exportadas com sucesso')),
    );
  }

  void _saveBusinessRules() {
    final businessRules = {
      'businessHours': {
        'type': _businessHours.type,
        'startTime': '${_businessHours.startTime.hour}:${_businessHours.startTime.minute}',
        'endTime': '${_businessHours.endTime.hour}:${_businessHours.endTime.minute}',
        'lunchStart': '${_businessHours.lunchStart.hour}:${_businessHours.lunchStart.minute}',
        'lunchEnd': '${_businessHours.lunchEnd.hour}:${_businessHours.lunchEnd.minute}',
      },
      'workingDays': _workingDays,
      'timezone': _selectedTimezone,
      'daylightSaving': _enableDaylightSaving,
      'holidays': {
        'national': _enableNationalHolidays,
        'regional': _enableRegionalHolidays,
        'custom': _enableCustomHolidays,
        'region': _selectedRegion,
        'customList': _customHolidays,
      },
      'weekendPolicy': {
        'includeWeekends': _includeWeekends,
        'halfDayFriday': _halfDayFriday,
      },
      'advanced': {
        'overtime': _enableOvertime,
        'flexibleHours': _enableFlexibleHours,
        'bufferMinutes': _bufferMinutes,
      },
    };

    context.read<SlaSettingsBloc>().add(
      UpdateSlaBusinessRulesEvent(businessRules: businessRules),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Regras de negócio salvas com sucesso')),
    );
  }
}

class _CustomHolidayDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _CustomHolidayDialog({required this.onAdd});

  @override
  State<_CustomHolidayDialog> createState() => _CustomHolidayDialogState();
}

class _CustomHolidayDialogState extends State<_CustomHolidayDialog> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Feriado Personalizado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Feriado',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Recorrente Anualmente'),
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value ?? false),
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
            if (_nameController.text.isNotEmpty) {
              widget.onAdd({
                'name': _nameController.text,
                'date': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                'isRecurring': _isRecurring,
                'timestamp': _selectedDate.millisecondsSinceEpoch,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/value_objects/business_hours.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaBusinessRulesWidget extends StatefulWidget {
  const SlaBusinessRulesWidget({Key? key}) : super(key: key);

  @override
  State<SlaBusinessRulesWidget> createState() => _SlaBusinessRulesWidgetState();
}

class _SlaBusinessRulesWidgetState extends State<SlaBusinessRulesWidget> {
  // Business Hours
  BusinessHours _businessHours = BusinessHours.standard();
  Map<int, bool> _workingDays = {
    1: true,  // Monday
    2: true,  // Tuesday
    3: true,  // Wednesday
    4: true,  // Thursday
    5: true,  // Friday
    6: false, // Saturday
    7: false, // Sunday
  };
  
  // Timezone
  String _selectedTimezone = 'America/Sao_Paulo';
  bool _enableDaylightSaving = true;
  
  // Holiday Settings
  bool _enableNationalHolidays = true;
  bool _enableRegionalHolidays = true;
  bool _enableCustomHolidays = true;
  String _selectedRegion = 'BR-SP'; // São Paulo
  
  // Weekend Policy
  bool _includeWeekends = false;
  bool _halfDayFriday = false;
  
  // Advanced Rules
  bool _enableOvertime = false;
  bool _enableFlexibleHours = false;
  int _bufferMinutes = 30;

  final List<Map<String, dynamic>> _customHolidays = [];

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
              _buildBusinessHoursSection(),
              const SizedBox(height: 24),
              _buildWorkingDaysSection(),
              const SizedBox(height: 24),
              _buildTimezoneSection(),
              const SizedBox(height: 24),
              _buildHolidaysSection(),
              const SizedBox(height: 24),
              _buildWeekendPolicySection(),
              const SizedBox(height: 24),
              _buildAdvancedRulesSection(),
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
            Icon(Icons.business, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Regras de Negócio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure horários comerciais, feriados e políticas específicas para cálculo preciso dos SLAs.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
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
                  'Horários Comerciais',
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
                  child: _buildBusinessHoursPreset(
                    'Padrão',
                    '09:00 - 18:00',
                    BusinessHours.standard(),
                    _businessHours.type == BusinessHours.standard().type,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBusinessHoursPreset(
                    'Estendido',
                    '08:00 - 20:00',
                    BusinessHours.extended(),
                    _businessHours.type == BusinessHours.extended().type,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBusinessHoursPreset(
                    '24/7',
                    'Sempre',
                    BusinessHours.fullTime(),
                    _businessHours.type == BusinessHours.fullTime().type,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_businessHours.type != 'full_time') ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      'Início',
                      _businessHours.startTime,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(startTime: time)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      'Fim',
                      _businessHours.endTime,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(endTime: time)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      'Início Almoço',
                      _businessHours.lunchStart,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(lunchStart: time)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      'Fim Almoço',
                      _businessHours.lunchEnd,
                      (time) => setState(() => _businessHours = _businessHours.copyWith(lunchEnd: time)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursPreset(String title, String description, BusinessHours preset, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _businessHours = preset),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildTimeField(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(time.format(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingDaysSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dias Úteis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Selecione os dias da semana considerados úteis para cálculo de SLA:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildDayChip('Seg', 1),
                _buildDayChip('Ter', 2),
                _buildDayChip('Qua', 3),
                _buildDayChip('Qui', 4),
                _buildDayChip('Sex', 5),
                _buildDayChip('Sáb', 6),
                _buildDayChip('Dom', 7),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int dayOfWeek) {
    final isSelected = _workingDays[dayOfWeek] ?? false;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _workingDays[dayOfWeek] = selected);
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildTimezoneSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Fuso Horário',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTimezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'America/Sao_Paulo',
                  child: Text('São Paulo (GMT-3)'),
                ),
                DropdownMenuItem(
                  value: 'America/Manaus',
                  child: Text('Manaus (GMT-4)'),
                ),
                DropdownMenuItem(
                  value: 'America/Rio_Branco',
                  child: Text('Rio Branco (GMT-5)'),
                ),
                DropdownMenuItem(
                  value: 'America/Noronha',
                  child: Text('Fernando de Noronha (GMT-2)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTimezone = value);
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Horário de Verão'),
              subtitle: const Text('Ajustar automaticamente para horário de verão'),
              value: _enableDaylightSaving,
              onChanged: (value) => setState(() => _enableDaylightSaving = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Feriados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Feriados Nacionais'),
              subtitle: const Text('Incluir feriados nacionais brasileiros'),
              value: _enableNationalHolidays,
              onChanged: (value) => setState(() => _enableNationalHolidays = value),
            ),
            SwitchListTile(
              title: const Text('Feriados Regionais'),
              subtitle: const Text('Incluir feriados estaduais/municipais'),
              value: _enableRegionalHolidays,
              onChanged: (value) => setState(() => _enableRegionalHolidays = value),
            ),
            if (_enableRegionalHolidays) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: const InputDecoration(
                  labelText: 'Região',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'BR-SP', child: Text('São Paulo')),
                  DropdownMenuItem(value: 'BR-RJ', child: Text('Rio de Janeiro')),
                  DropdownMenuItem(value: 'BR-MG', child: Text('Minas Gerais')),
                  DropdownMenuItem(value: 'BR-RS', child: Text('Rio Grande do Sul')),
                  DropdownMenuItem(value: 'BR-SC', child: Text('Santa Catarina')),
                  DropdownMenuItem(value: 'BR-PR', child: Text('Paraná')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRegion = value);
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Feriados Personalizados'),
              subtitle: const Text('Adicionar feriados específicos da empresa'),
              value: _enableCustomHolidays,
              onChanged: (value) => setState(() => _enableCustomHolidays = value),
            ),
            if (_enableCustomHolidays) ...[
              const SizedBox(height: 16),
              _buildCustomHolidaysSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHolidaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Feriados Personalizados',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addCustomHoliday,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_customHolidays.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              'Nenhum feriado personalizado adicionado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ..._customHolidays.map((holiday) => _buildCustomHolidayItem(holiday)),
      ],
    );
  }

  Widget _buildCustomHolidayItem(Map<String, dynamic> holiday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday['name'] ?? 'Feriado',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  holiday['date'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeCustomHoliday(holiday),
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendPolicySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.weekend, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Política de Finais de Semana',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Incluir Finais de Semana'),
              subtitle: const Text('Contar sábados e domingos nos prazos SLA'),
              value: _includeWeekends,
              onChanged: (value) => setState(() => _includeWeekends = value),
            ),
            SwitchListTile(
              title: const Text('Meio Período Sexta'),
              subtitle: const Text('Sexta-feira até meio-dia apenas'),
              value: _halfDayFriday,
              onChanged: (value) => setState(() => _halfDayFriday = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedRulesSection() {
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
                  'Regras Avançadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Permitir Horas Extras'),
              subtitle: const Text('Contar trabalho após horário comercial'),
              value: _enableOvertime,
              onChanged: (value) => setState(() => _enableOvertime = value),
            ),
            SwitchListTile(
              title: const Text('Horários Flexíveis'),
              subtitle: const Text('Permitir variação nos horários de trabalho'),
              value: _enableFlexibleHours,
              onChanged: (value) => setState(() => _enableFlexibleHours = value),
            ),
            const SizedBox(height: 16),
            Text(
              'Buffer de Tempo (minutos)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _bufferMinutes.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: 24,
                    label: '$_bufferMinutes min',
                    onChanged: (value) => setState(() => _bufferMinutes = value.round()),
                  ),
                ),
                Text('$_bufferMinutes min'),
              ],
            ),
            Text(
              'Buffer aplicado automaticamente nos cálculos de deadline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
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
            onPressed: () => _previewCalculation(),
            icon: const Icon(Icons.calculate),
            label: const Text('Testar Cálculo'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportSettings(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveBusinessRules(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  void _addCustomHoliday() {
    showDialog(
      context: context,
      builder: (context) => _CustomHolidayDialog(
        onAdd: (holiday) {
          setState(() => _customHolidays.add(holiday));
        },
      ),
    );
  }

  void _removeCustomHoliday(Map<String, dynamic> holiday) {
    setState(() => _customHolidays.remove(holiday));
  }

  void _previewCalculation() {
    // TODO: Implement calculation preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de teste de cálculo em desenvolvimento')),
    );
  }

  void _exportSettings() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações exportadas com sucesso')),
    );
  }

  void _saveBusinessRules() {
    final businessRules = {
      'businessHours': {
        'type': _businessHours.type,
        'startTime': '${_businessHours.startTime.hour}:${_businessHours.startTime.minute}',
        'endTime': '${_businessHours.endTime.hour}:${_businessHours.endTime.minute}',
        'lunchStart': '${_businessHours.lunchStart.hour}:${_businessHours.lunchStart.minute}',
        'lunchEnd': '${_businessHours.lunchEnd.hour}:${_businessHours.lunchEnd.minute}',
      },
      'workingDays': _workingDays,
      'timezone': _selectedTimezone,
      'daylightSaving': _enableDaylightSaving,
      'holidays': {
        'national': _enableNationalHolidays,
        'regional': _enableRegionalHolidays,
        'custom': _enableCustomHolidays,
        'region': _selectedRegion,
        'customList': _customHolidays,
      },
      'weekendPolicy': {
        'includeWeekends': _includeWeekends,
        'halfDayFriday': _halfDayFriday,
      },
      'advanced': {
        'overtime': _enableOvertime,
        'flexibleHours': _enableFlexibleHours,
        'bufferMinutes': _bufferMinutes,
      },
    };

    context.read<SlaSettingsBloc>().add(
      UpdateSlaBusinessRulesEvent(businessRules: businessRules),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Regras de negócio salvas com sucesso')),
    );
  }
}

class _CustomHolidayDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _CustomHolidayDialog({required this.onAdd});

  @override
  State<_CustomHolidayDialog> createState() => _CustomHolidayDialogState();
}

class _CustomHolidayDialogState extends State<_CustomHolidayDialog> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Feriado Personalizado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Feriado',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Recorrente Anualmente'),
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value ?? false),
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
            if (_nameController.text.isNotEmpty) {
              widget.onAdd({
                'name': _nameController.text,
                'date': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                'isRecurring': _isRecurring,
                'timestamp': _selectedDate.millisecondsSinceEpoch,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
} 