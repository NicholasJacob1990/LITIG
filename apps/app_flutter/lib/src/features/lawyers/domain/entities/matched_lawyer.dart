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
  final double fair;
  final double equity;
  final LawyerFeatures features;
  final int? experienceYears;
  final List<String> awards;
  final String? professionalSummary;
  final List<String> specializations;
  final String plan; // NOVO: Plano do advogado
  final bool isExternal; // NOVO: Indica se é um perfil externo (busca híbrida)

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
    this.experienceYears,
    this.awards = const [],
    this.professionalSummary,
    this.specializations = const [],
    this.plan = 'FREE', // NOVO: Padrão FREE
    this.isExternal = false, // NOVO: Padrão para perfis internos
  });

  /// Verifica se o advogado tem plano PRO
  bool get isPro => plan.toUpperCase() == 'PRO';

  /// Verifica se o advogado tem plano FREE
  bool get isFree => plan.toUpperCase() == 'FREE';

  /// Verifica se é um perfil verificado da plataforma
  bool get isVerified => !isExternal;

  /// Verifica se é um perfil público sugerido
  bool get isPublicSuggestion => isExternal;

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
      experienceYears: json['experience'] ?? json['experience_years'],
      awards: List<String>.from(json['awards'] ?? []),
      professionalSummary: json['professional_summary'] ?? json['bio'],
      specializations: List<String>.from(json['specializations'] ?? []),
      plan: json['plan'] as String? ?? 'FREE', // NOVO: Consumir plano do backend
      isExternal: json['is_external'] as bool? ?? false, // NOVO: Busca híbrida
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lawyer_id': id,
      'nome': nome,
      'primary_area': primaryArea,
      'review_count': reviewCount,
      'distance_km': distanceKm,
      'is_available': isAvailable,
      'avatar_url': avatarUrl,
      'rating': rating,
      'fair': fair,
      'fair_score': fair, // Alias para compatibilidade
      'equity': equity,
      'features': {
        'T': features.successRate,
        'C': features.softSkills,
        'U': features.responseTime,
      },
      'specializations': specializations,
      'is_external': isExternal,
    };
  }

  @override
  List<Object?> get props => [
    id, nome, primaryArea, reviewCount, distanceKm, isAvailable, avatarUrl,
    rating, fair, equity, features, experienceYears, awards, 
    professionalSummary, specializations, plan, isExternal, // NOVO
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