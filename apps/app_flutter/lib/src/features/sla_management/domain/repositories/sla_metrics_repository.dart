import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../entities/sla_metrics_entity.dart';

/// Contrato do repositório para métricas SLA
/// 
/// Define todas as operações relacionadas ao gerenciamento
/// de métricas, analytics e relatórios do sistema SLA
abstract class SlaMetricsRepository {
  
  /// Obtém métricas SLA para uma firma em um período específico
  Future<Either<Failure, SlaMetricsEntity>> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  });

  /// Obtém métricas em tempo real (cache de até 5 minutos)
  Future<Either<Failure, SlaMetricsEntity>> getRealTimeMetrics({
    required String firmId,
  });

  /// Obtém métricas históricas para análise de tendências
  Future<Either<Failure, List<SlaMetricsEntity>>> getHistoricalMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'daily', // daily, weekly, monthly
  });

  /// Obtém métricas por advogado
  Future<Either<Failure, Map<String, LawyerMetrics>>> getLawyerMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyerIds,
  });

  /// Obtém métricas por cliente
  Future<Either<Failure, Map<String, ClientMetrics>>> getClientMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
  });

  /// Obtém métricas por tipo de caso
  Future<Either<Failure, Map<String, CaseTypeMetrics>>> getCaseTypeMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? caseTypes,
  });

  /// Obtém alertas SLA ativos
  Future<Either<Failure, List<SlaAlert>>> getActiveAlerts({
    required String firmId,
    SlaAlertSeverity? minSeverity,
  });

  /// Obtém dados para dashboard (métricas resumidas)
  Future<Either<Failure, SlaMetricsEntity>> getDashboardMetrics({
    required String firmId,
    int daysBack = 30,
  });

  /// Calcula score SLA para uma firma
  Future<Either<Failure, double>> calculateSlaScore({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém tendências de compliance
  Future<Either<Failure, List<DataPoint>>> getComplianceTrend({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'daily',
  });

  /// Obtém distribuição de violações
  Future<Either<Failure, Map<String, int>>> getViolationDistribution({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'reason', // reason, priority, lawyer
  });

  /// Obtém estatísticas de performance
  Future<Either<Failure, PerformanceMetrics>> getPerformanceStats({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Compara métricas entre períodos
  Future<Either<Failure, Map<String, dynamic>>> compareMetrics({
    required String firmId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  });

  /// Gera relatório personalizado
  Future<Either<Failure, Map<String, dynamic>>> generateCustomReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> metrics,
    Map<String, dynamic>? filters,
  });

  /// Exporta métricas para arquivo
  Future<Either<Failure, String>> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format, // csv, excel, pdf
    Map<String, dynamic>? options,
  });

  /// Agenda geração automática de relatórios
  Future<Either<Failure, String>> scheduleReport({
    required String firmId,
    required String reportType,
    required String frequency, // daily, weekly, monthly
    required List<String> recipients,
    Map<String, dynamic>? options,
  });

  /// Cancela relatório agendado
  Future<Either<Failure, void>> cancelScheduledReport({
    required String scheduleId,
  });

  /// Obtém benchmarks da indústria
  Future<Either<Failure, Map<String, dynamic>>> getIndustryBenchmarks({
    required String firmSize, // small, medium, large
    required String practiceArea,
    String region = 'BR',
  });

  /// Calcula previsões baseadas em tendências
  Future<Either<Failure, Map<String, dynamic>>> getPredictions({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    int forecastDays = 30,
  });

  /// Obtém recomendações de melhoria
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecommendations({
    required String firmId,
  });

  /// Invalida cache de métricas
  Future<Either<Failure, void>> invalidateCache({
    required String firmId,
    DateTime? specificDate,
  });

  /// Recalcula métricas para um período
  Future<Either<Failure, SlaMetricsEntity>> recalculateMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém status do sistema de métricas
  Future<Either<Failure, Map<String, dynamic>>> getSystemHealth();

  /// Obtém configurações de métricas personalizadas
  Future<Either<Failure, Map<String, dynamic>>> getCustomMetricsConfig({
    required String firmId,
  });

  /// Salva configurações de métricas personalizadas
  Future<Either<Failure, void>> saveCustomMetricsConfig({
    required String firmId,
    required Map<String, dynamic> config,
  });
} 
import '../../../core/error/failure.dart';

/// Contrato do repositório para métricas SLA
/// 
/// Define todas as operações relacionadas ao gerenciamento
/// de métricas, analytics e relatórios do sistema SLA
abstract class SlaMetricsRepository {
  
  /// Obtém métricas SLA para uma firma em um período específico
  Future<Either<Failure, SlaMetricsEntity>> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  });

  /// Obtém métricas em tempo real (cache de até 5 minutos)
  Future<Either<Failure, SlaMetricsEntity>> getRealTimeMetrics({
    required String firmId,
  });

  /// Obtém métricas históricas para análise de tendências
  Future<Either<Failure, List<SlaMetricsEntity>>> getHistoricalMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'daily', // daily, weekly, monthly
  });

  /// Obtém métricas por advogado
  Future<Either<Failure, Map<String, LawyerMetrics>>> getLawyerMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyerIds,
  });

  /// Obtém métricas por cliente
  Future<Either<Failure, Map<String, ClientMetrics>>> getClientMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
  });

  /// Obtém métricas por tipo de caso
  Future<Either<Failure, Map<String, CaseTypeMetrics>>> getCaseTypeMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? caseTypes,
  });

  /// Obtém alertas SLA ativos
  Future<Either<Failure, List<SlaAlert>>> getActiveAlerts({
    required String firmId,
    SlaAlertSeverity? minSeverity,
  });

  /// Obtém dados para dashboard (métricas resumidas)
  Future<Either<Failure, SlaMetricsEntity>> getDashboardMetrics({
    required String firmId,
    int daysBack = 30,
  });

  /// Calcula score SLA para uma firma
  Future<Either<Failure, double>> calculateSlaScore({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém tendências de compliance
  Future<Either<Failure, List<DataPoint>>> getComplianceTrend({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'daily',
  });

  /// Obtém distribuição de violações
  Future<Either<Failure, Map<String, int>>> getViolationDistribution({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'reason', // reason, priority, lawyer
  });

  /// Obtém estatísticas de performance
  Future<Either<Failure, PerformanceMetrics>> getPerformanceStats({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Compara métricas entre períodos
  Future<Either<Failure, Map<String, dynamic>>> compareMetrics({
    required String firmId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  });

  /// Gera relatório personalizado
  Future<Either<Failure, Map<String, dynamic>>> generateCustomReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> metrics,
    Map<String, dynamic>? filters,
  });

  /// Exporta métricas para arquivo
  Future<Either<Failure, String>> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format, // csv, excel, pdf
    Map<String, dynamic>? options,
  });

  /// Agenda geração automática de relatórios
  Future<Either<Failure, String>> scheduleReport({
    required String firmId,
    required String reportType,
    required String frequency, // daily, weekly, monthly
    required List<String> recipients,
    Map<String, dynamic>? options,
  });

  /// Cancela relatório agendado
  Future<Either<Failure, void>> cancelScheduledReport({
    required String scheduleId,
  });

  /// Obtém benchmarks da indústria
  Future<Either<Failure, Map<String, dynamic>>> getIndustryBenchmarks({
    required String firmSize, // small, medium, large
    required String practiceArea,
    String region = 'BR',
  });

  /// Calcula previsões baseadas em tendências
  Future<Either<Failure, Map<String, dynamic>>> getPredictions({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    int forecastDays = 30,
  });

  /// Obtém recomendações de melhoria
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecommendations({
    required String firmId,
  });

  /// Invalida cache de métricas
  Future<Either<Failure, void>> invalidateCache({
    required String firmId,
    DateTime? specificDate,
  });

  /// Recalcula métricas para um período
  Future<Either<Failure, SlaMetricsEntity>> recalculateMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtém status do sistema de métricas
  Future<Either<Failure, Map<String, dynamic>>> getSystemHealth();

  /// Obtém configurações de métricas personalizadas
  Future<Either<Failure, Map<String, dynamic>>> getCustomMetricsConfig({
    required String firmId,
  });

  /// Salva configurações de métricas personalizadas
  Future<Either<Failure, void>> saveCustomMetricsConfig({
    required String firmId,
    required Map<String, dynamic> config,
  });
} 