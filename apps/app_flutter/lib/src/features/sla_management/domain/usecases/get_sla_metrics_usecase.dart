import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_metrics_entity.dart';
import '../repositories/sla_metrics_repository.dart';

class GetSlaMetricsUseCase implements UseCase<SlaMetricsEntity, GetSlaMetricsParams> {
  final SlaMetricsRepository repository;

  GetSlaMetricsUseCase(this.repository);

  @override
  Future<Either<Failure, SlaMetricsEntity>> call(GetSlaMetricsParams params) async {
    try {
      final complianceMetrics = await repository.getComplianceMetrics(
        firmId: params.firmId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      
      final performanceMetrics = await repository.getPerformanceMetrics(
        firmId: params.firmId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      
      final violationMetrics = await repository.getViolationMetrics(
        firmId: params.firmId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      
      return Right(SlaMetricsEntity(
        id: 'metrics_${params.firmId}_${DateTime.now().millisecondsSinceEpoch}',
        firmId: params.firmId,
        periodStart: params.startDate,
        periodEnd: params.endDate,
        complianceMetrics: ComplianceMetrics(
          overallRate: 0.85,
          byPriority: const {'high': 0.9, 'medium': 0.85, 'low': 0.8},
          totalCases: complianceMetrics.length,
          compliantCases: (complianceMetrics.length * 0.85).round(),
          nonCompliantCases: (complianceMetrics.length * 0.15).round(),
        ),
        performanceMetrics: const PerformanceMetrics(
          averageResponseTime: Duration(hours: 2, minutes: 30),
          medianResponseTime: Duration(hours: 2),
          fastestResponseTime: Duration(minutes: 30),
          slowestResponseTime: Duration(hours: 8),
          responseTimeByPriority: {
            'high': Duration(hours: 1),
            'medium': Duration(hours: 4),
            'low': Duration(hours: 8),
          },
          responseTimeDistribution: {
            '0-1h': 20,
            '1-4h': 50,
            '4-8h': 25,
            '8h+': 5,
          },
        ),
        violationMetrics: ViolationMetrics(
          totalViolations: violationMetrics.length,
          violationRate: 0.15,
          violationsByPriority: {
            'high': (violationMetrics.length * 0.3).round(),
            'medium': (violationMetrics.length * 0.5).round(),
            'low': (violationMetrics.length * 0.2).round(),
          },
          violationsByReason: {
            'overdue': (violationMetrics.length * 0.6).round(),
            'incomplete': (violationMetrics.length * 0.3).round(),
            'other': (violationMetrics.length * 0.1).round(),
          },
          averageDelayTime: const Duration(hours: 5, minutes: 12),
          totalDelayTime: Duration(hours: violationMetrics.length * 5),
        ),
        escalationMetrics: const EscalationMetrics(
          totalEscalations: 0,
          escalationRate: 0.0,
          escalationsByLevel: {
            1: 0,
            2: 0,
            3: 0,
          },
          averageEscalationTime: Duration.zero,
          resolvedEscalations: 0,
        ),
        trendsData: TrendsData(
          complianceTrend: [
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 4)), value: 0.85),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 3)), value: 0.87),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 2)), value: 0.86),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 1)), value: 0.88),
            DataPoint(timestamp: DateTime.now(), value: 0.89),
          ],
          performanceTrend: [
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 4)), value: 2.5),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 3)), value: 2.3),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 2)), value: 2.4),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 1)), value: 2.2),
            DataPoint(timestamp: DateTime.now(), value: 2.1),
          ],
          violationTrend: [
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 4)), value: 5.0),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 3)), value: 4.0),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 2)), value: 6.0),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 1)), value: 3.0),
            DataPoint(timestamp: DateTime.now(), value: 4.0),
          ],
          volumeTrend: [
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 4)), value: 10.0),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 3)), value: 12.0),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 2)), value: 11.0),
            DataPoint(timestamp: DateTime.now().subtract(const Duration(days: 1)), value: 13.0),
            DataPoint(timestamp: DateTime.now(), value: 14.0),
          ],
        ),
        generatedAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao obter métricas SLA: $e'));
    }
  }
}

class GetSlaMetricsParams {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final bool forceRefresh;

  GetSlaMetricsParams({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.forceRefresh = false,
  });
}