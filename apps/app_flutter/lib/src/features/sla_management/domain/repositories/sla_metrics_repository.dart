/// Interface simplificada para datasources de métricas SLA
/// 
/// Define os contratos essenciais para busca de métricas,
/// mantendo compatibilidade com a arquitetura existente
abstract class SlaMetricsRepository {
  
  /// Obtém métricas de compliance SLA
  Future<List<Map<String, dynamic>>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém métricas de performance SLA
  Future<List<Map<String, dynamic>>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém métricas de violações SLA
  Future<List<Map<String, dynamic>>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém métricas de escalações SLA
  Future<List<Map<String, dynamic>>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém métricas de tendências SLA
  Future<List<Map<String, dynamic>>> getTrendMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém alertas SLA ativos
  Future<List<Map<String, dynamic>>> getAlertMetrics({
    required String firmId,
  });
} 
