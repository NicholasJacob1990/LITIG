import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/shared/widgets/legal_areas_selector.dart';
import '../bloc/hybrid_match_bloc.dart';
import 'hybrid_filters_modal.dart'; // Para EntityFilter enum

/// Filtros inline para a aba "Buscar" 
/// 
/// Substitui o modal global por uma interface accordion
/// que mantém o usuário no contexto da busca.
class InlineSearchFilters extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const InlineSearchFilters({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<InlineSearchFilters> createState() => _InlineSearchFiltersState();
}

class _InlineSearchFiltersState extends State<InlineSearchFilters>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  EntityFilter _selectedFilter = EntityFilter.todos;
  String _selectedPreset = 'balanced';
  List<String> _selectedAreas = [];
  double _maxDistance = 50.0;
  RangeValues _priceRange = const RangeValues(100, 1000);
  double _minRating = 0.0;
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(InlineSearchFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header do Accordion
          InkWell(
            onTap: widget.onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.slidersHorizontal,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filtros Avançados',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: widget.isExpanded ? 0.5 : 0,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo Expansível
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Tipo de Profissional
                  _buildSectionTitle('Tipo de Profissional'),
                  const SizedBox(height: 8),
                  _buildEntityFilterSegmentedControl(),
                  const SizedBox(height: 16),

                  // Estilo de Recomendação
                  _buildSectionTitle('Estilo de Busca'),
                  const SizedBox(height: 8),
                  _buildPresetSelector(),
                  const SizedBox(height: 16),

                  // Áreas Jurídicas
                  _buildSectionTitle('Áreas de Especialização'),
                  const SizedBox(height: 8),
                  LegalAreasSelector(
                    initialValues: _selectedAreas,
                    onChanged: (areas) {
                      setState(() {
                        _selectedAreas = areas;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtros de Qualidade e Distância
                  Row(
                    children: [
                      Expanded(child: _buildRatingFilter()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDistanceFilter()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Preço
                  _buildPriceRangeFilter(),
                  const SizedBox(height: 16),

                  // Apenas Disponíveis
                  _buildAvailabilityFilter(),
                  const SizedBox(height: 20),

                  // Botões de Ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(
                            LucideIcons.rotateCcw,
                            size: 16,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            'Limpar',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: const Text('Aplicar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
    );
  }

  Widget _buildEntityFilterSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: EntityFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
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
      {'key': 'balanced', 'label': 'Equilibrado', 'icon': LucideIcons.star},
      {'key': 'economic', 'label': 'Custo-Benefício', 'icon': LucideIcons.dollarSign},
      {'key': 'expert', 'label': 'Experiente', 'icon': LucideIcons.award},
      {'key': 'fast', 'label': 'Resposta Rápida', 'icon': LucideIcons.zap},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSelected = _selectedPreset == preset['key'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPreset = preset['key'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  preset['icon'] as IconData,
                  size: 16,
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  preset['label'] as String,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avaliação Mínima',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Slider(
          value: _minRating,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          activeColor: AppColors.warning,
          inactiveColor: AppColors.warning.withValues(alpha: 0.3),
          label: _minRating.toStringAsFixed(1),
          onChanged: (value) => setState(() => _minRating = value),
        ),
        Text(
          '${_minRating.toStringAsFixed(1)} ⭐',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distância Máxima',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Slider(
          value: _maxDistance,
          min: 5.0,
          max: 100.0,
          divisions: 19,
          activeColor: AppColors.info,
          inactiveColor: AppColors.info.withValues(alpha: 0.3),
          label: '${_maxDistance.toInt()} km',
          onChanged: (value) => setState(() => _maxDistance = value),
        ),
        Text(
          '${_maxDistance.toInt()} km',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.info,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faixa de Preço (R\$ por hora)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RangeSlider(
          values: _priceRange,
          min: 50.0,
          max: 2000.0,
          divisions: 39,
          activeColor: AppColors.success,
          inactiveColor: AppColors.success.withValues(alpha: 0.3),
          labels: RangeLabels(
            'R\$ ${_priceRange.start.toInt()}',
            'R\$ ${_priceRange.end.toInt()}',
          ),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        Text(
          'R\$ ${_priceRange.start.toInt()} - R\$ ${_priceRange.end.toInt()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return CheckboxListTile(
      title: Text(
        'Apenas Disponíveis',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text('Mostrar apenas advogados com agenda livre'),
      value: _onlyAvailable,
      activeColor: AppColors.success,
      onChanged: (value) => setState(() => _onlyAvailable = value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = EntityFilter.todos;
      _selectedPreset = 'balanced';
      _selectedAreas = [];
      _maxDistance = 50.0;
      _priceRange = const RangeValues(100, 1000);
      _minRating = 0.0;
      _onlyAvailable = false;
    });
  }

  void _applyFilters() {
    // Aplicar filtros através do BLoC
    context.read<HybridMatchBloc>().add(ApplyHybridFilters(
      caseId: 'search_filters', // ID especial para filtros de busca
      includeFirms: _selectedFilter == EntityFilter.escritorios || 
                   _selectedFilter == EntityFilter.todos,
      includeLawyers: _selectedFilter == EntityFilter.individuais || 
                     _selectedFilter == EntityFilter.todos,
      preset: _selectedPreset,
      mixedRendering: false, // Sempre false para busca inline
    ));

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtros aplicados com sucesso!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }
} 