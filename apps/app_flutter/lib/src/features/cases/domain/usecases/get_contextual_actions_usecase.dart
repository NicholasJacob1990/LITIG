import '../entities/contextual_case_data.dart';
import '../repositories/contextual_case_repository.dart';
import '../../../../core/utils/logger.dart';

/// Use case para buscar ações contextuais disponíveis para um caso
/// 
/// Retorna as ações primárias e secundárias baseadas no
/// perfil do usuário e tipo de alocação do caso.
class GetContextualActionsUseCase {
  final ContextualCaseRepository repository;

  GetContextualActionsUseCase(this.repository);

  /// Executa o use case retornando as ações disponíveis
  /// 
  /// [caseId] - ID do caso
  /// [userId] - ID do usuário para contexto
  Future<ContextualActions> call({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('UseCase: Getting contextual actions for case $caseId, user $userId');

    try {
      final actions = await repository.getContextualActions(
        caseId: caseId,
        userId: userId,
      );

      AppLogger.info('UseCase: Actions retrieved successfully');
      return actions;

    } catch (e, stackTrace) {
      AppLogger.error('UseCase: Error getting contextual actions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
} 
