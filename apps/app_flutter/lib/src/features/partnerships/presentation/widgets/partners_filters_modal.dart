import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../lawyers/presentation/bloc/hybrid_match_bloc.dart';

/// Modal para filtros de busca de parceiros
/// 
/// Permite ao advogado contratante filtrar entre:
/// - Advogados individuais para correspondência
/// - Escritórios para parcerias estratégicas
/// - Ambos para busca ampla
class PartnersFiltersModal extends StatefulWidget {
  const PartnersFiltersModal({super.key});

  @override
  State<PartnersFiltersModal> createState() => _PartnersFiltersModalState();
}

class _PartnersFiltersModalState extends State<PartnersFiltersModal> {
  PartnerType _selectedType = PartnerType.todos;
  String _selectedPreset = 'correspondent';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Filtros de Parceiros',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tipo de Parceiro
          Text(
            'Tipo de Parceiro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPartnerTypeSelector(),
          const SizedBox(height: 24),

          // Estilo de Parceria
          Text(
            'Estilo de Parceria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPartnershipStyleSelector(),
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
    );
  }

  Widget _buildPartnerTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: PartnerType.values.map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
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

  Widget _buildPartnershipStyleSelector() {
    final styles = [
      {'key': 'correspondent', 'label': 'Correspondente', 'icon': LucideIcons.mapPin, 'description': 'Para representação em outras localidades'},
      {'key': 'expert_opinion', 'label': 'Opinião Especializada', 'icon': LucideIcons.award, 'description': 'Para consultoria técnica específica'},
      {'key': 'b2b', 'label': 'Parceria Estratégica', 'icon': LucideIcons.userPlus, 'description': 'Para colaboração de longo prazo'},
      {'key': 'balanced', 'label': 'Geral', 'icon': LucideIcons.users, 'description': 'Para qualquer tipo de parceria'},
    ];

    return Column(
      children: styles.map((style) {
        final isSelected = _selectedPreset == style['key'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPreset = style['key'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  style['icon'] as IconData,
                  size: 24,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style['description'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    LucideIcons.check,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedType = PartnerType.todos;
      _selectedPreset = 'correspondent';
    });
  }

  void _applyFilters() {
    // Disparar evento no BLoC com os filtros selecionados
    context.read<HybridMatchBloc>().add(ApplyHybridFilters(
      caseId: 'partnership_search',
      includeFirms: _selectedType == PartnerType.escritorios || _selectedType == PartnerType.todos,
      includeLawyers: _selectedType == PartnerType.advogados || _selectedType == PartnerType.todos,
      preset: _selectedPreset,
    ));

    Navigator.pop(context);
  }
}

/// Enum para tipos de parceiro
enum PartnerType {
  advogados,
  escritorios,
  todos;

  String get label {
    switch (this) {
      case PartnerType.advogados:
        return 'Advogados';
      case PartnerType.escritorios:
        return 'Escritórios';
      case PartnerType.todos:
        return 'Todos';
    }
  }

  IconData get icon {
    switch (this) {
      case PartnerType.advogados:
        return LucideIcons.user;
      case PartnerType.escritorios:
        return LucideIcons.building;
      case PartnerType.todos:
        return LucideIcons.users;
    }
  }
} 