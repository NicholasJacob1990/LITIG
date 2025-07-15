import 'package:equatable/equatable.dart';

class SearchParams extends Equatable {
  final String? query;
  final String preset;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final bool includeFirms;
  
  // Novos campos para filtros avançados
  final double? minRating;
  final double? maxDistance;
  final bool? onlyAvailable;
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;

  const SearchParams({
    this.query,
    this.preset = 'balanced',
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.includeFirms = true,
    // Novos parâmetros opcionais
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
        preset,
        latitude,
        longitude,
        radiusKm,
        includeFirms,
        minRating,
        maxDistance,
        onlyAvailable,
        minPrice,
        maxPrice,
        priceType,
      ];
} 
 