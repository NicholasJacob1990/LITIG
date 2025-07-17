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
  String _selectedPreset = 'balanced';
  bool _showMapView = false;
  final TextEditingController _searchController = TextEditingController();
  bool _hasPerformedSearch = false; // ✅ NOVA FLAG para controlar se já pesquisou
  
  // ✅ NOVO: Estado para case highlighting
  String? _highlightedCaseId;
  bool _isHighlightingCase = false;
  
  @override
  void initState() {
    super.initState();
    // ✅ REATIVO: NÃO carrega automaticamente
    // _fetchRecommendations(); // ❌ REMOVIDO
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForCaseParameters(); // ✅ MELHOR PRÁTICA: Acesso seguro ao ModalRoute
  }
  
  // ✅ NOVO: Verificar parâmetros de caso na URL
  void _checkForCaseParameters() {
    final route = ModalRoute.of(context);
    if (route != null) {
      final uri = Uri.parse(route.settings.name ?? '');
      final caseHighlight = uri.queryParameters['case_highlight'];
      final caseId = uri.queryParameters['case_id'];
      
      if (caseHighlight != null || caseId != null) {
        setState(() {
          _highlightedCaseId = caseHighlight ?? caseId;
          _isHighlightingCase = true;
          _hasPerformedSearch = true;
        });
        _loadMatchesForCase(_highlightedCaseId!);
      }
    }
  }
  
  // ✅ NOVO: Carregar matches específicos para um caso
  void _loadMatchesForCase(String caseId) {
    // Usar SearchParams com caseId para buscar matches específicos
    final params = SearchParams(
      caseId: caseId, // Assumindo que SearchParams suporta caseId
      preset: _selectedPreset,
      includeFirms: true,
    );
    context.read<SearchBloc>().add(SearchRequested(params));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchRecommendations() {
    final query = _searchController.text.trim();
    
    // ✅ REATIVO: Só busca se há query OU se o usuário explicitamente clicou em "buscar por preset"
    if (query.isNotEmpty || _hasPerformedSearch) {
      final params = SearchParams(
        query: query.isNotEmpty ? query : null,
        preset: _selectedPreset,
        includeFirms: true,
      );
      context.read<SearchBloc>().add(SearchRequested(params));
    }
  }

  void _performPresetSearch() {
    // ✅ Permite busca por preset mesmo sem texto (quando usuário explicitamente escolhe)
    setState(() {
      _hasPerformedSearch = true;
    });
    
    final params = SearchParams(
      preset: _selectedPreset,
      includeFirms: true,
    );
    context.read<SearchBloc>().add(SearchRequested(params));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com controles de pesquisa
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle de visualização Lista/Mapa (apenas ícones)
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
              
              // ✅ NOVO: Banner para caso destacado
              if (_isHighlightingCase && _highlightedCaseId != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.target,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recomendações para seu caso',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '#${_highlightedCaseId!.substring(0, 8)}...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isHighlightingCase = false;
                            _highlightedCaseId = null;
                            _hasPerformedSearch = false;
                          });
                          context.read<SearchBloc>().add(const SearchCleared());
                        },
                        icon: Icon(
                          LucideIcons.x,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // ✅ NOVO: Campo de pesquisa
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por especialização, nome...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _hasPerformedSearch = false;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _fetchRecommendations(),
                onSubmitted: (value) => _fetchRecommendations(),
              ),
              const SizedBox(height: 16),
              
              // Título da seção
              Text(
                'Tipo de Recomendação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // Chips de seleção de preset (melhorados)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip(
                      'balanced', 
                      'Recomendado', 
                      'Equilibra experiência e custo',
                      LucideIcons.star,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      'correspondent', 
                      'Melhor Custo', 
                      'Foca em economia',
                      LucideIcons.dollarSign,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      'expert_opinion', 
                      'Mais Experientes', 
                      'Prioriza expertise',
                      LucideIcons.award,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Resultados das recomendações
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              // ✅ REATIVO: Mostra estado inicial se não pesquisou
              if (!_hasPerformedSearch && _searchController.text.isEmpty) {
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

                // Escolher visualização baseada no toggle
                if (_showMapView) {
                  return _buildMapView(lawyers, firms);
                } else {
                  return PartnerSearchResultList(
                    lawyers: lawyers,
                    firms: firms,
                    emptyMessage: 'Nenhuma recomendação encontrada.\nTente ajustar os filtros.',
                    onRefresh: _fetchRecommendations,
                  );
                }
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Encontre Parceiros Ideais',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Digite uma especialização ou\nescolha um tipo de recomendação',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performPresetSearch,
            icon: const Icon(LucideIcons.star),
            label: const Text('Ver Recomendações Gerais'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String preset, String label, String description, IconData icon) {
    final isSelected = _selectedPreset == preset;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPreset = preset;
        });
        // ✅ REATIVO: Só busca se já havia pesquisado antes OU se forçar busca por preset
        if (_hasPerformedSearch || _searchController.text.isNotEmpty) {
          _fetchRecommendations();
        } else {
          _performPresetSearch(); // Busca por preset quando usuário escolhe explicitamente
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir o toggle de visualização (apenas ícones)
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

  // Widget para construir a visualização em mapa
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
      final location = mockLocations[i];
      
      markers.add(
        Marker(
          markerId: MarkerId('firm_${firm.id}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: firm.name,
            snippet: '${firm.teamSize} advogados',
          ),
        ),
      );
    }

    return Column(
      children: [
        // Legenda do mapa
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('${lawyers.length} Advogados'),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('${firms.length} Escritórios'),
                ],
              ),
            ],
          ),
        ),
        
        // Mapa
        Expanded(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-23.5505, -46.6333), // São Paulo
              zoom: 10,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
        ),
      ],
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
              _fetchRecommendations();
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
  bool _showMapView = false; // Nova variável para controlar visualização
  
  // Novas variáveis para ferramentas de precisão
  String? _selectedLocation;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _searchFocus = 'balanced'; // 'balanced', 'correspondent', 'expert_opinion'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com toggle de visualização
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle de visualização Lista/Mapa (apenas ícones)
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
              
              // Campo de busca principal
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
              const SizedBox(height: 16),
              
              // Ferramentas de precisão
              Row(
                children: [
                  // Dropdown de Foco da Busca
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _searchFocus,
                      decoration: InputDecoration(
                        labelText: 'Foco da Busca',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'balanced',
                          child: Text('Equilibrado'),
                        ),
                        DropdownMenuItem(
                          value: 'correspondent',
                          child: Text('Correspondente'),
                        ),
                        DropdownMenuItem(
                          value: 'expert_opinion',
                          child: Text('Parecer Técnico'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _searchFocus = value!;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Botão de Localização
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _showLocationPicker,
                      icon: Icon(
                        _selectedLocation != null 
                          ? LucideIcons.mapPin 
                          : LucideIcons.plus,
                        size: 18,
                      ),
                      label: Text(
                        _selectedLocation != null 
                          ? 'Local' 
                          : 'Adicionar',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        backgroundColor: _selectedLocation != null 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      ),
                    ),
                  ),
                ],
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
                  if (_selectedLocation != null) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearLocation,
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Limpar Local', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Indicador de localização selecionada
              if (_selectedLocation != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buscando próximo a: $_selectedLocation',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Resultados da busca
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
                  return PartnerSearchResultList(
                    lawyers: lawyers,
                    firms: firms,
                    emptyMessage: 'Nenhum resultado encontrado.\nTente usar termos diferentes.',
                    onRefresh: () => _performSearch(),
                  );
                }
              }
              
              return _buildSearchEmptyState(context);
            },
          ),
        ),
      ],
    );
  }

  void _showLocationPicker() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _selectedLatitude != null && _selectedLongitude != null
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
          initialAddress: _selectedLocation,
          onLocationSelected: (location, address) {
            setState(() {
              _selectedLocation = address;
              _selectedLatitude = location.latitude;
              _selectedLongitude = location.longitude;
              _searchFocus = 'correspondent'; // Mudar automaticamente para correspondente
            });
            _performSearch();
          },
        ),
      ),
    );
  }

  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
      _selectedLatitude = null;
      _selectedLongitude = null;
      _searchFocus = 'balanced'; // Volta ao foco equilibrado
    });
    _performSearch();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    
    // Se há query ou localização, faz a busca usando o SearchBloc
    if (query.isNotEmpty || _selectedLocation != null) {
      final params = SearchParams(
        query: query.isNotEmpty ? query : null,
        preset: _searchFocus,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        includeFirms: _searchingFirms,
      );
      
      context.read<SearchBloc>().add(SearchRequested(params));
    }
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

  // Widget para construir o toggle de visualização (apenas ícones)
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

  // Widget para construir a visualização em mapa
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
      final location = mockLocations[i];
      
      markers.add(
        Marker(
          markerId: MarkerId('firm_${firm.id}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: firm.name,
            snippet: '${firm.teamSize} advogados',
          ),
        ),
      );
    }

    return Column(
      children: [
        // Legenda do mapa
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('${lawyers.length} Advogados'),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('${firms.length} Escritórios'),
                ],
              ),
            ],
          ),
        ),
        
        // Mapa
        Expanded(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-23.5505, -46.6333), // São Paulo
              zoom: 10,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
        ),
      ],
    );
  }
}

/// Modal de Filtros Híbridos - Super-Filtro
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
  
  // Novos filtros de preço
  double _minPrice = 0.0;
  double _maxPrice = 2000.0;
  String _priceType = 'consultation'; // 'consultation' ou 'hourly'

  final List<String> _specialties = [
    'Direito Civil',
    'Direito Trabalhista',
    'Direito Empresarial',
    'Direito Penal',
    'Direito Tributário',
    'Direito Imobiliário',
    'Direito de Família',
    'Direito Previdenciário',
    'Direito Ambiental',
    'Direito Digital',
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
              Row(
                children: [
                  Icon(
                    LucideIcons.filter,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Super-Filtro',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSpecialty,
            hint: const Text('Selecione uma especialidade'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
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
          const SizedBox(height: 20),

          // Avaliação mínima
          Text(
            'Avaliação mínima: ${_minRating.toStringAsFixed(1)} ⭐',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minRating,
            max: 5.0,
            divisions: 50,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // Filtros de Preço - NOVO
          Text(
            'Faixa de Preço',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Tipo de preço
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Consulta'),
                  value: 'consultation',
                  groupValue: _priceType,
                  onChanged: (value) {
                    setState(() {
                      _priceType = value!;
                      if (value == 'consultation') {
                        _maxPrice = 2000.0;
                      } else {
                        _maxPrice = 1000.0;
                      }
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Por hora'),
                  value: 'hourly',
                  groupValue: _priceType,
                  onChanged: (value) {
                    setState(() {
                      _priceType = value!;
                      if (value == 'consultation') {
                        _maxPrice = 2000.0;
                      } else {
                        _maxPrice = 1000.0;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          
          // Range de preço
          Text(
            'R\$ ${_minPrice.toStringAsFixed(0)} - R\$ ${_maxPrice.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            max: _priceType == 'consultation' ? 2000.0 : 1000.0,
            divisions: 20,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 20),

          // Distância máxima
          Text(
            'Distância máxima: ${_maxDistance.toStringAsFixed(0)} km',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _maxDistance,
            max: 200.0,
            divisions: 40,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // Switches aprimorados
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Apenas disponíveis'),
                    subtitle: const Text('Advogados que podem aceitar novos casos'),
                    value: _showOnlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyAvailable = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Incluir escritórios'),
                    subtitle: const Text('Mostrar escritórios de advocacia nos resultados'),
                    value: _showOnlyFirms,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyFirms = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botões aprimorados
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSpecialty = null;
                      _minRating = 0.0;
                      _maxDistance = 50.0;
                      _showOnlyAvailable = false;
                      _showOnlyFirms = false;
                      _minPrice = 0.0;
                      _maxPrice = _priceType == 'consultation' ? 2000.0 : 1000.0;
                    });
                  },
                  icon: const Icon(LucideIcons.rotateCcw),
                  label: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implementação completa usando SearchBloc com todos os filtros
                    final params = SearchParams(
                      query: _selectedSpecialty,
                      preset: 'balanced', // Preset base, filtros aplicados depois
                      minRating: _minRating,
                      maxDistance: _maxDistance,
                      onlyAvailable: _showOnlyAvailable,
                      includeFirms: _showOnlyFirms,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      priceType: _priceType,
                    );
                    
                    context.read<SearchBloc>().add(SearchRequested(params));
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.search),
                  label: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}