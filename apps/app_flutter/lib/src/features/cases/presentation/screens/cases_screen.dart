import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/contextual_case_card.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/contextual_case_bloc.dart';

import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/injection_container.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/shared/widgets/instrumented_widgets.dart';
import '../widgets/case_search_dialog.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<CasesBloc>()..add(FetchCases()),
        ),
        BlocProvider(
          create: (context) => getIt<ContextualCaseBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Casos'),
          centerTitle: true,
          actions: [
            BlocBuilder<CasesBloc, CasesState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () => _showSearchDialog(context),
                  icon: Icon(
                    state is CasesLoaded && state.isSearchMode
                        ? LucideIcons.searchX
                        : LucideIcons.search,
                  ),
                  tooltip: state is CasesLoaded && state.isSearchMode
                      ? 'Limpar busca'
                      : 'Buscar casos',
                );
              },
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<AuthBloc, auth_states.AuthState>(
          builder: (context, authState) {
            if (authState is! auth_states.Authenticated) {
              return const SizedBox.shrink();
            }
            
            // Para advogados autônomos, mostrar botão de buscar parcerias
            if (authState.user.role == 'lawyer_individual') {
              return InstrumentedActionButton(
                actionType: 'search_partnerships',
                elementId: 'fab_search_partnerships',
                context: 'cases_screen',
                onPressed: () => context.go('/partners'),
                additionalData: const {
                  'screen': 'cases_list',
                  'action': 'search_partnerships',
                },
                child: const FloatingActionButton.extended(
                  onPressed: null, // Handled by InstrumentedActionButton
                  label: Text('Buscar Parcerias'),
                  icon: Icon(LucideIcons.search),
                ),
              );
            }
            
            // Para outros usuários que podem criar casos
            if (_canCreateCases(authState.user.role)) {
              return InstrumentedActionButton(
                actionType: 'create_case',
                elementId: 'fab_new_case',
                context: 'cases_screen',
                onPressed: () => context.go('/triage'),
                additionalData: const {
                  'screen': 'cases_list',
                  'action': 'start_triage',
                },
                child: const FloatingActionButton.extended(
                  onPressed: null, // Handled by InstrumentedActionButton
                  label: Text('Criar Novo Caso'),
                  icon: Icon(LucideIcons.plus),
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            _buildSearchHeader(),
            Expanded(
              child: BlocBuilder<CasesBloc, CasesState>(
                builder: (context, state) {
                  AppLogger.info('CasesScreen: Estado atual - ${state.runtimeType}');
                  
                  if (state is CasesLoading || state is CasesInitial) {
                    AppLogger.info('CasesScreen: Mostrando loading');
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CasesError) {
                    AppLogger.error('CasesScreen: Erro - ${state.message}');
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
                    AppLogger.info('CasesScreen: ${state.filteredCases.length} casos carregados');
                    if (state.filteredCases.isEmpty) {
                      AppLogger.info('CasesScreen: Nenhum caso encontrado');
                      return _buildEmptyState(state.activeFilter);
                    }
                    return BlocBuilder<AuthBloc, auth_states.AuthState>(
                      builder: (context, authState) {
                        return InstrumentedListView(
                          listId: 'cases_list_main',
                          listType: 'list',
                          contentType: 'cases',
                          sourceContext: 'cases_screen',
                          totalItems: state.filteredCases.length,
                          additionalData: {
                            'filter_type': state.activeFilter.toString(),
                            'user_role': authState is auth_states.Authenticated ? authState.user.role : 'unknown',
                            'has_cases': state.filteredCases.isNotEmpty,
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.filteredCases.length,
                            itemBuilder: (context, index) {
                            final caseData = state.filteredCases[index];
                            AppLogger.info('CasesScreen: Renderizando caso ${index + 1}: ${caseData.title}');
                            
                            // Determinar tipo de card baseado no usuário
                            if (authState is auth_states.Authenticated) {
                              return _buildUserSpecificCaseCard(context, caseData, authState.user);
                            }
                            
                            // Default CaseCard para usuários não autenticados (fallback)
                            return CaseCard(
                              caseId: caseData.id,
                              title: caseData.title,
                              subtitle: 'Status: ${caseData.status}',
                              clientType: 'PF',
                              status: caseData.status,
                              preAnalysisDate: caseData.createdAt.toIso8601String(),
                              lawyer: caseData.lawyer,
                              caseData: caseData,
                            );
                          },
                          ),
                        );
                      },
                    );
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
        ],
      ),
    );
  }

  bool _isLawyer(String? role) {
    return role != null && (
      role == 'lawyer_firm_member' ||     // Advogado associado da firma
      role == 'lawyer_individual' ||      // Advogado autônomo
      role == 'firm' ||                   // Escritório
      role == 'super_associate'           // Super associado da plataforma
    );
  }

  /// Determina se o usuário pode criar novos casos
  /// Advogados autônomos NÃO podem criar casos, apenas buscar parcerias
  bool _canCreateCases(String? role) {
    if (role == null) return false;
    
    switch (role) {
      case 'lawyer_firm_member':          // Advogado associado da firma
      case 'firm':                        // Escritório
      case 'super_associate':             // Super associado da plataforma
        return true; // Podem criar casos
      case 'lawyer_individual':
        return false; // Advogados autônomos NÃO podem criar casos
      case 'client':
      case 'client_pf':
      case 'client_pj':
        return true; // Clientes podem criar casos
      default:
        return false;
    }
  }

  Widget _buildUserSpecificCaseCard(BuildContext context, dynamic caseData, dynamic user) {
    // Debug logs detalhados
    AppLogger.info('=== DEBUGGING USER SPECIFIC CARD ===');
    AppLogger.info('User ID: ${user.id}');
    AppLogger.info('User role: ${user.role}');
    AppLogger.info('User effectiveUserRole: ${user.effectiveUserRole}');
    AppLogger.info('User isClient: ${user.isClient}');
    AppLogger.info('User isIndividualLawyer: ${user.isIndividualLawyer}');
    AppLogger.info('User isAssociatedLawyer: ${user.isAssociatedLawyer}');
    AppLogger.info('User isLawOffice: ${user.isLawOffice}');
    AppLogger.info('User isPlatformAssociate: ${user.isPlatformAssociate}');
    AppLogger.info('Case ID: ${caseData.id}');
    AppLogger.info('Case title: ${caseData.title}');
    AppLogger.info('Case allocationType: ${caseData.allocationType}');
    AppLogger.info('_isLawyer(user.role): ${_isLawyer(user.role)}');
    
    // Clientes sempre veem CaseCard simples
    if (user.isClient) {
      AppLogger.info('RESULTADO: Renderizando CaseCard para cliente');
      return CaseCard(
        caseId: caseData.id,
        title: caseData.title,
        subtitle: 'Status: ${caseData.status}',
        clientType: 'PF', // TODO: Obter do caso
        status: caseData.status,
        preAnalysisDate: caseData.createdAt.toIso8601String(),
        lawyer: caseData.lawyer,
        caseData: caseData,
      );
    }
    
    // Advogados veem cards contextuais
    if (_isLawyer(user.role)) {
      AppLogger.info('RESULTADO: Renderizando ContextualCaseCard para advogado');
      return _buildContextualCaseCard(context, caseData, user);
    }
    
    // Fallback para outros tipos de usuário
    AppLogger.info('RESULTADO: Renderizando CaseCard fallback');
    return CaseCard(
      caseId: caseData.id,
      title: caseData.title,
      subtitle: 'Status: ${caseData.status}',
      clientType: 'PF',
      status: caseData.status,
      preAnalysisDate: caseData.createdAt.toIso8601String(),
      lawyer: caseData.lawyer,
      caseData: caseData,
    );
  }

  Widget _buildContextualCaseCard(BuildContext context, dynamic caseData, dynamic user) {
    return BlocBuilder<ContextualCaseBloc, ContextualCaseState>(
      builder: (context, contextualState) {
        // Load contextual data if not already loaded
        if (contextualState is ContextualCaseInitial) {
          context.read<ContextualCaseBloc>().add(
            LoadContextualCaseData(
              caseId: caseData.id,
              userId: user.id,
            ),
          );
        }

        // If contextual data is available, use the specialized card
        if (contextualState is ContextualCaseLoaded) {
          final contextualData = contextualState.contextualData;
          
          // Use the factory to create the appropriate card type
          return ContextualCaseCardFactory.create(
            caseData: caseData,
            contextualData: contextualData,
            kpis: contextualState.kpis,
            actions: contextualState.actions,
            highlight: contextualState.highlight,
            currentUser: user,
            onActionTap: (action) {
              _handleContextualAction(context, action, caseData.id);
            },
          );
        }
        
        // Fallback to regular CaseCard while loading or on error
        return CaseCard(
          caseId: caseData.id,
          title: caseData.title,
          subtitle: 'Status: ${caseData.status}',
          clientType: 'PF',
          status: caseData.status,
          preAnalysisDate: caseData.createdAt.toIso8601String(),
          lawyer: caseData.lawyer,
          caseData: caseData,
        );
      },
    );
  }

  void _handleContextualAction(BuildContext context, String action, String caseId) {
    switch (action) {
      case 'view_details':
        context.push('/case-detail/$caseId');
        break;
      case 'accept_case':
        // Handle case acceptance
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caso aceito com sucesso!')),
        );
        break;
      case 'log_hours':
        // Handle hour logging
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrando horas...')),
        );
        break;
      case 'update_status':
        // Handle status update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status atualizado!')),
        );
        break;
      default:
        context.push('/case-detail/$caseId');
    }
  }

  Widget _buildSearchHeader() {
    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, state) {
        if (state is CasesLoaded && state.isSearchMode) {
          return Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resultados da Busca',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showSearchDialog(context),
                          icon: const Icon(LucideIcons.edit),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => context.read<CasesBloc>().add(ClearCaseSearch()),
                          icon: const Icon(LucideIcons.x),
                          label: const Text('Limpar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.filteredCases.length} caso${state.filteredCases.length != 1 ? 's' : ''} encontrado${state.filteredCases.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (state.searchFilters?.hasActiveFilters == true) ...[
                      const SizedBox(height: 12),
                      _buildActiveFilters(state.searchFilters!),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActiveFilters(CaseSearchFilters filters) {
    final activeFilters = <String>[];
    
    if (filters.searchQuery != null) {
      activeFilters.add('Busca: "${filters.searchQuery}"');
    }
    if (filters.status != null) {
      activeFilters.add('Status: ${filters.status}');
    }
    if (filters.category != null) {
      activeFilters.add('Categoria: ${filters.category}');
    }
    if (filters.priority != null) {
      activeFilters.add('Prioridade: ${filters.priority}');
    }
    if (filters.clientName != null) {
      activeFilters.add('Cliente: ${filters.clientName}');
    }
    if (filters.lawyerName != null) {
      activeFilters.add('Advogado: ${filters.lawyerName}');
    }
    if (filters.dateFrom != null || filters.dateTo != null) {
      String dateFilter = 'Data: ';
      if (filters.dateFrom != null) {
        dateFilter += 'de ${_formatDate(filters.dateFrom!)} ';
      }
      if (filters.dateTo != null) {
        dateFilter += 'até ${_formatDate(filters.dateTo!)}';
      }
      activeFilters.add(dateFilter.trim());
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: activeFilters.map((filter) => 
        Chip(
          label: Text(filter),
          deleteIcon: const Icon(LucideIcons.x, size: 14),
        )
      ).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showSearchDialog(BuildContext context) {
    final state = context.read<CasesBloc>().state;
    CaseSearchFilters? currentFilters;
    
    if (state is CasesLoaded && state.isSearchMode) {
      // Se já está em modo de busca, limpar a busca
      context.read<CasesBloc>().add(ClearCaseSearch());
      return;
    }
    
    if (state is CasesLoaded) {
      currentFilters = state.searchFilters;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => CaseSearchDialog(
        initialFilters: currentFilters,
        onSearch: (filters) {
          context.read<CasesBloc>().add(SearchCases(filters));
        },
      ),
    );
  }
}
