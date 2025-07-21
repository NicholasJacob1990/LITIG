import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/shared/widgets/legal_areas_selector.dart';

/// Modal para filtros híbridos (advogados + escritórios)
/// 
/// Permite ao usuário escolher entre:
/// - Individuais (apenas advogados)
/// - Escritórios (apenas escritórios)
/// - Todos (advogados + escritórios)
class HybridFiltersModal extends StatefulWidget {
  const HybridFiltersModal({super.key});

  @override
  State<HybridFiltersModal> createState() => _HybridFiltersModalState();
}

class _HybridFiltersModalState extends State<HybridFiltersModal> {
  EntityFilter _selectedFilter = EntityFilter.todos;
  String _selectedPreset = 'balanced';
  bool _mixedRendering = false;
  List<String> _selectedAreas = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtros de Busca',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filtro de Tipo de Entidade
            Text(
              'Tipo de Profissional',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildEntityFilterSegmentedControl(),
            const SizedBox(height: 24),

            // Preset de Busca
            Text(
              'Estilo de Recomendação',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPresetSelector(),
            const SizedBox(height: 24),

            // Filtro de Áreas Jurídicas
            Text(
              'Áreas de Especialização',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LegalAreasSelector(
              initialValues: _selectedAreas,
              onChanged: (areas) {
                setState(() {
                  _selectedAreas = areas;
                });
              },
            ),
            const SizedBox(height: 24),

            // Opção de Renderização Mista
            _buildRenderingOption(),
            const SizedBox(height: 32),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resetFilters(),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyFilters(),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
            
            // Espaçamento para safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityFilterSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: EntityFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPresetSelector() {
    final presets = [
      {'key': 'balanced', 'label': 'Recomendado', 'icon': LucideIcons.star},
      {'key': 'economic', 'label': 'Melhor Custo', 'icon': LucideIcons.dollarSign},
      {'key': 'expert', 'label': 'Mais Experiente', 'icon': LucideIcons.award},
      {'key': 'fast', 'label': 'Mais Rápido', 'icon': LucideIcons.zap},
    ];

    return Column(
      children: presets.map((preset) {
        final isSelected = _selectedPreset == preset['key'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPreset = preset['key'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  preset['icon'] as IconData,
                  size: 20,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  preset['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    LucideIcons.check,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRenderingOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visualização',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Resultados Mistos'),
          subtitle: const Text('Exibir advogados e escritórios em uma única lista'),
          value: _mixedRendering,
          onChanged: (value) {
            setState(() {
              _mixedRendering = value;
            });
          },
          secondary: Icon(
            _mixedRendering ? LucideIcons.shuffle : LucideIcons.list,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = EntityFilter.todos;
      _selectedPreset = 'balanced';
      _mixedRendering = false;
      _selectedAreas = [];
    });
  }

  void _applyFilters() {
    // Disparar evento no BLoC com os filtros selecionados
    context.read<HybridMatchBloc>().add(ApplyHybridFilters(
      caseId: 'mock_case_id', // TODO: Usar caso real
      includeFirms: _selectedFilter == EntityFilter.escritorios || _selectedFilter == EntityFilter.todos,
      includeLawyers: _selectedFilter == EntityFilter.individuais || _selectedFilter == EntityFilter.todos,
      preset: _selectedPreset,
      mixedRendering: _mixedRendering,
    ));

    Navigator.pop(context);
  }
}

/// Enum para tipos de filtro de entidade
enum EntityFilter {
  individuais,
  escritorios,
  todos;

  String get label {
    switch (this) {
      case EntityFilter.individuais:
        return 'Individuais';
      case EntityFilter.escritorios:
        return 'Escritórios';
      case EntityFilter.todos:
        return 'Todos';
    }
  }

  IconData get icon {
    switch (this) {
      case EntityFilter.individuais:
        return LucideIcons.user;
      case EntityFilter.escritorios:
        return LucideIcons.building;
      case EntityFilter.todos:
        return LucideIcons.users;
    }
  }
} 