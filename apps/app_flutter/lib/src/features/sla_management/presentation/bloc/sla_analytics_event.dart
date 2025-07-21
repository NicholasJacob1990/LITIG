import 'package:equatable/equatable.dart';

abstract class SlaAnalyticsEvent extends Equatable {
  const SlaAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

// Core Analytics Events
class LoadSlaAnalyticsEvent extends SlaAnalyticsEvent {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? lawyerId;
  final String? priority;
  final String? caseType;

  const LoadSlaAnalyticsEvent({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.lawyerId,
    this.priority,
    this.caseType,
  });

  @override
  List<Object?> get props => [firmId, startDate, endDate, lawyerId, priority, caseType];
}

class RefreshSlaAnalyticsEvent extends SlaAnalyticsEvent {
  final String firmId;

  const RefreshSlaAnalyticsEvent({required this.firmId});

  @override
  List<Object?> get props => [firmId];
}

class FilterSlaAnalyticsEvent extends SlaAnalyticsEvent {
  final String firmId;
  final SlaAnalyticsFilters filters;

  const FilterSlaAnalyticsEvent({
    required this.firmId,
    required this.filters,
  });

  @override
  List<Object?> get props => [firmId, filters];
}

// Report Generation Events
class LoadComplianceReportEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String period; // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final bool includeDetails;
  final String format; // 'json', 'pdf', 'excel'

  const LoadComplianceReportEvent({
    required this.firmId,
    required this.period,
    this.includeDetails = true,
    this.format = 'json',
  });

  @override
  List<Object?> get props => [firmId, period, includeDetails, format];
}

class LoadPerformanceTrendsEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String metric; // 'compliance', 'response_time', 'violations', 'escalations'
  final String period; // '7d', '30d', '90d', '1y'
  final String granularity; // 'hour', 'day', 'week', 'month'

  const LoadPerformanceTrendsEvent({
    required this.firmId,
    required this.metric,
    required this.period,
    required this.granularity,
  });

  @override
  List<Object?> get props => [firmId, metric, period, granularity];
}

class GenerateCustomReportEvent extends SlaAnalyticsEvent {
  final String firmId;
  final Map<String, dynamic> reportConfig;

  const GenerateCustomReportEvent({
    required this.firmId,
    required this.reportConfig,
  });

  @override
  List<Object?> get props => [firmId, reportConfig];
}

// Export Events
class ExportAnalyticsReportEvent extends SlaAnalyticsEvent {
  final String format; // 'pdf', 'excel', 'csv', 'json'
  final String reportType; // 'analytics', 'compliance', 'trends', 'custom'
  final String? filePath;

  const ExportAnalyticsReportEvent({
    required this.format,
    required this.reportType,
    this.filePath,
  });

  @override
  List<Object?> get props => [format, reportType, filePath];
}

class ScheduleReportEvent extends SlaAnalyticsEvent {
  final String firmId;
  final Map<String, dynamic> reportConfig;
  final String schedule; // cron expression: '0 9 * * MON' for weekly Monday 9AM
  final List<String> recipients;

  const ScheduleReportEvent({
    required this.firmId,
    required this.reportConfig,
    required this.schedule,
    required this.recipients,
  });

  @override
  List<Object?> get props => [firmId, reportConfig, schedule, recipients];
}

// Filter Update Events
class UpdateAnalyticsFiltersEvent extends SlaAnalyticsEvent {
  final SlaAnalyticsFilters filters;

  const UpdateAnalyticsFiltersEvent({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class ClearAnalyticsFiltersEvent extends SlaAnalyticsEvent {
  const ClearAnalyticsFiltersEvent();
}

// Dashboard Events
class LoadKPIDashboardEvent extends SlaAnalyticsEvent {
  final String firmId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadKPIDashboardEvent({
    required this.firmId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [firmId, startDate, endDate];
}

// Specific Analysis Events
class LoadViolationAnalysisEvent extends SlaAnalyticsEvent {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? groupBy; // 'lawyer', 'priority', 'case_type', 'day', 'week'

  const LoadViolationAnalysisEvent({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.groupBy,
  });

  @override
  List<Object?> get props => [firmId, startDate, endDate, groupBy];
}

class LoadEscalationAnalysisEvent extends SlaAnalyticsEvent {
  final String firmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? level; // 'level_1', 'level_2', 'level_3'

  const LoadEscalationAnalysisEvent({
    required this.firmId,
    required this.startDate,
    required this.endDate,
    this.level,
  });

  @override
  List<Object?> get props => [firmId, startDate, endDate, level];
}

class LoadTopPerformersEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String metric; // 'compliance', 'response_time', 'case_volume'
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadTopPerformersEvent({
    required this.firmId,
    required this.metric,
    this.limit = 10,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [firmId, metric, limit, startDate, endDate];
}

// Comparison Events
class LoadBenchmarkDataEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String metric; // 'compliance', 'response_time', 'satisfaction'
  final String? industry; // 'legal', 'corporate', 'litigation'
  final String? firmSize; // 'small', 'medium', 'large', 'enterprise'

  const LoadBenchmarkDataEvent({
    required this.firmId,
    required this.metric,
    this.industry,
    this.firmSize,
  });

  @override
  List<Object?> get props => [firmId, metric, industry, firmSize];
}

class ComparePeriodsEvent extends SlaAnalyticsEvent {
  final String firmId;
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;
  final List<String> metrics;

  const ComparePeriodsEvent({
    required this.firmId,
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
    required this.metrics,
  });

  @override
  List<Object?> get props => [
        firmId,
        period1Start,
        period1End,
        period2Start,
        period2End,
        metrics,
      ];
}

// Predictive Analytics Events
class LoadPredictiveAnalyticsEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String metric; // 'violations', 'escalations', 'workload'
  final int forecastDays;

  const LoadPredictiveAnalyticsEvent({
    required this.firmId,
    required this.metric,
    this.forecastDays = 30,
  });

  @override
  List<Object?> get props => [firmId, metric, forecastDays];
}

class LoadWorkloadForecastEvent extends SlaAnalyticsEvent {
  final String firmId;
  final int forecastDays;
  final String? lawyerId;

  const LoadWorkloadForecastEvent({
    required this.firmId,
    this.forecastDays = 30,
    this.lawyerId,
  });

  @override
  List<Object?> get props => [firmId, forecastDays, lawyerId];
}

// Alert Events
class LoadSlaAlertsEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String? severity; // 'low', 'medium', 'high', 'critical'
  final bool activeOnly;

  const LoadSlaAlertsEvent({
    required this.firmId,
    this.severity,
    this.activeOnly = true,
  });

  @override
  List<Object?> get props => [firmId, severity, activeOnly];
}

class CreateSlaAlertEvent extends SlaAnalyticsEvent {
  final String firmId;
  final Map<String, dynamic> alertConfig;

  const CreateSlaAlertEvent({
    required this.firmId,
    required this.alertConfig,
  });

  @override
  List<Object?> get props => [firmId, alertConfig];
}

class UpdateSlaAlertEvent extends SlaAnalyticsEvent {
  final String alertId;
  final Map<String, dynamic> alertConfig;

  const UpdateSlaAlertEvent({
    required this.alertId,
    required this.alertConfig,
  });

  @override
  List<Object?> get props => [alertId, alertConfig];
}

class DeleteSlaAlertEvent extends SlaAnalyticsEvent {
  final String alertId;

  const DeleteSlaAlertEvent({required this.alertId});

  @override
  List<Object?> get props => [alertId];
}

// Chart Configuration Events
class UpdateChartConfigEvent extends SlaAnalyticsEvent {
  final String chartType; // 'line', 'bar', 'pie', 'area'
  final Map<String, dynamic> config;

  const UpdateChartConfigEvent({
    required this.chartType,
    required this.config,
  });

  @override
  List<Object?> get props => [chartType, config];
}

class SaveChartPresetEvent extends SlaAnalyticsEvent {
  final String presetName;
  final Map<String, dynamic> chartConfig;

  const SaveChartPresetEvent({
    required this.presetName,
    required this.chartConfig,
  });

  @override
  List<Object?> get props => [presetName, chartConfig];
}

// Data Drill-down Events
class DrillDownAnalyticsEvent extends SlaAnalyticsEvent {
  final String dimension; // 'lawyer', 'case_type', 'priority', 'time'
  final String value;
  final Map<String, dynamic> context;

  const DrillDownAnalyticsEvent({
    required this.dimension,
    required this.value,
    required this.context,
  });

  @override
  List<Object?> get props => [dimension, value, context];
}

class LoadDetailedAnalysisEvent extends SlaAnalyticsEvent {
  final String firmId;
  final String analysisType; // 'lawyer_detail', 'case_detail', 'time_detail'
  final String entityId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadDetailedAnalysisEvent({
    required this.firmId,
    required this.analysisType,
    required this.entityId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [firmId, analysisType, entityId, startDate, endDate];
}

// Data Classes
class SlaAnalyticsFilters extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? lawyerId;
  final String? priority;
  final String? caseType;
  final String? groupBy;
  final List<String>? metrics;

  const SlaAnalyticsFilters({
    required this.startDate,
    required this.endDate,
    this.lawyerId,
    this.priority,
    this.caseType,
    this.groupBy,
    this.metrics,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        lawyerId,
        priority,
        caseType,
        groupBy,
        metrics,
      ];

  SlaAnalyticsFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? lawyerId,
    String? priority,
    String? caseType,
    String? groupBy,
    List<String>? metrics,
  }) {
    return SlaAnalyticsFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lawyerId: lawyerId ?? this.lawyerId,
      priority: priority ?? this.priority,
      caseType: caseType ?? this.caseType,
      groupBy: groupBy ?? this.groupBy,
      metrics: metrics ?? this.metrics,
    );
  }

  bool get hasFilters =>
      lawyerId != null || priority != null || caseType != null || groupBy != null;

  Map<String, dynamic> toMap() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      if (lawyerId != null) 'lawyer_id': lawyerId,
      if (priority != null) 'priority': priority,
      if (caseType != null) 'case_type': caseType,
      if (groupBy != null) 'group_by': groupBy,
      if (metrics != null) 'metrics': metrics,
    };
  }
} 

