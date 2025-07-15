import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';

class LawyerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String oab;
  final List<String> expertiseAreas;
  final Map<String, double>? coordinates;
  final double? distanceKm;
  final double score;
  final int estimatedResponseTimeHours;
  final double rating;
  final List<String> reviewTexts;
  final bool isAvailable;
  final int totalCases;
  final double estimatedSuccessRate;
  final double specializationScore;
  final String activityLevel;

  const LawyerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.oab,
    required this.expertiseAreas,
    this.coordinates,
    this.distanceKm,
    required this.score,
    required this.estimatedResponseTimeHours,
    required this.rating,
    required this.reviewTexts,
    required this.isAvailable,
    required this.totalCases,
    required this.estimatedSuccessRate,
    required this.specializationScore,
    required this.activityLevel,
  });

  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      id: json['id'] as String,
      name: json['nome'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['nome'] as String? ?? 'L')}',
      oab: json['oab_numero'] as String? ?? 'N/A',
      expertiseAreas: (json['expertise_areas'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      coordinates: (json['coordinates'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, (value as num).toDouble())),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      score: (json['score'] as num? ?? 0.0).toDouble(),
      estimatedResponseTimeHours: (json['estimated_response_time_hours'] as int? ?? 24),
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      reviewTexts: (json['review_texts'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      isAvailable: json['is_available'] as bool? ?? false,
      totalCases: json['total_cases'] as int? ?? 0,
      estimatedSuccessRate: (json['estimated_success_rate'] as num? ?? 0.0).toDouble(),
      specializationScore: (json['specialization_score'] as num? ?? 0.0).toDouble(),
      activityLevel: json['activity_level'] as String? ?? 'unknown',
    );
  }

  Lawyer toEntity() {
    return Lawyer(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      oab: oab,
      expertiseAreas: expertiseAreas,
      rating: rating,
      isAvailable: isAvailable,
      distanceKm: distanceKm,
    );
  }
} 