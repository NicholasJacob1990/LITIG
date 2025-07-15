import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyers_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_match_list.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_filters_modal.dart';
import 'package:meu_app/src/features/recommendations/presentation/widgets/lawyer_match_card.dart';
import 'package:meu_app/src/features/firms/presentation/widgets/firm_card.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_bloc.dart';
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
        BlocProvider(create: (context) => getIt<FirmBloc>()),
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
    return BlocListener<FirmBloc, FirmState>(
      listener: (context, state) {
        if (state is FirmError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
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
  
  @override
  void initState() {
    super.initState();
    // Buscar recomendações híbridas ao inicializar
    context.read<HybridMatchBloc>().add(const FetchHybridMatches(
      caseId: 'mock_case_id', // TODO: Usar caso real do contexto
      includeFirms: true,
      preset: 'balanced',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HybridMatchBloc, HybridMatchState>(
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
            showSectionHeaders: !state.mixedRendering,
            showMixedResults: state.mixedRendering,
            emptyMessage: 'Nenhuma recomendação encontrada.\nTente ajustar os filtros.',
            onRefresh: () {
              context.read<HybridMatchBloc>().add(const RefreshHybridMatches(
                caseId: 'mock_case_id',
                includeFirms: true,
                preset: 'balanced',
              ));
            },
          );
        }
        
        return _buildEmptyState(context);
      },
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
                    // TODO: Implementar lógica de filtro completa no BLoC e Repositório.
                    // A infraestrutura (evento, handler no BLoC, parâmetros no repositório)
                    // para os filtros avançados (rating, distance, etc.) precisa ser criada.
                    // Por enquanto, usamos a busca com a especialidade como query para manter a funcionalidade.
                    context.read<HybridMatchBloc>().add(SearchHybridMatches(
                      query: _selectedSpecialty ?? '',
                      // Respeita o toggle de "apenas escritórios", mantendo parte da lógica.
                      includeFirms: _showOnlyFirms,
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