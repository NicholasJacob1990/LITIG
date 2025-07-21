part of 'matches_bloc.dart';

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();
}

class FetchMatches extends MatchesEvent {
  final String? caseId;

  const FetchMatches({this.caseId});

  @override
  List<Object?> get props => [caseId];
}

class SearchLawyers extends MatchesEvent {
  final String query;
  final String location;
  final LegalArea? legalArea;
  final double minPrice;
  final double maxPrice;
  final double minRating;

  const SearchLawyers({
    required this.query,
    required this.location,
    this.legalArea,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
  });

  @override
  List<Object?> get props => [
    query,
    location,
    legalArea,
    minPrice,
    maxPrice,
    minRating,
  ];
} 