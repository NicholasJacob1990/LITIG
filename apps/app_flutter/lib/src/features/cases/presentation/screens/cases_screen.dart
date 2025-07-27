import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/contextual_case_card.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/contextual_case_bloc.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/injection_container.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/utils/logger.dart';

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
          create: (context) => getIt<ContextualCaseBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Casos'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/triage'),
          label: const Text('Criar Novo Caso'),
          icon: const Icon(LucideIcons.plus),
        ),
        body: Column(
          children: [
            _buildFilterSection(),
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
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredCases.length,
                          itemBuilder: (context, index) {
                            final caseData = state.filteredCases[index];
                            AppLogger.info('CasesScreen: Renderizando caso ${index + 1}: ${caseData.title}');
                            
                            // Use ContextualCaseCard for lawyers, CaseCard for clients
                            if (authState is auth_states.Authenticated && _isLawyer(authState.user.role)) {
                              return _buildContextualCaseCard(context, caseData, authState.user);
                            }
                            
                            // Default CaseCard for clients
                            return CaseCard(
                              caseId: caseData.id,
                              title: caseData.title,
                              subtitle: 'Status: ${caseData.status}',
                              clientType: 'PF', // TODO: Obter do caso
                              status: caseData.status,
                              preAnalysisDate: caseData.createdAt.toIso8601String(),
                              lawyer: caseData.lawyer,
                              caseData: caseData, // Passar dados completos do caso
                            );
                          },
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
      role == 'lawyer_firm_member' ||  // Atualizado de lawyer_associated
      role == 'lawyer_individual' ||
      role == 'firm' ||  // Atualizado de lawyer_office
      role == 'super_associate'  // Atualizado de lawyer_platform_associate
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
            kpis: contextualState.kpis ?? [],
            actions: contextualState.actions ?? _getDefaultActions(),
            highlight: contextualState.highlight ?? _getDefaultHighlight(),
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

  // Default actions for when contextual data is not available
  ContextualActions _getDefaultActions() {
    return const ContextualActions(
      primaryAction: ContextualAction(action: 'view_details', label: 'Ver Detalhes'),
      secondaryActions: [],
    );
  }

  // Default highlight for when contextual data is not available
  ContextualHighlight _getDefaultHighlight() {
    return const ContextualHighlight(
      text: 'Caso padrão',
      color: 'blue',
    );
  }
}
