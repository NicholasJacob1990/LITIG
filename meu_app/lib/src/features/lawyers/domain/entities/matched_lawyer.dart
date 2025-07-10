import 'package:equatable/equatable.dart';

class MatchedLawyer extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final String primaryArea;
  final double fairScore;
  final double rating;
  final double distanceKm;
  final int casesCount;

  const MatchedLawyer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.primaryArea,
    required this.fairScore,
    required this.rating,
    required this.distanceKm,
    required this.casesCount,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, primaryArea, fairScore, rating, distanceKm, casesCount];
} 