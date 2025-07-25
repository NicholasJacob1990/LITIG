import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_compliance_report_entity.dart';
import '../repositories/sla_metrics_repository.dart';

/// Use case para gerar relatórios de compliance SLA
/// 
/// Responsável por obter dados de conformidade SLA,
/// incluindo métricas de violação, tendências e análises
class GetSlaComplianceReport implements UseCase<SlaComplianceReportEntity, GetSlaComplianceReportParams> {
  final SlaMetricsRepository repository;

  GetSlaComplianceReport(this.repository);

  @override
  Future<Either<Failure, SlaComplianceReportEntity>> call(GetSlaComplianceReportParams params) async {
    try {
      final complianceMetrics = await repository.getComplianceMetrics(
        firmId: params.firmId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      
      final violationMetrics = await repository.getViolationMetrics(
        firmId: params.firmId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      
      // Calcular métricas agregadas
      final totalCases = complianceMetrics.fold(0, (sum, metric) => sum + (metric['total_cases'] as int? ?? 0));
      final compliantCases = complianceMetrics.fold(0, (sum, metric) => sum + (metric['compliant_cases'] as int? ?? 0));
      final violatedCases = totalCases - compliantCases;
      final overallCompliance = totalCases > 0 ? compliantCases / totalCases : 0.0;
      
      return Right(SlaComplianceReportEntity(
        firmId: params.firmId,
        periodStart: params.startDate,
        periodEnd: params.endDate,
        overallCompliance: overallCompliance,
        totalCases: totalCases,
        compliantCases: compliantCases,
        violatedCases: violatedCases,
        averageResponseTime: 24.0, // TODO: Calcular baseado nos dados
        complianceByPriority: const {}, // TODO: Agrupar por prioridade
        complianceByCaseType: const {}, // TODO: Agrupar por tipo
        violationsByReason: const {}, // TODO: Agrupar por motivo
        trends: const [], // TODO: Gerar tendências
        riskAnalysis: const RiskAnalysisData(
          overallRisk: 'low',
          riskFactors: {},
          criticalAreas: [],
          riskTrend: 'stable',
        ),
        recommendations: const [], // TODO: Gerar recomendações
        generatedAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro ao gerar relatório de compliance: ${e.toString()}'));
    }
  }
}

/// Parâmetros para obter relatório de compliance SLA
class GetSlaComplianceReportParams {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final bool includeDetails;
  final String? groupBy; // 'case_type', 'priority', 'lawyer', 'month'
  final Map<String, dynamic>? filters;

  GetSlaComplianceReportParams({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.includeDetails = false,
    this.groupBy,
    this.filters,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmId': firmId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'includeDetails': includeDetails,
      if (groupBy != null) 'groupBy': groupBy,
      if (filters != null) 'filters': filters,
    };
  }
}