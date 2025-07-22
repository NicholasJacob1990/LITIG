import 'package:equatable/equatable.dart';
import 'litigation_party.dart';
import 'process_status.dart';

class CaseDetail extends Equatable {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LawyerInfo assignedLawyer;
  final ConsultationInfo consultation;
  final PreAnalysis preAnalysis;
  final List<NextStep> nextSteps;
  final List<CaseDocument> documents;
  final ProcessStatus processStatus;
  final List<LitigationParty> parties; // NOVO: Partes processuais
  final String? caseType; // NOVO: Tipo do caso (litigation, consultancy, etc.)
  final String? cnjNumber; // NOVO: Número CNJ para casos contenciosos

  const CaseDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedLawyer,
    required this.consultation,
    required this.preAnalysis,
    required this.nextSteps,
    required this.documents,
    required this.processStatus,
    this.parties = const [], // NOVO: Lista de partes processuais
    this.caseType, // NOVO: Tipo do caso
    this.cnjNumber, // NOVO: Número CNJ
  });

  /// Verifica se o caso é contencioso (tem partes processuais)
  bool get isLitigation => caseType == 'litigation' || parties.isNotEmpty;

  /// Verifica se o caso é consultivo
  bool get isConsultancy => caseType == 'consultancy';

  /// Obtém o autor principal (primeira parte do tipo plaintiff)
  LitigationParty? get mainPlaintiff => 
      parties.where((party) => party.isPlaintiff).isNotEmpty 
          ? parties.where((party) => party.isPlaintiff).first 
          : null;

  /// Obtém o réu principal (primeira parte do tipo defendant)
  LitigationParty? get mainDefendant => 
      parties.where((party) => party.isDefendant).isNotEmpty 
          ? parties.where((party) => party.isDefendant).first 
          : null;

  /// Factory method para criar CaseDetail com partes processuais
  factory CaseDetail.withLitigationParties({
    required CaseDetail originalCase,
    required List<LitigationParty> parties,
    String? cnjNumber,
  }) {
    return CaseDetail(
      id: originalCase.id,
      title: originalCase.title,
      description: originalCase.description,
      status: originalCase.status,
      createdAt: originalCase.createdAt,
      updatedAt: originalCase.updatedAt,
      assignedLawyer: originalCase.assignedLawyer,
      consultation: originalCase.consultation,
      preAnalysis: originalCase.preAnalysis,
      nextSteps: originalCase.nextSteps,
      documents: originalCase.documents,
      processStatus: originalCase.processStatus,
      parties: parties,
      caseType: 'litigation',
      cnjNumber: cnjNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        createdAt,
        updatedAt,
        assignedLawyer,
        consultation,
        preAnalysis,
        nextSteps,
        documents,
        processStatus,
        parties, // NOVO
        caseType, // NOVO
        cnjNumber, // NOVO
      ];
}

class LawyerInfo extends Equatable {
  final String id;
  final String name;
  final String specialty;
  final String avatarUrl;
  final double rating;
  final int experienceYears;
  final bool isAvailable;

  const LawyerInfo({
    required this.id,
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.rating,
    required this.experienceYears,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        specialty,
        avatarUrl,
        rating,
        experienceYears,
        isAvailable,
      ];
}

class ConsultationInfo extends Equatable {
  final DateTime date;
  final int durationMinutes;
  final String modality;
  final String plan;
  final String notes;

  const ConsultationInfo({
    required this.date,
    required this.durationMinutes,
    required this.modality,
    required this.plan,
    required this.notes,
  });

  @override
  List<Object?> get props => [date, durationMinutes, modality, plan, notes];
}

class PreAnalysis extends Equatable {
  final String summary;
  final String legalArea;
  final String urgencyLevel;
  final List<String> keyPoints;
  final String recommendation;
  final DateTime analyzedAt;
  final List<String> requiredDocuments;
  final String riskAssessment;
  final Map<String, double> estimatedCosts;

  const PreAnalysis({
    required this.summary,
    required this.legalArea,
    required this.urgencyLevel,
    required this.keyPoints,
    required this.recommendation,
    required this.analyzedAt,
    required this.requiredDocuments,
    required this.riskAssessment,
    required this.estimatedCosts,
  });

  @override
  List<Object?> get props => [
        summary,
        legalArea,
        urgencyLevel,
        keyPoints,
        recommendation,
        analyzedAt,
        requiredDocuments,
        riskAssessment,
        estimatedCosts,
      ];
}

class NextStep extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  final bool isCompleted;
  final String responsibleParty;

  const NextStep({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.responsibleParty,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dueDate,
        priority,
        isCompleted,
        responsibleParty,
      ];
}

class CaseDocument extends Equatable {
  final String id;
  final String name;
  final String type;
  final String url;
  final DateTime uploadedAt;
  final String uploadedBy;
  final int sizeBytes;
  final bool isRequired;

  const CaseDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.sizeBytes,
    required this.isRequired,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        url,
        uploadedAt,
        uploadedBy,
        sizeBytes,
        isRequired,
      ];
}

 