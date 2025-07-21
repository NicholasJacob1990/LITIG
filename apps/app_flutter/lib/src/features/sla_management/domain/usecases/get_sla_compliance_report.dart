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
    return await repository.getComplianceReport(
      firmId: params.firmId,
      startDate: params.startDate,
      endDate: params.endDate,
      includeDetails: params.includeDetails,
      groupBy: params.groupBy,
      filters: params.filters,
    );
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