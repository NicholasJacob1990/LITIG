import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/theme.dart';
import 'package:meu_app/src/features/cases/data/repositories/mock_case_repository.dart';
import '../bloc/case_detail_bloc.dart';
import '../../domain/entities/case_detail_models.dart';
import '../../domain/usecases/get_case_detail.dart';

class CaseDetailScreen extends StatelessWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CaseDetailBloc(
        getCaseDetail: GetCaseDetail(MockCaseRepository()),
      )..add(LoadCaseDetail(caseId)),
      child: CaseDetailView(caseId: caseId),
    );
  }
}

class CaseDetailView extends StatelessWidget {
  final String caseId;
  const CaseDetailView({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CaseDetailBloc, CaseDetailState>(
          builder: (context, state) {
            if (state is CaseDetailLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.caseDetail.title),
                  Text(
                    'Caso #${state.caseDetail.caseNumber} • ${state.caseDetail.status}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              );
            }
            return const Text('Carregando...');
          },
        ),
        leading: const BackButton(),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: BlocConsumer<CaseDetailBloc, CaseDetailState>(
        listener: (context, state) {
          if (state is CaseDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is CaseDetailLoading || state is CaseDetailUpdating && state is! CaseDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CaseDetailError) {
            return Center(child: Text(state.message));
          }

          if (state is CaseDetailLoaded) {
            final caseDetail = state.caseDetail;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Advogado Responsável', theme),
                  _lawyerCard(caseDetail.lawyer, theme),
                  const SizedBox(height: 16),
                  _sectionTitle('Informações da Consulta', theme),
                  _infoCard(caseDetail.consultationInfo, theme),
                  const SizedBox(height: 16),
                  _sectionTitle('Pré-análise IA', theme),
                  _preAnalysisCard(caseDetail.preAnalysis, theme),
                  const SizedBox(height: 16),
                  _analysisDetailCard(caseDetail.preAnalysis, theme),
                  const SizedBox(height: 16),
                  _sectionTitle('Próximos Passos', theme),
                  _nextStepsSection(caseDetail.nextSteps, theme),
                  const SizedBox(height: 16),
                  _sectionTitle('Documentos', theme),
                  _documentsSection(caseDetail.documents, theme),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(title, style: theme.textTheme.displayLarge?.copyWith(fontSize: 18)),
      );

  Widget _lawyerCard(Lawyer lawyer, ThemeData theme) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surface,
            backgroundImage: CachedNetworkImageProvider(lawyer.avatarUrl),
          ),
          title: Text(lawyer.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text('${lawyer.specialty}\n⭐ ${lawyer.rating}   ${lawyer.experienceYears} anos'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
              IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
            ],
          ),
        ),
      );

  Widget _infoCard(ConsultationInfo info, ThemeData theme) => _simpleInfoCard([
        _infoRow(LucideIcons.calendar, 'Data da Consulta', info.date, theme),
        _infoRow(LucideIcons.clock, 'Duração', info.duration, theme),
        _infoRow(LucideIcons.video, 'Modalidade', info.mode, theme),
        _infoRow(LucideIcons.fileText, 'Plano', info.plan, theme),
      ]);

  Widget _preAnalysisCard(PreAnalysis pre, ThemeData theme) => Card(
        color: theme.cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: _getUrgencyColor(pre.priority), borderRadius: BorderRadius.circular(16)),
                    child: Text(pre.priority, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(pre.tag, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.share_outlined)
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.highlightPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                    child: Text('Análise Preliminar por IA\nSujeita a conferência humana',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.highlightPurple, fontWeight: FontWeight.w500))),
              ),
              const SizedBox(height: 16),
              _infoRow(LucideIcons.timer, 'Prazo Estimado', pre.estimatedTime, theme),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Nível de Urgência:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: LinearProgressIndicator(
                    value: pre.urgency / 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(_getUrgencyColor(pre.priority)),
                  )),
                  const SizedBox(width: 8),
                  Text('${pre.urgency}/10', style: TextStyle(color: _getUrgencyColor(pre.priority), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _analysisDetailCard(PreAnalysis pre, ThemeData theme) => _simpleInfoCard([
        Text('Análise Preliminar', style: theme.textTheme.displayLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Text(pre.summary, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text('Documentos Necessários', style: theme.textTheme.displayLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        ...pre.requiredDocs.map((doc) => Text('• $doc', style: theme.textTheme.bodyMedium)).toList(),
        const SizedBox(height: 16),
        Text('Estimativa de Custos', style: theme.textTheme.displayLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: pre.costs.map((cost) => Expanded(child: Text('${cost.label}\n${cost.value}', style: theme.textTheme.bodyMedium))).toList(),
        ),
        const SizedBox(height: 16),
        Text('Avaliação de Risco', style: theme.textTheme.displayLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Text(pre.risk, style: theme.textTheme.bodyMedium),
      ]);

  Widget _nextStepsSection(List<NextStep> steps, ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.map((step) => _taskCard(step, theme)).toList(),
      );

  Widget _documentsSection(List<DocumentItem> docs, ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: docs.map((doc) => _fileTile(doc, theme)).toList(),
      );

  Widget _simpleInfoCard(List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.textTheme.bodyMedium?.color),
            const SizedBox(width: 12),
            Text('$label: ', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            Expanded(child: Text(value, textAlign: TextAlign.end, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );

  Widget _taskCard(NextStep step, ThemeData theme) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(step.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text('${step.description}\nPrazo: ${step.dueDate}', style: theme.textTheme.bodyMedium),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [step.priority, step.status].map((tag) => _tagChip(tag)).toList(),
          ),
        ),
      );

  Widget _tagChip(String tag) {
    Color color;
    switch (tag.toUpperCase()) {
      case 'HIGH':
        color = AppColors.urgencyHigh;
        break;
      case 'MEDIUM':
        color = AppColors.urgencyMedium;
        break;
      case 'PENDING':
        color = AppColors.primaryBlue;
        break;
      default:
        color = AppColors.secondaryText;
    }
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getUrgencyColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppColors.urgencyHigh;
      case 'MEDIUM':
        return AppColors.urgencyMedium;
      default:
        return AppColors.secondaryText;
    }
  }

  Widget _fileTile(DocumentItem doc, ThemeData theme) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(LucideIcons.fileText, color: AppColors.primaryBlue),
          title: Text(doc.name, style: theme.textTheme.bodyLarge),
          subtitle: Text(doc.sizeDate, style: theme.textTheme.bodyMedium),
          trailing: IconButton(icon: const Icon(LucideIcons.download), onPressed: () {}),
        ),
      );
}