import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import '../repositories/rating_repository.dart';

/// Use case para verificar se o usuário pode avaliar um caso
class CheckCanRateUseCase {
  final RatingRepository repository;

  CheckCanRateUseCase(this.repository);

  /// Verifica se o usuário pode avaliar o caso
  Future<Either<Failure, Map<String, dynamic>>> call(String caseId) async {
    // Validações
    if (caseId.isEmpty) {
      return Left(ValidationFailure(message: 'ID do caso é obrigatório'));
    }

    // Verificar permissão
    return await repository.canRateCase(caseId);
  }
} 