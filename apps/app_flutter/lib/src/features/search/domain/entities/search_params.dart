import 'package:equatable/equatable.dart';

enum SearchType { keyword, semantic }

class SearchParams extends Equatable {
  final String? query;
  final SearchType searchType;
  final String preset;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final bool includeFirms;
  
  // Campo para busca específica por caso
  final String? caseId;
  
  // Novos campos para filtros avançados
  final String? area;
  final String? specialty;
  final double? minRating;
  final double? maxDistance;
  final bool? onlyAvailable;
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;

  const SearchParams({
    this.query,
    this.searchType = SearchType.keyword,
    this.preset = 'balanced',
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.includeFirms = true,
    this.caseId,
    // Novos parâmetros opcionais
    this.area,
    this.specialty,
    this.minRating,
    this.maxDistance,
    this.onlyAvailable,
    this.minPrice,
    this.maxPrice,
    this.priceType,
  });

  Map<String, dynamic> toQuery() {
    final Map<String, dynamic> queryParams = {};
    if (query != null) queryParams['query'] = query;
    if (caseId != null) queryParams['case_id'] = caseId;
    if (area != null) queryParams['area'] = area;
    if (specialty != null) queryParams['specialty'] = specialty;
    if (minRating != null) queryParams['min_rating'] = minRating;
    if (maxDistance != null) queryParams['max_distance'] = maxDistance;
    if (onlyAvailable != null) queryParams['is_available'] = onlyAvailable;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;
    
    return queryParams;
  }

  @override
  List<Object?> get props => [
        query,
        searchType,
        preset,
        latitude,
        longitude,
        radiusKm,
        includeFirms,
        caseId,
        area,
        specialty,
        minRating,
        maxDistance,
        onlyAvailable,
        minPrice,
        maxPrice,
        priceType,
      ];
} 
 