import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_bloc.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_event.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_state.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/partners_filters_modal.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/search/presentation/widgets/partner_search_result_list.dart';
import '../../../../shared/services/analytics_service.dart';

/// Tela de busca de parceiros para advogados contratantes
/// 
/// Permite buscar e filtrar advogados e escritórios para formar parcerias
/// estratégicas, correspondência ou colaboração especializada.
class PartnersSearchScreen extends StatelessWidget {
  const PartnersSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SearchBloc>(),
      child: const PartnersSearchView(),
    );
  }
}

class PartnersSearchView extends StatefulWidget {
  const PartnersSearchView({super.key});

  @override
  State<PartnersSearchView> createState() => _PartnersSearchViewState();
}

class _PartnersSearchViewState extends State<PartnersSearchView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late AnalyticsService _analytics;
  DateTime? _searchStartTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnalytics();
    _setupSearchListeners();
    
    // Buscar parceiros por padrão (incluindo escritórios)
    context.read<SearchBloc>().add(const SearchRequested(
      SearchParams(preset: 'correspondent', includeFirms: true),
    ));
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
  }

  void _setupSearchListeners() {
    _searchController.addListener(() {
      if (_searchStartTime == null && _searchController.text.isNotEmpty) {
        _searchStartTime = DateTime.now();
        _trackSearchStart();
      }
    });
  }

  void _trackSearchStart() {
    _analytics.trackSearch(
      'partners_search',
      _searchController.text,
      results: [], // Will be filled when results arrive
      searchContext: 'partners_search_screen',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchBloc, SearchState>(
      listener: (context, state) {
        if (state is SearchError) {
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
            'Buscar Parceiros',
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
              Tab(
                icon: Icon(LucideIcons.compass),
                text: 'Descobrir',
              ),
              Tab(
                icon: Icon(LucideIcons.search),
                text: 'Buscar',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const PartnersDiscoveryTabView(),
            PartnersSearchTabView(searchController: _searchController),
          ],
        ),
      ),
    );
  }

  void _showFiltersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PartnersFiltersModal(),
    );
  }
}

/// Tab de descoberta de parceiros (recomendações baseadas em perfil)
class PartnersDiscoveryTabView extends StatelessWidget {
  const PartnersDiscoveryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
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

          return PartnerSearchResultList(
            lawyers: lawyers,
            firms: firms,
            emptyMessage: 'Nenhum parceiro encontrado.\nTente ajustar os filtros de busca.',
            onRefresh: () {
              context.read<SearchBloc>().add(const SearchRequested(
                SearchParams(preset: 'correspondent', includeFirms: true),
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
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao buscar parceiros',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<SearchBloc>().add(const SearchRequested(
                SearchParams(preset: 'correspondent', includeFirms: true),
              ));
            },
            child: const Text('Tentar Novamente'),
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
            LucideIcons.userPlus,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum parceiro encontrado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros de busca',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Tab de busca ativa de parceiros
class PartnersSearchTabView extends StatefulWidget {
  final TextEditingController searchController;

  const PartnersSearchTabView({
    super.key,
    required this.searchController,
  });

  @override
  State<PartnersSearchTabView> createState() => _PartnersSearchTabViewState();
}

class _PartnersSearchTabViewState extends State<PartnersSearchTabView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, especialidade ou localização...',
              prefixIcon: const Icon(LucideIcons.search),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        widget.searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
            onSubmitted: _performSearch,
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
                return Center(
                  child: Text('Erro na busca: ${state.message}'),
                );
              }
              
              if (state is SearchLoaded) {
                final lawyers = state.results.whereType<Lawyer>().toList();
                final firms = state.results.whereType<LawFirm>().toList();

                return PartnerSearchResultList(
                  lawyers: lawyers,
                  firms: firms,
                  emptyMessage: 'Nenhum resultado encontrado.\nTente usar termos diferentes.',
                );
              }
              
              return const Center(
                child: Text('Digite algo para buscar parceiros...'),
              );
            },
          ),
        ),
      ],
    );
  }

  void _performSearch(String query) {
    final queryTrimmed = query.trim();
    final params = queryTrimmed.isEmpty
        ? const SearchParams(preset: 'correspondent', includeFirms: true)
        : SearchParams(query: queryTrimmed, includeFirms: true);

    _trackSearchExecution(queryTrimmed);
    context.read<SearchBloc>().add(SearchRequested(params));
  }

  void _trackSearchExecution(String query) {
    final searchDuration = _searchStartTime != null 
        ? DateTime.now().difference(_searchStartTime!) 
        : null;

    _analytics.trackSearch(
      'partners_search',
      query,
      results: [], // Will be filled when results arrive
      searchContext: 'partners_search_screen',
      searchDuration: searchDuration,
      appliedFilters: {
        'search_type': 'correspondent',
        'include_firms': true,
        'current_tab': _tabController.index == 0 ? 'lawyers' : 'firms',
        'is_empty_search': query.isEmpty,
      },
    );

    // Reset search start time for next search
    _searchStartTime = null;
  }
} 