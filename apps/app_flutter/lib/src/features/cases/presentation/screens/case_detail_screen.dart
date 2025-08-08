import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../bloc/case_detail_bloc.dart';
import '../bloc/contextual_case_bloc.dart';
import '../widgets/contextual_case_detail_section_factory.dart';
import '../widgets/lawyer_responsible_section.dart';
import '../widgets/consultation_info_section.dart';
import '../widgets/pre_analysis_section.dart';
import '../widgets/next_steps_section.dart';
import '../widgets/documents_section.dart';
import '../widgets/process_status_section.dart';
import '../widgets/sections/case_chat_section.dart';
import '../../../../shared/utils/app_colors.dart';
import 'package:meu_app/src/features/cases/domain/entities/process_status.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/case_detail.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' as auth_states;
import '../../../../core/utils/logger.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/privacy_cases_bloc.dart';
import 'package:meu_app/injection_container.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({super.key, required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CaseDetailBloc()..add(LoadCaseDetail(caseId)),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          ],
          title: BlocBuilder<CaseDetailBloc, CaseDetailState>(
            builder: (context, state) {
              final caseDetail = state.caseDetail;
              return Column(
                children: [
                  Text(caseDetail?.title ?? 'Carregando...'),
                  Text(
                    'Caso #${caseDetail?.id ?? '...'} • ${caseDetail?.status.replaceAll('_', ' ').toUpperCase() ?? 'CARREGANDO'}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              );
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
        body: BlocBuilder<CaseDetailBloc, CaseDetailState>(
          builder: (_, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Erro ao carregar dados',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(state.error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CaseDetailBloc>().add(LoadCaseDetail(caseId)),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }
            
            final caseDetail = state.caseDetail;
            if (caseDetail == null) {
              return const Center(
                child: Text('Nenhum dado disponível'),
              );
            }
            
            return BlocBuilder<AuthBloc, auth_states.AuthState>(
              builder: (context, authState) {
                if (authState is! auth_states.Authenticated) {
                  AppLogger.warning('User not authenticated, using fallback client sections');
                  return _buildFallbackClientView(caseDetail);
                }

                final currentUser = authState.user;
                
                AppLogger.info('User authenticated: ${currentUser.id}, role: ${currentUser.role}, userRole: ${currentUser.userRole}, isClient: ${currentUser.isClient}');
                
                // CORREÇÃO: Para clientes, usar APENAS a experiência padrão do cliente (sem contexto nem BlocProvider de advogado)
                if (currentUser.isClient) {
                  AppLogger.info('Client detected: ${currentUser.id} - Showing pure client experience without contextual data');
                  return _buildFallbackClientView(caseDetail);
                }
                
                // Carregar dados contextuais SOMENTE para advogados
                AppLogger.info('Lawyer detected: ${currentUser.id} - Loading contextual view');
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<ContextualCaseBloc>(
                      create: (context) => GetIt.instance<ContextualCaseBloc>()
                        ..add(LoadContextualCaseData(
                          caseId: caseId,
                          userId: currentUser.id,
                        )),
                    ),
                    BlocProvider<PrivacyCasesBloc>(
                      create: (_) => getIt<PrivacyCasesBloc>(),
                    ),
                  ],
                  child: BlocConsumer<ContextualCaseBloc, ContextualCaseState>(
                    listener: (context, contextualState) {
                      if (contextualState is ContextualCaseError) {
                        AppLogger.error('Contextual data error: ${contextualState.message}');
                      }
                    },
                    builder: (context, contextualState) {
                      // Se carregado, usar CaseDetail e ContextualData tipados do backend
                      CaseDetail? effectiveCaseDetail = caseDetail;
                      ContextualCaseData? contextualData;
                      if (contextualState is ContextualCaseLoaded) {
                        effectiveCaseDetail = contextualState.caseDetail;
                        contextualData = contextualState.contextualData;
                        AppLogger.info('Using contextual data for allocation: ${contextualData.allocationType}');
                      } else {
                        AppLogger.info('No contextual data available for lawyer, using basic lawyer sections');
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contextualState is ContextualCaseLoading)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    SizedBox(width: 8),
                                    Text('Carregando dados contextuais...', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),

                            // Banner de estado de acesso (Full/Preview)
                            BlocBuilder<PrivacyCasesBloc, PrivacyCasesState>(
                              builder: (context, pState) {
                                final fullAccess = pState is AccessStatusLoaded && pState.fullAccess;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: fullAccess
                                        ? Colors.green.withValues(alpha: 0.08)
                                        : Colors.amber.withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: fullAccess
                                          ? Colors.green.withValues(alpha: 0.3)
                                          : Colors.amber.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        fullAccess ? Icons.lock_open : Icons.visibility_off,
                                        color: fullAccess ? Colors.green : Colors.amber[800],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fullAccess
                                              ? 'Acesso Completo aos dados do cliente'
                                              : 'Visualização em modo Preview. Aceite o caso para ver dados completos do cliente.',
                                          style: TextStyle(
                                            color: fullAccess ? Colors.green[800] : Colors.amber[900],
                                          ),
                                        ),
                                      ),
                                      if (!fullAccess)
                                        TextButton.icon(
                                          onPressed: () => context
                                              .read<PrivacyCasesBloc>()
                                              .add(AcceptCaseRequested(caseId)),
                                          icon: const Icon(Icons.verified_user),
                                          label: const Text('Aceitar Caso'),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Ações de aceite/abandono para advogados
                            BlocConsumer<PrivacyCasesBloc, PrivacyCasesState>(
                              listener: (context, pState) {
                                if (pState is PrivacyCasesActionSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(pState.message)),
                                  );
                                  // Revalidar acesso após ações
                                  context.read<PrivacyCasesBloc>().add(CheckAccessRequested(caseId));
                                } else if (pState is PrivacyCasesError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(pState.message)),
                                  );
                                }
                              },
                              builder: (context, pState) {
                                final isLoading = pState is PrivacyCasesLoading;
                                final fullAccess = pState is AccessStatusLoaded && pState.fullAccess;
                                // dispara verificação de acesso uma vez
                                if (pState is! AccessStatusLoaded && pState is! PrivacyCasesLoading) {
                                  context.read<PrivacyCasesBloc>().add(CheckAccessRequested(caseId));
                                }
                                return Row(
                                  children: [
                                    if (!fullAccess)
                                      ElevatedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () => context.read<PrivacyCasesBloc>().add(
                                                  AcceptCaseRequested(caseId),
                                                ),
                                        icon: const Icon(Icons.verified_user),
                                        label: const Text('Aceitar Caso'),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock_open, size: 16, color: Colors.green),
                                            SizedBox(width: 6),
                                            Text('Acesso Completo', style: TextStyle(color: Colors.green)),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (dCtx) => AlertDialog(
                                                  title: const Text('Abandonar Caso'),
                                                  content: const Text('Tem certeza que deseja abandonar este caso?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(dCtx).pop(false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.of(dCtx).pop(true),
                                                      child: const Text('Confirmar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                // opcional: solicitar motivo
                                                context.read<PrivacyCasesBloc>().add(
                                                      AbandonCaseRequested(caseId),
                                                    );
                                              }
                                            },
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Abandonar'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            ...ContextualCaseDetailSectionFactory.buildSectionsForUser(
                              currentUser: currentUser,
                              caseDetail: effectiveCaseDetail,
                              contextualData: contextualData,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// **Experiência de fallback - mantém UI original do cliente**
  Widget _buildFallbackClientView(caseDetail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LawyerResponsibleSection(lawyer: caseDetail.assignedLawyer),
          const SizedBox(height: 16),
          ConsultationInfoSection(consultation: caseDetail.consultation),
          const SizedBox(height: 16),
          PreAnalysisSection(preAnalysis: caseDetail.preAnalysis),
          const SizedBox(height: 16),
          NextStepsSection(nextSteps: caseDetail.nextSteps),
          const SizedBox(height: 16),
          DocumentsSection(
            documents: caseDetail.documents,
            caseId: caseDetail.id,
          ),
          const SizedBox(height: 16),
          ProcessStatusSection(
            processStatus: _getMockProcessStatus(),
            caseId: caseDetail.id,
          ),
          const SizedBox(height: 16),
          CaseChatSection(
            caseId: caseDetail.id,
            caseName: caseDetail.title ?? 'Caso',
            lawyerName: caseDetail.assignedLawyer?.name,
            clientName: 'Cliente', // This should come from the case or user context
          ),
        ],
      ),
    );
  }

  ProcessStatus _getMockProcessStatus() {
    return ProcessStatus(
      currentPhase: 'Em Andamento',
      description: 'Seu processo está avançando conforme o planejado. A fase atual é a coleta de provas.',
      progressPercentage: 45.0,
      phases: [
        ProcessPhase(
          name: 'Petição Inicial',
          description: 'Apresentação formal da sua causa à justiça.',
          isCompleted: true,
          isCurrent: false,
          completedAt: DateTime(2024, 5, 20),
          documents: const [
            PhaseDocument(name: 'Peticao_Inicial_v1.pdf', url: ''),
          ],
        ),
        const ProcessPhase(
          name: 'Coleta de Provas',
          description: 'Reunindo todas as evidências e documentos necessários.',
          isCompleted: false,
          isCurrent: true,
          documents: [
            PhaseDocument(name: 'Contrato_Servico.pdf', url: ''),
            PhaseDocument(name: 'Email_Troca_Evidencias.pdf', url: ''),
          ],
        ),
        const ProcessPhase(
          name: 'Audiência de Conciliação',
          description: 'Tentativa de acordo amigável entre as partes.',
          isCompleted: false,
          isCurrent: false,
        ),
      ],
    );
  }
}