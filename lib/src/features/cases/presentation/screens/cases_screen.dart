import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/contextual_case_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/contextual_case_card.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/injection_container.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<CasesBloc>()..add(FetchCases()),
        ),
        BlocProvider(
          create: (context) => ContextualCaseBloc(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Casos'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings),
              onPressed: () {
                // TODO: Navegar para configurações contextuais
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            _buildContextualToggle(),
            Expanded(
              child: BlocBuilder<CasesBloc, CasesState>(
                builder: (context, state) {
                  if (state is CasesLoading || state is CasesInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CasesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Erro: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<CasesBloc>().add(FetchCases()),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is CasesLoaded) {
                    if (state.filteredCases.isEmpty) {
                      return _buildEmptyState(state.activeFilter);
                    }
                    return _buildCasesList(context, state.filteredCases);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói a lista de casos com componentes contextuais
  Widget _buildCasesList(BuildContext context, List<Case> cases) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final caseData = cases[index];
        
        // Gerar dados contextuais mock para demonstração
        final contextualData = _generateMockContextualData(caseData);
        final kpis = _generateMockKPIs(caseData);
        final actions = _generateMockActions(caseData);
        final highlight = _generateMockHighlight(caseData);
        
        // Mock user - em produção, obter do contexto de autenticação
        final currentUser = User(
          id: 'user_123',
          name: 'Usuário Atual',
          email: 'usuario@exemplo.com',
          role: 'lawyer',
          profilePictureUrl: null,
        );

        return ContextualCaseCard(
          caseData: caseData,
          contextualData: contextualData,
          kpis: kpis,
          actions: actions,
          highlight: highlight,
          currentUser: currentUser,
          onActionTap: (action) => _handleContextualAction(context, caseData.id, action),
        );
      },
    );
  }

  /// Gera dados contextuais mock baseados no caso
  ContextualCaseData _generateMockContextualData(Case caseData) {
    // Lógica para determinar o tipo de alocação baseado no caso
    final allocationType = _determineAllocationType(caseData);
    
    return ContextualCaseData(
      allocationType: allocationType,
      partnerId: allocationType == AllocationType.platformMatchPartnership ? 'partner_123' : null,
      delegatedBy: allocationType == AllocationType.internalDelegation ? 'manager_456' : null,
      matchScore: allocationType == AllocationType.platformMatchDirect ? 0.95 : null,
      responseDeadline: DateTime.now().add(const Duration(hours: 24)),
      contextMetadata: {
        'source': _getSourceFromAllocationType(allocationType),
        'priority': _getPriorityFromCase(caseData),
        'created_at': caseData.createdAt.toIso8601String(),
      },
    );
  }

  /// Determina o tipo de alocação baseado no caso
  AllocationType _determineAllocationType(Case caseData) {
    // Lógica mock - em produção, isso viria do banco de dados
    if (caseData.status == 'Em Andamento') {
      return AllocationType.platformMatchDirect;
    } else if (caseData.status == 'Aguardando') {
      return AllocationType.platformMatchPartnership;
    } else {
      return AllocationType.partnershipProactiveSearch;
    }
  }

  /// Gera KPIs mock baseados no caso
  List<ContextualKPI> _generateMockKPIs(Case caseData) {
    final allocationType = _determineAllocationType(caseData);
    
    switch (allocationType) {
      case AllocationType.platformMatchDirect:
        return [
          ContextualKPI(
            id: 'conversion_rate',
            label: 'Taxa de Conversão',
            value: '85%',
            trend: 'up',
            description: 'Matches aceitos vs oferecidos',
          ),
          ContextualKPI(
            id: 'response_time',
            label: 'Tempo de Resposta',
            value: '2h',
            trend: 'stable',
            description: 'Tempo médio de resposta',
          ),
        ];
      case AllocationType.platformMatchPartnership:
        return [
          ContextualKPI(
            id: 'partnership_success',
            label: 'Sucesso em Parcerias',
            value: '92%',
            trend: 'up',
            description: 'Taxa de sucesso em parcerias',
          ),
        ];
      default:
        return [
          ContextualKPI(
            id: 'proactive_success',
            label: 'Busca Proativa',
            value: '78%',
            trend: 'stable',
            description: 'Sucesso em buscas proativas',
          ),
        ];
    }
  }

  /// Gera ações mock baseadas no caso
  ContextualActions _generateMockActions(Case caseData) {
    final allocationType = _determineAllocationType(caseData);
    
    switch (allocationType) {
      case AllocationType.platformMatchDirect:
        return ContextualActions(
          primary: [
            ContextualAction(id: 'accept', label: 'Aceitar Caso', icon: 'check'),
            ContextualAction(id: 'negotiate', label: 'Negociar', icon: 'chat'),
          ],
          secondary: [
            ContextualAction(id: 'delegate', label: 'Delegar', icon: 'person_add'),
            ContextualAction(id: 'reject', label: 'Rejeitar', icon: 'close'),
          ],
        );
      case AllocationType.platformMatchPartnership:
        return ContextualActions(
          primary: [
            ContextualAction(id: 'view_partnership', label: 'Ver Parceria', icon: 'users'),
            ContextualAction(id: 'contact_partner', label: 'Contatar Parceiro', icon: 'phone'),
          ],
          secondary: [
            ContextualAction(id: 'share', label: 'Compartilhar', icon: 'share'),
          ],
        );
      default:
        return ContextualActions(
          primary: [
            ContextualAction(id: 'view_details', label: 'Ver Detalhes', icon: 'info'),
          ],
          secondary: [
            ContextualAction(id: 'edit', label: 'Editar', icon: 'edit'),
          ],
        );
    }
  }

  /// Gera highlight mock baseado no caso
  ContextualHighlight _generateMockHighlight(Case caseData) {
    final allocationType = _determineAllocationType(caseData);
    
    switch (allocationType) {
      case AllocationType.platformMatchDirect:
        return ContextualHighlight(
          text: 'Match Direto - Algoritmo IA',
          color: 'blue',
          priority: 'high',
        );
      case AllocationType.platformMatchPartnership:
        return ContextualHighlight(
          text: 'Via Parceria - Colaboração',
          color: 'green',
          priority: 'medium',
        );
      default:
        return ContextualHighlight(
          text: 'Busca Proativa - Iniciativa',
          color: 'orange',
          priority: 'medium',
        );
    }
  }

  /// Métodos auxiliares para gerar dados contextuais
  String _getSourceFromAllocationType(AllocationType type) {
    switch (type) {
      case AllocationType.platformMatchDirect:
        return 'algorithm';
      case AllocationType.platformMatchPartnership:
        return 'partnership';
      case AllocationType.partnershipProactiveSearch:
        return 'proactive_search';
      case AllocationType.partnershipPlatformSuggestion:
        return 'platform_suggestion';
      case AllocationType.internalDelegation:
        return 'internal_delegation';
    }
  }

  String _getPriorityFromCase(Case caseData) {
    if (caseData.status == 'Em Andamento') return 'high';
    if (caseData.status == 'Aguardando') return 'medium';
    return 'low';
  }

  /// Handler para ações contextuais
  void _handleContextualAction(BuildContext context, String caseId, String action) {
    // Disparar evento no BLoC contextual
    context.read<ContextualCaseBloc>().add(
      ExecuteContextualAction(
        caseId: caseId,
        actionId: action,
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      ),
    );

    // Mostrar feedback ao usuário
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ação "$action" executada para o caso $caseId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Toggle para alternar entre visualização contextual e tradicional
  Widget _buildContextualToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Visualização Contextual',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Switch(
            value: true, // TODO: Implementar estado de toggle
            onChanged: (value) {
              // TODO: Implementar alternância entre visualizações
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection() {
    const filters = ['Todos', 'Em Andamento', 'Concluído', 'Aguardando'];
    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, state) {
        if (state is! CasesLoaded) return const SizedBox(height: 60);

        return SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: state.activeFilter == filter,
                  onSelected: (_) => context.read<CasesBloc>().add(FilterCases(filter)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String activeFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.folderX, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Não há casos com status "$activeFilter"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navegar para tela de nova triagem
            },
            icon: const Icon(LucideIcons.plus),
            label: const Text('Iniciar Nova Consulta'),
          ),
        ],
      ),
    );
  }
} 