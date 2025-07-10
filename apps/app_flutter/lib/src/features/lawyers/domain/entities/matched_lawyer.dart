import 'package:equatable/equatable.dart';

class MatchedLawyer extends Equatable {
  final String id;
  final String nome;
  final List<String> expertiseAreas;
  final double score;
  final double distanceKm;
  final int? estimatedResponseTimeHours;
  final double? rating;
  final bool isAvailable;
  final String avatarUrl;

  const MatchedLawyer({
    required this.id,
    required this.nome,
    required this.expertiseAreas,
    required this.score,
    required this.distanceKm,
    this.estimatedResponseTimeHours,
    this.rating,
    required this.isAvailable,
    required this.avatarUrl,
  });

  factory MatchedLawyer.fromJson(Map<String, dynamic> json) {
    return MatchedLawyer(
      id: json['id'],
      nome: json['nome'],
      expertiseAreas: List<String>.from(json['expertise_areas'] ?? []),
      score: (json['score'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedResponseTimeHours: json['estimated_response_time_hours'],
      rating: (json['rating'] as num?)?.toDouble(),
      isAvailable: json['is_available'] ?? false,
      avatarUrl: json['avatar_url'] ?? 'https://i.pravatar.cc/150?u=${json['id']}',
    );
  }

  @override
  List<Object?> get props => [
        id,
        nome,
        expertiseAreas,
        score,
        distanceKm,
        estimatedResponseTimeHours,
        rating,
        isAvailable,
        avatarUrl,
      ];
} 