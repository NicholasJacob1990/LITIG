import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sla_audit_entity.dart';
import '../entities/sla_enums.dart';

/// Contrato do repositório para auditoria SLA
/// 
/// Define todas as operações relacionadas ao sistema de auditoria,
/// compliance tracking e logs de segurança do sistema SLA
abstract class SlaAuditRepository {
  
  /// Cria um novo evento de auditoria
  Future<Either<Failure, SlaAuditEntity>> createAuditEvent({
    required SlaAuditEntity auditEvent,
  });

  /// Obtém eventos de auditoria com filtros
  Future<Either<Failure, List<SlaAuditEntity>>> getAuditEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    List<AuditEventType>? eventTypes,
    List<AuditEventCategory>? categories,
    List<AuditSeverity>? severities,
    String? userId,
    String? entityType,
    String? entityId,
    int limit = 100,
    int offset = 0,
  });

  /// Obtém evento de auditoria específico
  Future<Either<Failure, SlaAuditEntity>> getAuditEvent({
    required String auditId,
  });

  /// Obtém trail de auditoria para uma entidade específica
  Future<Either<Failure, List<SlaAuditEntity>>> getEntityAuditTrail({
    required String entityType,
    required String entityId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obtém eventos de auditoria críticos
  Future<Either<Failure, List<SlaAuditEntity>>> getCriticalEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    bool unacknowledgedOnly = false,
  });

  /// Obtém eventos de auditoria por usuário
  Future<Either<Failure, List<SlaAuditEntity>>> getUserAuditEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    List<AuditEventType>? eventTypes,
    int limit = 100,
  });

  /// Marca evento como reconhecido/analisado
  Future<Either<Failure, void>> acknowledgeEvent({
    required String auditId,
    required String acknowledgedBy,
    String? notes,
  });

  /// Gera relatório de compliance
  Future<Either<Failure, Map<String, dynamic>>> generateComplianceReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String reportType = 'standard', // standard, detailed, summary
  });

  /// Obtém estatísticas de auditoria
  Future<Either<Failure, Map<String, dynamic>>> getAuditStatistics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Verifica integridade dos logs
  Future<Either<Failure, Map<String, dynamic>>> verifyLogIntegrity({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Exporta logs de auditoria
  Future<Either<Failure, String>> exportAuditLogs({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format, // json, csv, pdf
    Map<String, dynamic>? filters,
  });

  /// Obtém violações de compliance
  Future<Either<Failure, List<SlaAuditEntity>>> getComplianceViolations({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    List<ComplianceStatus>? statuses,
  });

  /// Obtém eventos de mudança de configuração
  Future<Either<Failure, List<SlaAuditEntity>>> getConfigurationChanges({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? entityType,
  });

  /// Obtém eventos de acesso a dados
  Future<Either<Failure, List<SlaAuditEntity>>> getDataAccessEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? entityType,
  });

  /// Obtém tentativas de login e autenticação
  Future<Either<Failure, List<SlaAuditEntity>>> getAuthenticationEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    bool failedOnly = false,
  });

  /// Obtém eventos de segurança
  Future<Either<Failure, List<SlaAuditEntity>>> getSecurityEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    List<AuditSeverity>? severities,
  });

  /// Pesquisa eventos por texto
  Future<Either<Failure, List<SlaAuditEntity>>> searchAuditEvents({
    required String firmId,
    required String searchTerm,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });

  /// Obtém resumo de atividade por usuário
  Future<Either<Failure, Map<String, dynamic>>> getUserActivitySummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém padrões de uso suspeitos
  Future<Either<Failure, List<Map<String, dynamic>>>> getSuspiciousPatterns({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Configura alertas de auditoria
  Future<Either<Failure, String>> createAuditAlert({
    required String firmId,
    required String name,
    required Map<String, dynamic> conditions,
    required List<String> recipients,
    bool isActive = true,
  });

  /// Obtém alertas de auditoria configurados
  Future<Either<Failure, List<Map<String, dynamic>>>> getAuditAlerts({
    required String firmId,
    bool activeOnly = false,
  });

  /// Atualiza alerta de auditoria
  Future<Either<Failure, void>> updateAuditAlert({
    required String alertId,
    Map<String, dynamic>? conditions,
    List<String>? recipients,
    bool? isActive,
  });

  /// Remove alerta de auditoria
  Future<Either<Failure, void>> deleteAuditAlert({
    required String alertId,
  });

  /// Obtém configurações de retenção de logs
  Future<Either<Failure, Map<String, dynamic>>> getRetentionSettings({
    required String firmId,
  });

  /// Atualiza configurações de retenção
  Future<Either<Failure, void>> updateRetentionSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  });

  /// Executa limpeza automática de logs antigos
  Future<Either<Failure, Map<String, dynamic>>> cleanupOldLogs({
    required String firmId,
    DateTime? cutoffDate,
    bool dryRun = true,
  });

  /// Obtém políticas de compliance
  Future<Either<Failure, List<Map<String, dynamic>>>> getCompliancePolicies({
    required String firmId,
  });

  /// Atualiza política de compliance
  Future<Either<Failure, void>> updateCompliancePolicy({
    required String firmId,
    required String policyId,
    required Map<String, dynamic> policy,
  });

  /// Verifica compliance contra políticas
  Future<Either<Failure, Map<String, dynamic>>> checkCompliance({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? policyIds,
  });

  /// Obtém métricas de auditoria
  Future<Either<Failure, Map<String, dynamic>>> getAuditMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Cria backup de logs de auditoria
  Future<Either<Failure, String>> createAuditBackup({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String format = 'encrypted_json',
  });

  /// Restaura logs de backup
  Future<Either<Failure, void>> restoreAuditBackup({
    required String firmId,
    required String backupId,
    bool validateIntegrity = true,
  });

  /// Obtém status do sistema de auditoria
  Future<Either<Failure, Map<String, dynamic>>> getAuditSystemHealth();
} 
