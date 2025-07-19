import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import '../entities/case_rating.dart';
import '../repositories/rating_repository.dart';

/// Use case para submeter uma nova avaliação
class SubmitRatingUseCase {
  final RatingRepository repository;

  SubmitRatingUseCase(this.repository);

  /// Executa a submissão da avaliação
  Future<Either<Failure, String>> call(CaseRating rating) async {
    // Validações básicas
    if (rating.overallRating < 1 || rating.overallRating > 5) {
      return const Left(ValidationFailure(message: 'Avaliação geral deve estar entre 1 e 5'));
    }

    if (rating.communicationRating < 1 || rating.communicationRating > 5) {
      return const Left(ValidationFailure(message: 'Avaliação de comunicação deve estar entre 1 e 5'));
    }

    if (rating.expertiseRating < 1 || rating.expertiseRating > 5) {
      return const Left(ValidationFailure(message: 'Avaliação de expertise deve estar entre 1 e 5'));
    }

    if (rating.responsivenessRating < 1 || rating.responsivenessRating > 5) {
      return const Left(ValidationFailure(message: 'Avaliação de responsividade deve estar entre 1 e 5'));
    }

    if (rating.valueRating < 1 || rating.valueRating > 5) {
      return const Left(ValidationFailure(message: 'Avaliação de custo-benefício deve estar entre 1 e 5'));
    }

    if (rating.comment != null && rating.comment!.length > 500) {
      return const Left(ValidationFailure(message: 'Comentário não pode exceder 500 caracteres'));
    }

    if (rating.caseId.isEmpty) {
      return const Left(ValidationFailure(message: 'ID do caso é obrigatório'));
    }

    if (rating.lawyerId.isEmpty) {
      return const Left(ValidationFailure(message: 'ID do advogado é obrigatório'));
    }

    if (rating.clientId.isEmpty) {
      return const Left(ValidationFailure(message: 'ID do cliente é obrigatório'));
    }

    if (!['client', 'lawyer'].contains(rating.raterType)) {
      return const Left(ValidationFailure(message: 'Tipo do avaliador deve ser "client" ou "lawyer"'));
    }

    // Submeter avaliação
    return await repository.createRating(rating);
  }
} 