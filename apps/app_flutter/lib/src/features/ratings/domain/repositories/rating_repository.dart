import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import '../entities/case_rating.dart';
import '../entities/lawyer_rating_stats.dart';

/// Repositório abstrato para operações com avaliações
abstract class RatingRepository {
  /// Cria uma nova avaliação
  Future<Either<Failure, String>> createRating(CaseRating rating);

  /// Busca avaliações de um advogado específico
  Future<Either<Failure, List<CaseRating>>> getLawyerRatings(
    String lawyerId, {
    int page = 1,
    int limit = 10,
  });

  /// Busca estatísticas de avaliação de um advogado
  Future<Either<Failure, LawyerRatingStats>> getLawyerStats(String lawyerId);

  /// Verifica se o usuário pode avaliar um caso específico
  Future<Either<Failure, Map<String, dynamic>>> canRateCase(String caseId);

  /// Busca avaliações por caso
  Future<Either<Failure, List<CaseRating>>> getCaseRatings(String caseId);

  /// Atualiza uma avaliação existente
  Future<Either<Failure, void>> updateRating(CaseRating rating);

  /// Remove uma avaliação
  Future<Either<Failure, void>> deleteRating(String ratingId);

  /// Vota em uma avaliação como útil
  Future<Either<Failure, void>> voteHelpful(String ratingId);

  /// Busca estatísticas gerais do sistema de avaliações
  Future<Either<Failure, Map<String, dynamic>>> getSystemStats();
} 