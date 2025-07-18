import '../models/case_rating_model.dart';
import '../models/lawyer_rating_stats_model.dart';

/// Interface para operações remotas de avaliações
abstract class RatingRemoteDataSource {
  /// Cria uma nova avaliação
  Future<String> createRating(CaseRatingModel rating);

  /// Busca avaliações de um advogado
  Future<List<CaseRatingModel>> getLawyerRatings(
    String lawyerId, {
    int page = 1,
    int limit = 10,
  });

  /// Busca estatísticas de um advogado
  Future<LawyerRatingStatsModel> getLawyerStats(String lawyerId);

  /// Verifica se pode avaliar um caso
  Future<Map<String, dynamic>> canRateCase(String caseId);

  /// Busca avaliações de um caso
  Future<List<CaseRatingModel>> getCaseRatings(String caseId);

  /// Atualiza uma avaliação
  Future<void> updateRating(CaseRatingModel rating);

  /// Remove uma avaliação
  Future<void> deleteRating(String ratingId);

  /// Vota como útil
  Future<void> voteHelpful(String ratingId);

  /// Busca estatísticas do sistema
  Future<Map<String, dynamic>> getSystemStats();
} 