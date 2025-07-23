import '../entities/case_detail.dart' as detail;
import '../entities/process_status.dart';
import '../entities/lawyer_info.dart';
import '../entities/case_detail_models.dart' as models;

/// Converters for contextual case data to handle type conflicts
mixin ContextualCaseDataConverters {
  
  /// Converts LawyerInfo from lawyer_info.dart to case_detail.dart format
  detail.LawyerInfo convertLawyerInfo(Map<String, dynamic> data) {
    final sourceInfo = LawyerInfo.fromJson(data);
    return detail.LawyerInfo(
      id: 'lawyer_${sourceInfo.name.hashCode}',
      name: sourceInfo.name,
      specialty: sourceInfo.specialty,
      avatarUrl: sourceInfo.avatarUrl,
      rating: 4.5, // Default rating
      experienceYears: 5, // Default experience
      isAvailable: true,
    );
  }

  /// Converts ConsultationInfo from models to case_detail format
  detail.ConsultationInfo convertConsultationInfo(Map<String, dynamic> data) {
    final sourceInfo = models.ConsultationInfo.fromJson(data);
    return detail.ConsultationInfo(
      date: DateTime.tryParse(sourceInfo.date) ?? DateTime.now(),
      durationMinutes: int.tryParse(sourceInfo.duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60,
      modality: sourceInfo.mode,
      plan: sourceInfo.plan,
      notes: 'Consulta agendada via ${sourceInfo.mode}',
    );
  }

  /// Converts PreAnalysis from models to case_detail format
  detail.PreAnalysis convertPreAnalysis(Map<String, dynamic> data) {
    return detail.PreAnalysis(
      summary: data['summary'] ?? 'Análise prévia do caso',
      legalArea: data['tag'] ?? 'Civil',
      urgencyLevel: data['urgency']?.toString() ?? 'Média',
      keyPoints: List<String>.from(data['required_docs'] ?? []),
      recommendation: 'Recomendação baseada na análise prévia',
      analyzedAt: DateTime.now(),
      requiredDocuments: List<String>.from(data['required_docs'] ?? []),
      riskAssessment: data['risk'] ?? 'Baixo',
      estimatedCosts: Map<String, double>.from(data['costs'] ?? {}),
    );
  }

  /// Converts NextStep from models to case_detail format
  detail.NextStep convertNextStep(Map<String, dynamic> data) {
    return detail.NextStep(
      id: 'step_${(data['title'] ?? '').hashCode}',
      title: data['title'] ?? 'Próximo Passo',
      description: data['description'] ?? 'Descrição do próximo passo',
      dueDate: DateTime.tryParse(data['due_date'] ?? '') ?? 
                DateTime.now().add(const Duration(days: 7)),
      priority: (data['priority'] ?? 'medium').toLowerCase(),
      isCompleted: data['status'] == 'DONE',
      responsibleParty: 'lawyer',
    );
  }

  /// Converts CaseDocument from doc to case_detail format
  detail.CaseDocument convertCaseDocument(Map<String, dynamic> data) {
    return detail.CaseDocument(
      id: 'doc_${(data['name'] ?? '').hashCode}',
      name: data['name'] ?? 'Documento',
      type: data['type'] ?? 'pdf',
      url: '/documents/${data['name'] ?? 'documento'}',
      uploadedAt: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      uploadedBy: 'client',
      sizeBytes: int.tryParse((data['size'] ?? '1024').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1024,
      isRequired: data['category'] == 'required',
    );
  }

  /// Converts ProcessStatus from status to case_detail format
  ProcessStatus convertProcessStatus(Map<String, dynamic> data) {
    return ProcessStatus(
      currentPhase: data['current_phase'] as String? ?? 'Em Andamento',
      description: data['description'] as String? ?? 'Processo em andamento',
      progressPercentage: (data['progress_percentage'] as num?)?.toDouble() ?? 50.0,
      phases: (data['phases'] as List<dynamic>?)?.map((phase) => 
        ProcessPhase(
          name: phase['name'] as String,
          description: phase['description'] as String,
          isCompleted: phase['is_completed'] as bool? ?? false,
          isCurrent: phase['is_current'] as bool? ?? false,
          completedAt: phase['completed_at'] != null ? 
            DateTime.tryParse(phase['completed_at'] as String) : null,
        ),
      ).toList() ?? [],
    );
  }
}

/// Helper class for CaseDocumentPreview - extending case_detail namespace
class CaseDocumentPreview {
  final String id;
  final String name;
  final String url;
  final String type;

  const CaseDocumentPreview({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
  });
}

/// Extension para converter entre as diferentes versões de CaseDocumentPreview
  // TODO: Fix CaseDocumentPreview conversion - temporarily commented
  // extension CaseDocumentPreviewConverter on CaseDocumentPreview {
  //   detail.CaseDocumentPreview toDetail() {
  //     return detail.CaseDocumentPreview(
  //       id: id,
  //       name: name,
  //     );
  //   }
  // }