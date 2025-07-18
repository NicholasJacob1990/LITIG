import '../../domain/entities/lawyer_rating_stats.dart';

/// Modelo de dados para estatísticas de avaliação de advogado
class LawyerRatingStatsModel extends LawyerRatingStats {
  const LawyerRatingStatsModel({
    required super.lawyerId,
    required super.overallRating,
    required super.totalRatings,
    required super.communicationAvg,
    required super.expertiseAvg,
    required super.responsivenessAvg,
    required super.valueAvg,
    required super.starDistribution,
    required super.lastUpdated,
  });

  /// Converte de JSON para modelo
  factory LawyerRatingStatsModel.fromJson(Map<String, dynamic> json) {
    return LawyerRatingStatsModel(
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

  /// Converte modelo para JSON
  @override
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

  /// Converte de entidade para modelo
  factory LawyerRatingStatsModel.fromEntity(LawyerRatingStats entity) {
    return LawyerRatingStatsModel(
      lawyerId: entity.lawyerId,
      overallRating: entity.overallRating,
      totalRatings: entity.totalRatings,
      communicationAvg: entity.communicationAvg,
      expertiseAvg: entity.expertiseAvg,
      responsivenessAvg: entity.responsivenessAvg,
      valueAvg: entity.valueAvg,
      starDistribution: entity.starDistribution,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// Converte modelo para entidade
  LawyerRatingStats toEntity() {
    return LawyerRatingStats(
      lawyerId: lawyerId,
      overallRating: overallRating,
      totalRatings: totalRatings,
      communicationAvg: communicationAvg,
      expertiseAvg: expertiseAvg,
      responsivenessAvg: responsivenessAvg,
      valueAvg: valueAvg,
      starDistribution: starDistribution,
      lastUpdated: lastUpdated,
    );
  }

  /// Cria uma cópia do modelo com campos modificados
  LawyerRatingStatsModel copyWith({
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
    return LawyerRatingStatsModel(
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
} 