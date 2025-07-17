import 'package:equatable/equatable.dart';
import '../../domain/entities/sla_metrics_entity.dart';
import 'sla_analytics_event.dart';

abstract class SlaAnalyticsState extends Equatable {
  const SlaAnalyticsState();

  @override
  List<Object?> get props => [];
}

// Initial State
class SlaAnalyticsInitial extends SlaAnalyticsState {
  const SlaAnalyticsInitial();
}

// Loading States
class SlaAnalyticsLoading extends SlaAnalyticsState {
  final String? message;

  const SlaAnalyticsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class SlaAnalyticsRefreshing extends SlaAnalyticsState {
  final SlaMetricsEntity previousMetrics;
  final SlaAnalyticsFilters filters;

  const SlaAnalyticsRefreshing({
    required this.previousMetrics,
    required this.filters,
  });

  @override
  List<Object?> get props => [previousMetrics, filters];
}

// Loaded State - Main state with analytics data
class SlaAnalyticsLoaded extends SlaAnalyticsState {
  final SlaMetricsEntity metrics;
  final SlaAnalyticsFilters filters;
  final DateTime loadedAt;
  final SlaMetricsEntity? previousMetrics;
  final Map<String, dynamic>? complianceReport;
  final List<Map<String, dynamic>>? performanceTrends;
  final Map<String, dynamic>? customReportData;

  const SlaAnalyticsLoaded({
    required this.metrics,
    required this.filters,
    required this.loadedAt,
    this.previousMetrics,
    this.complianceReport,
    this.performanceTrends,
    this.customReportData,
  });

  @override
  List<Object?> get props => [
        metrics,
        filters,
        loadedAt,
        previousMetrics,
        complianceReport,
        performanceTrends,
        customReportData,
      ];

  SlaAnalyticsLoaded copyWith({
    SlaMetricsEntity? metrics,
    SlaAnalyticsFilters? filters,
    DateTime? loadedAt,
    SlaMetricsEntity? previousMetrics,
    Map<String, dynamic>? complianceReport,
    List<Map<String, dynamic>>? performanceTrends,
    Map<String, dynamic>? customReportData,
  }) {
    return SlaAnalyticsLoaded(
      metrics: metrics ?? this.metrics,
      filters: filters ?? this.filters,
      loadedAt: loadedAt ?? this.loadedAt,
      previousMetrics: previousMetrics ?? this.previousMetrics,
      complianceReport: complianceReport ?? this.complianceReport,
      performanceTrends: performanceTrends ?? this.performanceTrends,
      customReportData: customReportData ?? this.customReportData,
    );
  }

  // Helper getters
  bool get hasComplianceReport => complianceReport != null;
  bool get hasPerformanceTrends => performanceTrends != null;
  bool get hasCustomReport => customReportData != null;
  bool get hasPreviousMetrics => previousMetrics != null;
  Duration get timeSinceLoaded => DateTime.now().difference(loadedAt);
  bool get needsRefresh => timeSinceLoaded.inMinutes > 5; // Refresh after 5 minutes
}

// Report States
class SlaAnalyticsReportLoading extends SlaAnalyticsState {
  final String reportType;
  final SlaMetricsEntity? baseMetrics;
  final double? progress;

  const SlaAnalyticsReportLoading({
    required this.reportType,
    this.baseMetrics,
    this.progress,
  });

  @override
  List<Object?> get props => [reportType, baseMetrics, progress];
}

class SlaAnalyticsReportLoaded extends SlaAnalyticsState {
  final String reportType;
  final Map<String, dynamic> reportData;
  final DateTime generatedAt;
  final SlaMetricsEntity? baseMetrics;

  const SlaAnalyticsReportLoaded({
    required this.reportType,
    required this.reportData,
    required this.generatedAt,
    this.baseMetrics,
  });

  @override
  List<Object?> get props => [reportType, reportData, generatedAt, baseMetrics];

  // Helper getters
  bool get isComplianceReport => reportType == 'compliance';
  bool get isTrendsReport => reportType == 'trends';
  bool get isCustomReport => reportType == 'custom';
  Duration get reportAge => DateTime.now().difference(generatedAt);
}

class SlaAnalyticsReportScheduled extends SlaAnalyticsState {
  final Map<String, dynamic> reportConfig;
  final String schedule;
  final List<String> recipients;
  final DateTime scheduledAt;

  const SlaAnalyticsReportScheduled({
    required this.reportConfig,
    required this.schedule,
    required this.recipients,
    required this.scheduledAt,
  });

  @override
  List<Object?> get props => [reportConfig, schedule, recipients, scheduledAt];
}

// Export States
class SlaAnalyticsExporting extends SlaAnalyticsState {
  final String format;
  final String reportType;
  final double progress; // 0.0 to 1.0

  const SlaAnalyticsExporting({
    required this.format,
    required this.reportType,
    required this.progress,
  });

  @override
  List<Object?> get props => [format, reportType, progress];

  // Helper getters
  int get progressPercent => (progress * 100).round();
  bool get isComplete => progress >= 1.0;
}

class SlaAnalyticsExported extends SlaAnalyticsState {
  final String filePath;
  final String format;
  final String reportType;
  final DateTime exportedAt;

  const SlaAnalyticsExported({
    required this.filePath,
    required this.format,
    required this.reportType,
    required this.exportedAt,
  });

  @override
  List<Object?> get props => [filePath, format, reportType, exportedAt];
}

// Specialized Analysis States
class SlaKPIDashboardLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> kpiData;
  final DateTime loadedAt;

  const SlaKPIDashboardLoaded({
    required this.kpiData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [kpiData, loadedAt];

  // Helper getters for KPI data
  double? get complianceRate => kpiData['compliance_rate']?.toDouble();
  String? get avgResponseTime => kpiData['avg_response_time'];
  int? get violationsCount => kpiData['violations_count'];
  int? get escalationsCount => kpiData['escalations_count'];
  List<String>? get topPerformers => 
      (kpiData['top_performers'] as List?)?.cast<String>();
  List<String>? get bottomPerformers => 
      (kpiData['bottom_performers'] as List?)?.cast<String>();
}

class SlaViolationAnalysisLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> violationData;
  final DateTime loadedAt;

  const SlaViolationAnalysisLoaded({
    required this.violationData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [violationData, loadedAt];

  // Helper getters
  int? get totalViolations => violationData['total_violations'];
  Map<String, dynamic>? get violationsByPriority => violationData['by_priority'];
  Map<String, dynamic>? get violationsByLawyer => violationData['by_lawyer'];
  List<Map<String, dynamic>>? get violationTrends => 
      (violationData['trends'] as List?)?.cast<Map<String, dynamic>>();
}

class SlaEscalationAnalysisLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> escalationData;
  final DateTime loadedAt;

  const SlaEscalationAnalysisLoaded({
    required this.escalationData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [escalationData, loadedAt];

  // Helper getters
  int? get totalEscalations => escalationData['total_escalations'];
  Map<String, dynamic>? get escalationsByLevel => escalationData['by_level'];
  double? get successRate => escalationData['success_rate']?.toDouble();
  String? get avgResolutionTime => escalationData['avg_resolution_time'];
}

class SlaBenchmarkDataLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> benchmarkData;
  final DateTime loadedAt;

  const SlaBenchmarkDataLoaded({
    required this.benchmarkData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [benchmarkData, loadedAt];

  // Helper getters
  double? get firmScore => benchmarkData['firm_score']?.toDouble();
  double? get industryAverage => benchmarkData['industry_average']?.toDouble();
  double? get topQuartile => benchmarkData['top_quartile']?.toDouble();
  String? get ranking => benchmarkData['ranking'];
  List<String>? get improvementAreas => 
      (benchmarkData['improvement_areas'] as List?)?.cast<String>();
  
  bool get isAboveAverage => 
      firmScore != null && industryAverage != null && firmScore! > industryAverage!;
  bool get isTopQuartilePerformer => 
      firmScore != null && topQuartile != null && firmScore! >= topQuartile!;
}

class SlaPredictiveAnalyticsLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> predictiveData;
  final int forecastDays;
  final DateTime loadedAt;

  const SlaPredictiveAnalyticsLoaded({
    required this.predictiveData,
    required this.forecastDays,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [predictiveData, forecastDays, loadedAt];

  // Helper getters
  int? get predictedViolations => predictiveData['predicted_violations'];
  double? get confidence => predictiveData['confidence']?.toDouble();
  List<String>? get riskFactors => 
      (predictiveData['risk_factors'] as List?)?.cast<String>();
  List<String>? get recommendations => 
      (predictiveData['recommendations'] as List?)?.cast<String>();
  
  bool get isHighConfidence => confidence != null && confidence! >= 80.0;
  bool get hasRiskFactors => riskFactors?.isNotEmpty ?? false;
}

// Comparison States
class SlaPeriodsComparisonLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> period1Data;
  final Map<String, dynamic> period2Data;
  final Map<String, dynamic> comparisonResults;
  final DateTime loadedAt;

  const SlaPeriodsComparisonLoaded({
    required this.period1Data,
    required this.period2Data,
    required this.comparisonResults,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [period1Data, period2Data, comparisonResults, loadedAt];
}

// Alert States
class SlaAlertsLoaded extends SlaAnalyticsState {
  final List<Map<String, dynamic>> alerts;
  final DateTime loadedAt;

  const SlaAlertsLoaded({
    required this.alerts,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [alerts, loadedAt];

  // Helper getters
  int get totalAlerts => alerts.length;
  List<Map<String, dynamic>> get criticalAlerts => 
      alerts.where((alert) => alert['severity'] == 'critical').toList();
  List<Map<String, dynamic>> get activeAlerts => 
      alerts.where((alert) => alert['active'] == true).toList();
  bool get hasCriticalAlerts => criticalAlerts.isNotEmpty;
}

// Drill-down States
class SlaDetailedAnalysisLoaded extends SlaAnalyticsState {
  final String analysisType;
  final String entityId;
  final Map<String, dynamic> detailedData;
  final DateTime loadedAt;

  const SlaDetailedAnalysisLoaded({
    required this.analysisType,
    required this.entityId,
    required this.detailedData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [analysisType, entityId, detailedData, loadedAt];

  // Helper getters
  bool get isLawyerDetail => analysisType == 'lawyer_detail';
  bool get isCaseDetail => analysisType == 'case_detail';
  bool get isTimeDetail => analysisType == 'time_detail';
}

// Error State
class SlaAnalyticsError extends SlaAnalyticsState {
  final String message;
  final String? errorCode;
  final dynamic error;
  final StackTrace? stackTrace;

  const SlaAnalyticsError({
    required this.message,
    this.errorCode,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, errorCode, error, stackTrace];

  // Helper getters
  bool get isNetworkError => errorCode?.contains('NETWORK') ?? false;
  bool get isServerError => errorCode?.contains('SERVER') ?? false;
  bool get isDataError => errorCode?.contains('DATA') ?? false;
  bool get isPermissionError => errorCode?.contains('PERMISSION') ?? false;
  bool get isRetryableError => isNetworkError || isServerError;
} 

abstract class SlaAnalyticsState extends Equatable {
  const SlaAnalyticsState();

  @override
  List<Object?> get props => [];
}

// Initial State
class SlaAnalyticsInitial extends SlaAnalyticsState {
  const SlaAnalyticsInitial();
}

// Loading States
class SlaAnalyticsLoading extends SlaAnalyticsState {
  final String? message;

  const SlaAnalyticsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class SlaAnalyticsRefreshing extends SlaAnalyticsState {
  final SlaMetricsEntity previousMetrics;
  final SlaAnalyticsFilters filters;

  const SlaAnalyticsRefreshing({
    required this.previousMetrics,
    required this.filters,
  });

  @override
  List<Object?> get props => [previousMetrics, filters];
}

// Loaded State - Main state with analytics data
class SlaAnalyticsLoaded extends SlaAnalyticsState {
  final SlaMetricsEntity metrics;
  final SlaAnalyticsFilters filters;
  final DateTime loadedAt;
  final SlaMetricsEntity? previousMetrics;
  final Map<String, dynamic>? complianceReport;
  final List<Map<String, dynamic>>? performanceTrends;
  final Map<String, dynamic>? customReportData;

  const SlaAnalyticsLoaded({
    required this.metrics,
    required this.filters,
    required this.loadedAt,
    this.previousMetrics,
    this.complianceReport,
    this.performanceTrends,
    this.customReportData,
  });

  @override
  List<Object?> get props => [
        metrics,
        filters,
        loadedAt,
        previousMetrics,
        complianceReport,
        performanceTrends,
        customReportData,
      ];

  SlaAnalyticsLoaded copyWith({
    SlaMetricsEntity? metrics,
    SlaAnalyticsFilters? filters,
    DateTime? loadedAt,
    SlaMetricsEntity? previousMetrics,
    Map<String, dynamic>? complianceReport,
    List<Map<String, dynamic>>? performanceTrends,
    Map<String, dynamic>? customReportData,
  }) {
    return SlaAnalyticsLoaded(
      metrics: metrics ?? this.metrics,
      filters: filters ?? this.filters,
      loadedAt: loadedAt ?? this.loadedAt,
      previousMetrics: previousMetrics ?? this.previousMetrics,
      complianceReport: complianceReport ?? this.complianceReport,
      performanceTrends: performanceTrends ?? this.performanceTrends,
      customReportData: customReportData ?? this.customReportData,
    );
  }

  // Helper getters
  bool get hasComplianceReport => complianceReport != null;
  bool get hasPerformanceTrends => performanceTrends != null;
  bool get hasCustomReport => customReportData != null;
  bool get hasPreviousMetrics => previousMetrics != null;
  Duration get timeSinceLoaded => DateTime.now().difference(loadedAt);
  bool get needsRefresh => timeSinceLoaded.inMinutes > 5; // Refresh after 5 minutes
}

// Report States
class SlaAnalyticsReportLoading extends SlaAnalyticsState {
  final String reportType;
  final SlaMetricsEntity? baseMetrics;
  final double? progress;

  const SlaAnalyticsReportLoading({
    required this.reportType,
    this.baseMetrics,
    this.progress,
  });

  @override
  List<Object?> get props => [reportType, baseMetrics, progress];
}

class SlaAnalyticsReportLoaded extends SlaAnalyticsState {
  final String reportType;
  final Map<String, dynamic> reportData;
  final DateTime generatedAt;
  final SlaMetricsEntity? baseMetrics;

  const SlaAnalyticsReportLoaded({
    required this.reportType,
    required this.reportData,
    required this.generatedAt,
    this.baseMetrics,
  });

  @override
  List<Object?> get props => [reportType, reportData, generatedAt, baseMetrics];

  // Helper getters
  bool get isComplianceReport => reportType == 'compliance';
  bool get isTrendsReport => reportType == 'trends';
  bool get isCustomReport => reportType == 'custom';
  Duration get reportAge => DateTime.now().difference(generatedAt);
}

class SlaAnalyticsReportScheduled extends SlaAnalyticsState {
  final Map<String, dynamic> reportConfig;
  final String schedule;
  final List<String> recipients;
  final DateTime scheduledAt;

  const SlaAnalyticsReportScheduled({
    required this.reportConfig,
    required this.schedule,
    required this.recipients,
    required this.scheduledAt,
  });

  @override
  List<Object?> get props => [reportConfig, schedule, recipients, scheduledAt];
}

// Export States
class SlaAnalyticsExporting extends SlaAnalyticsState {
  final String format;
  final String reportType;
  final double progress; // 0.0 to 1.0

  const SlaAnalyticsExporting({
    required this.format,
    required this.reportType,
    required this.progress,
  });

  @override
  List<Object?> get props => [format, reportType, progress];

  // Helper getters
  int get progressPercent => (progress * 100).round();
  bool get isComplete => progress >= 1.0;
}

class SlaAnalyticsExported extends SlaAnalyticsState {
  final String filePath;
  final String format;
  final String reportType;
  final DateTime exportedAt;

  const SlaAnalyticsExported({
    required this.filePath,
    required this.format,
    required this.reportType,
    required this.exportedAt,
  });

  @override
  List<Object?> get props => [filePath, format, reportType, exportedAt];
}

// Specialized Analysis States
class SlaKPIDashboardLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> kpiData;
  final DateTime loadedAt;

  const SlaKPIDashboardLoaded({
    required this.kpiData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [kpiData, loadedAt];

  // Helper getters for KPI data
  double? get complianceRate => kpiData['compliance_rate']?.toDouble();
  String? get avgResponseTime => kpiData['avg_response_time'];
  int? get violationsCount => kpiData['violations_count'];
  int? get escalationsCount => kpiData['escalations_count'];
  List<String>? get topPerformers => 
      (kpiData['top_performers'] as List?)?.cast<String>();
  List<String>? get bottomPerformers => 
      (kpiData['bottom_performers'] as List?)?.cast<String>();
}

class SlaViolationAnalysisLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> violationData;
  final DateTime loadedAt;

  const SlaViolationAnalysisLoaded({
    required this.violationData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [violationData, loadedAt];

  // Helper getters
  int? get totalViolations => violationData['total_violations'];
  Map<String, dynamic>? get violationsByPriority => violationData['by_priority'];
  Map<String, dynamic>? get violationsByLawyer => violationData['by_lawyer'];
  List<Map<String, dynamic>>? get violationTrends => 
      (violationData['trends'] as List?)?.cast<Map<String, dynamic>>();
}

class SlaEscalationAnalysisLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> escalationData;
  final DateTime loadedAt;

  const SlaEscalationAnalysisLoaded({
    required this.escalationData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [escalationData, loadedAt];

  // Helper getters
  int? get totalEscalations => escalationData['total_escalations'];
  Map<String, dynamic>? get escalationsByLevel => escalationData['by_level'];
  double? get successRate => escalationData['success_rate']?.toDouble();
  String? get avgResolutionTime => escalationData['avg_resolution_time'];
}

class SlaBenchmarkDataLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> benchmarkData;
  final DateTime loadedAt;

  const SlaBenchmarkDataLoaded({
    required this.benchmarkData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [benchmarkData, loadedAt];

  // Helper getters
  double? get firmScore => benchmarkData['firm_score']?.toDouble();
  double? get industryAverage => benchmarkData['industry_average']?.toDouble();
  double? get topQuartile => benchmarkData['top_quartile']?.toDouble();
  String? get ranking => benchmarkData['ranking'];
  List<String>? get improvementAreas => 
      (benchmarkData['improvement_areas'] as List?)?.cast<String>();
  
  bool get isAboveAverage => 
      firmScore != null && industryAverage != null && firmScore! > industryAverage!;
  bool get isTopQuartilePerformer => 
      firmScore != null && topQuartile != null && firmScore! >= topQuartile!;
}

class SlaPredictiveAnalyticsLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> predictiveData;
  final int forecastDays;
  final DateTime loadedAt;

  const SlaPredictiveAnalyticsLoaded({
    required this.predictiveData,
    required this.forecastDays,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [predictiveData, forecastDays, loadedAt];

  // Helper getters
  int? get predictedViolations => predictiveData['predicted_violations'];
  double? get confidence => predictiveData['confidence']?.toDouble();
  List<String>? get riskFactors => 
      (predictiveData['risk_factors'] as List?)?.cast<String>();
  List<String>? get recommendations => 
      (predictiveData['recommendations'] as List?)?.cast<String>();
  
  bool get isHighConfidence => confidence != null && confidence! >= 80.0;
  bool get hasRiskFactors => riskFactors?.isNotEmpty ?? false;
}

// Comparison States
class SlaPeriodsComparisonLoaded extends SlaAnalyticsState {
  final Map<String, dynamic> period1Data;
  final Map<String, dynamic> period2Data;
  final Map<String, dynamic> comparisonResults;
  final DateTime loadedAt;

  const SlaPeriodsComparisonLoaded({
    required this.period1Data,
    required this.period2Data,
    required this.comparisonResults,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [period1Data, period2Data, comparisonResults, loadedAt];
}

// Alert States
class SlaAlertsLoaded extends SlaAnalyticsState {
  final List<Map<String, dynamic>> alerts;
  final DateTime loadedAt;

  const SlaAlertsLoaded({
    required this.alerts,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [alerts, loadedAt];

  // Helper getters
  int get totalAlerts => alerts.length;
  List<Map<String, dynamic>> get criticalAlerts => 
      alerts.where((alert) => alert['severity'] == 'critical').toList();
  List<Map<String, dynamic>> get activeAlerts => 
      alerts.where((alert) => alert['active'] == true).toList();
  bool get hasCriticalAlerts => criticalAlerts.isNotEmpty;
}

// Drill-down States
class SlaDetailedAnalysisLoaded extends SlaAnalyticsState {
  final String analysisType;
  final String entityId;
  final Map<String, dynamic> detailedData;
  final DateTime loadedAt;

  const SlaDetailedAnalysisLoaded({
    required this.analysisType,
    required this.entityId,
    required this.detailedData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [analysisType, entityId, detailedData, loadedAt];

  // Helper getters
  bool get isLawyerDetail => analysisType == 'lawyer_detail';
  bool get isCaseDetail => analysisType == 'case_detail';
  bool get isTimeDetail => analysisType == 'time_detail';
}

// Error State
class SlaAnalyticsError extends SlaAnalyticsState {
  final String message;
  final String? errorCode;
  final dynamic error;
  final StackTrace? stackTrace;

  const SlaAnalyticsError({
    required this.message,
    this.errorCode,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, errorCode, error, stackTrace];

  // Helper getters
  bool get isNetworkError => errorCode?.contains('NETWORK') ?? false;
  bool get isServerError => errorCode?.contains('SERVER') ?? false;
  bool get isDataError => errorCode?.contains('DATA') ?? false;
  bool get isPermissionError => errorCode?.contains('PERMISSION') ?? false;
  bool get isRetryableError => isNetworkError || isServerError;
} 