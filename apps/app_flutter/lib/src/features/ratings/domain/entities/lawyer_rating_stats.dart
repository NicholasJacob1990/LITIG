import 'package:equatable/equatable.dart';

/// Entidade que representa as estatísticas de avaliação de um advogado
class LawyerRatingStats extends Equatable {
  final String lawyerId;
  final double overallRating;
  final int totalRatings;
  final double communicationAvg;
  final double expertiseAvg;
  final double responsivenessAvg;
  final double valueAvg;
  final Map<String, int> starDistribution;
  final DateTime lastUpdated;

  const LawyerRatingStats({
    required this.lawyerId,
    required this.overallRating,
    required this.totalRatings,
    required this.communicationAvg,
    required this.expertiseAvg,
    required this.responsivenessAvg,
    required this.valueAvg,
    required this.starDistribution,
    required this.lastUpdated,
  });

  /// Cria estatísticas vazias para um advogado
  factory LawyerRatingStats.empty(String lawyerId) {
    return LawyerRatingStats(
      lawyerId: lawyerId,
      overallRating: 0.0,
      totalRatings: 0,
      communicationAvg: 0.0,
      expertiseAvg: 0.0,
      responsivenessAvg: 0.0,
      valueAvg: 0.0,
      starDistribution: const {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      lastUpdated: DateTime.now(),
    );
  }

  /// Converte de JSON para entidade
  factory LawyerRatingStats.fromJson(Map<String, dynamic> json) {
    return LawyerRatingStats(
      lawyerId: json['lawyer_id'],
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      communicationAvg: (json['communication_avg'] as num?)?.toDouble() ?? 0.0,
      expertiseAvg: (json['expertise_avg'] as num?)?.toDouble() ?? 0.0,
      responsivenessAvg: (json['responsiveness_avg'] as num?)?.toDouble() ?? 0.0,
      valueAvg: (json['value_avg'] as num?)?.toDouble() ?? 0.0,
      starDistribution: Map<String, int>.from(json['star_distribution'] ?? {}),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }

  /// Converte entidade para JSON
  Map<String, dynamic> toJson() {
    return {
      'lawyer_id': lawyerId,
      'overall_rating': overallRating,
      'total_ratings': totalRatings,
      'communication_avg': communicationAvg,
      'expertise_avg': expertiseAvg,
      'responsiveness_avg': responsivenessAvg,
      'value_avg': valueAvg,
      'star_distribution': starDistribution,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Cria uma cópia das estatísticas com campos modificados
  LawyerRatingStats copyWith({
    String? lawyerId,
    double? overallRating,
    int? totalRatings,
    double? communicationAvg,
    double? expertiseAvg,
    double? responsivenessAvg,
    double? valueAvg,
    Map<String, int>? starDistribution,
    DateTime? lastUpdated,
  }) {
    return LawyerRatingStats(
      lawyerId: lawyerId ?? this.lawyerId,
      overallRating: overallRating ?? this.overallRating,
      totalRatings: totalRatings ?? this.totalRatings,
      communicationAvg: communicationAvg ?? this.communicationAvg,
      expertiseAvg: expertiseAvg ?? this.expertiseAvg,
      responsivenessAvg: responsivenessAvg ?? this.responsivenessAvg,
      valueAvg: valueAvg ?? this.valueAvg,
      starDistribution: starDistribution ?? this.starDistribution,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Retorna true se o advogado tem avaliações
  bool get hasRatings => totalRatings > 0;

  /// Retorna true se o advogado é recomendado (nota >= 4.0)
  bool get isRecommended => overallRating >= 4.0 && totalRatings >= 5;

  /// Retorna o percentual de cada estrela
  Map<String, double> get starPercentages {
    if (totalRatings == 0) return {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    
    return starDistribution.map(
      (key, value) => MapEntry(key, (value / totalRatings) * 100),
    );
  }

  /// Retorna a classificação textual baseada na nota
  String get ratingText {
    if (overallRating >= 4.5) return 'Excelente';
    if (overallRating >= 4.0) return 'Muito Bom';
    if (overallRating >= 3.5) return 'Bom';
    if (overallRating >= 3.0) return 'Regular';
    if (overallRating >= 2.0) return 'Ruim';
    if (overallRating >= 1.0) return 'Muito Ruim';
    return 'Sem Avaliações';
  }

  /// Retorna a cor associada à nota
  String get ratingColor {
    if (overallRating >= 4.5) return '#4CAF50'; // Verde
    if (overallRating >= 4.0) return '#8BC34A'; // Verde claro
    if (overallRating >= 3.5) return '#CDDC39'; // Lima
    if (overallRating >= 3.0) return '#FFC107'; // Amarelo
    if (overallRating >= 2.0) return '#FF9800'; // Laranja
    if (overallRating >= 1.0) return '#F44336'; // Vermelho
    return '#9E9E9E'; // Cinza
  }

  /// Retorna o ponto mais forte do advogado
  String get strongestPoint {
    final ratings = {
      'Comunicação': communicationAvg,
      'Expertise': expertiseAvg,
      'Responsividade': responsivenessAvg,
      'Custo-Benefício': valueAvg,
    };
    
    if (ratings.values.every((rating) => rating == 0)) return 'N/A';
    
    final strongest = ratings.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return strongest.key;
  }

  /// Retorna o ponto que precisa melhorar
  String get improvementArea {
    final ratings = {
      'Comunicação': communicationAvg,
      'Expertise': expertiseAvg,
      'Responsividade': responsivenessAvg,
      'Custo-Benefício': valueAvg,
    };
    
    if (ratings.values.every((rating) => rating == 0)) return 'N/A';
    
    final weakest = ratings.entries
        .reduce((a, b) => a.value < b.value ? a : b);
    
    return weakest.key;
  }

  /// Formata as estatísticas para exibição
  String get formattedStats {
    if (!hasRatings) return 'Nenhuma avaliação ainda';
    
    return '$totalRatings avaliação${totalRatings > 1 ? 'ões' : ''} • ${overallRating.toStringAsFixed(1)}/5.0';
  }

  @override
  List<Object?> get props => [
        lawyerId,
        overallRating,
        totalRatings,
        communicationAvg,
        expertiseAvg,
        responsivenessAvg,
        valueAvg,
        starDistribution,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'LawyerRatingStats{lawyerId: $lawyerId, overallRating: $overallRating, totalRatings: $totalRatings}';
  }
} 