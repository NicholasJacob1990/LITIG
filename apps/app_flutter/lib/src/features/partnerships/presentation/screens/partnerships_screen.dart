import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/hybrid_partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/hybrid_partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/hybrid_partnerships_state.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/hybrid_partnerships_list.dart';
import 'package:meu_app/src/shared/widgets/molecules/empty_state_widget.dart';
import '../../../../shared/services/analytics_service.dart';

class PartnershipsScreen extends StatefulWidget {
  const PartnershipsScreen({super.key});

  @override
  State<PartnershipsScreen> createState() => _PartnershipsScreenState();
}

class _PartnershipsScreenState extends State<PartnershipsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all';
  Timer? _debounce;
  late AnalyticsService _analytics;
  DateTime? _screenEnterTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnalytics();
    _setupTabTracking();
    _screenEnterTime = DateTime.now();
    
    // Carregar parcerias híbridas ao inicializar
    context.read<HybridPartnershipsBloc>().add(const LoadHybridPartnerships());
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
      'partnerships_screen',
      additionalData: {
        'screen_type': 'partnerships_management',
        'has_tab_navigation': true,
        'tab_count': 3,
        'initial_tab': 'active',
      },
    );
  }

  void _trackTabChange(int tabIndex) {
    final tabNames = ['active', 'pending', 'history'];
    final tabName = tabIndex < tabNames.length ? tabNames[tabIndex] : 'unknown';
    
    _analytics.trackUserClick(
      'tab_navigation',
      'partnerships_screen',
      additionalData: {
        'from_tab': _tabController.previousIndex,
        'to_tab': tabIndex,
        'tab_name': tabName,
        'time_on_previous_tab': _getTimeOnCurrentTab(),
        'current_filter': _currentFilter,
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
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Parcerias'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterModal(context),
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchModal(context),
            tooltip: 'Buscar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nova Parceria',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'lawyer',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Parceria com Advogado'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'firm',
                child: ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Parceria B2B (Escritório)'),
                  dense: true,
                ),
              ),
            ],
            onSelected: (value) => _handleNewPartnership(value),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Ativas',
            ),
            Tab(
              icon: Icon(Icons.send),
              text: 'Enviadas',
            ),
            Tab(
              icon: Icon(Icons.inbox),
              text: 'Recebidas',
            ),
          ],
        ),
      ),
      body: BlocBuilder<HybridPartnershipsBloc, HybridPartnershipsState>(
        builder: (context, state) {
          if (state is HybridPartnershipsLoading || state is HybridPartnershipsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is HybridPartnershipsError) {
            return _buildErrorState(state.message);
          }
          
          if (state is HybridPartnershipsLoaded) {
            final hasPartnerships = state.lawyerPartnerships.isNotEmpty || 
                                  state.firmPartnerships.isNotEmpty;
            
            if (!hasPartnerships) {
              return _buildEmptyState();
            }
            
            return TabBarView(
              controller: _tabController,
              children: [
                _buildPartnershipsList(
                  state, 
                  HybridPartnershipsListType.active,
                  'Parcerias ativas, mostrando advogados e escritórios.',
                ),
                _buildPartnershipsList(
                  state, 
                  HybridPartnershipsListType.sent,
                  'Propostas de parceria enviadas por você.',
                ),
                _buildPartnershipsList(
                  state, 
                  HybridPartnershipsListType.received,
                  'Propostas de parceria recebidas.',
                ),
              ],
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToPartnersSearch(),
        icon: const Icon(Icons.explore),
        label: const Text('Buscar Parceiros'),
      ),
    );
  }

  Widget _buildPartnershipsList(
    HybridPartnershipsLoaded state, 
    HybridPartnershipsListType type,
    String semanticLabel,
  ) {
    return Semantics(
      label: semanticLabel,
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<HybridPartnershipsBloc>().add(const LoadHybridPartnerships(refresh: true));
        },
        child: HybridPartnershipsList(
          lawyerPartnerships: state.lawyerPartnerships,
          firmPartnerships: state.firmPartnerships,
          listType: type,
          onRefresh: () async {
            context.read<HybridPartnershipsBloc>().add(const LoadHybridPartnerships(refresh: true));
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<HybridPartnershipsBloc>().add(const LoadHybridPartnerships(refresh: true));
              },
              child: const Text('Tentar Novamente'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.handshake_outlined,
      message: 'Nenhuma parceria encontrada.\nComece criando parcerias com advogados ou escritórios.',
      actionText: 'Buscar Parceiros',
      onActionPressed: () => _navigateToPartnersSearch(),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros de Parceria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('all', 'Todas as Parcerias', Icons.list),
            _buildFilterOption('active', 'Apenas Ativas', Icons.check_circle),
            _buildFilterOption('high_performance', 'Alta Performance (Escritórios)', Icons.trending_up),
            _buildFilterOption('large_firm', 'Grandes Escritórios', Icons.business),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (_currentFilter != 'all') {
                    context.read<HybridPartnershipsBloc>().add(
                      FilterHybridPartnershipsByStatus(_currentFilter),
                    );
                  } else {
                    context.read<HybridPartnershipsBloc>().add(
                      const LoadHybridPartnerships(refresh: true),
                    );
                  }
                },
                child: const Text('Aplicar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _currentFilter,
      onChanged: (newValue) {
        setState(() {
          _currentFilter = newValue!;
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Parcerias'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Digite para buscar...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onChanged: _onSearchChanged,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        context.read<HybridPartnershipsBloc>().add(SearchHybridPartnerships(query));
      } else {
        // Opcional: recarregar a lista original se a busca for limpa
        context.read<HybridPartnershipsBloc>().add(const LoadHybridPartnerships(refresh: true));
      }
    });
  }

  void _handleNewPartnership(String type) {
    switch (type) {
      case 'lawyer':
        // TODO: Navegar para criação de parceria com advogado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade: Nova parceria com advogado')),
        );
        break;
      case 'firm':
        // TODO: Navegar para criação de parceria B2B
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade: Nova parceria B2B')),
        );
        break;
    }
  }

  void _navigateToPartnersSearch() {
    // TODO: Implementar navegação para busca de parceiros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando para busca de parceiros...')),
    );
  }
} 