import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_preset_entity.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaPresetsWidget extends StatefulWidget {
  final List<SlaPresetEntity>? presets;
  final Function(SlaPresetEntity)? onPresetSelected;
  final Function(SlaPresetEntity)? onPresetCreated;

  const SlaPresetsWidget({
    super.key,
    this.presets,
    this.onPresetSelected,
    this.onPresetCreated,
  });

  @override
  State<SlaPresetsWidget> createState() => _SlaPresetsWidgetState();
}

class _SlaPresetsWidgetState extends State<SlaPresetsWidget> {
  String? _selectedPresetId;
  bool _showCustomForm = false;
  
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
              _buildSystemPresets(),
              const SizedBox(height: 24),
              _buildCustomPresets(),
              const SizedBox(height: 24),
              _buildPresetActions(),
              if (_showCustomForm) ...[
                const SizedBox(height: 24),
                _buildCustomPresetForm(),
              ],
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
            Icon(Icons.bookmark, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Presets SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Utilize templates pré-configurados ou crie presets personalizados para diferentes tipos de firma.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSystemPresets() {
    final systemPresets = _getSystemPresets();
    
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
                  'Presets do Sistema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...systemPresets.map((preset) => _buildPresetCard(preset, true)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomPresets() {
    final customPresets = widget.presets?.where((p) => !p.isSystemPreset).toList() ?? [];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.create, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Presets Personalizados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customPresets.isEmpty)
              _buildEmptyCustomPresets()
            else
              ...customPresets.map((preset) => _buildPresetCard(preset, false)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPresetCard(SlaPresetEntity preset, bool isSystem) {
    final isSelected = _selectedPresetId == preset.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectPreset(preset),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getPresetIcon(preset.name),
                              color: _getPresetColor(preset.name),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              preset.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Theme.of(context).primaryColor : null,
                              ),
                            ),
                            if (isSystem) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SISTEMA',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                  if (!isSystem) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (action) => _handlePresetAction(action, preset),
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
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 16),
                              SizedBox(width: 8),
                              Text('Exportar'),
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
                ],
              ),
              const SizedBox(height: 12),
              _buildPresetTimings(preset),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPresetTimings(SlaPresetEntity preset) {
    return Row(
      children: [
        Expanded(
          child: _buildTimingChip(
            'Normal',
            '${preset.normalHours}h',
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTimingChip(
            'Urgente',
            '${preset.urgentHours}h',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTimingChip(
            'Emergência',
            '${preset.emergencyHours}h',
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTimingChip(
            'Complexo',
            '${preset.complexHours}h',
            Colors.purple,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimingChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyCustomPresets() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_add,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum preset personalizado',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie presets personalizados para diferentes tipos de firma ou casos específicos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPresetActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _importPreset(),
            icon: const Icon(Icons.upload),
            label: const Text('Importar Preset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showCustomForm = !_showCustomForm),
            icon: Icon(_showCustomForm ? Icons.close : Icons.add),
            label: Text(_showCustomForm ? 'Cancelar' : 'Criar Preset'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCustomPresetForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criar Preset Personalizado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome do Preset',
                hintText: 'Ex: Firma Grande, Boutique, Criminal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva quando usar este preset',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Tempos de Resposta (horas)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Normal',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Urgente',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Emergência',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Complexo',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showCustomForm = false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createCustomPreset(),
                    child: const Text('Criar Preset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  List<SlaPresetEntity> _getSystemPresets() {
    return [
      SlaPresetEntity.conservative(),
      SlaPresetEntity.balanced(),
      SlaPresetEntity.aggressive(),
      SlaPresetEntity.largeFirm(),
      SlaPresetEntity.boutiqueFirm(),
    ];
  }
  
  IconData _getPresetIcon(String name) {
    switch (name.toLowerCase()) {
      case 'conservative':
      case 'conservador':
        return Icons.shield;
      case 'balanced':
      case 'equilibrado':
        return Icons.balance;
      case 'aggressive':
      case 'agressivo':
        return Icons.flash_on;
      case 'large firm':
      case 'firma grande':
        return Icons.business;
      case 'boutique firm':
      case 'boutique':
        return Icons.diamond;
      default:
        return Icons.bookmark;
    }
  }
  
  Color _getPresetColor(String name) {
    switch (name.toLowerCase()) {
      case 'conservative':
      case 'conservador':
        return Colors.green;
      case 'balanced':
      case 'equilibrado':
        return Colors.blue;
      case 'aggressive':
      case 'agressivo':
        return Colors.red;
      case 'large firm':
      case 'firma grande':
        return Colors.purple;
      case 'boutique firm':
      case 'boutique':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  void _selectPreset(SlaPresetEntity preset) {
    setState(() => _selectedPresetId = preset.id);
    if (widget.onPresetSelected != null) {
      widget.onPresetSelected!(preset);
    }
    
    // Apply preset via BLoC
    context.read<SlaSettingsBloc>().add(
      ApplySlaPresetEvent(preset),
    );
  }
  
  void _handlePresetAction(String action, SlaPresetEntity preset) {
    switch (action) {
      case 'edit':
        _editPreset(preset);
        break;
      case 'duplicate':
        _duplicatePreset(preset);
        break;
      case 'export':
        _exportPreset(preset);
        break;
      case 'delete':
        _deletePreset(preset);
        break;
    }
  }
  
  void _editPreset(SlaPresetEntity preset) {
    // TODO: Implementar edição de preset
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
    );
  }
  
  void _duplicatePreset(SlaPresetEntity preset) {
    final duplicated = preset.copyWith(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      name: '${preset.name} (Cópia)',
      isSystemPreset: false,
    );
    
    context.read<SlaSettingsBloc>().add(
      CreateCustomSlaPresetEvent(duplicated),
    );
  }
  
  void _exportPreset(SlaPresetEntity preset) {
    context.read<SlaSettingsBloc>().add(
      ExportSlaPresetEvent(preset),
    );
  }
  
  void _deletePreset(SlaPresetEntity preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Preset'),
        content: Text('Tem certeza que deseja excluir o preset "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SlaSettingsBloc>().add(
                DeleteSlaPresetEvent(preset.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
  
  void _importPreset() {
    // TODO: Implementar importação de preset
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de importação em desenvolvimento')),
    );
  }
  
  void _createCustomPreset() {
    // TODO: Implementar criação de preset customizado
    setState(() => _showCustomForm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preset personalizado criado com sucesso')),
    );
  }
}