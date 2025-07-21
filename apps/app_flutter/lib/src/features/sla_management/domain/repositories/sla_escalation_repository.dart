import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Contrato do repositório para escalações SLA
/// 
/// Define todas as operações relacionadas ao gerenciamento
/// de escalações automáticas e manuais do sistema SLA
abstract class SlaEscalationRepository {
  
  /// Obtém escalações ativas
  Future<Either<Failure, List<Map<String, dynamic>>>> getActiveEscalations({
    required String firmId,
    String? lawyerId,
    String? caseId,
    String? priority,
  });

  /// Obtém histórico de escalações
  Future<Either<Failure, List<Map<String, dynamic>>>> getEscalationHistory({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? lawyerId,
    String? caseId,
  });

  /// Cria nova escalação manual
  Future<Either<Failure, Map<String, dynamic>>> createEscalation({
    required String firmId,
    required String caseId,
    required String reason,
    required String escalatedTo,
    required String escalatedBy,
    String? notes,
    String priority = 'medium',
  });

  /// Resolve escalação
  Future<Either<Failure, void>> resolveEscalation({
    required String escalationId,
    required String resolvedBy,
    required String resolution,
    String? notes,
  });

  /// Transfere escalação para outro responsável
  Future<Either<Failure, void>> transferEscalation({
    required String escalationId,
    required String newAssignee,
    required String transferredBy,
    String? reason,
  });

  /// Obtém regras de escalação
  Future<Either<Failure, List<Map<String, dynamic>>>> getEscalationRules({
    required String firmId,
  });

  /// Cria nova regra de escalação
  Future<Either<Failure, Map<String, dynamic>>> createEscalationRule({
    required String firmId,
    required String name,
    required Map<String, dynamic> conditions,
    required Map<String, dynamic> actions,
    bool isActive = true,
  });

  /// Atualiza regra de escalação
  Future<Either<Failure, void>> updateEscalationRule({
    required String ruleId,
    String? name,
    Map<String, dynamic>? conditions,
    Map<String, dynamic>? actions,
    bool? isActive,
  });

  /// Remove regra de escalação
  Future<Either<Failure, void>> deleteEscalationRule({
    required String ruleId,
  });

  /// Testa regra de escalação
  Future<Either<Failure, Map<String, dynamic>>> testEscalationRule({
    required String ruleId,
    required Map<String, dynamic> testData,
  });

  /// Obtém escalações pendentes para um usuário
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingEscalations({
    required String userId,
    String? priority,
  });

  /// Obtém métricas de escalação
  Future<Either<Failure, Map<String, dynamic>>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém estatísticas de tempo de resolução
  Future<Either<Failure, Map<String, dynamic>>> getResolutionStats({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
  });

  /// Obtém configurações de notificação para escalações
  Future<Either<Failure, Map<String, dynamic>>> getEscalationNotificationSettings({
    required String firmId,
  });

  /// Atualiza configurações de notificação
  Future<Either<Failure, void>> updateEscalationNotificationSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  });

  /// Força execução das regras de escalação
  Future<Either<Failure, Map<String, dynamic>>> executeEscalationRules({
    required String firmId,
    String? caseId,
    bool dryRun = false,
  });

  /// Obtém logs de execução das regras
  Future<Either<Failure, List<Map<String, dynamic>>>> getEscalationLogs({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? ruleId,
  });

  /// Adiciona comentário à escalação
  Future<Either<Failure, void>> addEscalationComment({
    required String escalationId,
    required String comment,
    required String addedBy,
  });

  /// Obtém comentários da escalação
  Future<Either<Failure, List<Map<String, dynamic>>>> getEscalationComments({
    required String escalationId,
  });

  /// Marca escalação como crítica
  Future<Either<Failure, void>> markEscalationAsCritical({
    required String escalationId,
    required String markedBy,
    String? reason,
  });

  /// Obtém dashboard de escalações
  Future<Either<Failure, Map<String, dynamic>>> getEscalationDashboard({
    required String firmId,
    DateTime? date,
  });
}