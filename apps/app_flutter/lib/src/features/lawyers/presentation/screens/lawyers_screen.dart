import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/features/search/presentation/widgets/lawyer_search_form.dart';
// import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_match_card.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_bloc.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_event.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_state.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/search/presentation/widgets/partner_search_result_list.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_filters_modal.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/injection_container.dart';

import '../../../../shared/services/analytics_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';

class LawyersScreen extends StatefulWidget {
  const LawyersScreen({super.key});

  @override
  State<LawyersScreen> createState() => _LawyersScreenState();
}

class _LawyersScreenState extends State<LawyersScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnalyticsService _analytics;
  DateTime? _screenEnterTime;
  bool _showMapView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnalytics();
    _setupTabTracking();
    _screenEnterTime = DateTime.now();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
    _trackScreenView();
  }

  void _setupTabTracking() {
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _trackTabChange(_tabController.index);
        setState(() {});
      }
    });
  }

  void _trackScreenView() {
    _analytics.trackUserClick(
      'screen_view',
      'lawyers_screen',
      additionalData: {
        'screen_type': 'main_search',
        'has_tab_navigation': true,
        'tab_count': 2,
        'initial_tab': 'search',
      },
    );
  }

  void _trackTabChange(int tabIndex) {
    final tabNames = ['search', 'recommendations'];
    final tabName = tabIndex < tabNames.length ? tabNames[tabIndex] : 'unknown';
    
    _analytics.trackUserClick(
      'tab_navigation',
      'lawyers_screen',
      additionalData: {
        'from_tab': _tabController.previousIndex,
        'to_tab': tabIndex,
        'tab_name': tabName,
        'time_on_previous_tab': _getTimeOnCurrentTab(),
      },
    );
  }

  Duration _getTimeOnCurrentTab() {
    return _screenEnterTime != null 
        ? DateTime.now().difference(_screenEnterTime!)
        : Duration.zero;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MatchesBloc>(
          create: (context) => getIt<MatchesBloc>(),
        ),
        BlocProvider<SearchBloc>(
          create: (context) => getIt<SearchBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advogados & Escritórios'),
          actions: [
            // Toggle Lista/Mapa visível apenas na aba Buscar (index 0)
            if (_tabController.index == 0)
              IconButton(
                tooltip: _showMapView ? 'Ver lista' : 'Ver mapa',
                icon: Icon(_showMapView ? LucideIcons.list : LucideIcons.map),
                onPressed: () => setState(() => _showMapView = !_showMapView),
              ),
            if (_tabController.index == 1)
              IconButton(
                icon: const Icon(LucideIcons.slidersHorizontal),
                onPressed: () => _showFiltersModal(context),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(LucideIcons.search),
                text: 'Buscar',
              ),
              Tab(
                icon: Icon(LucideIcons.sparkles),
                text: 'Recomendações',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Aba de busca
            _SearchTab(showMapView: _showMapView),
            // Aba de recomendações com presets
            const _RecommendationsTab(),
          ],
        ),
        // Toggle movido para AppBar; não usar FAB
        floatingActionButton: null,
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

class _SearchTab extends StatelessWidget {
  final bool showMapView;

  const _SearchTab({required this.showMapView});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const LawyerSearchForm(),
          const SizedBox(height: 16),
          Expanded(
            child: _SearchResults(showMapView: showMapView),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final bool showMapView;

  const _SearchResults({required this.showMapView});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        // Se o toggle de mapa estiver ativo, sempre renderize o mapa.
        if (showMapView) {
          if (state is SearchLoaded) {
            final lawyers = state.results.whereType<Lawyer>().toList();
            return _buildMapView(context, lawyers);
          }
          // Sem resultados (ainda) ou em erro/carregando: mostra mapa vazio (SP como fallback)
          return _buildMapView(context, const <Lawyer>[]);
        }

        // Lista padrão quando o mapa não está ativo
        if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SearchError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
              ],
            ),
          );
        }
        if (state is SearchLoaded) {
          final lawyers = state.results.whereType<Lawyer>().toList();
          final firms = state.results.whereType<LawFirm>().toList();

          if (lawyers.isEmpty && firms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.searchX, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('Nenhum resultado encontrado. Ajuste os filtros e tente novamente.'),
                ],
              ),
            );
          }

          return PartnerSearchResultList(
            lawyers: lawyers,
            firms: firms,
            emptyMessage: 'Nenhum resultado encontrado.',
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.search, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text('Busque por advogados'),
            ],
          ),
        );
      },
    );
  }
}

extension on _SearchResults {
  Widget _buildMapView(BuildContext context, List<Lawyer> lawyers) {
    final withCoords = lawyers.where((l) => l.latitude != null && l.longitude != null).toList();
    final Set<Marker> markers = withCoords
        .map((l) => Marker(
              markerId: MarkerId('lawyer_${l.id}'),
              position: LatLng(l.latitude!, l.longitude!),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(title: l.name, snippet: 'OAB: ${l.oab}'),
            ))
        .toSet();

    final CameraPosition initial = withCoords.isNotEmpty
        ? CameraPosition(target: LatLng(withCoords.first.latitude!, withCoords.first.longitude!), zoom: 11)
        : const CameraPosition(target: LatLng(-23.5505, -46.6333), zoom: 10);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 6),
              Text('${withCoords.length} Advogados com localização'),
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: initial,
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

class _RecommendationsTab extends StatefulWidget {
  const _RecommendationsTab();

  @override
  State<_RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<_RecommendationsTab> {
  String _selectedPreset = 'balanced';

  @override
  void initState() {
    super.initState();
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
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tipo de Recomendação',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildPresetChip('balanced', 'Recomendado', 'Equilibra experiência e custo', LucideIcons.star),
                  _buildPresetChip('correspondent', 'Melhor Custo', 'Foca em economia', LucideIcons.dollarSign),
                  _buildPresetChip('expert_opinion', 'Mais Experientes', 'Prioriza expertise', LucideIcons.award),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SearchError) {
                return Center(child: Text(state.message));
              }
              if (state is SearchLoaded) {
                final lawyers = state.results.whereType<Lawyer>().toList();
                final firms = state.results.whereType<LawFirm>().toList();
                return PartnerSearchResultList(
                  lawyers: lawyers,
                  firms: firms,
                  emptyMessage: 'Nenhuma recomendação encontrada. Tente outro preset.',
                  onRefresh: _fetchRecommendations,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String value, String title, String subtitle, IconData icon) {
    final bool selected = _selectedPreset == value;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(title),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _selectedPreset = value;
        });
        _fetchRecommendations();
      },
    );
  }
}