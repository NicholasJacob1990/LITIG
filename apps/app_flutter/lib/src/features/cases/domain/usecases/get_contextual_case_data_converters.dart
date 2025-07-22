import '../entities/case_detail.dart' as detail;
import '../entities/lawyer_info.dart';
import '../entities/case_detail_models.dart' as models;
import '../entities/case_document.dart' as doc;
import '../entities/process_status.dart' as status;

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
    final sourceInfo = models.PreAnalysis.fromJson(data);
    return detail.PreAnalysis(
      summary: sourceInfo.summary,
      legalArea: sourceInfo.tag,
      urgencyLevel: sourceInfo.urgency.toString(),
      keyPoints: sourceInfo.requiredDocs,
      recommendation: 'Recomendação baseada na análise prévia',
      analyzedAt: DateTime.now(),
      requiredDocuments: sourceInfo.requiredDocs,
      riskAssessment: sourceInfo.risk,
      estimatedCosts: sourceInfo.costs.fold<Map<String, double>>(
        {},
        (map, cost) => map..[cost.label] = double.tryParse(
          cost.value.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
        ) ?? 0.0,
      ),
    );
  }

  /// Converts NextStep from models to case_detail format
  detail.NextStep convertNextStep(Map<String, dynamic> data) {
    final sourceInfo = models.NextStep.fromJson(data);
    return detail.NextStep(
      id: 'step_${sourceInfo.title.hashCode}',
      title: sourceInfo.title,
      description: sourceInfo.description,
      dueDate: DateTime.tryParse(sourceInfo.dueDate) ?? 
                DateTime.now().add(const Duration(days: 7)),
      priority: sourceInfo.priority.toLowerCase(),
      isCompleted: sourceInfo.status == 'DONE',
      responsibleParty: 'lawyer',
    );
  }

  /// Converts CaseDocument from doc to case_detail format
  detail.CaseDocument convertCaseDocument(Map<String, dynamic> data) {
    final sourceInfo = doc.CaseDocument.fromJson(data);
    return detail.CaseDocument(
      id: 'doc_${sourceInfo.name.hashCode}',
      name: sourceInfo.name,
      type: sourceInfo.type,
      url: '/documents/${sourceInfo.name}',
      uploadedAt: DateTime.tryParse(sourceInfo.date) ?? DateTime.now(),
      uploadedBy: 'client',
      sizeBytes: int.tryParse(sourceInfo.size.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1024,
      isRequired: sourceInfo.category == 'required',
    );
  }

  /// Converts ProcessStatus from status to case_detail format
  // TODO: Fix ProcessStatus conversion - temporarily commented
  // detail.ProcessStatus convertProcessStatus(Map<String, dynamic> data) {
  //   final sourceInfo = status.ProcessStatus.fromJson(data);
  //   return detail.ProcessStatus(
  //     currentPhase: sourceInfo.currentPhase,
  //     description: sourceInfo.description,
  //     progressPercentage: sourceInfo.progressPercentage,
  //     lastUpdate: DateTime.now(),
  //     phases: sourceInfo.phases.map((phase) => detail.ProcessPhase(
  //       id: 'phase_${phase.name.hashCode}',
  //       name: phase.name,
  //       description: phase.description,
  //       isCompleted: phase.isCompleted,
  //       isCurrent: phase.isCurrent,
  //       completedAt: phase.completedAt,
  //       documents: phase.documents.map((phaseDoc) => detail.CaseDocumentPreview(
  //         id: 'preview_${phaseDoc.name.hashCode}',
  //         name: phaseDoc.name,
  //       )).toList(),
  //     )).toList(),
  //   );
  // }
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