import 'package:equatable/equatable.dart';

class MatchedLawyer extends Equatable {
  final String id;
  final String nome;
  final String primaryArea;
  final int reviewCount;
  final double distanceKm;
  final bool isAvailable;
  final String avatarUrl;
  final double? rating;

  // Novos campos do LITGO6
  final double fair; // Score de compatibilidade (substitui score)
  final double equity;
  final LawyerFeatures features;

  const MatchedLawyer({
    required this.id,
    required this.nome,
    required this.primaryArea,
    required this.reviewCount,
    required this.distanceKm,
    required this.isAvailable,
    required this.avatarUrl,
    this.rating,
    required this.fair,
    required this.equity,
    required this.features,
  });

  factory MatchedLawyer.fromJson(Map<String, dynamic> json) {
    return MatchedLawyer(
      id: json['lawyer_id'],
      nome: json['nome'],
      primaryArea: json['primary_area'] ?? 'Não informado',
      reviewCount: json['review_count'] ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] ?? false,
      avatarUrl: json['avatar_url'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['name'] ?? 'Advogado')}&background=6B7280&color=fff',
      rating: (json['rating'] as num?)?.toDouble(),
      fair: (json['fair'] as num?)?.toDouble() ?? 0.0,
      equity: (json['equity'] as num?)?.toDouble() ?? 0.0,
      features: LawyerFeatures.fromJson(json['features'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        nome,
        primaryArea,
        reviewCount,
        distanceKm,
        isAvailable,
        avatarUrl,
        rating,
        fair,
        equity,
        features,
      ];
}

class LawyerFeatures extends Equatable {
  final double successRate; // T
  final double softSkills;  // C
  final int responseTime; // U

  const LawyerFeatures({
    required this.successRate,
    required this.softSkills,
    required this.responseTime,
  });

  factory LawyerFeatures.fromJson(Map<String, dynamic> json) {
    return LawyerFeatures(
      successRate: (json['T'] as num?)?.toDouble() ?? 0.0,
      softSkills: (json['C'] as num?)?.toDouble() ?? 0.0,
      responseTime: (json['U'] as num?)?.toInt() ?? 24, // Fallback para 24h
    );
  }

  @override
  List<Object?> get props => [successRate, softSkills, responseTime];
} 