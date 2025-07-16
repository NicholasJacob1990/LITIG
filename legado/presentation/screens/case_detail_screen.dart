import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          leading: const BackButton(),
          actions: [IconButton(icon: const Icon(Icons.share), onPressed: () {})],
          title: const Column(
            children: [
              Text('Rescisão Trabalhista'),
              Text('Caso #001 • Em Andamento',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
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
              return Center(child: Text(state.error!));
            }
            return const SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LawyerResponsibleSection(),
                  SizedBox(height: 16),
                  ConsultationInfoSection(),
                  SizedBox(height: 16),
                  PreAnalysisSection(),
                  SizedBox(height: 16),
                  NextStepsSection(),
                  SizedBox(height: 16),
                  DocumentsSection(),
                  SizedBox(height: 16),
                  ProcessStatusSection(),
                  SizedBox(height: 24), // Espaço extra no final
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}