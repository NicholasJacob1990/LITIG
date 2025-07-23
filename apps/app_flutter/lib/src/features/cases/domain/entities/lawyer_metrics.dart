import 'package:equatable/equatable.dart';
import 'allocation_type.dart';

/// Métricas base para advogados
abstract class LawyerMetrics extends Equatable {
  final String caseId;
  final AllocationType allocationType;
  final DateTime lastUpdated;

  const LawyerMetrics({
    required this.caseId,
    required this.allocationType,
    required this.lastUpdated,
  });

  /// Factory method para criar métricas específicas baseadas no tipo
  factory LawyerMetrics.create({
    required String caseId,
    required AllocationType allocationType,
    required Map<String, dynamic> data,
  }) {
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return AssociateLawyerMetrics.fromJson(data..['case_id'] = caseId);
      case AllocationType.platformMatchDirect:
        return IndependentLawyerMetrics.fromJson(data..['case_id'] = caseId);
      case AllocationType.partnershipProactiveSearch:
      case AllocationType.platformMatchPartnership:
      case AllocationType.partnershipPlatformSuggestion:
        return OfficeLawyerMetrics.fromJson(data..['case_id'] = caseId);
      default:
        return IndependentLawyerMetrics.fromJson(data..['case_id'] = caseId);
    }
  }
}

/// Métricas para Advogados Associados (Delegação Interna)
class AssociateLawyerMetrics extends LawyerMetrics {
  final Duration timeInvested;
  final Duration estimatedRemaining;
  final double supervisorRating; // 0-5
  final int learningPoints;
  final List<Skill> skillsToImprove;
  final double completionPercentage; // 0-100
  final List<String> delegatorFeedback;
  final int tasksCompleted;
  final int tasksTotal;
  final double billableHours;
  final String supervisorName;

  const AssociateLawyerMetrics({
    required super.caseId,
    required super.lastUpdated,
    required this.timeInvested,
    required this.estimatedRemaining,
    required this.supervisorRating,
    required this.learningPoints,
    required this.skillsToImprove,
    required this.completionPercentage,
    required this.delegatorFeedback,
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.billableHours,
    required this.supervisorName,
  }) : super(allocationType: AllocationType.internalDelegation);

  factory AssociateLawyerMetrics.fromJson(Map<String, dynamic> json) {
    return AssociateLawyerMetrics(
      caseId: json['case_id'] ?? '',
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
      timeInvested: Duration(hours: json['time_invested_hours'] ?? 0),
      estimatedRemaining: Duration(hours: json['estimated_remaining_hours'] ?? 0),
      supervisorRating: (json['supervisor_rating'] as num?)?.toDouble() ?? 0.0,
      learningPoints: json['learning_points'] ?? 0,
      skillsToImprove: (json['skills_to_improve'] as List?)
          ?.map((skill) => Skill.fromJson(skill))
          .toList() ?? [],
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      delegatorFeedback: List<String>.from(json['delegator_feedback'] ?? []),
      tasksCompleted: json['tasks_completed'] ?? 0,
      tasksTotal: json['tasks_total'] ?? 0,
      billableHours: (json['billable_hours'] as num?)?.toDouble() ?? 0.0,
      supervisorName: json['supervisor_name'] ?? '',
    );
  }

  /// Percentual de tarefas completadas
  double get taskCompletionRate => 
      tasksTotal > 0 ? (tasksCompleted / tasksTotal) * 100 : 0.0;

  /// Se está dentro do prazo estimado
  bool get isOnSchedule => timeInvested <= estimatedRemaining;

  /// Nível de performance baseado na avaliação do supervisor
  String get performanceLevel {
    if (supervisorRating >= 4.5) return 'Excelente';
    if (supervisorRating >= 3.5) return 'Bom';
    if (supervisorRating >= 2.5) return 'Regular';
    return 'Precisa Melhorar';
  }

  @override
  List<Object?> get props => [
        caseId,
        allocationType,
        lastUpdated,
        timeInvested,
        estimatedRemaining,
        supervisorRating,
        learningPoints,
        skillsToImprove,
        completionPercentage,
        delegatorFeedback,
        tasksCompleted,
        tasksTotal,
        billableHours,
        supervisorName,
      ];
}

/// Métricas para Advogados Autônomos e Contratantes (Match Algorítmico)
/// Usado por: lawyer_individual, lawyer_office, lawyer_platform_associate
class IndependentLawyerMetrics extends LawyerMetrics {
  final double matchScore; // 0-100
  final double successProbability; // 0-1
  final double caseValue;
  final int competitorCount;
  final String differentiator;
  final double clientSatisfactionPrediction; // 0-5
  final List<String> strengthAreas;
  final List<String> riskFactors;
  final double timeToClosePrediction; // em dias
  final double revenueProjection;
  final CaseSource caseSource; // algoritmo, captação direta, etc.

  const IndependentLawyerMetrics({
    required super.caseId,
    required super.lastUpdated,
    required this.matchScore,
    required this.successProbability,
    required this.caseValue,
    required this.competitorCount,
    required this.differentiator,
    required this.clientSatisfactionPrediction,
    required this.strengthAreas,
    required this.riskFactors,
    required this.timeToClosePrediction,
    required this.revenueProjection,
    required this.caseSource,
  }) : super(allocationType: AllocationType.platformMatchDirect);

  factory IndependentLawyerMetrics.fromJson(Map<String, dynamic> json) {
    return IndependentLawyerMetrics(
      caseId: json['case_id'] ?? '',
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      successProbability: (json['success_probability'] as num?)?.toDouble() ?? 0.0,
      caseValue: (json['case_value'] as num?)?.toDouble() ?? 0.0,
      competitorCount: json['competitor_count'] ?? 0,
      differentiator: json['differentiator'] ?? '',
      clientSatisfactionPrediction: (json['client_satisfaction_prediction'] as num?)?.toDouble() ?? 0.0,
      strengthAreas: List<String>.from(json['strength_areas'] ?? []),
      riskFactors: List<String>.from(json['risk_factors'] ?? []),
      timeToClosePrediction: (json['time_to_close_prediction'] as num?)?.toDouble() ?? 0.0,
      revenueProjection: (json['revenue_projection'] as num?)?.toDouble() ?? 0.0,
      caseSource: CaseSource.fromString(json['case_source'] ?? 'algorithm'),
    );
  }

  /// Classificação do match
  String get matchGrade {
    if (matchScore >= 90) return 'A+';
    if (matchScore >= 80) return 'A';
    if (matchScore >= 70) return 'B';
    if (matchScore >= 60) return 'C';
    return 'D';
  }

  /// Nível de competição
  String get competitionLevel {
    if (competitorCount == 0) return 'Exclusivo';
    if (competitorCount <= 2) return 'Baixa';
    if (competitorCount <= 5) return 'Média';
    return 'Alta';
  }

  /// ROI estimado
  double get estimatedROI => caseValue > 0 ? revenueProjection / caseValue : 0.0;

  @override
  List<Object?> get props => [
        caseId,
        allocationType,
        lastUpdated,
        matchScore,
        successProbability,
        caseValue,
        competitorCount,
        differentiator,
        clientSatisfactionPrediction,
        strengthAreas,
        riskFactors,
        timeToClosePrediction,
        revenueProjection,
        caseSource,
      ];
}

/// Métricas para Escritórios (Parcerias)
class OfficeLawyerMetrics extends LawyerMetrics {
  final PartnershipInfo partnership;
  final double revenueShare; // 0-100
  final double riskLevel; // 0-100
  final int teamMembers;
  final double clientSatisfaction; // 0-5
  final List<String> responsibilityAreas;
  final double collaborationScore; // 0-100
  final double synergyIndex; // 0-100
  final Map<String, double> resourceAllocation;
  final double profitMargin; // 0-100

  const OfficeLawyerMetrics({
    required super.caseId,
    required super.lastUpdated,
    required this.partnership,
    required this.revenueShare,
    required this.riskLevel,
    required this.teamMembers,
    required this.clientSatisfaction,
    required this.responsibilityAreas,
    required this.collaborationScore,
    required this.synergyIndex,
    required this.resourceAllocation,
    required this.profitMargin,
  }) : super(allocationType: AllocationType.partnershipProactiveSearch);

  factory OfficeLawyerMetrics.fromJson(Map<String, dynamic> json) {
    return OfficeLawyerMetrics(
      caseId: json['case_id'] ?? '',
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
      partnership: PartnershipInfo.fromJson(json['partnership'] ?? {}),
      revenueShare: (json['revenue_share'] as num?)?.toDouble() ?? 0.0,
      riskLevel: (json['risk_level'] as num?)?.toDouble() ?? 0.0,
      teamMembers: json['team_members'] ?? 0,
      clientSatisfaction: (json['client_satisfaction'] as num?)?.toDouble() ?? 0.0,
      responsibilityAreas: List<String>.from(json['responsibility_areas'] ?? []),
      collaborationScore: (json['collaboration_score'] as num?)?.toDouble() ?? 0.0,
      synergyIndex: (json['synergy_index'] as num?)?.toDouble() ?? 0.0,
      resourceAllocation: Map<String, double>.from(
        (json['resource_allocation'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble())
        ) ?? {}
      ),
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Classificação do nível de risco
  String get riskLevelDescription {
    if (riskLevel >= 80) return 'Alto';
    if (riskLevel >= 60) return 'Médio';
    if (riskLevel >= 40) return 'Baixo';
    return 'Muito Baixo';
  }

  /// Eficiência da colaboração
  String get collaborationEfficiency {
    if (collaborationScore >= 80) return 'Excelente';
    if (collaborationScore >= 60) return 'Boa';
    if (collaborationScore >= 40) return 'Regular';
    return 'Precisa Melhorar';
  }

  @override
  List<Object?> get props => [
        caseId,
        allocationType,
        lastUpdated,
        partnership,
        revenueShare,
        riskLevel,
        teamMembers,
        clientSatisfaction,
        responsibilityAreas,
        collaborationScore,
        synergyIndex,
        resourceAllocation,
        profitMargin,
      ];
}

/// Informações de parceria
class PartnershipInfo extends Equatable {
  final String id;
  final String partnerName;
  final String partnerType;
  final double partnerShare; // 0-100
  final DateTime startDate;
  final DateTime? endDate;
  final String contractType;

  const PartnershipInfo({
    required this.id,
    required this.partnerName,
    required this.partnerType,
    required this.partnerShare,
    required this.startDate,
    this.endDate,
    required this.contractType,
  });

  factory PartnershipInfo.fromJson(Map<String, dynamic> json) {
    return PartnershipInfo(
      id: json['id'] ?? '',
      partnerName: json['partner_name'] ?? '',
      partnerType: json['partner_type'] ?? '',
      partnerShare: (json['partner_share'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      contractType: json['contract_type'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerName,
        partnerType,
        partnerShare,
        startDate,
        endDate,
        contractType,
      ];
}

/// Habilidade para desenvolvimento
class Skill extends Equatable {
  final String name;
  final String category;
  final int currentLevel; // 1-5
  final int targetLevel; // 1-5
  final String description;
  final List<String> improvementActions;

  const Skill({
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.targetLevel,
    required this.description,
    required this.improvementActions,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      currentLevel: json['current_level'] ?? 1,
      targetLevel: json['target_level'] ?? 1,
      description: json['description'] ?? '',
      improvementActions: List<String>.from(json['improvement_actions'] ?? []),
    );
  }

  /// Gap de habilidade
  int get skillGap => targetLevel - currentLevel;

  /// Se precisa melhorar a habilidade
  bool get needsImprovement => skillGap > 0;

  @override
  List<Object?> get props => [
        name,
        category,
        currentLevel,
        targetLevel,
        description,
        improvementActions,
      ];
}

/// Fonte do caso
enum CaseSource {
  algorithm('algorithm'),
  directCapture('direct_capture'),
  partnership('partnership'),
  referral('referral');

  const CaseSource(this.value);
  
  final String value;

  static CaseSource fromString(String value) {
    switch (value) {
      case 'algorithm':
        return CaseSource.algorithm;
      case 'direct_capture':
        return CaseSource.directCapture;
      case 'partnership':
        return CaseSource.partnership;
      case 'referral':
        return CaseSource.referral;
      default:
        return CaseSource.algorithm;
    }
  }

  String get displayName {
    switch (this) {
      case CaseSource.algorithm:
        return 'Via Algoritmo';
      case CaseSource.directCapture:
        return 'Captação Direta';
      case CaseSource.partnership:
        return 'Parceria';
      case CaseSource.referral:
        return 'Indicação';
    }
  }
} 