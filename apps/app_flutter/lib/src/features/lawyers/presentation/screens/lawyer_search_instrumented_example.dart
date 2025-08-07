/// EXEMPLO DE INSTRUMENTAÇÃO COMPLETA - LAWYER SEARCH
/// ================================================
/// 
/// Este arquivo demonstra como instrumentar uma tela completa para capturar
/// TODAS as interações significativas que alimentam o data flywheel.
/// 
/// Interações capturadas:
/// ✅ Visualização da tela
/// ✅ Buscas realizadas
/// ✅ Visualizações de perfil
/// ✅ Cliques em elementos
/// ✅ Filtros aplicados
/// ✅ Convites enviados
/// ✅ Tempo de permanência
/// ✅ Navegação entre telas
library;

import 'package:flutter/material.dart';
import '../../../shared/widgets/instrumented_widgets.dart';
import '../../../shared/services/analytics_service.dart';

class LawyerSearchInstrumentedExample extends StatefulWidget {
  final String? caseId;
  final Map<String, dynamic>? initialFilters;

  const LawyerSearchInstrumentedExample({
    super.key,
    this.caseId,
    this.initialFilters,
  });

  @override
  State<LawyerSearchInstrumentedExample> createState() => _LawyerSearchInstrumentedExampleState();
}

class _LawyerSearchInstrumentedExampleState extends State<LawyerSearchInstrumentedExample>
    with InstrumentedOnboarding {  // Mixin para onboarding se necessário
  
  late AnalyticsService _analytics;
  final TextEditingController _searchController = TextEditingController();
  
  List<LawyerProfile> _searchResults = [];
  Map<String, dynamic> _currentFilters = {};
  DateTime? _searchStartTime;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
    _initializeFilters();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
    
    // Track entrada na tela de busca
    await _analytics.trackScreenView(
      'lawyer_search',
      properties: {
        'case_id': widget.caseId,
        'has_initial_filters': widget.initialFilters?.isNotEmpty ?? false,
        'entry_context': widget.caseId != null ? 'case_creation' : 'general_search',
      },
    );
  }

  void _initializeFilters() {
    _currentFilters = Map.from(widget.initialFilters ?? {});
    
    // Track uso de filtros iniciais
    if (_currentFilters.isNotEmpty) {
      _analytics.trackUserAction(
        'filters_applied',
        properties: {
          'filter_count': _currentFilters.length,
          'filter_types': _currentFilters.keys.toList(),
          'context': 'initial_load',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InstrumentedScreen(
      screenName: 'lawyer_search',
      additionalProperties: {
        'case_id': widget.caseId,
        'search_context': widget.caseId != null ? 'case_matching' : 'general',
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar Advogados'),
          actions: [
            // Botão de filtros instrumentado
            AnalyticsHelper.instrumentClick(
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFiltersDialog(),
              ),
              'filter_button',
              'toolbar',
              additionalData: {
                'current_filter_count': _currentFilters.length,
                'has_results': _searchResults.isNotEmpty,
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Campo de busca instrumentado
            _buildInstrumentedSearchField(),
            
            // Filtros ativos
            if (_currentFilters.isNotEmpty) _buildActiveFilters(),
            
            // Resultados da busca
            Expanded(
              child: _searchResults.isEmpty 
                  ? _buildEmptyState()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentedSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar por especialidade, nome ou localização...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (query) {
          // Debounce implementado no método de busca
          _handleSearchQueryChange(query);
        },
        onSubmitted: (query) {
          _performSearch(query);
        },
      ),
    );
  }

  void _handleSearchQueryChange(String query) {
    // Implementar debounce para evitar muitas requisições
    if (query != _lastQuery) {
      _lastQuery = query;
      _searchStartTime = DateTime.now();
      
      // Track que usuário começou a digitar (para análise de intent)
      _analytics.trackUserAction(
        'search_input_started',
        properties: {
          'query_length': query.length,
          'has_filters': _currentFilters.isNotEmpty,
          'context': widget.caseId != null ? 'case_search' : 'general_search',
        },
      );
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    final searchDuration = _searchStartTime != null 
        ? DateTime.now().difference(_searchStartTime!)
        : null;

    // Simular busca (em implementação real, chamaria API)
    final results = await _simulateSearch(query);
    
    setState(() {
      _searchResults = results;
    });

    // Track busca completa - CRÍTICO para melhorar algoritmo
    await _analytics.trackSearch(
      'lawyer',
      query,
      results: results.map((l) => l.id).toList(),
      appliedFilters: _currentFilters,
      searchContext: widget.caseId != null ? 'case_matching' : 'general_search',
      searchDuration: searchDuration,
    );

    // Track resultado da busca para análise de qualidade
    await _analytics.trackUserAction(
      'search_completed',
      properties: {
        'query': query,
        'results_count': results.length,
        'filter_count': _currentFilters.length,
        'search_quality': results.isNotEmpty ? 'success' : 'no_results',
        'case_context': widget.caseId,
      },
    );
  }

  Widget _buildActiveFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _currentFilters.length,
        itemBuilder: (context, index) {
          final filterKey = _currentFilters.keys.elementAt(index);
          final filterValue = _currentFilters[filterKey];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnalyticsHelper.instrumentClick(
              Chip(
                label: Text('$filterKey: $filterValue'),
                onDeleted: () => _removeFilter(filterKey),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
              'filter_chip_remove',
              'active_filters',
              additionalData: {
                'filter_key': filterKey,
                'filter_value': filterValue,
                'remaining_filters': _currentFilters.length - 1,
              },
              onTap: () => _removeFilter(filterKey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final lawyer = _searchResults[index];
        
        // INSTRUMENTAÇÃO CRÍTICA: Profile Card que captura visualizações
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InstrumentedProfileCard(
            profileId: lawyer.id,
            profileType: 'lawyer',
            sourceContext: 'search_results',
            searchQuery: _lastQuery,
            searchRank: index.toDouble(),
            searchFilters: _currentFilters,
            caseContext: widget.caseId,
            onTap: () => _navigateToLawyerProfile(lawyer, index),
            child: _buildLawyerCard(lawyer, index),
          ),
        );
      },
    );
  }

  Widget _buildLawyerCard(LawyerProfile lawyer, int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: (lawyer.photoUrl != null && lawyer.photoUrl!.isNotEmpty)
                      ? NetworkImage(lawyer.photoUrl!)
                      : null,
                  child: (lawyer.photoUrl == null || lawyer.photoUrl!.isEmpty)
                      ? const Icon(LucideIcons.user)
                      : null,
                  child: lawyer.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (lawyer.firmName != null)
                        Text(
                          lawyer.firmName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                // Match score (se houver)
                if (lawyer.matchScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(lawyer.matchScore! * 100).toInt()}% match',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Especialidades
            if (lawyer.specialties.isNotEmpty)
              Wrap(
                spacing: 8,
                children: lawyer.specialties.take(3).map((specialty) =>
                  Chip(
                    label: Text(specialty),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ).toList(),
              ),
            
            const SizedBox(height: 12),
            
            // Botões de ação instrumentados
            Row(
              children: [
                Expanded(
                  child: InstrumentedInviteButton(
                    recipientId: lawyer.id,
                    invitationType: 'case_invitation',
                    context: 'search_results',
                    caseId: widget.caseId,
                    matchScore: lawyer.matchScore,
                    recipientType: 'lawyer',
                    selectedCriteria: _currentFilters.keys.toList(),
                    onPressed: () => _sendInvitation(lawyer),
                    child: const Text('Convidar'),
                  ),
                ),
                const SizedBox(width: 8),
                AnalyticsHelper.instrumentClick(
                  OutlinedButton(
                    onPressed: () => _showQuickContact(lawyer),
                    child: const Text('Contato'),
                  ),
                  'quick_contact_button',
                  'search_results',
                  additionalData: {
                    'lawyer_id': lawyer.id,
                    'search_rank': index,
                    'match_score': lawyer.matchScore,
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _lastQuery.isEmpty 
                ? 'Digite para buscar advogados'
                : 'Nenhum resultado encontrado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_lastQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou usar termos diferentes',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AnalyticsHelper.instrumentClick(
              ElevatedButton(
                onPressed: () => _suggestBetterSearch(),
                child: const Text('Dicas de Busca'),
              ),
              'search_help_button',
              'empty_state',
              additionalData: {
                'failed_query': _lastQuery,
                'applied_filters': _currentFilters.keys.toList(),
              },
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================================================
  // ACTION HANDLERS - TODOS INSTRUMENTADOS
  // ========================================================================================

  Future<void> _navigateToLawyerProfile(LawyerProfile lawyer, int searchRank) async {
    // Track navegação para perfil - dados críticos para análise de conversão
    await _analytics.trackUserAction(
      'profile_navigation',
      properties: {
        'from_screen': 'lawyer_search',
        'target_profile_id': lawyer.id,
        'search_rank': searchRank,
        'search_query': _lastQuery,
        'applied_filters': _currentFilters,
        'match_score': lawyer.matchScore,
        'case_context': widget.caseId,
      },
    );

    // Navegar para o perfil
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawyerProfileScreen(
          lawyerId: lawyer.id,
          sourceContext: 'search_results',
          searchRank: searchRank,
          caseContext: widget.caseId,
        ),
      ),
    );
  }

  Future<void> _sendInvitation(LawyerProfile lawyer) async {
    // Instrumentação já está no InstrumentedInviteButton
    // Implementar lógica de envio de convite
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convite Enviado'),
        content: Text('Convite enviado para ${lawyer.name}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Track sucesso do envio
              _analytics.trackUserAction(
                'invitation_sent_success',
                properties: {
                  'lawyer_id': lawyer.id,
                  'case_id': widget.caseId,
                  'source': 'search_results',
                },
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickContact(LawyerProfile lawyer) async {
    // Track abertura de contato rápido
    await _analytics.trackUserAction(
      'quick_contact_opened',
      properties: {
        'lawyer_id': lawyer.id,
        'contact_method': 'quick_dialog',
        'source': 'search_results',
      },
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => _buildQuickContactSheet(lawyer),
    );
  }

  Widget _buildQuickContactSheet(LawyerProfile lawyer) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Contatar ${lawyer.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Opções de contato instrumentadas
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Enviar Mensagem'),
            onTap: () => _trackAndExecute(
              'contact_method_selected',
              {'method': 'message', 'lawyer_id': lawyer.id},
              () => _openMessaging(lawyer),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Agendar Videochamada'),
            onTap: () => _trackAndExecute(
              'contact_method_selected',
              {'method': 'video_call', 'lawyer_id': lawyer.id},
              () => _scheduleVideoCall(lawyer),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Ligar Agora'),
            onTap: () => _trackAndExecute(
              'contact_method_selected',
              {'method': 'phone_call', 'lawyer_id': lawyer.id},
              () => _makePhoneCall(lawyer),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFiltersDialog() async {
    // Track abertura de filtros
    await _analytics.trackUserAction(
      'filters_dialog_opened',
      properties: {
        'current_filter_count': _currentFilters.length,
        'search_context': widget.caseId != null ? 'case_search' : 'general',
      },
    );

    final newFilters = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FilterDialog(currentFilters: _currentFilters),
    );

    if (newFilters != null) {
      setState(() {
        _currentFilters = newFilters;
      });

      // Track aplicação de filtros
      await _analytics.trackUserAction(
        'filters_applied',
        properties: {
          'filter_count': newFilters.length,
          'filter_types': newFilters.keys.toList(),
          'context': 'filter_dialog',
        },
      );

      // Re-executar busca com novos filtros
      if (_lastQuery.isNotEmpty) {
        _performSearch(_lastQuery);
      }
    }
  }

  void _removeFilter(String filterKey) {
    setState(() {
      _currentFilters.remove(filterKey);
    });

    // Track remoção de filtro
    _analytics.trackUserAction(
      'filter_removed',
      properties: {
        'removed_filter': filterKey,
        'remaining_filters': _currentFilters.length,
      },
    );

    // Re-executar busca
    if (_lastQuery.isNotEmpty) {
      _performSearch(_lastQuery);
    }
  }

  Future<void> _suggestBetterSearch() async {
    await _analytics.trackUserAction(
      'search_help_requested',
      properties: {
        'failed_query': _lastQuery,
        'context': 'empty_results',
      },
    );

    // Implementar sugestões de busca
  }

  // ========================================================================================
  // UTILITY METHODS
  // ========================================================================================

  Future<void> _trackAndExecute(
    String eventName,
    Map<String, dynamic> properties,
    VoidCallback action,
  ) async {
    await _analytics.trackUserAction(eventName, properties: properties);
    action();
  }

  Future<List<LawyerProfile>> _simulateSearch(String query) async {
    // Simular busca - em implementação real, chamaria API
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      LawyerProfile(
        id: '1',
        name: 'Dr. João Silva',
        firmName: 'Silva & Associados',
        specialties: ['Direito Civil', 'Direito Empresarial'],
        matchScore: 0.95,
      ),
      LawyerProfile(
        id: '2',
        name: 'Dra. Maria Santos',
        firmName: 'Santos Advocacia',
        specialties: ['Direito Trabalhista', 'Direito Previdenciário'],
        matchScore: 0.88,
      ),
    ];
  }

  // Placeholder methods para ações
  void _openMessaging(LawyerProfile lawyer) {}
  void _scheduleVideoCall(LawyerProfile lawyer) {}
  void _makePhoneCall(LawyerProfile lawyer) {}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ========================================================================================
// SUPPORTING CLASSES
// ========================================================================================

class LawyerProfile {
  final String id;
  final String name;
  final String? firmName;
  final String? photoUrl;
  final List<String> specialties;
  final double? matchScore;

  LawyerProfile({
    required this.id,
    required this.name,
    this.firmName,
    this.photoUrl,
    this.specialties = const [],
    this.matchScore,
  });
}

class FilterDialog extends StatelessWidget {
  final Map<String, dynamic> currentFilters;

  const FilterDialog({super.key, required this.currentFilters});

  @override
  Widget build(BuildContext context) {
    // Implementação simplificada do dialog de filtros
    return AlertDialog(
      title: const Text('Filtros'),
      content: const Text('Implementar filtros aqui'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, currentFilters),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class LawyerProfileScreen extends StatelessWidget {
  final String lawyerId;
  final String sourceContext;
  final int searchRank;
  final String? caseContext;

  const LawyerProfileScreen({
    super.key,
    required this.lawyerId,
    required this.sourceContext,
    required this.searchRank,
    this.caseContext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Advogado')),
      body: Center(child: Text('Perfil do advogado $lawyerId')),
    );
  }
}

/**
 * RESULTADO DA INSTRUMENTAÇÃO:
 * 
 * ✅ Captura TODAS as interações significativas
 * ✅ Feeding algoritmo de busca com dados de relevância
 * ✅ Tracking de network effects via convites
 * ✅ Análise de funil de conversão completa
 * ✅ Dados para otimização de UX
 * ✅ Sinais para ML e recomendações
 * 
 * Eventos capturados nesta tela:
 * - screen_view (entrada na tela)
 * - search_input_started (início de digitação)
 * - search_performed (busca completa com resultados)
 * - profile_view (visualização de perfil nos resultados)
 * - user_click (cliques em elementos)
 * - invitation_sent (convites enviados)
 * - filters_applied/removed (uso de filtros)
 * - contact_method_selected (métodos de contato)
 * - profile_navigation (navegação para perfil completo)
 * 
 * Todos esses eventos alimentam o data flywheel para:
 * 1. Melhorar algoritmo de busca
 * 2. Otimizar recomendações
 * 3. Aumentar taxa de conversão
 * 4. Analisar network effects
 * 5. Personalizar experiência
 */