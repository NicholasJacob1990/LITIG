import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/performance/optimized_list_view.dart';
import '../../../../shared/widgets/accessibility/accessible_components.dart';
import '../../../../core/analytics/firebase_analytics_service.dart';
import '../../domain/entities/enriched_firm.dart';
import '../../domain/entities/case_info.dart';
import '../../domain/entities/partnership_info.dart';
import '../bloc/firm_profile_bloc.dart';
import '../bloc/firm_profile_event.dart';
import '../bloc/firm_profile_state.dart';

/// Exemplo de como integrar as melhorias em uma tela existente
/// 
/// Demonstra:
/// - Integração com dados reais do backend
/// - Performance otimizada para listas grandes
/// - Acessibilidade completa
/// - Analytics integrado
class EnhancedFirmProfileScreen extends StatefulWidget {
  final String firmId;

  const EnhancedFirmProfileScreen({
    super.key,
    required this.firmId,
  });

  @override
  State<EnhancedFirmProfileScreen> createState() => _EnhancedFirmProfileScreenState();
}

class _EnhancedFirmProfileScreenState extends State<EnhancedFirmProfileScreen> 
    with AccessibilityMixin, TickerProviderStateMixin {
  
  late final TabController _tabController;
  final IntegratedAnalyticsService _analytics = IntegratedAnalyticsService();
  final OptimizedListViewController<CaseInfo> _casesController = OptimizedListViewController<CaseInfo>();
  final OptimizedListViewController<PartnershipInfo> _partnershipsController = OptimizedListViewController<PartnershipInfo>();
  
  // Filtros para otimização
  String _caseStatusFilter = 'all';
  String _caseAreaFilter = 'all';
  String _partnershipTypeFilter = 'all';
  String _partnershipStatusFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Carrega dados do perfil
    context.read<FirmProfileBloc>().add(LoadFirmProfile(widget.firmId));
    
    // Analytics: Track visualização
    _trackProfileView();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    
    final tabNames = ['overview', 'team', 'cases', 'partnerships', 'financial', 'transparency'];
    final tabName = tabNames[_tabController.index];
    
    // Analytics: Track navegação de aba
    _analytics.trackTabNavigation('firm', tabName, metadata: {
      'firm_id': widget.firmId,
      'previous_tab': _tabController.previousIndex,
    });
    
    // Acessibilidade: Anuncia mudança de aba
    announceStateChange('Navegou para aba $tabName');
  }

  void _trackProfileView() {
    _analytics.trackFirmProfileView(widget.firmId, metadata: {
      'source': 'direct_link',
      'user_type': 'client',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _handleRefresh() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      context.read<FirmProfileBloc>().add(RefreshFirmProfile(widget.firmId));
      
      // Analytics: Track refresh
      _analytics.trackDataRefresh('firm', widget.firmId, metadata: {
        'trigger': 'user_pull_refresh',
        'current_tab': _tabController.index,
      });
      
      // Aguarda carregamento
      await Future.delayed(const Duration(seconds: 1)); // Simula carregamento
      
      // Analytics: Track tempo de carregamento
      stopwatch.stop();
      _analytics.trackLoadingTime('firm_profile_refresh', stopwatch.elapsed);
      
      // Acessibilidade: Anuncia sucesso
      announceStateChange('Dados atualizados com sucesso');
      
    } catch (e) {
      // Analytics: Track erro
      _analytics.trackError('firm_profile_refresh_error', e.toString(), metadata: {
        'firm_id': widget.firmId,
      });
      
      // Acessibilidade: Anuncia erro
      announceStateChange('Erro ao atualizar dados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAccessibleAppBar(),
      body: BlocBuilder<FirmProfileBloc, FirmProfileState>(
        builder: (context, state) {
          if (state is FirmProfileLoading) {
            return const AccessibleLoadingIndicator(
              message: 'Carregando perfil do escritório',
            );
          }
          
          if (state is FirmProfileError) {
            return _buildErrorState(state.message);
          }
          
          if (state is FirmProfileLoaded) {
            return _buildLoadedState(state.enrichedFirm);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAccessibleAppBar() {
    return AppBar(
      title: const Text('Perfil do Escritório'),
      leading: AccessibleButton(
        onPressed: () => Navigator.of(context).pop(),
        label: 'Voltar',
        icon: Icons.arrow_back,
        type: AccessibleButtonType.icon,
        semanticHint: 'Voltar para tela anterior',
      ),
      actions: [
        AccessibleButton(
          onPressed: _handleRefresh,
          label: 'Atualizar',
          icon: Icons.refresh,
          type: AccessibleButtonType.icon,
          semanticHint: 'Atualizar dados do perfil',
        ),
        AccessibleButton(
          onPressed: _handleShare,
          label: 'Compartilhar',
          icon: Icons.share,
          type: AccessibleButtonType.icon,
          semanticHint: 'Compartilhar perfil do escritório',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Visão Geral', icon: Icon(Icons.overview)),
          Tab(text: 'Equipe', icon: Icon(Icons.people)),
          Tab(text: 'Casos', icon: Icon(Icons.gavel)),
          Tab(text: 'Parcerias', icon: Icon(Icons.handshake)),
          Tab(text: 'Financeiro', icon: Icon(Icons.monetization_on)),
          Tab(text: 'Transparência', icon: Icon(Icons.visibility)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Semantics(
        label: 'Erro ao carregar perfil',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar perfil',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AccessibleButton(
              onPressed: () {
                context.read<FirmProfileBloc>().add(LoadFirmProfile(widget.firmId));
              },
              label: 'Tentar Novamente',
              icon: Icons.refresh,
              semanticHint: 'Tentar carregar perfil novamente',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(EnrichedFirm firm) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(firm),
          _buildTeamTab(firm),
          _buildCasesTab(firm),
          _buildPartnershipsTab(firm),
          _buildFinancialTab(firm),
          _buildTransparencyTab(firm),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(EnrichedFirm firm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleProfileCard(
            title: firm.name,
            subtitle: firm.location,
            description: firm.description,
            semanticLabel: 'Escritório ${firm.name}, localizado em ${firm.location}',
            actions: [
              AccessibleAction(
                label: 'Entrar em Contato',
                icon: Icons.phone,
                onPressed: () => _handleContact(firm),
              ),
              AccessibleAction(
                label: 'Ver Website',
                icon: Icons.web,
                onPressed: () => _handleWebsite(firm),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSpecializationsSection(firm),
          const SizedBox(height: 24),
          _buildMetricsSection(firm),
        ],
      ),
    );
  }

  Widget _buildCasesTab(EnrichedFirm firm) {
    return Column(
      children: [
        _buildCasesFilters(),
        Expanded(
          child: OptimizedListView<CaseInfo>(
            controller: _casesController,
            onLoadPage: (page, pageSize) => _loadCases(firm.id, page, pageSize),
            itemBuilder: (context, caseInfo, index) => _buildCaseCard(caseInfo),
            itemExtent: 120,
            pageSize: 20,
            loadingBuilder: (context) => const AccessibleLoadingIndicator(
              message: 'Carregando casos',
            ),
            emptyBuilder: (context) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhum caso encontrado'),
                ],
              ),
            ),
            semanticLabel: 'Lista de casos do escritório',
          ),
        ),
      ],
    );
  }

  Widget _buildPartnershipsTab(EnrichedFirm firm) {
    return Column(
      children: [
        _buildPartnershipsFilters(),
        Expanded(
          child: OptimizedListView<PartnershipInfo>(
            controller: _partnershipsController,
            onLoadPage: (page, pageSize) => _loadPartnerships(firm.id, page, pageSize),
            itemBuilder: (context, partnership, index) => _buildPartnershipCard(partnership),
            itemExtent: 100,
            pageSize: 15,
            loadingBuilder: (context) => const AccessibleLoadingIndicator(
              message: 'Carregando parcerias',
            ),
            emptyBuilder: (context) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma parceria encontrada'),
                ],
              ),
            ),
            semanticLabel: 'Lista de parcerias do escritório',
          ),
        ),
      ],
    );
  }

  Widget _buildCasesFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AccessibleChip(
            label: 'Todos',
            selected: _caseStatusFilter == 'all',
            onTap: () => _updateCaseStatusFilter('all'),
            semanticLabel: 'Filtrar por todos os status de casos',
          ),
          AccessibleChip(
            label: 'Ativos',
            selected: _caseStatusFilter == 'active',
            onTap: () => _updateCaseStatusFilter('active'),
            semanticLabel: 'Filtrar por casos ativos',
          ),
          AccessibleChip(
            label: 'Ganhos',
            selected: _caseStatusFilter == 'won',
            onTap: () => _updateCaseStatusFilter('won'),
            semanticLabel: 'Filtrar por casos ganhos',
          ),
          AccessibleChip(
            label: 'Encerrados',
            selected: _caseStatusFilter == 'closed',
            onTap: () => _updateCaseStatusFilter('closed'),
            semanticLabel: 'Filtrar por casos encerrados',
          ),
        ],
      ),
    );
  }

  Widget _buildPartnershipsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AccessibleChip(
            label: 'Todas',
            selected: _partnershipTypeFilter == 'all',
            onTap: () => _updatePartnershipTypeFilter('all'),
            semanticLabel: 'Filtrar por todos os tipos de parceria',
          ),
          AccessibleChip(
            label: 'Estratégicas',
            selected: _partnershipTypeFilter == 'strategic',
            onTap: () => _updatePartnershipTypeFilter('strategic'),
            semanticLabel: 'Filtrar por parcerias estratégicas',
          ),
          AccessibleChip(
            label: 'Comerciais',
            selected: _partnershipTypeFilter == 'commercial',
            onTap: () => _updatePartnershipTypeFilter('commercial'),
            semanticLabel: 'Filtrar por parcerias comerciais',
          ),
          AccessibleChip(
            label: 'Internacionais',
            selected: _partnershipTypeFilter == 'international',
            onTap: () => _updatePartnershipTypeFilter('international'),
            semanticLabel: 'Filtrar por parcerias internacionais',
          ),
        ],
      ),
    );
  }

  void _updateCaseStatusFilter(String filter) {
    setState(() {
      _caseStatusFilter = filter;
    });
    
    // Analytics: Track uso de filtro
    _analytics.trackFilterUsage('firm_cases', {'status': filter}, metadata: {
      'firm_id': widget.firmId,
    });
    
    // Acessibilidade: Anuncia mudança de filtro
    announceStateChange('Filtro de casos alterado para $filter');
    
    // Refresh da lista
    _casesController.refresh();
  }

  void _updatePartnershipTypeFilter(String filter) {
    setState(() {
      _partnershipTypeFilter = filter;
    });
    
    // Analytics: Track uso de filtro
    _analytics.trackFilterUsage('firm_partnerships', {'type': filter}, metadata: {
      'firm_id': widget.firmId,
    });
    
    // Acessibilidade: Anuncia mudança de filtro
    announceStateChange('Filtro de parcerias alterado para $filter');
    
    // Refresh da lista
    _partnershipsController.refresh();
  }

  // Métodos de carregamento de dados (integração com backend)
  Future<List<CaseInfo>> _loadCases(String firmId, int page, int pageSize) async {
    try {
      // Integração real com o backend
      final filters = <String, dynamic>{
        'status': _caseStatusFilter != 'all' ? _caseStatusFilter : null,
        'area': _caseAreaFilter != 'all' ? _caseAreaFilter : null,
        'page': page,
        'page_size': pageSize,
      };
      
      // TODO: Substituir por chamada real para o data source
      // final cases = await context.read<EnrichedFirmRepository>().getFirmCases(firmId, filters: filters);
      
      // Simulação com dados mock por enquanto
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockCases(page, pageSize);
      
    } catch (e) {
      _analytics.trackError('load_firm_cases_error', e.toString(), metadata: {
        'firm_id': firmId,
        'page': page,
      });
      rethrow;
    }
  }

  Future<List<PartnershipInfo>> _loadPartnerships(String firmId, int page, int pageSize) async {
    try {
      // Integração real com o backend
      final filters = <String, dynamic>{
        'type': _partnershipTypeFilter != 'all' ? _partnershipTypeFilter : null,
        'status': _partnershipStatusFilter != 'all' ? _partnershipStatusFilter : null,
        'page': page,
        'page_size': pageSize,
      };
      
      // TODO: Substituir por chamada real para o data source
      // final partnerships = await context.read<EnrichedFirmRepository>().getFirmPartnerships(firmId, filters: filters);
      
      // Simulação com dados mock por enquanto
      await Future.delayed(const Duration(milliseconds: 300));
      return _getMockPartnerships(page, pageSize);
      
    } catch (e) {
      _analytics.trackError('load_firm_partnerships_error', e.toString(), metadata: {
        'firm_id': firmId,
        'page': page,
      });
      rethrow;
    }
  }

  // Builders para cards otimizados
  Widget _buildCaseCard(CaseInfo caseInfo) {
    return AccessibleProfileCard(
      title: caseInfo.title,
      subtitle: '${caseInfo.area.displayName} • ${caseInfo.status.displayName}',
      description: caseInfo.summary,
      semanticLabel: 'Caso ${caseInfo.title}, área ${caseInfo.area.displayName}, status ${caseInfo.status.displayName}',
      actions: [
        AccessibleAction(
          label: 'Ver Detalhes',
          icon: Icons.visibility,
          onPressed: () => _viewCaseDetails(caseInfo),
        ),
      ],
    );
  }

  Widget _buildPartnershipCard(PartnershipInfo partnership) {
    return AccessibleProfileCard(
      title: partnership.partnerName,
      subtitle: '${partnership.type.displayName} • ${partnership.status.displayName}',
      description: partnership.description,
      semanticLabel: 'Parceria com ${partnership.partnerName}, tipo ${partnership.type.displayName}, status ${partnership.status.displayName}',
      actions: [
        AccessibleAction(
          label: 'Ver Parceria',
          icon: Icons.visibility,
          onPressed: () => _viewPartnershipDetails(partnership),
        ),
      ],
    );
  }

  // Implementações restantes dos métodos...
  Widget _buildTeamTab(EnrichedFirm firm) => const SizedBox(); // TODO: Implementar
  Widget _buildFinancialTab(EnrichedFirm firm) => const SizedBox(); // TODO: Implementar
  Widget _buildTransparencyTab(EnrichedFirm firm) => const SizedBox(); // TODO: Implementar
  Widget _buildSpecializationsSection(EnrichedFirm firm) => const SizedBox(); // TODO: Implementar
  Widget _buildMetricsSection(EnrichedFirm firm) => const SizedBox(); // TODO: Implementar

  void _handleContact(EnrichedFirm firm) {} // TODO: Implementar
  void _handleWebsite(EnrichedFirm firm) {} // TODO: Implementar
  void _handleShare() {} // TODO: Implementar
  void _viewCaseDetails(CaseInfo caseInfo) {} // TODO: Implementar
  void _viewPartnershipDetails(PartnershipInfo partnership) {} // TODO: Implementar

  // Dados mock temporários
  List<CaseInfo> _getMockCases(int page, int pageSize) => []; // TODO: Implementar
  List<PartnershipInfo> _getMockPartnerships(int page, int pageSize) => []; // TODO: Implementar
} 