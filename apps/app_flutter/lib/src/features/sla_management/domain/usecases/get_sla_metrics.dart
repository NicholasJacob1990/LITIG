import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_metrics_entity.dart';
import '../repositories/sla_metrics_repository.dart';

class GetSlaMetrics implements UseCase<SlaMetricsEntity, GetSlaMetricsParams> {
  final SlaMetricsRepository repository;

  GetSlaMetrics(this.repository);

  @override
  Future<Either<Failure, SlaMetricsEntity>> call(GetSlaMetricsParams params) async {
    return await repository.getMetrics(
      firmId: params.firmId,
      startDate: params.startDate,
      endDate: params.endDate,
      lawyerId: params.lawyerId,
      priority: params.priority,
      caseType: params.caseType,
    );
  }
}

class GetSlaMetricsParams {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? lawyerId;
  final String? priority;
  final String? caseType;

  GetSlaMetricsParams({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.lawyerId,
    this.priority,
    this.caseType,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmId': firmId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (lawyerId != null) 'lawyerId': lawyerId,
      if (priority != null) 'priority': priority,
      if (caseType != null) 'caseType': caseType,
    };
  }
}

class GetSlaComplianceReport implements UseCase<Map<String, dynamic>, GetSlaComplianceReportParams> {
  final SlaMetricsRepository repository;

  GetSlaComplianceReport(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetSlaComplianceReportParams params) async {
    return await repository.generateComplianceReport(
      firmId: params.firmId,
      period: params.period,
      includeDetails: params.includeDetails,
      format: params.format,
    );
  }
}

class GetSlaComplianceReportParams {
  final String firmId;
  final String period; // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final bool includeDetails;
  final String format; // 'json', 'pdf', 'excel'

  GetSlaComplianceReportParams({
    required this.firmId,
    required this.period,
    this.includeDetails = true,
    this.format = 'json',
  });
}

class GetSlaPerformanceTrends implements UseCase<List<Map<String, dynamic>>, GetSlaPerformanceTrendsParams> {
  final SlaMetricsRepository repository;

  GetSlaPerformanceTrends(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetSlaPerformanceTrendsParams params) async {
    return await repository.getPerformanceTrends(
      firmId: params.firmId,
      metric: params.metric,
      period: params.period,
      granularity: params.granularity,
    );
  }
}

class GetSlaPerformanceTrendsParams {
  final String firmId;
  final String metric; // 'compliance', 'response_time', 'violations', 'escalations'
  final String period; // '7d', '30d', '90d', '1y'
  final String granularity; // 'hour', 'day', 'week', 'month'

  GetSlaPerformanceTrendsParams({
    required this.firmId,
    required this.metric,
    required this.period,
    required this.granularity,
  });
} 

class GetSlaMetrics implements UseCase<SlaMetricsEntity, GetSlaMetricsParams> {
  final SlaMetricsRepository repository;

  GetSlaMetrics(this.repository);

  @override
  Future<Either<Failure, SlaMetricsEntity>> call(GetSlaMetricsParams params) async {
    return await repository.getMetrics(
      firmId: params.firmId,
      startDate: params.startDate,
      endDate: params.endDate,
      lawyerId: params.lawyerId,
      priority: params.priority,
      caseType: params.caseType,
    );
  }
}

class GetSlaMetricsParams {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? lawyerId;
  final String? priority;
  final String? caseType;

  GetSlaMetricsParams({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.lawyerId,
    this.priority,
    this.caseType,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmId': firmId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (lawyerId != null) 'lawyerId': lawyerId,
      if (priority != null) 'priority': priority,
      if (caseType != null) 'caseType': caseType,
    };
  }
}

class GetSlaComplianceReport implements UseCase<Map<String, dynamic>, GetSlaComplianceReportParams> {
  final SlaMetricsRepository repository;

  GetSlaComplianceReport(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetSlaComplianceReportParams params) async {
    return await repository.generateComplianceReport(
      firmId: params.firmId,
      period: params.period,
      includeDetails: params.includeDetails,
      format: params.format,
    );
  }
}

class GetSlaComplianceReportParams {
  final String firmId;
  final String period; // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final bool includeDetails;
  final String format; // 'json', 'pdf', 'excel'

  GetSlaComplianceReportParams({
    required this.firmId,
    required this.period,
    this.includeDetails = true,
    this.format = 'json',
  });
}

class GetSlaPerformanceTrends implements UseCase<List<Map<String, dynamic>>, GetSlaPerformanceTrendsParams> {
  final SlaMetricsRepository repository;

  GetSlaPerformanceTrends(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetSlaPerformanceTrendsParams params) async {
    return await repository.getPerformanceTrends(
      firmId: params.firmId,
      metric: params.metric,
      period: params.period,
      granularity: params.granularity,
    );
  }
}

class GetSlaPerformanceTrendsParams {
  final String firmId;
  final String metric; // 'compliance', 'response_time', 'violations', 'escalations'
  final String period; // '7d', '30d', '90d', '1y'
  final String granularity; // 'hour', 'day', 'week', 'month'

  GetSlaPerformanceTrendsParams({
    required this.firmId,
    required this.metric,
    required this.period,
    required this.granularity,
  });
} 