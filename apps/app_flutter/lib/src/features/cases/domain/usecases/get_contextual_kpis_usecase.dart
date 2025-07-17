import '../entities/contextual_case_data.dart';
import '../repositories/contextual_case_repository.dart';
import '../../../../core/utils/logger.dart';

/// Use case para buscar apenas KPIs contextuais de um caso
/// 
/// Útil para atualizações parciais ou widgets específicos
/// que precisam apenas dos indicadores principais.
class GetContextualKPIsUseCase {
  final ContextualCaseRepository repository;

  GetContextualKPIsUseCase(this.repository);

  /// Executa o use case retornando apenas os KPIs
  /// 
  /// [caseId] - ID do caso
  /// [userId] - ID do usuário para contexto
  Future<List<ContextualKPI>> call({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('UseCase: Getting contextual KPIs for case $caseId, user $userId');

    try {
      final kpis = await repository.getContextualKPIs(
        caseId: caseId,
        userId: userId,
      );

      AppLogger.info('UseCase: KPIs retrieved successfully, count: ${kpis.length}');
      return kpis;

    } catch (e, stackTrace) {
      AppLogger.error('UseCase: Error getting contextual KPIs', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
} 
import '../repositories/contextual_case_repository.dart';
import '../../../../core/utils/logger.dart';

/// Use case para buscar apenas KPIs contextuais de um caso
/// 
/// Útil para atualizações parciais ou widgets específicos
/// que precisam apenas dos indicadores principais.
class GetContextualKPIsUseCase {
  final ContextualCaseRepository repository;

  GetContextualKPIsUseCase(this.repository);

  /// Executa o use case retornando apenas os KPIs
  /// 
  /// [caseId] - ID do caso
  /// [userId] - ID do usuário para contexto
  Future<List<ContextualKPI>> call({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('UseCase: Getting contextual KPIs for case $caseId, user $userId');

    try {
      final kpis = await repository.getContextualKPIs(
        caseId: caseId,
        userId: userId,
      );

      AppLogger.info('UseCase: KPIs retrieved successfully, count: ${kpis.length}');
      return kpis;

    } catch (e, stackTrace) {
      AppLogger.error('UseCase: Error getting contextual KPIs', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
} 