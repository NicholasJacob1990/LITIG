class CaseOffer {
  final String id;
  final String caseId;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int clientChoiceOrder;
  
  // Detalhes do caso
  final String caseSummary;
  final String legalArea;
  final String urgencyLevel;
  final String? estimatedFee;
  final String clientLocation;

  const CaseOffer({
    required this.id,
    required this.caseId,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.clientChoiceOrder,
    required this.caseSummary,
    required this.legalArea,
    required this.urgencyLevel,
    this.estimatedFee,
    required this.clientLocation,
  });

  factory CaseOffer.fromJson(Map<String, dynamic> json) {
    // Analisando o payload da API real do offers.py, ele parece um pouco diferente do plano
    // A API real parece retornar um objeto Offer mais direto.
    // Vamos adaptar o fromJson para a API existente em offers.py
    // A API retorna `case_details` aninhado, o plano não. O plano parece mais correto.
    // O plano tem `offer_details`. `offers.py` não mostra o que `Offer` é.
    // O plano é a fonte da verdade aqui.
    return CaseOffer(
      id: json['id'],
      caseId: json['case_id'],
      status: json['status'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      clientChoiceOrder: json['client_choice_order'],
      caseSummary: json['offer_details']['case_summary'] ?? '',
      legalArea: json['offer_details']['legal_area'] ?? '',
      urgencyLevel: json['offer_details']['urgency_level'] ?? '',
      estimatedFee: json['offer_details']['estimated_fee'],
      clientLocation: json['offer_details']['client_location'] ?? '',
    );
  }
}

class OfferStats {
  final int totalOffers;
  final int accepted;
  final int rejected;
  final int expired;
  final double acceptanceRate;
  final double avgResponseTimeHours;

  const OfferStats({
    required this.totalOffers,
    required this.accepted,
    required this.rejected,
    required this.expired,
    required this.acceptanceRate,
    required this.avgResponseTimeHours,
  });

  factory OfferStats.fromJson(Map<String, dynamic> json) {
    return OfferStats(
      totalOffers: json['total_offers'],
      accepted: json['accepted'],
      rejected: json['rejected'],
      expired: json['expired'],
      acceptanceRate: (json['acceptance_rate'] ?? 0.0).toDouble(),
      avgResponseTimeHours: (json['avg_response_time_hours'] ?? 0.0).toDouble(),
    );
  }
} 