import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyers_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_match_list.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/preset_selector.dart';
import 'package:meu_app/src/features/recommendations/presentation/widgets/lawyer_match_card.dart';
import 'package:meu_app/src/features/firms/presentation/widgets/firm_card.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/injection_container.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LawyersScreen extends StatelessWidget {
  const LawyersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LawyersBloc()),
        BlocProvider(create: (context) => HybridMatchBloc(
          lawyersRepository: getIt(),
          firmsRepository: getIt(),
        )),
      ],
      child: const LawyersView(),
    );
  }
}

class LawyersView extends StatefulWidget {
  const LawyersView({super.key});

  @override
  State<LawyersView> createState() => _LawyersViewState();
}

class _LawyersViewState extends State<LawyersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advogados & Escritórios',
          style: TextStyle(
            fontFamily: 'Sans-serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            onPressed: () => _showFiltersModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recomendações'),
            Tab(text: 'Buscar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HybridRecommendationsTabView(),
          HybridSearchTabView(),
        ],
      ),
    );
  }

  void _showFiltersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Pass the HybridMatchBloc to the modal using BlocProvider.value
      builder: (_) => BlocProvider.value(
        value: context.read<HybridMatchBloc>(),
        child: const HybridFiltersModal(),
      ),
    );
  }
}

/// Tab de Recomendações Híbridas (Advogados + Escritórios)
class HybridRecommendationsTabView extends StatefulWidget {
  const HybridRecommendationsTabView({super.key});

  @override
  State<HybridRecommendationsTabView> createState() => _HybridRecommendationsTabViewState();
}

class _HybridRecommendationsTabViewState extends State<HybridRecommendationsTabView> {
  String _selectedPreset = 'balanced';
  
  final List<Map<String, dynamic>> _clientPresets = [
    {
      'value': 'balanced',
      'label': '⭐ Recomendado',
      'description': 'Equilibrio ideal entre qualidade e preço',
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'value': 'economic',
      'label': '💰 Melhor Custo',
      'description': 'Foco em economia e custo-benefício',
      'icon': Icons.attach_money,
      'color': Colors.green,
    },
    {
      'value': 'expert',
      'label': '🏆 Mais Experientes',
      'description': 'Especialistas renomados na área',
      'icon': Icons.emoji_events,
      'color': Colors.purple,
    },
    {
      'value': 'fast',
      'label': '⚡ Mais Rápidos',
      'description': 'Disponibilidade imediata',
      'icon': Icons.flash_on,
      'color': Colors.orange,
    },
    {
      'value': 'b2b',
      'label': '🏢 Escritórios',
      'description': 'Foco em grandes escritórios',
      'icon': Icons.business,
      'color': Colors.blue,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Buscar recomendações híbridas ao inicializar
    _fetchRecommendations();
  }
  
  void _fetchRecommendations() {
    context.read<HybridMatchBloc>().add(FetchHybridMatches(
      caseId: 'mock_case_id', // TODO: Usar caso real do contexto
      includeFirms: true,
      preset: _selectedPreset,
    ));
  }
  
  void _onPresetChanged(String preset) {
    setState(() {
      _selectedPreset = preset;
    });
    _fetchRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPresetSelector(),
        Expanded(
          child: BlocBuilder<HybridMatchBloc, HybridMatchState>(
      builder: (context, state) {
        if (state is HybridMatchLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is HybridMatchError) {
          return _buildErrorState(context, state.message);
        }
        
        if (state is HybridMatchLoaded) {
          return HybridMatchList(
            lawyers: state.lawyers,
            firms: state.firms,
            showSectionHeaders: true,
            emptyMessage: 'Nenhuma recomendação encontrada.\nTente ajustar os filtros.',
            onRefresh: () {
                    context.read<HybridMatchBloc>().add(RefreshHybridMatches(
                caseId: 'mock_case_id',
                includeFirms: true,
                      preset: _selectedPreset,
              ));
            },
          );
        }
        
        return _buildEmptyState(context);
      },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPresetSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Recomendação',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _clientPresets.length,
              itemBuilder: (context, index) {
                final preset = _clientPresets[index];
                final isSelected = preset['value'] == _selectedPreset;
                
                return Padding(
                  padding: EdgeInsets.only(right: index < _clientPresets.length - 1 ? 12 : 0),
                  child: GestureDetector(
                    onTap: () => _onPresetChanged(preset['value']),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? preset['color'].withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? preset['color']
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            preset['icon'],
                            color: isSelected 
                                ? preset['color']
                                : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset['label'],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? preset['color']
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _clientPresets.firstWhere((p) => p['value'] == _selectedPreset)['description'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar recomendações',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<HybridMatchBloc>().add(const FetchHybridMatches(
                caseId: 'mock_case_id',
                includeFirms: true,
                preset: 'balanced',
              ));
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando recomendações...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

/// Tab de Busca Híbrida
class HybridSearchTabView extends StatefulWidget {
  const HybridSearchTabView({super.key});

  @override
  State<HybridSearchTabView> createState() => _HybridSearchTabViewState();
}

class _HybridSearchTabViewState extends State<HybridSearchTabView> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchingFirms = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar advogados ou escritórios...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _performSearch(),
              ),
              const SizedBox(height: 12),
              // Toggle para buscar escritórios
              Row(
                children: [
                  Switch(
                    value: _searchingFirms,
                    onChanged: (value) {
                      setState(() {
                        _searchingFirms = value;
                      });
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Incluir escritórios na busca',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Resultados da busca
        Expanded(
          child: BlocBuilder<HybridMatchBloc, HybridMatchState>(
            builder: (context, state) {
              if (state is HybridMatchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is HybridMatchError) {
                return _buildSearchError(context, state.message);
              }
              
              if (state is HybridMatchLoaded) {
                return HybridMatchList(
                  lawyers: state.lawyers,
                  firms: state.firms,
                  showSectionHeaders: true,
                  emptyMessage: 'Nenhum resultado encontrado.\nTente usar termos diferentes.',
                  onRefresh: () => _performSearch(),
                );
              }
              
              return _buildSearchEmptyState(context);
            },
          ),
        ),
      ],
    );
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    context.read<HybridMatchBloc>().add(SearchHybridMatches(
      query: query,
      includeFirms: _searchingFirms,
    ));
  }

  Widget _buildSearchError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro na busca',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performSearch,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Digite para buscar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Encontre advogados e escritórios\nque atendam suas necessidades',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Modal de Filtros Híbridos
class HybridFiltersModal extends StatefulWidget {
  const HybridFiltersModal({super.key});

  @override
  State<HybridFiltersModal> createState() => _HybridFiltersModalState();
}

class _HybridFiltersModalState extends State<HybridFiltersModal> {
  String? _selectedSpecialty;
  double _minRating = 0.0;
  double _maxDistance = 50.0;
  bool _showOnlyAvailable = false;
  bool _showOnlyFirms = false;

  final List<String> _specialties = [
    'Direito Civil',
    'Direito Trabalhista',
    'Direito Empresarial',
    'Direito Penal',
    'Direito Tributário',
    'Direito Imobiliário',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Especialidade
          Text(
            'Especialidade',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSpecialty,
            hint: const Text('Selecione uma especialidade'),
            items: _specialties.map((specialty) {
              return DropdownMenuItem(
                value: specialty,
                child: Text(specialty),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecialty = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Avaliação mínima
          Text(
            'Avaliação mínima: ${_minRating.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _minRating,
            max: 5.0,
            divisions: 50,
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Distância máxima
          Text(
            'Distância máxima: ${_maxDistance.toStringAsFixed(0)} km',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _maxDistance,
            max: 100.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Switches
          SwitchListTile(
            title: const Text('Apenas disponíveis'),
            value: _showOnlyAvailable,
            onChanged: (value) {
              setState(() {
                _showOnlyAvailable = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Apenas escritórios'),
            value: _showOnlyFirms,
            onChanged: (value) {
              setState(() {
                _showOnlyFirms = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedSpecialty = null;
                      _minRating = 0.0;
                      _maxDistance = 50.0;
                      _showOnlyAvailable = false;
                      _showOnlyFirms = false;
                    });
                  },
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<HybridMatchBloc>().add(FilterHybridMatches(
                      specialty: _selectedSpecialty,
                      minRating: _minRating,
                      maxDistance: _maxDistance,
                      showOnlyAvailable: _showOnlyAvailable,
                      showOnlyFirms: _showOnlyFirms,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// DADOS MOCK PARA DESENVOLVIMENTO E TESTES
// =================================================================

/// Classe utilitária para armazenar dados mock de advogados
class MockLawyersData {
  static final List<Map<String, dynamic>> lawyers = [
    {
      'lawyer_id': '1',
      'nome': 'Dr. João Silva',
      'primary_area': 'Direito Civil',
      'rating': 4.8,
      'distance_km': 5.2,
      'is_available': true,
      'experience_years': 15,
      'awards': ['OAB Destaque 2023', 'Melhor Advogado Civil SP', 'Top Lawyer 2022'],
      'professional_summary': 'Especialista em Direito Civil com 15 anos de experiência. Formado pela USP, com mestrado em Direito Contratual. Atua principalmente em contratos empresariais, responsabilidade civil e direito imobiliário. Reconhecido pela OAB-SP como advogado destaque em 2023.',
      'features': {
        'area_match': 0.95,
        'case_similarity': 0.87,
        'success_rate': 0.92,
        'geography': 0.88,
        'qualification': 0.90,
        'urgency': 0.85,
        'review_score': 0.96,
        'soft_skills': 0.89,
      },
      'fair': 0.89,
      'equity': 0.85,
      'avatar_url': 'https://ui-avatars.com/api/?name=João+Silva&background=6B7280&color=fff',
    },
    {
      'lawyer_id': '2',
      'nome': 'Dra. Maria Santos',
      'primary_area': 'Direito Trabalhista',
      'rating': 4.6,
      'distance_km': 8.7,
      'is_available': true,
      'experience_years': 12,
      'awards': ['Top Lawyer 2022', 'Especialista Trabalhista', 'OAB Reconhecimento 2021'],
      'professional_summary': 'Advogada trabalhista com sólida experiência em ações trabalhistas, acordos coletivos e consultoria empresarial. Formada pela PUC-SP, especialista em Direito do Trabalho. Reconhecida como Top Lawyer pela revista Análise Advocacia em 2022.',
      'features': {
        'area_match': 0.92,
        'case_similarity': 0.83,
        'success_rate': 0.88,
        'geography': 0.82,
        'qualification': 0.94,
        'urgency': 0.90,
        'review_score': 0.92,
        'soft_skills': 0.91,
      },
      'fair': 0.87,
      'equity': 0.88,
      'avatar_url': 'https://ui-avatars.com/api/?name=Maria+Santos&background=6B7280&color=fff',
    },
    {
      'lawyer_id': '3',
      'nome': 'Dr. Carlos Oliveira',
      'primary_area': 'Direito Empresarial',
      'rating': 4.9,
      'distance_km': 3.1,
      'is_available': false,
      'experience_years': 20,
      'awards': ['Advogado do Ano 2023', 'Especialista Empresarial', 'Reconhecimento FIESP'],
      'professional_summary': 'Advogado empresarial com mais de 20 anos de experiência. Especialista em fusões e aquisições, direito societário e compliance. Formado pela FGV, com MBA em Gestão Empresarial. Atuou em grandes operações de M&A no mercado brasileiro.',
      'features': {
        'area_match': 0.88,
        'case_similarity': 0.91,
        'success_rate': 0.95,
        'geography': 0.95,
        'qualification': 0.98,
        'urgency': 0.82,
        'review_score': 0.98,
        'soft_skills': 0.87,
      },
      'fair': 0.92,
      'equity': 0.91,
      'avatar_url': 'https://ui-avatars.com/api/?name=Carlos+Oliveira&background=8B5CF6&color=fff',
    },
  ];

  /// Método utilitário para construir uma lista de advogados mock
  static Widget buildMockLawyersList(BuildContext context) {
    return ListView.builder(
      itemCount: lawyers.length,
      itemBuilder: (context, index) {
        final lawyer = lawyers[index];
        return LawyerMatchCard(
          lawyer: lawyer,
          onSelect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Advogado ${lawyer['nome']} selecionado')),
            );
          },
          onExplain: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Explicação para ${lawyer['nome']}')),
            );
          },
        );
      },
    );
  }
}