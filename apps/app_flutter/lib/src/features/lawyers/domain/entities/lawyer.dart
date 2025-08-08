import 'package:equatable/equatable.dart';

class Lawyer extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final String oab;
  final List<String> expertiseAreas;
  final double rating;
  final bool isAvailable;
  final double? distanceKm;
  final String plan; // NOVO: Plano do advogado (PRO, FREE, etc.)
  final double? latitude; // NOVO: localização opcional
  final double? longitude; // NOVO: localização opcional

  const Lawyer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.oab,
    required this.expertiseAreas,
    required this.rating,
    required this.isAvailable,
    this.distanceKm,
    this.plan = 'FREE', // NOVO: Padrão FREE para compatibilidade
    this.latitude,
    this.longitude,
  });

  /// Verifica se o advogado tem plano PRO
  bool get isPro => plan.toUpperCase() == 'PRO';

  /// Verifica se o advogado tem plano FREE
  bool get isFree => plan.toUpperCase() == 'FREE';

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        oab,
        expertiseAreas,
        rating,
        isAvailable,
        distanceKm,
        plan, // NOVO
        latitude,
        longitude,
      ];
} 