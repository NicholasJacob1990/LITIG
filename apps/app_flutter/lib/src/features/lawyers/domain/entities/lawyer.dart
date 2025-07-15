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

  const Lawyer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.oab,
    required this.expertiseAreas,
    required this.rating,
    required this.isAvailable,
    this.distanceKm,
  });

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
      ];
} 