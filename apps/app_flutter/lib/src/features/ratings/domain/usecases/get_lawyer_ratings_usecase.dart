import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import '../entities/case_rating.dart';
import '../repositories/rating_repository.dart';

/// Use case para buscar avaliações de um advogado específico
class GetLawyerRatingsUseCase {
  final RatingRepository repository;

  GetLawyerRatingsUseCase(this.repository);

  /// Executa a busca das avaliações do advogado
  Future<Either<Failure, List<CaseRating>>> call(
    String lawyerId, {
    int page = 1,
    int limit = 10,
  }) async {
    // Validações
    if (lawyerId.isEmpty) {
      return Left(ValidationFailure(message: 'ID do advogado é obrigatório'));
    }

    if (page < 1) {
      return Left(ValidationFailure(message: 'Página deve ser maior que 0'));
    }

    if (limit < 1 || limit > 50) {
      return Left(ValidationFailure(message: 'Limite deve estar entre 1 e 50'));
    }

    // Buscar avaliações
    return await repository.getLawyerRatings(lawyerId, page: page, limit: limit);
  }
} 