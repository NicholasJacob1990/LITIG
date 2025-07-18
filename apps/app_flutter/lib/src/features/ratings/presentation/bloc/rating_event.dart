import 'package:equatable/equatable.dart';
import '../../domain/entities/case_rating.dart';

/// Eventos do sistema de avaliações
abstract class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para submeter uma nova avaliação
class SubmitRating extends RatingEvent {
  final CaseRating rating;

  const SubmitRating(this.rating);

  @override
  List<Object?> get props => [rating];
}

/// Evento para carregar avaliações de um advogado
class LoadLawyerRatings extends RatingEvent {
  final String lawyerId;
  final int page;
  final int limit;

  const LoadLawyerRatings({
    required this.lawyerId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [lawyerId, page, limit];
}

/// Evento para carregar estatísticas de um advogado
class LoadLawyerStats extends RatingEvent {
  final String lawyerId;

  const LoadLawyerStats(this.lawyerId);

  @override
  List<Object?> get props => [lawyerId];
}

/// Evento para verificar se pode avaliar um caso
class CheckCanRate extends RatingEvent {
  final String caseId;

  const CheckCanRate(this.caseId);

  @override
  List<Object?> get props => [caseId];
}

/// Evento para carregar avaliações de um caso
class LoadCaseRatings extends RatingEvent {
  final String caseId;

  const LoadCaseRatings(this.caseId);

  @override
  List<Object?> get props => [caseId];
}

/// Evento para votar em uma avaliação como útil
class VoteHelpful extends RatingEvent {
  final String ratingId;

  const VoteHelpful(this.ratingId);

  @override
  List<Object?> get props => [ratingId];
}

/// Evento para atualizar uma avaliação existente
class UpdateRating extends RatingEvent {
  final CaseRating rating;

  const UpdateRating(this.rating);

  @override
  List<Object?> get props => [rating];
}

/// Evento para deletar uma avaliação
class DeleteRating extends RatingEvent {
  final String ratingId;

  const DeleteRating(this.ratingId);

  @override
  List<Object?> get props => [ratingId];
}

/// Evento para limpar o estado
class ClearRatingState extends RatingEvent {
  const ClearRatingState();
}

/// Evento para carregar mais avaliações (paginação)
class LoadMoreRatings extends RatingEvent {
  final String lawyerId;

  const LoadMoreRatings(this.lawyerId);

  @override
  List<Object?> get props => [lawyerId];
} 