import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/case_detail_bloc.dart';
import '../widgets/lawyer_responsible_section.dart';
import '../widgets/consultation_info_section.dart';
import '../widgets/pre_analysis_section.dart';
import '../widgets/next_steps_section.dart';
import '../widgets/documents_section.dart';
import '../widgets/process_status_section.dart';
import '../../../../shared/utils/app_colors.dart';

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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryGradientTop,
                  AppColors.primaryGradientBot,
                ],
              ),
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
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(state.error!),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CaseDetailBloc>().add(LoadCaseDetail(caseId)),
                      child: Text('Tentar novamente'),
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
                    processStatus: caseDetail.processStatus,
                    caseId: caseDetail.id,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
    );
  }
}