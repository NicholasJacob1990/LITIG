import 'package:equatable/equatable.dart';

/// Status do cliente para contexto de relacionamento
enum ClientStatus {
  active('active'),
  potential('potential'),
  problematic('problematic'),
  vip('vip'),
  returning('returning');

  const ClientStatus(this.value);
  final String value;

  static ClientStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ClientStatus.active;
      case 'potential':
        return ClientStatus.potential;
      case 'problematic':
        return ClientStatus.problematic;
      case 'vip':
        return ClientStatus.vip;
      case 'returning':
        return ClientStatus.returning;
      default:
        return ClientStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case ClientStatus.active:
        return 'Ativo';
      case ClientStatus.potential:
        return 'Potencial';
      case ClientStatus.problematic:
        return 'Atenção';
      case ClientStatus.vip:
        return 'VIP';
      case ClientStatus.returning:
        return 'Recorrente';
    }
  }
}

/// Informações completas do cliente na visão do advogado
/// Contraparte da LawyerInfo - Garante simetria de informações
class ClientInfo extends Equatable {
  final String id;
  final String name;
  final String type; // PF, PJ
  final String email;
  final String phone;
  final String? company;
  final String? avatarUrl;
  
  // Métricas de relacionamento (equivalente ao rating do advogado)
  final double riskScore; // 0-100 (0 = baixo risco, 100 = alto risco)
  final int previousCases; // Histórico de casos
  final double averageRating; // Rating médio que o cliente dá aos advogados
  final double paymentReliability; // Confiabilidade de pagamento 0-100
  
  // Perfil de comunicação
  final String preferredCommunication; // email, phone, whatsapp, teams
  final int averageResponseTimeHours; // Tempo médio de resposta em horas
  final List<String> specialNeeds; // Necessidades especiais
  final String? preferredLanguage; // Idioma preferido
  
  // Contexto comercial
  final ClientStatus status;
  final double budgetRangeMin; // Faixa de orçamento mínima
  final double budgetRangeMax; // Faixa de orçamento máxima
  final String decisionMaker; // Quem toma a decisão final
  final bool isDecisionMaker; // Se este contato é o decisor
  
  // Análise de potencial
  final List<String> interests; // Áreas de interesse jurídico
  final double expansionPotential; // Potencial de novos casos 0-100
  final String? referralSource; // Como chegou até a plataforma
  final DateTime? lastInteraction; // Última interação
  
  // Contexto empresarial (para PJ)
  final String? industry; // Setor da empresa
  final int? companySize; // Tamanho da empresa (funcionários)
  final String? companyStage; // startup, growth, mature, enterprise
  
  const ClientInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    this.company,
    this.avatarUrl,
    required this.riskScore,
    required this.previousCases,
    required this.averageRating,
    required this.paymentReliability,
    required this.preferredCommunication,
    required this.averageResponseTimeHours,
    required this.specialNeeds,
    this.preferredLanguage,
    required this.status,
    required this.budgetRangeMin,
    required this.budgetRangeMax,
    required this.decisionMaker,
    required this.isDecisionMaker,
    required this.interests,
    required this.expansionPotential,
    this.referralSource,
    this.lastInteraction,
    this.industry,
    this.companySize,
    this.companyStage,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      company: json['company'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      previousCases: json['previous_cases'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      paymentReliability: (json['payment_reliability'] as num?)?.toDouble() ?? 100.0,
      preferredCommunication: json['preferred_communication'] as String? ?? 'email',
      averageResponseTimeHours: json['average_response_time_hours'] as int? ?? 24,
      specialNeeds: (json['special_needs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      preferredLanguage: json['preferred_language'] as String?,
      status: ClientStatus.fromString(json['status'] as String? ?? 'active'),
      budgetRangeMin: (json['budget_range_min'] as num?)?.toDouble() ?? 0.0,
      budgetRangeMax: (json['budget_range_max'] as num?)?.toDouble() ?? 0.0,
      decisionMaker: json['decision_maker'] as String? ?? '',
      isDecisionMaker: json['is_decision_maker'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      expansionPotential: (json['expansion_potential'] as num?)?.toDouble() ?? 0.0,
      referralSource: json['referral_source'] as String?,
      lastInteraction: json['last_interaction'] != null
          ? DateTime.parse(json['last_interaction'] as String)
          : null,
      industry: json['industry'] as String?,
      companySize: json['company_size'] as int?,
      companyStage: json['company_stage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'email': email,
      'phone': phone,
      'company': company,
      'avatar_url': avatarUrl,
      'risk_score': riskScore,
      'previous_cases': previousCases,
      'average_rating': averageRating,
      'payment_reliability': paymentReliability,
      'preferred_communication': preferredCommunication,
      'average_response_time_hours': averageResponseTimeHours,
      'special_needs': specialNeeds,
      'preferred_language': preferredLanguage,
      'status': status.value,
      'budget_range_min': budgetRangeMin,
      'budget_range_max': budgetRangeMax,
      'decision_maker': decisionMaker,
      'is_decision_maker': isDecisionMaker,
      'interests': interests,
      'expansion_potential': expansionPotential,
      'referral_source': referralSource,
      'last_interaction': lastInteraction?.toIso8601String(),
      'industry': industry,
      'company_size': companySize,
      'company_stage': companyStage,
    };
  }

  /// Retorna indicador de risco visual
  String get riskLevel {
    if (riskScore <= 30) return 'Baixo';
    if (riskScore <= 60) return 'Médio';
    return 'Alto';
  }

  /// Retorna se é um cliente corporativo
  bool get isCorporate => type == 'PJ';

  /// Retorna se é um cliente individual
  bool get isIndividual => type == 'PF';

  /// Retorna faixa de orçamento formatada
  String get budgetRangeFormatted {
    if (budgetRangeMin == 0 && budgetRangeMax == 0) return 'Não informado';
    return 'R\$ ${budgetRangeMin.toStringAsFixed(0)} - R\$ ${budgetRangeMax.toStringAsFixed(0)}';
  }

  /// Retorna se tem potencial de expansão
  bool get hasExpansionPotential => expansionPotential >= 70;

  /// Retorna se é um cliente VIP
  bool get isVIP => status == ClientStatus.vip;

  /// Retorna se é um cliente problemático
  bool get isProblematic => status == ClientStatus.problematic;

  /// Retorna tempo de resposta formatado
  String get responseTimeFormatted {
    if (averageResponseTimeHours <= 2) return 'Muito rápido (${averageResponseTimeHours}h)';
    if (averageResponseTimeHours <= 8) return 'Rápido (${averageResponseTimeHours}h)';
    if (averageResponseTimeHours <= 24) return 'Normal (${averageResponseTimeHours}h)';
    return 'Lento (${averageResponseTimeHours}h)';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    email,
    phone,
    company,
    avatarUrl,
    riskScore,
    previousCases,
    averageRating,
    paymentReliability,
    preferredCommunication,
    averageResponseTimeHours,
    specialNeeds,
    preferredLanguage,
    status,
    budgetRangeMin,
    budgetRangeMax,
    decisionMaker,
    isDecisionMaker,
    interests,
    expansionPotential,
    referralSource,
    lastInteraction,
    industry,
    companySize,
    companyStage,
  ];
} 