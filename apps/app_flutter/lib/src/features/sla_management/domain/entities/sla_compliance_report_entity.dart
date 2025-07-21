import 'package:equatable/equatable.dart';

/// Entidade que representa um relatório de compliance SLA
/// 
/// Contém dados agregados sobre conformidade com SLAs,
/// violações, tendências e análises de risco
class SlaComplianceReportEntity extends Equatable {
  const SlaComplianceReportEntity({
    required this.firmId,
    required this.periodStart,
    required this.periodEnd,
    required this.overallCompliance,
    required this.totalCases,
    required this.compliantCases,
    required this.violatedCases,
    required this.averageResponseTime,
    required this.complianceByPriority,
    required this.complianceByCaseType,
    required this.violationsByReason,
    required this.trends,
    required this.riskAnalysis,
    required this.recommendations,
    required this.generatedAt,
    this.details,
    this.metadata,
  });

  /// ID da firma
  final String firmId;

  /// Data de início do período
  final DateTime periodStart;

  /// Data de fim do período
  final DateTime periodEnd;

  /// Taxa de compliance geral (0.0 a 1.0)
  final double overallCompliance;

  /// Total de casos no período
  final int totalCases;

  /// Casos em conformidade
  final int compliantCases;

  /// Casos com violação SLA
  final int violatedCases;

  /// Tempo médio de resposta em horas
  final double averageResponseTime;

  /// Compliance por prioridade
  final Map<String, ComplianceMetric> complianceByPriority;

  /// Compliance por tipo de caso
  final Map<String, ComplianceMetric> complianceByCaseType;

  /// Violações agrupadas por motivo
  final Map<String, int> violationsByReason;

  /// Dados de tendência temporal
  final List<ComplianceTrendPoint> trends;

  /// Análise de risco
  final RiskAnalysisData riskAnalysis;

  /// Recomendações de melhoria
  final List<ComplianceRecommendation> recommendations;

  /// Data de geração do relatório
  final DateTime generatedAt;

  /// Detalhes adicionais por caso (opcional)
  final List<CaseComplianceDetail>? details;

  /// Metadados do relatório
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        firmId,
        periodStart,
        periodEnd,
        overallCompliance,
        totalCases,
        compliantCases,
        violatedCases,
        averageResponseTime,
        complianceByPriority,
        complianceByCaseType,
        violationsByReason,
        trends,
        riskAnalysis,
        recommendations,
        generatedAt,
        details,
        metadata,
      ];

  /// Taxa de violação (1.0 - compliance)
  double get violationRate => 1.0 - overallCompliance;

  /// Percentual de compliance formatado
  String get compliancePercentage => '${(overallCompliance * 100).toStringAsFixed(1)}%';

  /// Score de qualidade baseado em múltiplos fatores
  double get qualityScore {
    final complianceScore = overallCompliance * 0.6;
    final responseTimeScore = (averageResponseTime <= 24 ? 1.0 : 24 / averageResponseTime) * 0.3;
    final consistencyScore = _calculateConsistencyScore() * 0.1;
    
    return (complianceScore + responseTimeScore + consistencyScore).clamp(0.0, 1.0);
  }

  /// Calcula score de consistência baseado na variação entre tipos
  double _calculateConsistencyScore() {
    if (complianceByCaseType.isEmpty) return 1.0;
    
    final rates = complianceByCaseType.values.map((m) => m.rate).toList();
    final mean = rates.reduce((a, b) => a + b) / rates.length;
    final variance = rates.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / rates.length;
    
    // Score alto para baixa variância (consistência)
    return (1.0 - variance.clamp(0.0, 1.0));
  }

  /// Cria cópia com modificações
  SlaComplianceReportEntity copyWith({
    String? firmId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? overallCompliance,
    int? totalCases,
    int? compliantCases,
    int? violatedCases,
    double? averageResponseTime,
    Map<String, ComplianceMetric>? complianceByPriority,
    Map<String, ComplianceMetric>? complianceByCaseType,
    Map<String, int>? violationsByReason,
    List<ComplianceTrendPoint>? trends,
    RiskAnalysisData? riskAnalysis,
    List<ComplianceRecommendation>? recommendations,
    DateTime? generatedAt,
    List<CaseComplianceDetail>? details,
    Map<String, dynamic>? metadata,
  }) {
    return SlaComplianceReportEntity(
      firmId: firmId ?? this.firmId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      overallCompliance: overallCompliance ?? this.overallCompliance,
      totalCases: totalCases ?? this.totalCases,
      compliantCases: compliantCases ?? this.compliantCases,
      violatedCases: violatedCases ?? this.violatedCases,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      complianceByPriority: complianceByPriority ?? this.complianceByPriority,
      complianceByCaseType: complianceByCaseType ?? this.complianceByCaseType,
      violationsByReason: violationsByReason ?? this.violationsByReason,
      trends: trends ?? this.trends,
      riskAnalysis: riskAnalysis ?? this.riskAnalysis,
      recommendations: recommendations ?? this.recommendations,
      generatedAt: generatedAt ?? this.generatedAt,
      details: details ?? this.details,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Métrica de compliance para uma categoria específica
class ComplianceMetric extends Equatable {
  const ComplianceMetric({
    required this.total,
    required this.compliant,
    required this.violated,
    required this.rate,
    required this.averageTime,
  });

  final int total;
  final int compliant;
  final int violated;
  final double rate;
  final double averageTime;

  @override
  List<Object> get props => [total, compliant, violated, rate, averageTime];
}

/// Ponto de tendência temporal
class ComplianceTrendPoint extends Equatable {
  const ComplianceTrendPoint({
    required this.date,
    required this.complianceRate,
    required this.totalCases,
    required this.averageTime,
  });

  final DateTime date;
  final double complianceRate;
  final int totalCases;
  final double averageTime;

  @override
  List<Object> get props => [date, complianceRate, totalCases, averageTime];
}

/// Dados de análise de risco
class RiskAnalysisData extends Equatable {
  const RiskAnalysisData({
    required this.overallRisk,
    required this.riskFactors,
    required this.criticalAreas,
    required this.riskTrend,
  });

  final String overallRisk; // 'low', 'medium', 'high', 'critical'
  final Map<String, double> riskFactors;
  final List<String> criticalAreas;
  final String riskTrend; // 'improving', 'stable', 'deteriorating'

  @override
  List<Object> get props => [overallRisk, riskFactors, criticalAreas, riskTrend];
}

/// Recomendação de melhoria
class ComplianceRecommendation extends Equatable {
  const ComplianceRecommendation({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.impact,
    required this.effort,
    this.timeframe,
    this.relatedMetrics,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final String impact; // 'low', 'medium', 'high'
  final String effort; // 'low', 'medium', 'high'
  final String? timeframe;
  final List<String>? relatedMetrics;

  @override
  List<Object?> get props => [
        id,
        category,
        title,
        description,
        priority,
        impact,
        effort,
        timeframe,
        relatedMetrics,
      ];
}

/// Detalhe de compliance por caso
class CaseComplianceDetail extends Equatable {
  const CaseComplianceDetail({
    required this.caseId,
    required this.caseType,
    required this.priority,
    required this.isCompliant,
    required this.slaDeadline,
    required this.actualTime,
    this.violationReason,
    this.escalatonLevel,
  });

  final String caseId;
  final String caseType;
  final String priority;
  final bool isCompliant;
  final DateTime slaDeadline;
  final Duration actualTime;
  final String? violationReason;
  final int? escalatonLevel;

  @override
  List<Object?> get props => [
        caseId,
        caseType,
        priority,
        isCompliant,
        slaDeadline,
        actualTime,
        violationReason,
        escalatonLevel,
      ];
}