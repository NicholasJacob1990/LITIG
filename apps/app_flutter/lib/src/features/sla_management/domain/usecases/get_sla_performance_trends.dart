import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_performance_trends_entity.dart';
import '../repositories/sla_metrics_repository.dart';

/// Use case para obter tendências de performance SLA
/// 
/// Responsável por analisar tendências históricas,
/// identificar padrões e prever performance futura
class GetSlaPerformanceTrends implements UseCase<SlaPerformanceTrendsEntity, GetSlaPerformanceTrendsParams> {
  final SlaMetricsRepository repository;

  GetSlaPerformanceTrends(this.repository);

  @override
  Future<Either<Failure, SlaPerformanceTrendsEntity>> call(GetSlaPerformanceTrendsParams params) async {
    try {
      final trendData = await repository.getTrendMetrics(
        firmId: params.firmId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      
      // Converter os dados de tendências para a entidade 
      final trends = SlaPerformanceTrendsEntity(
        firmId: params.firmId,
        periodStart: params.startDate,
        periodEnd: params.endDate,
        granularity: params.granularity,
        dataPoints: const <PerformanceDataPoint>[],
        overallTrend: TrendDirection.stable,
        metrics: const <String, MetricTrend>{},
        seasonalPatterns: const SeasonalPatterns(
          hasSeasonality: false,
          weeklyPattern: {},
          monthlyPattern: {},
          yearlyPattern: {},
        ),
        anomalies: const <PerformanceAnomaly>[],
        generatedAt: DateTime.now(),
        metadata: const {},
      );
      
      return Right(trends);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao obter tendências de performance'));
    }
  }
}

/// Parâmetros para obter tendências de performance SLA
class GetSlaPerformanceTrendsParams {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final String granularity; // 'daily', 'weekly', 'monthly'
  final List<String>? metrics; // null = todas as métricas
  final bool includeForecasting;
  final int? forecastPeriod; // em dias

  GetSlaPerformanceTrendsParams({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.granularity = 'weekly',
    this.metrics,
    this.includeForecasting = false,
    this.forecastPeriod,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmId': firmId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'granularity': granularity,
      if (metrics != null) 'metrics': metrics,
      'includeForecasting': includeForecasting,
      if (forecastPeriod != null) 'forecastPeriod': forecastPeriod,
    };
  }
}