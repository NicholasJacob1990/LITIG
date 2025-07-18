import 'package:equatable/equatable.dart';
import '../../domain/entities/case_rating.dart';
import '../../domain/entities/lawyer_rating_stats.dart';

/// Estados do sistema de avaliações
abstract class RatingState extends Equatable {
  const RatingState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class RatingInitial extends RatingState {
  const RatingInitial();
}

/// Estado de carregamento
class RatingLoading extends RatingState {
  const RatingLoading();
}

/// Estado de submissão de avaliação
class RatingSubmitting extends RatingState {
  const RatingSubmitting();
}

/// Estado de avaliação submetida com sucesso
class RatingSubmitted extends RatingState {
  final String ratingId;
  final String message;

  const RatingSubmitted({
    required this.ratingId,
    this.message = 'Avaliação enviada com sucesso!',
  });

  @override
  List<Object?> get props => [ratingId, message];
}

/// Estado com avaliações de advogado carregadas
class LawyerRatingsLoaded extends RatingState {
  final List<CaseRating> ratings;
  final LawyerRatingStats? stats;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const LawyerRatingsLoaded({
    required this.ratings,
    this.stats,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [ratings, stats, currentPage, hasMore, isLoadingMore];

  /// Cria uma cópia do estado com campos modificados
  LawyerRatingsLoaded copyWith({
    List<CaseRating>? ratings,
    LawyerRatingStats? stats,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return LawyerRatingsLoaded(
      ratings: ratings ?? this.ratings,
      stats: stats ?? this.stats,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Estado com estatísticas de advogado carregadas
class LawyerStatsLoaded extends RatingState {
  final LawyerRatingStats stats;

  const LawyerStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// Estado com informações de permissão para avaliar
class CanRateLoaded extends RatingState {
  final bool canRate;
  final String? reason;
  final String? raterType;
  final Map<String, dynamic>? caseInfo;
  final String? existingRatingId;

  const CanRateLoaded({
    required this.canRate,
    this.reason,
    this.raterType,
    this.caseInfo,
    this.existingRatingId,
  });

  @override
  List<Object?> get props => [canRate, reason, raterType, caseInfo, existingRatingId];
}

/// Estado com avaliações de caso carregadas
class CaseRatingsLoaded extends RatingState {
  final List<CaseRating> ratings;

  const CaseRatingsLoaded(this.ratings);

  @override
  List<Object?> get props => [ratings];
}

/// Estado de voto registrado
class VoteRegistered extends RatingState {
  final String ratingId;
  final String message;

  const VoteRegistered({
    required this.ratingId,
    this.message = 'Voto registrado com sucesso!',
  });

  @override
  List<Object?> get props => [ratingId, message];
}

/// Estado de avaliação atualizada
class RatingUpdated extends RatingState {
  final CaseRating rating;
  final String message;

  const RatingUpdated({
    required this.rating,
    this.message = 'Avaliação atualizada com sucesso!',
  });

  @override
  List<Object?> get props => [rating, message];
}

/// Estado de avaliação deletada
class RatingDeleted extends RatingState {
  final String ratingId;
  final String message;

  const RatingDeleted({
    required this.ratingId,
    this.message = 'Avaliação removida com sucesso!',
  });

  @override
  List<Object?> get props => [ratingId, message];
}

/// Estado de erro
class RatingError extends RatingState {
  final String message;
  final String? code;
  final dynamic error;

  const RatingError({
    required this.message,
    this.code,
    this.error,
  });

  @override
  List<Object?> get props => [message, code, error];
}

/// Estado de erro de validação
class RatingValidationError extends RatingState {
  final String message;
  final Map<String, String>? fieldErrors;

  const RatingValidationError({
    required this.message,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Estado de erro de rede
class RatingNetworkError extends RatingState {
  final String message;
  final bool isOffline;

  const RatingNetworkError({
    required this.message,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [message, isOffline];
}

/// Estado composto para múltiplas operações
class RatingMultiState extends RatingState {
  final LawyerRatingsLoaded? lawyerRatings;
  final LawyerStatsLoaded? lawyerStats;
  final CanRateLoaded? canRate;
  final CaseRatingsLoaded? caseRatings;
  final bool isLoading;

  const RatingMultiState({
    this.lawyerRatings,
    this.lawyerStats,
    this.canRate,
    this.caseRatings,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
        lawyerRatings,
        lawyerStats,
        canRate,
        caseRatings,
        isLoading,
      ];

  /// Cria uma cópia do estado com campos modificados
  RatingMultiState copyWith({
    LawyerRatingsLoaded? lawyerRatings,
    LawyerStatsLoaded? lawyerStats,
    CanRateLoaded? canRate,
    CaseRatingsLoaded? caseRatings,
    bool? isLoading,
  }) {
    return RatingMultiState(
      lawyerRatings: lawyerRatings ?? this.lawyerRatings,
      lawyerStats: lawyerStats ?? this.lawyerStats,
      canRate: canRate ?? this.canRate,
      caseRatings: caseRatings ?? this.caseRatings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Retorna true se algum dado está carregado
  bool get hasData =>
      lawyerRatings != null ||
      lawyerStats != null ||
      canRate != null ||
      caseRatings != null;
} 