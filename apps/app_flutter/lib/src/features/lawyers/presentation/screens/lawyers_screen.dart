import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/features/search/presentation/widgets/lawyer_search_form.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_match_card.dart';
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

class LawyersScreen extends StatefulWidget {
  const LawyersScreen({super.key});

  @override
  State<LawyersScreen> createState() => _LawyersScreenState();
}

class _LawyersScreenState extends State<LawyersScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnalyticsService _analytics;
  DateTime? _screenEnterTime;

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
          children: const [
            // Aba de busca
            _SearchTab(),
            // Aba de recomendações com presets
            _RecommendationsTab(),
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

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          LawyerSearchForm(),
          SizedBox(height: 16),
          Expanded(
            child: _SearchResults(),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        if (state is MatchesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is MatchesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao buscar advogados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Tentar novamente a busca
                  },
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }
        
        if (state is MatchesLoaded) {
          if (state.matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.searchX,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum advogado encontrado',
                    style: Theme.of(context).textTheme.titleMedium,
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
          
          return ListView.builder(
            itemCount: state.matches.length,
            itemBuilder: (context, index) {
              final match = state.matches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LawyerMatchCard(lawyer: match),
              );
            },
          );
        }
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.search,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Busque por advogados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Use os filtros acima para encontrar o advogado ideal',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
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