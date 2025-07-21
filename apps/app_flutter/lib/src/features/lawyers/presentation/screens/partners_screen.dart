import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyers_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_bloc.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_bloc.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_event.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_state.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/search/presentation/widgets/partner_search_result_list.dart';
import 'package:meu_app/src/features/search/presentation/widgets/location_picker.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meu_app/injection_container.dart';

// Novos imports para cartões compactos e filtros inline
import 'package:meu_app/src/features/lawyers/presentation/widgets/compact_search_card.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/compact_firm_card.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/inline_search_filters.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_filters_modal.dart';

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
        BlocProvider(create: (context) => getIt<SearchBloc>()),
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
          // ❌ REMOVIDO: Ícone de filtros global - agora filtros são inline na aba "Buscar"
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
            HybridSearchTabView(), // ✅ ATUALIZADA: Agora com filtros inline e cartões compactos
          ],
        ),
      ),
    );
  }
}

/// Tab de Recomendações Híbridas (Advogados + Escritórios)
/// 
/// ✅ MANTIDA: Sem alterações - continua usando cartões completos
class HybridRecommendationsTabView extends StatefulWidget {
  const HybridRecommendationsTabView({super.key});

  @override
  State<HybridRecommendationsTabView> createState() => _HybridRecommendationsTabViewState();
}

class _HybridRecommendationsTabViewState extends State<HybridRecommendationsTabView> {
  bool _hasPerformedSearch = false;
  final bool _showMapView = false; // ❌ REMOVIDO: Toggle mapa das recomendações conforme especificação
  
  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  void _fetchRecommendations() {
    setState(() => _hasPerformedSearch = true);
    context.read<SearchBloc>().add(const SearchRequested(
      SearchParams(preset: 'balanced', includeFirms: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com controles de pesquisa - SIMPLIFICADO para recomendações
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ❌ REMOVIDO: Toggle Lista/Mapa (exclusivo da aba "Buscar")
              
              // ✅ NOVO: Banner para caso destacado
                Container(
                padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                      LucideIcons.lightbulb,
                      color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                      child: Text(
                        'Recomendações personalizadas baseadas no seu perfil e histórico',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        
        // Lista de resultados - MANTIDA: Cartões completos LawyerMatchCard
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              // ✅ REATIVO: Mostra estado inicial se não pesquisou
              if (!_hasPerformedSearch && !_hasSearched) {
                return _buildInitialState(context);
              }
              
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is SearchError) {
                return _buildErrorState(context, state.message);
              }
              
              if (state is SearchLoaded) {
                final lawyers = state.results.whereType<Lawyer>().toList();
                final firms = state.results.whereType<LawFirm>().toList();

                // ✅ SEMPRE LISTA: Sem toggle mapa nas recomendações
                  return PartnerSearchResultList(
                    lawyers: lawyers,
                    firms: firms,
                    emptyMessage: 'Nenhuma recomendação encontrada.\nTente ajustar os filtros.',
                    onRefresh: _fetchRecommendations,
                  );
              }
              
              return _buildEmptyState(context);
            },
          ),
        ),
      ],
    );
  }

  // ✅ NOVO: Estado inicial antes de qualquer pesquisa
  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
              'Carregando suas recomendações...',
            style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
              'Estamos encontrando os melhores advogados e escritórios para você.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
              color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar recomendações',
            style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: _fetchRecommendations,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              LucideIcons.searchX,
            size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
              'Nenhuma recomendação encontrada',
            style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Não encontramos advogados ou escritórios compatíveis com o seu perfil no momento.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Atualizar'),
          ),
        ],
        ),
      ),
    );
  }
}

/// Tab de Busca Híbrida - ✅ REFATORADA: Cartões compactos + Filtros inline
class HybridSearchTabView extends StatefulWidget {
  const HybridSearchTabView({super.key});

  @override
  State<HybridSearchTabView> createState() => _HybridSearchTabViewState();
}

class _HybridSearchTabViewState extends State<HybridSearchTabView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showMapView = false; // ✅ MANTIDO: Toggle Lista/Mapa apenas na busca
  bool _filtersExpanded = false; // ✅ NOVO: Controle do accordion de filtros

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header simplificado - ✅ FOCO: apenas busca e toggle
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle de visualização Lista/Mapa - ✅ MANTIDO apenas na busca
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggle(
                          icon: LucideIcons.list,
                          isSelected: !_showMapView,
                          onTap: () => setState(() => _showMapView = false),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        _buildViewToggle(
                          icon: LucideIcons.map,
                          isSelected: _showMapView,
                          onTap: () => setState(() => _showMapView = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Campo de busca principal - ✅ SIMPLIFICADO
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar advogados ou escritórios...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
                    },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                      onChanged: (value) {
                  setState(() {}); // Para atualizar o suffixIcon
                        _performSearch();
                      },
                  ),
                ],
              ),
        ),
              
        // ✅ NOVO: Filtros inline (accordion)
        InlineSearchFilters(
          isExpanded: _filtersExpanded,
          onToggle: () => setState(() => _filtersExpanded = !_filtersExpanded),
        ),
        
        // Resultados de busca - ✅ NOVO: Cartões compactos
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is SearchError) {
                return _buildSearchError(context, state.message);
              }
              
              if (state is SearchLoaded) {
                final lawyers = state.results.whereType<Lawyer>().toList();
                final firms = state.results.whereType<LawFirm>().toList();

                // Escolher visualização baseada no toggle
                if (_showMapView) {
                  return _buildMapView(lawyers, firms);
                } else {
                  // ✅ NOVO: Lista com cartões compactos
                  return _buildCompactResultsList(lawyers, firms);
                }
              }
              
              return _buildSearchEmptyState(context);
            },
          ),
        ),
      ],
    );
  }

  // ✅ NOVO: Lista com cartões compactos para busca
  Widget _buildCompactResultsList(List<Lawyer> lawyers, List<LawFirm> firms) {
    final combinedResults = <dynamic>[];
    
    // Adicionar escritórios primeiro
    combinedResults.addAll(firms);
    // Adicionar advogados
    combinedResults.addAll(lawyers);

    if (combinedResults.isEmpty) {
      return _buildSearchEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => _performSearch(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: combinedResults.length,
        itemBuilder: (context, index) {
          final item = combinedResults[index];
          
          if (item is LawFirm) {
            return CompactFirmCard(
              firm: item,
              onSelect: () => _selectFirm(item),
              onViewFirm: () => _viewFirmDetails(item),
            );
          } else if (item is Lawyer) {
            return CompactSearchCard(
              item: item,
              onSelect: () => _selectLawyer(item),
              onViewProfile: () => _viewLawyerProfile(item),
      );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ✅ Handlers para ações dos cartões compactos
  void _selectLawyer(Lawyer lawyer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Advogado ${lawyer.name} selecionado'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar lógica de seleção
  }

  void _selectFirm(LawFirm firm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Escritório ${firm.name} selecionado'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar lógica de seleção
  }

  void _viewLawyerProfile(Lawyer lawyer) {
    // TODO: Navegar para perfil completo do advogado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrindo perfil de ${lawyer.name}')),
    );
  }

  void _viewFirmDetails(LawFirm firm) {
    // TODO: Navegar para detalhes do escritório
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrindo detalhes de ${firm.name}')),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected 
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // Widget para construir a visualização em mapa - ✅ MANTIDO
  Widget _buildMapView(List<Lawyer> lawyers, List<LawFirm> firms) {
    // Coordenadas mock para demonstração
    final mockLocations = [
      const LatLng(-23.5505, -46.6333), // São Paulo
      const LatLng(-22.9068, -43.1729), // Rio de Janeiro
      const LatLng(-19.9167, -43.9345), // Belo Horizonte
      const LatLng(-15.7942, -47.8822), // Brasília
      const LatLng(-30.0346, -51.2177), // Porto Alegre
    ];

    final Set<Marker> markers = {};

    // Adicionar marcadores para advogados (azuis)
    for (int i = 0; i < lawyers.length && i < mockLocations.length; i++) {
      final lawyer = lawyers[i];
      final location = mockLocations[i];
      
      markers.add(
        Marker(
          markerId: MarkerId('lawyer_${lawyer.id}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: lawyer.name,
            snippet: 'OAB: ${lawyer.oab}',
          ),
        ),
      );
    }

    // Adicionar marcadores para escritórios (verdes)
    for (int i = 0; i < firms.length && i < mockLocations.length; i++) {
      final firm = firms[i];
      final location = mockLocations[i + lawyers.length < mockLocations.length 
          ? i + lawyers.length 
          : i];
      
      markers.add(
        Marker(
          markerId: MarkerId('firm_${firm.id}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: firm.name,
            snippet: 'Escritório de advocacia',
          ),
        ),
      );
    }

    return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-23.5505, -46.6333), // São Paulo
              zoom: 10,
            ),
            markers: markers,
      onMapCreated: (GoogleMapController controller) {
        // Configurações adicionais do mapa se necessário
      },
    );
  }

  Widget _buildSearchError(BuildContext context, String message) {
    return Center(
      child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: Colors.red.withValues(alpha: 0.5),
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
      ),
    );
  }

  Widget _buildSearchEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
          ),
            const SizedBox(height: 16),
          Text(
              _searchController.text.isEmpty 
                  ? 'Digite algo para buscar' 
                  : 'Nenhum resultado encontrado',
              style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
              _searchController.text.isEmpty
                  ? 'Use a busca para encontrar advogados e escritórios'
                  : 'Tente usar termos diferentes ou ajuste os filtros',
            style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final params = query.isEmpty
        ? const SearchParams(preset: 'balanced', includeFirms: true)
        : SearchParams(query: query, includeFirms: true);
                    
                    context.read<SearchBloc>().add(SearchRequested(params));
  }
}