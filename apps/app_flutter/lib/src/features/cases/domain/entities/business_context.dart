import 'package:equatable/equatable.dart';

/// Análise competitiva do caso
class CompetitiveAnalysis extends Equatable {
  final int competitorCount; // Quantos advogados concorrem
  final List<String> competitorProfiles; // Perfis dos concorrentes
  final String differentiation; // Como se diferenciar
  final double winProbability; // Probabilidade de ganhar o caso 0-100
  
  const CompetitiveAnalysis({
    required this.competitorCount,
    required this.competitorProfiles,
    required this.differentiation,
    required this.winProbability,
  });

  factory CompetitiveAnalysis.fromJson(Map<String, dynamic> json) {
    return CompetitiveAnalysis(
      competitorCount: json['competitor_count'] as int? ?? 0,
      competitorProfiles: (json['competitor_profiles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      differentiation: json['differentiation'] as String? ?? '',
      winProbability: (json['win_probability'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'competitor_count': competitorCount,
      'competitor_profiles': competitorProfiles,
      'differentiation': differentiation,
      'win_probability': winProbability,
    };
  }

  @override
  List<Object?> get props => [competitorCount, competitorProfiles, differentiation, winProbability];
}

/// Perfil de risco do caso
class RiskProfile extends Equatable {
  final double legalRisk; // Risco jurídico 0-100
  final double financialRisk; // Risco financeiro 0-100
  final double reputationalRisk; // Risco reputacional 0-100
  final double clientRisk; // Risco do cliente 0-100
  final String riskSummary; // Resumo dos riscos
  final List<String> mitigationStrategies; // Estratégias de mitigação

  const RiskProfile({
    required this.legalRisk,
    required this.financialRisk,
    required this.reputationalRisk,
    required this.clientRisk,
    required this.riskSummary,
    required this.mitigationStrategies,
  });

  factory RiskProfile.fromJson(Map<String, dynamic> json) {
    return RiskProfile(
      legalRisk: (json['legal_risk'] as num?)?.toDouble() ?? 0.0,
      financialRisk: (json['financial_risk'] as num?)?.toDouble() ?? 0.0,
      reputationalRisk: (json['reputational_risk'] as num?)?.toDouble() ?? 0.0,
      clientRisk: (json['client_risk'] as num?)?.toDouble() ?? 0.0,
      riskSummary: json['risk_summary'] as String? ?? '',
      mitigationStrategies: (json['mitigation_strategies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  /// Retorna o risco geral calculado
  double get overallRisk => (legalRisk + financialRisk + reputationalRisk + clientRisk) / 4;

  /// Retorna classificação do risco
  String get riskLevel {
    final overall = overallRisk;
    if (overall <= 30) return 'Baixo';
    if (overall <= 60) return 'Médio';
    return 'Alto';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'legal_risk': legalRisk,
      'financial_risk': financialRisk,
      'reputational_risk': reputationalRisk,
      'client_risk': clientRisk,
      'risk_summary': riskSummary,
      'mitigation_strategies': mitigationStrategies,
    };
  }

  @override
  List<Object?> get props => [legalRisk, financialRisk, reputationalRisk, clientRisk, riskSummary, mitigationStrategies];
}

/// Contexto comercial completo do caso na visão do advogado
/// Fornece todas as informações que o advogado precisa para análise de negócio
class BusinessContext extends Equatable {
  // Análise financeira
  final double estimatedValue; // Valor estimado total do caso
  final double investmentRequired; // Investimento necessário em horas/recursos
  final double roiProjection; // ROI projetado em %
  final String revenueModel; // fixed, hourly, success_fee, hybrid
  final double expectedHours; // Horas estimadas de trabalho
  final double hourlyRateRecommended; // Taxa horária recomendada
  
  // Análise temporal
  final Duration estimatedDuration; // Duração estimada do caso
  final DateTime? expectedStartDate; // Data prevista de início
  final DateTime? expectedEndDate; // Data prevista de conclusão
  final List<String> criticalDeadlines; // Prazos críticos
  
  // Análise de complexidade
  final double complexityScore; // Complexidade 0-100
  final List<String> complexityFactors; // Fatores de complexidade
  final String difficultyLevel; // simple, medium, complex, expert
  final List<String> requiredSkills; // Habilidades necessárias
  
  // Análise de mercado
  final String marketSegment; // Segmento de mercado
  final double marketDemand; // Demanda do mercado 0-100
  final List<String> marketTrends; // Tendências do mercado
  final String competitivePosition; // Posição competitiva
  
  // Análise de oportunidade
  final List<String> upsellOpportunities; // Oportunidades de venda adicional
  final double expansionPotential; // Potencial de expansão 0-100
  final List<String> referralOpportunities; // Oportunidades de indicação
  final String strategicValue; // Valor estratégico do caso
  
  // Análise competitiva e de risco
  final CompetitiveAnalysis competition;
  final RiskProfile riskProfile;

  const BusinessContext({
    required this.estimatedValue,
    required this.investmentRequired,
    required this.roiProjection,
    required this.revenueModel,
    required this.expectedHours,
    required this.hourlyRateRecommended,
    required this.estimatedDuration,
    this.expectedStartDate,
    this.expectedEndDate,
    required this.criticalDeadlines,
    required this.complexityScore,
    required this.complexityFactors,
    required this.difficultyLevel,
    required this.requiredSkills,
    required this.marketSegment,
    required this.marketDemand,
    required this.marketTrends,
    required this.competitivePosition,
    required this.upsellOpportunities,
    required this.expansionPotential,
    required this.referralOpportunities,
    required this.strategicValue,
    required this.competition,
    required this.riskProfile,
  });

  factory BusinessContext.fromJson(Map<String, dynamic> json) {
    return BusinessContext(
      estimatedValue: (json['estimated_value'] as num?)?.toDouble() ?? 0.0,
      investmentRequired: (json['investment_required'] as num?)?.toDouble() ?? 0.0,
      roiProjection: (json['roi_projection'] as num?)?.toDouble() ?? 0.0,
      revenueModel: json['revenue_model'] as String? ?? 'fixed',
      expectedHours: (json['expected_hours'] as num?)?.toDouble() ?? 0.0,
      hourlyRateRecommended: (json['hourly_rate_recommended'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: Duration(days: json['estimated_duration_days'] as int? ?? 30),
      expectedStartDate: json['expected_start_date'] != null 
          ? DateTime.parse(json['expected_start_date'] as String)
          : null,
      expectedEndDate: json['expected_end_date'] != null 
          ? DateTime.parse(json['expected_end_date'] as String)
          : null,
      criticalDeadlines: (json['critical_deadlines'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      complexityScore: (json['complexity_score'] as num?)?.toDouble() ?? 0.0,
      complexityFactors: (json['complexity_factors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      requiredSkills: (json['required_skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      marketSegment: json['market_segment'] as String? ?? '',
      marketDemand: (json['market_demand'] as num?)?.toDouble() ?? 0.0,
      marketTrends: (json['market_trends'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      competitivePosition: json['competitive_position'] as String? ?? '',
      upsellOpportunities: (json['upsell_opportunities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      expansionPotential: (json['expansion_potential'] as num?)?.toDouble() ?? 0.0,
      referralOpportunities: (json['referral_opportunities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      strategicValue: json['strategic_value'] as String? ?? '',
      competition: CompetitiveAnalysis.fromJson(json['competition'] ?? {}),
      riskProfile: RiskProfile.fromJson(json['risk_profile'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimated_value': estimatedValue,
      'investment_required': investmentRequired,
      'roi_projection': roiProjection,
      'revenue_model': revenueModel,
      'expected_hours': expectedHours,
      'hourly_rate_recommended': hourlyRateRecommended,
      'estimated_duration_days': estimatedDuration.inDays,
      'expected_start_date': expectedStartDate?.toIso8601String(),
      'expected_end_date': expectedEndDate?.toIso8601String(),
      'critical_deadlines': criticalDeadlines,
      'complexity_score': complexityScore,
      'complexity_factors': complexityFactors,
      'difficulty_level': difficultyLevel,
      'required_skills': requiredSkills,
      'market_segment': marketSegment,
      'market_demand': marketDemand,
      'market_trends': marketTrends,
      'competitive_position': competitivePosition,
      'upsell_opportunities': upsellOpportunities,
      'expansion_potential': expansionPotential,
      'referral_opportunities': referralOpportunities,
      'strategic_value': strategicValue,
      'competition': competition.toJson(),
      'risk_profile': riskProfile.toJson(),
    };
  }

  /// Retorna se o caso é rentável
  bool get isProfitable => roiProjection > 0;

  /// Retorna se é um caso de alta complexidade
  bool get isHighComplexity => complexityScore >= 70;

  /// Retorna se tem potencial de expansão
  bool get hasExpansionPotential => expansionPotential >= 70;

  /// Retorna se é um caso estratégico
  bool get isStrategic => strategicValue.isNotEmpty;
  
  /// Getters adicionais para compatibilidade
  String get estimatedDurationFormatted {
    final days = estimatedDuration.inDays;
    if (days < 30) return '$days dias';
    if (days < 365) return '${(days / 30).round()} meses';
    return '${(days / 365).round()} anos';
  }
  
  String get complexityLevel => difficultyLevel;
  
  double get clientUrgency => 50.0; // Valor padrão
  double get realUrgency => 50.0; // Valor padrão

  @override
  List<Object?> get props => [
    estimatedValue,
    investmentRequired,
    roiProjection,
    revenueModel,
    expectedHours,
    hourlyRateRecommended,
    estimatedDuration,
    expectedStartDate,
    expectedEndDate,
    criticalDeadlines,
    complexityScore,
    complexityFactors,
    difficultyLevel,
    requiredSkills,
    marketSegment,
    marketDemand,
    marketTrends,
    competitivePosition,
    upsellOpportunities,
    expansionPotential,
    referralOpportunities,
    strategicValue,
    competition,
    riskProfile,
  ];
} 