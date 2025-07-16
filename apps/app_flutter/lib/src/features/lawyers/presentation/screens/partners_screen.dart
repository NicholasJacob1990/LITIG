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
import 'package:flutter/foundation.dart' show kIsWeb;

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
  bool _showMapView = false; // Estado de visualização centralizado

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

  // Widget de toggle de visualização (reutilizável)
  Widget _buildViewToggle({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Widget para construir a visualização em mapa
  Widget _buildMapView(List<Lawyer> lawyers, List<LawFirm> firms) {
    // Exibe placeholder na Web se a chave não estiver configurada
    if (kIsWeb) {
      return _buildMapPlaceholder();
    }

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
                  Icon(
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
                  Icon(
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

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.mapPinOff,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Visualização de Mapa Indisponível',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Para habilitar o mapa na versão web, é necessário configurar a API Key do Google Maps no arquivo "web/index.html".',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
            // Controle de visualização unificado na AppBar
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  _buildViewToggle(
                    icon: LucideIcons.list,
                    isSelected: !_showMapView,
                    onTap: () => setState(() => _showMapView = false),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  _buildViewToggle(
                    icon: LucideIcons.map,
                    isSelected: _showMapView,
                    onTap: () => setState(() => _showMapView = true),
                  ),
                ],
              ),
            ),
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
          children: [
            // Passa o estado de visualização para as abas filhas
            HybridRecommendationsTabView(showMapView: _showMapView),
            HybridSearchTabView(showMapView: _showMapView),
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
  final bool showMapView;
  const HybridRecommendationsTabView({super.key, required this.showMapView});

  @override
  State<HybridRecommendationsTabView> createState() => _HybridRecommendationsTabViewState();
}

class _HybridRecommendationsTabViewState extends State<HybridRecommendationsTabView> {
  String _selectedPreset = 'balanced';
  // A variável _showMapView foi removida daqui
  
  @override
  void initState() {
    super.initState();
    // Buscar recomendações usando SearchBloc
    _fetchRecommendations();
  }

  void _fetchRecommendations() {
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
        // O header com o toggle de visualização foi removido daqui
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título da seção
              Text(
                'Tipo de Recomendação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // Chips de seleção de preset com Wrap para responsividade
              Wrap(
                spacing: 8.0, // Espaçamento horizontal entre os chips
                runSpacing: 8.0, // Espaçamento vertical entre as linhas de chips
                children: [
                  _buildPresetChip(
                    'balanced', 
                    'Recomendado', 
                    'Equilibra experiência e custo',
                    LucideIcons.star,
                  ),
                  _buildPresetChip(
                    'correspondent', 
                    'Melhor Custo', 
                    'Foca em economia',
                    LucideIcons.dollarSign,
                  ),
                  _buildPresetChip(
                    'expert_opinion', 
                    'Mais Experientes', 
                    'Prioriza expertise',
                    LucideIcons.award,
                  ),
                ],
              ),
              const SizedBox(height: 16), // Espaçamento inferior
            ],
          ),
        ),
        
        // Resultados das recomendações
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is SearchError) {
                return _buildErrorState(context, state.message);
              }
              
              if (state is SearchLoaded) {
                final lawyers = state.results.whereType<Lawyer>().toList();
                final firms = state.results.whereType<LawFirm>().toList();

                // Usa o estado de visualização recebido via widget
                if (widget.showMapView) {
                  // Chama o método centralizado do widget pai
                  return (context.findAncestorStateOfType<_LawyersViewState>())!
                      ._buildMapView(lawyers, firms);
                }

                if (state.results.isEmpty) {
                  return _buildEmptyState(context);
                }

                return PartnerSearchResultList(
                  lawyers: lawyers,
                  firms: firms,
                  emptyMessage: 'Nenhuma recomendação encontrada.\nTente ajustar os filtros.',
                  onRefresh: _fetchRecommendations,
                );
              }
              
              return const Center(child: Text('Selecione um preset para ver as recomendações.'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String preset, String label, String description, IconData icon) {
    final isSelected = _selectedPreset == preset;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPreset = preset;
        });
        _fetchRecommendations();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
            const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }

  // Widget para construir a visualização em mapa
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
            'Nenhuma recomendação encontrada.\nTente ajustar os filtros.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Tab de Busca Híbrida (Advogados + Escritórios)
class HybridSearchTabView extends StatefulWidget {
  final bool showMapView;
  const HybridSearchTabView({super.key, required this.showMapView});

  @override
  State<HybridSearchTabView> createState() => _HybridSearchTabViewState();
}

class _HybridSearchTabViewState extends State<HybridSearchTabView> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String _searchFocus = 'balanced'; // 'balanced', 'correspondent', 'expert_opinion'
  bool _searchingFirms = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    
    final params = SearchParams(
      query: query.isNotEmpty ? query : null,
      preset: _searchFocus,
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      includeFirms: _searchingFirms,
    );
    
    context.read<SearchBloc>().add(SearchRequested(params));
  }

  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
    });
    _handleSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header de busca
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: Column(
            children: [
              // Campo de busca principal
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, OAB, especialidade...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _handleSearch(),
              ),
              const SizedBox(height: 12),
              
              // Ferramentas de precisão
              Row(
                children: [
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
                        DropdownMenuItem(value: 'balanced', child: Text('Equilibrado')),
                        DropdownMenuItem(value: 'correspondent', child: Text('Correspondente')),
                        DropdownMenuItem(value: 'expert_opinion', child: Text('Parecer Técnico')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _searchFocus = value);
                          _handleSearch();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: LocationPicker(
                      onLocationSelected: (location, address) {
                        setState(() {
                          _selectedLocation = location;
                        });
                        _handleSearch();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Switch para incluir escritórios e botão para limpar localização
              Row(
                children: [
                  Switch(
                    value: _searchingFirms,
                    onChanged: (value) {
                      setState(() => _searchingFirms = value);
                      _handleSearch();
                    },
                  ),
                  const Text('Incluir escritórios'),
                  const Spacer(),
                  if (_selectedLocation != null)
                    TextButton.icon(
                      onPressed: _clearLocation,
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Limpar Local'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Resultados
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SearchError) {
                return _buildErrorState(context, state.message);
              }
              if (state is SearchLoaded) {
                final lawyers = state.results.whereType<Lawyer>().toList();
                final firms = state.results.whereType<LawFirm>().toList();

                // Usa o estado de visualização recebido via widget
                if (widget.showMapView) {
                  // Chama o método centralizado do widget pai
                  return (context.findAncestorStateOfType<_LawyersViewState>())!
                      ._buildMapView(lawyers, firms);
                }

                if (state.results.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return PartnerSearchResultList(
                  lawyers: lawyers,
                  firms: firms,
                  emptyMessage: 'Nenhum resultado encontrado.\nTente usar termos diferentes.',
                  onRefresh: _handleSearch,
                );
              }
              return _buildInitialState(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado.\nTente usar termos diferentes.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Busque Advogados e Escritórios',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Use os campos acima para encontrar o parceiro ideal.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
            'Erro na Busca',
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
            onPressed: _handleSearch,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  // O método _buildMapView foi removido daqui e centralizado em _LawyersViewState
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