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
import '../../../../shared/utils/app_colors.dart';
import 'package:meu_app/src/features/cases/domain/entities/process_status.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' as auth_states;
import '../../../../core/utils/logger.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({super.key, required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CaseDetailBloc()..add(LoadCaseDetail(caseId)),
        ),
        BlocProvider(
          create: (context) => GetIt.instance<ContextualCaseBloc>()
            ..add(LoadContextualCaseData(
              caseId: caseId,
              userId: 'current_user', // TODO: Get from AuthBloc
            )),
        ),
      ],
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
                
                // Carregar dados contextuais quando há usuário autenticado
                return BlocConsumer<ContextualCaseBloc, ContextualCaseState>(
                  listener: (context, contextualState) {
                    if (contextualState is ContextualCaseError) {
                      AppLogger.error('Contextual data error: ${contextualState.message}');
                      // Para erros contextuais, não impedir que o usuário veja o caso
                      // O fallback client será usado pela factory
                    }
                  },
                  builder: (context, contextualState) {
                    // Trigger contextual data loading if not already loaded
                    if (contextualState is ContextualCaseInitial) {
                      context.read<ContextualCaseBloc>().add(
                        LoadContextualCaseData(
                          caseId: caseId,
                          userId: currentUser.id,
                        ),
                      );
                    }

                    // Extract contextual data if available
                    ContextualCaseData? contextualData;
                    if (contextualState is ContextualCaseLoaded) {
                      contextualData = contextualState.contextualData;
                      AppLogger.info('Using contextual data for allocation: ${contextualData.allocationType}');
                    } else {
                      AppLogger.info('No contextual data available, factory will use client sections');
                    }
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show contextual loading indicator if loading
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
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Carregando dados contextuais...',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Render sections using factory
                          ...ContextualCaseDetailSectionFactory.buildSectionsForUser(
                            currentUser: currentUser,
                            caseDetail: caseDetail,
                            contextualData: contextualData,
                          ),
                        ],
                      ),
                    );
                  },
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