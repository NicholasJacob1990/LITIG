import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_match_list.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/partners_filters_modal.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_bloc.dart';
import 'package:meu_app/injection_container.dart';

/// Tela de busca de parceiros para advogados contratantes
/// 
/// Permite buscar e filtrar advogados e escritórios para formar parcerias
/// estratégicas, correspondência ou colaboração especializada.
class PartnersSearchScreen extends StatelessWidget {
  const PartnersSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HybridMatchBloc(
          lawyersRepository: getIt(),
          firmsRepository: getIt(),
        )),
        BlocProvider(create: (context) => getIt<FirmBloc>()),
      ],
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Buscar parceiros por padrão (incluindo escritórios)
    context.read<HybridMatchBloc>().add(const FetchHybridMatches(
      caseId: 'partnership_search',
      includeFirms: true,
      preset: 'correspondent', // Preset específico para parcerias
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
    );
  }
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
            showSectionHeaders: true,
            emptyMessage: 'Nenhum parceiro encontrado.\nTente ajustar os filtros de busca.',
            onRefresh: () {
              context.read<HybridMatchBloc>().add(const RefreshHybridMatches(
                caseId: 'partnership_search',
                includeFirms: true,
                preset: 'correspondent',
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
              context.read<HybridMatchBloc>().add(const RefreshHybridMatches(
                caseId: 'partnership_search',
                includeFirms: true,
                preset: 'correspondent',
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
          child: BlocBuilder<HybridMatchBloc, HybridMatchState>(
            builder: (context, state) {
              if (state is HybridMatchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is HybridMatchError) {
                return Center(
                  child: Text('Erro na busca: ${state.message}'),
                );
              }
              
              if (state is HybridMatchLoaded) {
                return HybridMatchList(
                  lawyers: state.lawyers,
                  firms: state.firms,
                  showSectionHeaders: true,
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
    if (query.trim().isEmpty) {
      // Se busca vazia, voltar ao estado inicial
      context.read<HybridMatchBloc>().add(const FetchHybridMatches(
        caseId: 'partnership_search',
        includeFirms: true,
        preset: 'correspondent',
      ));
    } else {
      // Buscar com o termo
      context.read<HybridMatchBloc>().add(SearchHybridMatches(
        query: query,
        includeFirms: true,
      ));
    }
  }
} 