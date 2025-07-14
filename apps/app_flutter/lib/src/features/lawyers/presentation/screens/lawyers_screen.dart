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
      builder: (context) => const HybridFiltersModal(),
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
  // Dados mock para demonstração
  final List<Map<String, dynamic>> _mockLawyers = [
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

  @override
  Widget build(BuildContext context) {
            return ListView.builder(
      itemCount: _mockLawyers.length,
              itemBuilder: (context, index) {
        final lawyer = _mockLawyers[index];
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

class SearchTabView extends StatefulWidget {
  const SearchTabView({super.key});

  @override
  State<SearchTabView> createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<SearchTabView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedArea;
  String? _selectedUF;
  double _minRating = 0;
  double _maxDistance = 50;
  bool _onlyAvailable = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  bool _isListView = true; // Controla se está vendo lista ou mapa
  
  // Google Maps
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  int? _selectedLawyerId;

  final List<String> _areas = [
    'Direito Civil',
    'Direito Penal',
    'Direito Trabalhista',
    'Direito Tributário',
    'Direito Empresarial',
    'Direito de Família',
    'Direito Previdenciário',
    'Direito Administrativo',
    'Direito Constitucional',
    'Direito Ambiental',
  ];

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_searchController.text.trim().isEmpty && 
        _selectedArea == null && 
        _selectedUF == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um termo de busca ou selecione filtros')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      // TODO: Implementar busca real via API
      // Por enquanto, simular busca
      await Future.delayed(const Duration(seconds: 1));
      
      // Dados mock para demonstração com coordenadas
      _searchResults = [
        {
          'lawyer_id': '1',
          'nome': 'Dr. João Silva',
          'primary_area': _selectedArea ?? 'Direito Civil',
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
          'latitude': -23.5505,
          'longitude': -46.6333,
        },
        {
          'lawyer_id': '2',
          'nome': 'Dra. Maria Santos',
          'primary_area': _selectedArea ?? 'Direito Trabalhista',
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
          'latitude': -23.5615,
          'longitude': -46.6565,
        },
        {
          'lawyer_id': '3',
          'nome': 'Dr. Carlos Oliveira',
          'primary_area': _selectedArea ?? 'Direito Empresarial',
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
          'latitude': -23.5489,
          'longitude': -46.6388,
        },
      ];

      // Aplicar filtros locais
      _searchResults = _searchResults.where((lawyer) {
        if (_minRating > 0 && lawyer['rating'] < _minRating) return false;
        if (_maxDistance < 50 && lawyer['distance_km'] > _maxDistance) return false;
        if (_onlyAvailable && !lawyer['is_available']) return false;
        return true;
      }).toList();

      // Atualizar marcadores do mapa
      _updateMapMarkers();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na busca: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _updateMapMarkers() {
    _markers.clear();
    
    for (int i = 0; i < _searchResults.length; i++) {
      final lawyer = _searchResults[i];
      final isSelected = _selectedLawyerId == int.parse(lawyer['lawyer_id']);
      
      _markers.add(
        Marker(
          markerId: MarkerId(lawyer['lawyer_id']),
          position: LatLng(lawyer['latitude'], lawyer['longitude']),
          infoWindow: InfoWindow(
            title: lawyer['nome'],
            snippet: '${lawyer['primary_area']} • ${lawyer['rating']}⭐',
          ),
          icon: isSelected 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : BitmapDescriptor.defaultMarker,
          onTap: () {
            setState(() {
              _selectedLawyerId = int.parse(lawyer['lawyer_id']);
            });
          },
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedArea = null;
      _selectedUF = null;
      _minRating = 0;
      _maxDistance = 50;
      _onlyAvailable = false;
      _searchResults.clear();
      _markers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de Pesquisa com botões de visualização
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar advogado por nome ou OAB...',
                        prefixIcon: Icon(LucideIcons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    child: _isSearching 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botões de alternância de visualização
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Lista'),
                        icon: Icon(LucideIcons.list),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Mapa'),
                        icon: Icon(LucideIcons.map),
                      ),
                    ],
                    selected: {_isListView},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isListView = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filtros Avançados
        ExpansionTile(
          title: const Text('Filtros Avançados'),
          leading: const Icon(LucideIcons.filter),
          trailing: _hasActiveFilters()
              ? Badge(
                  child: const Icon(Icons.expand_more),
                )
              : const Icon(Icons.expand_more),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área Jurídica
                  const Text('Área Jurídica', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    hint: const Text('Selecione uma área'),
                    items: _areas.map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedArea = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Estado
                  const Text('Estado (UF)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedUF,
                    hint: const Text('Selecione um estado'),
                    items: _estados.map((uf) => DropdownMenuItem(
                      value: uf,
                      child: Text(uf),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedUF = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Avaliação Mínima
                  Text('Avaliação Mínima: ${_minRating.toStringAsFixed(1)}⭐', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 50,
                    onChanged: (value) => setState(() => _minRating = value),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Distância Máxima
                  Text('Distância Máxima: ${_maxDistance.toStringAsFixed(0)} km', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Apenas Disponíveis
                  CheckboxListTile(
                    title: const Text('Apenas advogados disponíveis'),
                    value: _onlyAvailable,
                    onChanged: (value) => setState(() => _onlyAvailable = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botões de Ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpar Filtros'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _performSearch,
                          child: const Text('Aplicar Filtros'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Resultados da Busca
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedArea != null || 
           _selectedUF != null || 
           _minRating > 0 || 
           _maxDistance < 50 || 
           _onlyAvailable;
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando advogados...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou termos de busca',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Alternar entre lista e mapa
    return _isListView ? _buildListView() : _buildMapView();
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final lawyer = _searchResults[index];
        return _buildLawyerProfileCard(lawyer);
      },
    );
  }

  Widget _buildMapView() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Faça uma busca para ver advogados no mapa'),
      );
    }

    // Calcular bounds para mostrar todos os advogados
    double minLat = _searchResults.map((l) => l['latitude'] as double).reduce((a, b) => a < b ? a : b);
    double maxLat = _searchResults.map((l) => l['latitude'] as double).reduce((a, b) => a > b ? a : b);
    double minLng = _searchResults.map((l) => l['longitude'] as double).reduce((a, b) => a < b ? a : b);
    double maxLng = _searchResults.map((l) => l['longitude'] as double).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Informações do advogado selecionado
        if (_selectedLawyerId != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSelectedLawyerInfo(),
          ),
        ],
        
        // Mapa
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (minLat + maxLat) / 2,
                    (minLng + maxLng) / 2,
                  ),
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                  
                  // Ajustar câmera para mostrar todos os marcadores
                  Future.delayed(const Duration(milliseconds: 500), () async {
                    final GoogleMapController mapController = await _mapController.future;
                    mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(minLat - 0.01, minLng - 0.01),
                          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
                        ),
                        100.0,
                      ),
                    );
                  });
                },
                onTap: (position) {
                  // Desselecionar advogado ao tocar no mapa
                  setState(() {
                    _selectedLawyerId = null;
                  });
                  _updateMapMarkers();
                },
              ),
              
              // Controles do mapa
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      onPressed: () async {
                        final GoogleMapController controller = await _mapController.future;
                        controller.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: const Icon(Icons.zoom_in),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      onPressed: () async {
                        final GoogleMapController controller = await _mapController.future;
                        controller.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: const Icon(Icons.zoom_out),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedLawyerInfo() {
    if (_selectedLawyerId == null) return const SizedBox.shrink();
    
    final lawyer = _searchResults.firstWhere(
      (l) => l['lawyer_id'] == _selectedLawyerId.toString(),
      orElse: () => null,
    );
    
    if (lawyer == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(lawyer['avatar_url']),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lawyer['nome'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(lawyer['primary_area']),
              Row(
                children: [
                  Icon(LucideIcons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${lawyer['rating']}'),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${lawyer['distance_km']} km'),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Contratando ${lawyer['nome']}')),
            );
          },
          child: const Text('Contratar'),
        ),
      ],
    );
  }

  Widget _buildLawyerProfileCard(Map<String, dynamic> lawyer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com foto e info básica
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(lawyer['avatar_url']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer['nome'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(lawyer['primary_area']),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${lawyer['rating']}'),
                          const SizedBox(width: 16),
                          Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${lawyer['distance_km']} km'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${(lawyer['fair'] * 100).toInt()}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Experiência e Prêmios
            if (lawyer['experience_years'] != null) ...[
              Row(
                children: [
                  Icon(LucideIcons.briefcase, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${lawyer['experience_years']} anos de experiência',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  // Botão Ver Currículo
                  if (lawyer['professional_summary'] != null) ...[
                    TextButton.icon(
                      onPressed: () => _showCurriculumModal(context, lawyer),
                      icon: const Icon(LucideIcons.fileText, size: 16),
                      label: const Text('Ver Currículo'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Prêmios
            if (lawyer['awards'] != null && lawyer['awards'].isNotEmpty) ...[
              Row(
                children: [
                  Icon(LucideIcons.award, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (lawyer['awards'] as List)
                          .take(3)
                          .map((award) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Text(
                                  award,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contratando ${lawyer['nome']}')),
                      );
                    },
                    icon: const Icon(LucideIcons.fileSignature),
                    label: const Text('Contratar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.messageSquare),
                  tooltip: 'Chat',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.video),
                  tooltip: 'Vídeo Chamada',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCurriculumModal(BuildContext context, Map<String, dynamic> lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currículo - ${lawyer['nome']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lawyer['experience_years'] != null) ...[
                            Text(
                              'Experiência: ${lawyer['experience_years']} anos',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (lawyer['awards'] != null && (lawyer['awards'] as List).isNotEmpty) ...[
                            Text(
                              'Prêmios e Reconhecimentos:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...(lawyer['awards'] as List).map((award) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $award', style: Theme.of(context).textTheme.bodyMedium),
                            )).toList(),
                            const SizedBox(height: 16),
                          ],
                          
                          Text(
                            'Resumo Profissional:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lawyer['professional_summary'] ?? 'Não disponível',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }