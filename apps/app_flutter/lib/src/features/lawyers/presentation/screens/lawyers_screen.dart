import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/features/search/presentation/widgets/lawyer_search_form.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_match_card.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_match_list.dart';
import 'package:meu_app/injection_container.dart';

class LawyersScreen extends StatefulWidget {
  const LawyersScreen({super.key});

  @override
  State<LawyersScreen> createState() => _LawyersScreenState();
}

class _LawyersScreenState extends State<LawyersScreen> with TickerProviderStateMixin {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<MatchesBloc>(
          create: (context) => getIt<MatchesBloc>(),
        ),
        BlocProvider<HybridMatchBloc>(
          create: (context) => getIt<HybridMatchBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar Advogados'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(LucideIcons.search),
                text: 'Buscar',
              ),
              Tab(
                icon: Icon(LucideIcons.users),
                text: 'Matches',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            // Aba de busca
            _SearchTab(),
            // Aba de matches
            _MatchesTab(),
          ],
        ),
      ),
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

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HybridMatchBloc, HybridMatchState>(
      builder: (context, state) {
        if (state is HybridMatchLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is HybridMatchError) {
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
                  'Erro ao carregar matches',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (state is HybridMatchLoaded) {
          // Usar HybridMatchList que suporta tanto advogados quanto escritórios
          return HybridMatchList(
            lawyers: state.lawyers,
            firms: state.firms,
            showSectionHeaders: true,
            emptyMessage: 'Complete seu perfil para receber matches personalizados',
            onRefresh: () {
              // Recarregar matches
              context.read<HybridMatchBloc>().add(
                const RefreshHybridMatches(caseId: 'current_case_id')
              );
            },
          );
        }
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Matches Inteligentes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Baseados no seu perfil e necessidades',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}