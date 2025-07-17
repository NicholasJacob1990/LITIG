import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sla_metrics_entity.dart';

part 'sla_metrics_model.g.dart';

/// Model que implementa serialização JSON para SlaMetricsEntity
/// 
/// Responsável pela conversão de todas as métricas complexas,
/// incluindo submodels para diferentes tipos de métricas
@JsonSerializable(explicitToJson: true)
class SlaMetricsModel extends SlaMetricsEntity {
  const SlaMetricsModel({
    required super.id,
    required super.firmId,
    required super.periodStart,
    required super.periodEnd,
    required super.complianceMetrics,
    required super.performanceMetrics,
    required super.violationMetrics,
    required super.escalationMetrics,
    required super.trendsData,
    required super.generatedAt,
    super.lawyerMetrics,
    super.clientMetrics,
    super.caseTypeMetrics,
    super.customMetrics,
    super.metadata,
  });

  /// Cria um SlaMetricsModel a partir de JSON
  factory SlaMetricsModel.fromJson(Map<String, dynamic> json) {
    return SlaMetricsModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      complianceMetrics: ComplianceMetricsModel.fromJson(
        json['compliance_metrics'] as Map<String, dynamic>
      ),
      performanceMetrics: PerformanceMetricsModel.fromJson(
        json['performance_metrics'] as Map<String, dynamic>
      ),
      violationMetrics: ViolationMetricsModel.fromJson(
        json['violation_metrics'] as Map<String, dynamic>
      ),
      escalationMetrics: EscalationMetricsModel.fromJson(
        json['escalation_metrics'] as Map<String, dynamic>
      ),
      trendsData: TrendsDataModel.fromJson(
        json['trends_data'] as Map<String, dynamic>
      ),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      lawyerMetrics: json['lawyer_metrics'] != null
          ? (json['lawyer_metrics'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key, 
                LawyerMetricsModel.fromJson(value as Map<String, dynamic>)
              )
            )
          : null,
      clientMetrics: json['client_metrics'] != null
          ? (json['client_metrics'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key, 
                ClientMetricsModel.fromJson(value as Map<String, dynamic>)
              )
            )
          : null,
      caseTypeMetrics: json['case_type_metrics'] != null
          ? (json['case_type_metrics'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key, 
                CaseTypeMetricsModel.fromJson(value as Map<String, dynamic>)
              )
            )
          : null,
      customMetrics: json['custom_metrics'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte o SlaMetricsModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'compliance_metrics': (complianceMetrics as ComplianceMetricsModel).toJson(),
      'performance_metrics': (performanceMetrics as PerformanceMetricsModel).toJson(),
      'violation_metrics': (violationMetrics as ViolationMetricsModel).toJson(),
      'escalation_metrics': (escalationMetrics as EscalationMetricsModel).toJson(),
      'trends_data': (trendsData as TrendsDataModel).toJson(),
      'generated_at': generatedAt.toIso8601String(),
      'lawyer_metrics': lawyerMetrics?.map(
        (key, value) => MapEntry(key, (value as LawyerMetricsModel).toJson())
      ),
      'client_metrics': clientMetrics?.map(
        (key, value) => MapEntry(key, (value as ClientMetricsModel).toJson())
      ),
      'case_type_metrics': caseTypeMetrics?.map(
        (key, value) => MapEntry(key, (value as CaseTypeMetricsModel).toJson())
      ),
      'custom_metrics': customMetrics,
      'metadata': metadata,
    };
  }

  /// Converte uma entidade de domínio para model
  factory SlaMetricsModel.fromEntity(SlaMetricsEntity entity) {
    return SlaMetricsModel(
      id: entity.id,
      firmId: entity.firmId,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      complianceMetrics: ComplianceMetricsModel.fromEntity(entity.complianceMetrics),
      performanceMetrics: PerformanceMetricsModel.fromEntity(entity.performanceMetrics),
      violationMetrics: ViolationMetricsModel.fromEntity(entity.violationMetrics),
      escalationMetrics: EscalationMetricsModel.fromEntity(entity.escalationMetrics),
      trendsData: TrendsDataModel.fromEntity(entity.trendsData),
      generatedAt: entity.generatedAt,
      lawyerMetrics: entity.lawyerMetrics?.map(
        (key, value) => MapEntry(key, LawyerMetricsModel.fromEntity(value))
      ),
      clientMetrics: entity.clientMetrics?.map(
        (key, value) => MapEntry(key, ClientMetricsModel.fromEntity(value))
      ),
      caseTypeMetrics: entity.caseTypeMetrics?.map(
        (key, value) => MapEntry(key, CaseTypeMetricsModel.fromEntity(value))
      ),
      customMetrics: entity.customMetrics,
      metadata: entity.metadata,
    );
  }
}

/// Model para ComplianceMetrics
@JsonSerializable(explicitToJson: true)
class ComplianceMetricsModel extends ComplianceMetrics {
  const ComplianceMetricsModel({
    required super.overallRate,
    required super.byPriority,
    required super.totalCases,
    required super.compliantCases,
    required super.nonCompliantCases,
  });

  factory ComplianceMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$ComplianceMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ComplianceMetricsModelToJson(this);

  factory ComplianceMetricsModel.fromEntity(ComplianceMetrics entity) {
    return ComplianceMetricsModel(
      overallRate: entity.overallRate,
      byPriority: entity.byPriority,
      totalCases: entity.totalCases,
      compliantCases: entity.compliantCases,
      nonCompliantCases: entity.nonCompliantCases,
    );
  }
}

/// Model para PerformanceMetrics
@JsonSerializable(explicitToJson: true)
class PerformanceMetricsModel extends PerformanceMetrics {
  const PerformanceMetricsModel({
    required super.averageResponseTime,
    required super.medianResponseTime,
    required super.fastestResponseTime,
    required super.slowestResponseTime,
    required super.responseTimeByPriority,
    required super.responseTimeDistribution,
  });

  factory PerformanceMetricsModel.fromJson(Map<String, dynamic> json) {
    return PerformanceMetricsModel(
      averageResponseTime: Duration(milliseconds: json['average_response_time_ms'] as int),
      medianResponseTime: Duration(milliseconds: json['median_response_time_ms'] as int),
      fastestResponseTime: Duration(milliseconds: json['fastest_response_time_ms'] as int),
      slowestResponseTime: Duration(milliseconds: json['slowest_response_time_ms'] as int),
      responseTimeByPriority: (json['response_time_by_priority'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, Duration(milliseconds: value as int))),
      responseTimeDistribution: (json['response_time_distribution'] as Map<String, dynamic>)
          .cast<String, int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'median_response_time_ms': medianResponseTime.inMilliseconds,
      'fastest_response_time_ms': fastestResponseTime.inMilliseconds,
      'slowest_response_time_ms': slowestResponseTime.inMilliseconds,
      'response_time_by_priority': responseTimeByPriority
          .map((key, value) => MapEntry(key, value.inMilliseconds)),
      'response_time_distribution': responseTimeDistribution,
    };
  }

  factory PerformanceMetricsModel.fromEntity(PerformanceMetrics entity) {
    return PerformanceMetricsModel(
      averageResponseTime: entity.averageResponseTime,
      medianResponseTime: entity.medianResponseTime,
      fastestResponseTime: entity.fastestResponseTime,
      slowestResponseTime: entity.slowestResponseTime,
      responseTimeByPriority: entity.responseTimeByPriority,
      responseTimeDistribution: entity.responseTimeDistribution,
    );
  }
}

/// Model para ViolationMetrics
@JsonSerializable(explicitToJson: true)
class ViolationMetricsModel extends ViolationMetrics {
  const ViolationMetricsModel({
    required super.totalViolations,
    required super.violationRate,
    required super.violationsByPriority,
    required super.violationsByReason,
    required super.averageDelayTime,
    required super.totalDelayTime,
  });

  factory ViolationMetricsModel.fromJson(Map<String, dynamic> json) {
    return ViolationMetricsModel(
      totalViolations: json['total_violations'] as int,
      violationRate: (json['violation_rate'] as num).toDouble(),
      violationsByPriority: (json['violations_by_priority'] as Map<String, dynamic>)
          .cast<String, int>(),
      violationsByReason: (json['violations_by_reason'] as Map<String, dynamic>)
          .cast<String, int>(),
      averageDelayTime: Duration(milliseconds: json['average_delay_time_ms'] as int),
      totalDelayTime: Duration(milliseconds: json['total_delay_time_ms'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_violations': totalViolations,
      'violation_rate': violationRate,
      'violations_by_priority': violationsByPriority,
      'violations_by_reason': violationsByReason,
      'average_delay_time_ms': averageDelayTime.inMilliseconds,
      'total_delay_time_ms': totalDelayTime.inMilliseconds,
    };
  }

  factory ViolationMetricsModel.fromEntity(ViolationMetrics entity) {
    return ViolationMetricsModel(
      totalViolations: entity.totalViolations,
      violationRate: entity.violationRate,
      violationsByPriority: entity.violationsByPriority,
      violationsByReason: entity.violationsByReason,
      averageDelayTime: entity.averageDelayTime,
      totalDelayTime: entity.totalDelayTime,
    );
  }
}

/// Model para EscalationMetrics
@JsonSerializable(explicitToJson: true)
class EscalationMetricsModel extends EscalationMetrics {
  const EscalationMetricsModel({
    required super.totalEscalations,
    required super.escalationRate,
    required super.escalationsByLevel,
    required super.averageEscalationTime,
    required super.resolvedEscalations,
  });

  factory EscalationMetricsModel.fromJson(Map<String, dynamic> json) {
    return EscalationMetricsModel(
      totalEscalations: json['total_escalations'] as int,
      escalationRate: (json['escalation_rate'] as num).toDouble(),
      escalationsByLevel: (json['escalations_by_level'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(int.parse(key), value as int)),
      averageEscalationTime: Duration(milliseconds: json['average_escalation_time_ms'] as int),
      resolvedEscalations: json['resolved_escalations'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_escalations': totalEscalations,
      'escalation_rate': escalationRate,
      'escalations_by_level': escalationsByLevel
          .map((key, value) => MapEntry(key.toString(), value)),
      'average_escalation_time_ms': averageEscalationTime.inMilliseconds,
      'resolved_escalations': resolvedEscalations,
    };
  }

  factory EscalationMetricsModel.fromEntity(EscalationMetrics entity) {
    return EscalationMetricsModel(
      totalEscalations: entity.totalEscalations,
      escalationRate: entity.escalationRate,
      escalationsByLevel: entity.escalationsByLevel,
      averageEscalationTime: entity.averageEscalationTime,
      resolvedEscalations: entity.resolvedEscalations,
    );
  }
}

/// Model para TrendsData
@JsonSerializable(explicitToJson: true)
class TrendsDataModel extends TrendsData {
  const TrendsDataModel({
    required super.complianceTrend,
    required super.violationTrend,
    required super.performanceTrend,
    required super.volumeTrend,
  });

  factory TrendsDataModel.fromJson(Map<String, dynamic> json) {
    return TrendsDataModel(
      complianceTrend: (json['compliance_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      violationTrend: (json['violation_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      performanceTrend: (json['performance_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      volumeTrend: (json['volume_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compliance_trend': complianceTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
      'violation_trend': violationTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
      'performance_trend': performanceTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
      'volume_trend': volumeTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
    };
  }

  factory TrendsDataModel.fromEntity(TrendsData entity) {
    return TrendsDataModel(
      complianceTrend: entity.complianceTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
      violationTrend: entity.violationTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
      performanceTrend: entity.performanceTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
      volumeTrend: entity.volumeTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
    );
  }
}

/// Model para DataPoint
@JsonSerializable(explicitToJson: true)
class DataPointModel extends DataPoint {
  const DataPointModel({
    required super.timestamp,
    required super.value,
    super.metadata,
  });

  factory DataPointModel.fromJson(Map<String, dynamic> json) =>
      _$DataPointModelFromJson(json);

  Map<String, dynamic> toJson() => _$DataPointModelToJson(this);

  factory DataPointModel.fromEntity(DataPoint entity) {
    return DataPointModel(
      timestamp: entity.timestamp,
      value: entity.value,
      metadata: entity.metadata,
    );
  }
}

/// Model para LawyerMetrics
@JsonSerializable(explicitToJson: true)
class LawyerMetricsModel extends LawyerMetrics {
  const LawyerMetricsModel({
    required super.lawyerId,
    required super.lawyerName,
    required super.totalCases,
    required super.complianceRate,
    required super.averageResponseTime,
    required super.violations,
    required super.escalations,
  });

  factory LawyerMetricsModel.fromJson(Map<String, dynamic> json) {
    return LawyerMetricsModel(
      lawyerId: json['lawyer_id'] as String,
      lawyerName: json['lawyer_name'] as String,
      totalCases: json['total_cases'] as int,
      complianceRate: (json['compliance_rate'] as num).toDouble(),
      averageResponseTime: Duration(milliseconds: json['average_response_time_ms'] as int),
      violations: json['violations'] as int,
      escalations: json['escalations'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lawyer_id': lawyerId,
      'lawyer_name': lawyerName,
      'total_cases': totalCases,
      'compliance_rate': complianceRate,
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'violations': violations,
      'escalations': escalations,
    };
  }

  factory LawyerMetricsModel.fromEntity(LawyerMetrics entity) {
    return LawyerMetricsModel(
      lawyerId: entity.lawyerId,
      lawyerName: entity.lawyerName,
      totalCases: entity.totalCases,
      complianceRate: entity.complianceRate,
      averageResponseTime: entity.averageResponseTime,
      violations: entity.violations,
      escalations: entity.escalations,
    );
  }
}

/// Model para ClientMetrics
@JsonSerializable(explicitToJson: true)
class ClientMetricsModel extends ClientMetrics {
  const ClientMetricsModel({
    required super.clientId,
    required super.clientName,
    required super.totalCases,
    required super.complianceRate,
    required super.averageResponseTime,
    required super.violations,
  });

  factory ClientMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$ClientMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClientMetricsModelToJson(this);

  factory ClientMetricsModel.fromEntity(ClientMetrics entity) {
    return ClientMetricsModel(
      clientId: entity.clientId,
      clientName: entity.clientName,
      totalCases: entity.totalCases,
      complianceRate: entity.complianceRate,
      averageResponseTime: entity.averageResponseTime,
      violations: entity.violations,
    );
  }
}

/// Model para CaseTypeMetrics
@JsonSerializable(explicitToJson: true)
class CaseTypeMetricsModel extends CaseTypeMetrics {
  const CaseTypeMetricsModel({
    required super.caseType,
    required super.totalCases,
    required super.complianceRate,
    required super.averageResponseTime,
    required super.violations,
  });

  factory CaseTypeMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$CaseTypeMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$CaseTypeMetricsModelToJson(this);

  factory CaseTypeMetricsModel.fromEntity(CaseTypeMetrics entity) {
    return CaseTypeMetricsModel(
      caseType: entity.caseType,
      totalCases: entity.totalCases,
      complianceRate: entity.complianceRate,
      averageResponseTime: entity.averageResponseTime,
      violations: entity.violations,
    );
  }
} 
import '../../domain/entities/sla_metrics_entity.dart';

part 'sla_metrics_model.g.dart';

/// Model que implementa serialização JSON para SlaMetricsEntity
/// 
/// Responsável pela conversão de todas as métricas complexas,
/// incluindo submodels para diferentes tipos de métricas
@JsonSerializable(explicitToJson: true)
class SlaMetricsModel extends SlaMetricsEntity {
  const SlaMetricsModel({
    required super.id,
    required super.firmId,
    required super.periodStart,
    required super.periodEnd,
    required super.complianceMetrics,
    required super.performanceMetrics,
    required super.violationMetrics,
    required super.escalationMetrics,
    required super.trendsData,
    required super.generatedAt,
    super.lawyerMetrics,
    super.clientMetrics,
    super.caseTypeMetrics,
    super.customMetrics,
    super.metadata,
  });

  /// Cria um SlaMetricsModel a partir de JSON
  factory SlaMetricsModel.fromJson(Map<String, dynamic> json) {
    return SlaMetricsModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      complianceMetrics: ComplianceMetricsModel.fromJson(
        json['compliance_metrics'] as Map<String, dynamic>
      ),
      performanceMetrics: PerformanceMetricsModel.fromJson(
        json['performance_metrics'] as Map<String, dynamic>
      ),
      violationMetrics: ViolationMetricsModel.fromJson(
        json['violation_metrics'] as Map<String, dynamic>
      ),
      escalationMetrics: EscalationMetricsModel.fromJson(
        json['escalation_metrics'] as Map<String, dynamic>
      ),
      trendsData: TrendsDataModel.fromJson(
        json['trends_data'] as Map<String, dynamic>
      ),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      lawyerMetrics: json['lawyer_metrics'] != null
          ? (json['lawyer_metrics'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key, 
                LawyerMetricsModel.fromJson(value as Map<String, dynamic>)
              )
            )
          : null,
      clientMetrics: json['client_metrics'] != null
          ? (json['client_metrics'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key, 
                ClientMetricsModel.fromJson(value as Map<String, dynamic>)
              )
            )
          : null,
      caseTypeMetrics: json['case_type_metrics'] != null
          ? (json['case_type_metrics'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key, 
                CaseTypeMetricsModel.fromJson(value as Map<String, dynamic>)
              )
            )
          : null,
      customMetrics: json['custom_metrics'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte o SlaMetricsModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'compliance_metrics': (complianceMetrics as ComplianceMetricsModel).toJson(),
      'performance_metrics': (performanceMetrics as PerformanceMetricsModel).toJson(),
      'violation_metrics': (violationMetrics as ViolationMetricsModel).toJson(),
      'escalation_metrics': (escalationMetrics as EscalationMetricsModel).toJson(),
      'trends_data': (trendsData as TrendsDataModel).toJson(),
      'generated_at': generatedAt.toIso8601String(),
      'lawyer_metrics': lawyerMetrics?.map(
        (key, value) => MapEntry(key, (value as LawyerMetricsModel).toJson())
      ),
      'client_metrics': clientMetrics?.map(
        (key, value) => MapEntry(key, (value as ClientMetricsModel).toJson())
      ),
      'case_type_metrics': caseTypeMetrics?.map(
        (key, value) => MapEntry(key, (value as CaseTypeMetricsModel).toJson())
      ),
      'custom_metrics': customMetrics,
      'metadata': metadata,
    };
  }

  /// Converte uma entidade de domínio para model
  factory SlaMetricsModel.fromEntity(SlaMetricsEntity entity) {
    return SlaMetricsModel(
      id: entity.id,
      firmId: entity.firmId,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      complianceMetrics: ComplianceMetricsModel.fromEntity(entity.complianceMetrics),
      performanceMetrics: PerformanceMetricsModel.fromEntity(entity.performanceMetrics),
      violationMetrics: ViolationMetricsModel.fromEntity(entity.violationMetrics),
      escalationMetrics: EscalationMetricsModel.fromEntity(entity.escalationMetrics),
      trendsData: TrendsDataModel.fromEntity(entity.trendsData),
      generatedAt: entity.generatedAt,
      lawyerMetrics: entity.lawyerMetrics?.map(
        (key, value) => MapEntry(key, LawyerMetricsModel.fromEntity(value))
      ),
      clientMetrics: entity.clientMetrics?.map(
        (key, value) => MapEntry(key, ClientMetricsModel.fromEntity(value))
      ),
      caseTypeMetrics: entity.caseTypeMetrics?.map(
        (key, value) => MapEntry(key, CaseTypeMetricsModel.fromEntity(value))
      ),
      customMetrics: entity.customMetrics,
      metadata: entity.metadata,
    );
  }
}

/// Model para ComplianceMetrics
@JsonSerializable(explicitToJson: true)
class ComplianceMetricsModel extends ComplianceMetrics {
  const ComplianceMetricsModel({
    required super.overallRate,
    required super.byPriority,
    required super.totalCases,
    required super.compliantCases,
    required super.nonCompliantCases,
  });

  factory ComplianceMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$ComplianceMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ComplianceMetricsModelToJson(this);

  factory ComplianceMetricsModel.fromEntity(ComplianceMetrics entity) {
    return ComplianceMetricsModel(
      overallRate: entity.overallRate,
      byPriority: entity.byPriority,
      totalCases: entity.totalCases,
      compliantCases: entity.compliantCases,
      nonCompliantCases: entity.nonCompliantCases,
    );
  }
}

/// Model para PerformanceMetrics
@JsonSerializable(explicitToJson: true)
class PerformanceMetricsModel extends PerformanceMetrics {
  const PerformanceMetricsModel({
    required super.averageResponseTime,
    required super.medianResponseTime,
    required super.fastestResponseTime,
    required super.slowestResponseTime,
    required super.responseTimeByPriority,
    required super.responseTimeDistribution,
  });

  factory PerformanceMetricsModel.fromJson(Map<String, dynamic> json) {
    return PerformanceMetricsModel(
      averageResponseTime: Duration(milliseconds: json['average_response_time_ms'] as int),
      medianResponseTime: Duration(milliseconds: json['median_response_time_ms'] as int),
      fastestResponseTime: Duration(milliseconds: json['fastest_response_time_ms'] as int),
      slowestResponseTime: Duration(milliseconds: json['slowest_response_time_ms'] as int),
      responseTimeByPriority: (json['response_time_by_priority'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, Duration(milliseconds: value as int))),
      responseTimeDistribution: (json['response_time_distribution'] as Map<String, dynamic>)
          .cast<String, int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'median_response_time_ms': medianResponseTime.inMilliseconds,
      'fastest_response_time_ms': fastestResponseTime.inMilliseconds,
      'slowest_response_time_ms': slowestResponseTime.inMilliseconds,
      'response_time_by_priority': responseTimeByPriority
          .map((key, value) => MapEntry(key, value.inMilliseconds)),
      'response_time_distribution': responseTimeDistribution,
    };
  }

  factory PerformanceMetricsModel.fromEntity(PerformanceMetrics entity) {
    return PerformanceMetricsModel(
      averageResponseTime: entity.averageResponseTime,
      medianResponseTime: entity.medianResponseTime,
      fastestResponseTime: entity.fastestResponseTime,
      slowestResponseTime: entity.slowestResponseTime,
      responseTimeByPriority: entity.responseTimeByPriority,
      responseTimeDistribution: entity.responseTimeDistribution,
    );
  }
}

/// Model para ViolationMetrics
@JsonSerializable(explicitToJson: true)
class ViolationMetricsModel extends ViolationMetrics {
  const ViolationMetricsModel({
    required super.totalViolations,
    required super.violationRate,
    required super.violationsByPriority,
    required super.violationsByReason,
    required super.averageDelayTime,
    required super.totalDelayTime,
  });

  factory ViolationMetricsModel.fromJson(Map<String, dynamic> json) {
    return ViolationMetricsModel(
      totalViolations: json['total_violations'] as int,
      violationRate: (json['violation_rate'] as num).toDouble(),
      violationsByPriority: (json['violations_by_priority'] as Map<String, dynamic>)
          .cast<String, int>(),
      violationsByReason: (json['violations_by_reason'] as Map<String, dynamic>)
          .cast<String, int>(),
      averageDelayTime: Duration(milliseconds: json['average_delay_time_ms'] as int),
      totalDelayTime: Duration(milliseconds: json['total_delay_time_ms'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_violations': totalViolations,
      'violation_rate': violationRate,
      'violations_by_priority': violationsByPriority,
      'violations_by_reason': violationsByReason,
      'average_delay_time_ms': averageDelayTime.inMilliseconds,
      'total_delay_time_ms': totalDelayTime.inMilliseconds,
    };
  }

  factory ViolationMetricsModel.fromEntity(ViolationMetrics entity) {
    return ViolationMetricsModel(
      totalViolations: entity.totalViolations,
      violationRate: entity.violationRate,
      violationsByPriority: entity.violationsByPriority,
      violationsByReason: entity.violationsByReason,
      averageDelayTime: entity.averageDelayTime,
      totalDelayTime: entity.totalDelayTime,
    );
  }
}

/// Model para EscalationMetrics
@JsonSerializable(explicitToJson: true)
class EscalationMetricsModel extends EscalationMetrics {
  const EscalationMetricsModel({
    required super.totalEscalations,
    required super.escalationRate,
    required super.escalationsByLevel,
    required super.averageEscalationTime,
    required super.resolvedEscalations,
  });

  factory EscalationMetricsModel.fromJson(Map<String, dynamic> json) {
    return EscalationMetricsModel(
      totalEscalations: json['total_escalations'] as int,
      escalationRate: (json['escalation_rate'] as num).toDouble(),
      escalationsByLevel: (json['escalations_by_level'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(int.parse(key), value as int)),
      averageEscalationTime: Duration(milliseconds: json['average_escalation_time_ms'] as int),
      resolvedEscalations: json['resolved_escalations'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_escalations': totalEscalations,
      'escalation_rate': escalationRate,
      'escalations_by_level': escalationsByLevel
          .map((key, value) => MapEntry(key.toString(), value)),
      'average_escalation_time_ms': averageEscalationTime.inMilliseconds,
      'resolved_escalations': resolvedEscalations,
    };
  }

  factory EscalationMetricsModel.fromEntity(EscalationMetrics entity) {
    return EscalationMetricsModel(
      totalEscalations: entity.totalEscalations,
      escalationRate: entity.escalationRate,
      escalationsByLevel: entity.escalationsByLevel,
      averageEscalationTime: entity.averageEscalationTime,
      resolvedEscalations: entity.resolvedEscalations,
    );
  }
}

/// Model para TrendsData
@JsonSerializable(explicitToJson: true)
class TrendsDataModel extends TrendsData {
  const TrendsDataModel({
    required super.complianceTrend,
    required super.violationTrend,
    required super.performanceTrend,
    required super.volumeTrend,
  });

  factory TrendsDataModel.fromJson(Map<String, dynamic> json) {
    return TrendsDataModel(
      complianceTrend: (json['compliance_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      violationTrend: (json['violation_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      performanceTrend: (json['performance_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      volumeTrend: (json['volume_trend'] as List<dynamic>)
          .map((item) => DataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compliance_trend': complianceTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
      'violation_trend': violationTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
      'performance_trend': performanceTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
      'volume_trend': volumeTrend
          .map((item) => (item as DataPointModel).toJson())
          .toList(),
    };
  }

  factory TrendsDataModel.fromEntity(TrendsData entity) {
    return TrendsDataModel(
      complianceTrend: entity.complianceTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
      violationTrend: entity.violationTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
      performanceTrend: entity.performanceTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
      volumeTrend: entity.volumeTrend
          .map((item) => DataPointModel.fromEntity(item))
          .toList(),
    );
  }
}

/// Model para DataPoint
@JsonSerializable(explicitToJson: true)
class DataPointModel extends DataPoint {
  const DataPointModel({
    required super.timestamp,
    required super.value,
    super.metadata,
  });

  factory DataPointModel.fromJson(Map<String, dynamic> json) =>
      _$DataPointModelFromJson(json);

  Map<String, dynamic> toJson() => _$DataPointModelToJson(this);

  factory DataPointModel.fromEntity(DataPoint entity) {
    return DataPointModel(
      timestamp: entity.timestamp,
      value: entity.value,
      metadata: entity.metadata,
    );
  }
}

/// Model para LawyerMetrics
@JsonSerializable(explicitToJson: true)
class LawyerMetricsModel extends LawyerMetrics {
  const LawyerMetricsModel({
    required super.lawyerId,
    required super.lawyerName,
    required super.totalCases,
    required super.complianceRate,
    required super.averageResponseTime,
    required super.violations,
    required super.escalations,
  });

  factory LawyerMetricsModel.fromJson(Map<String, dynamic> json) {
    return LawyerMetricsModel(
      lawyerId: json['lawyer_id'] as String,
      lawyerName: json['lawyer_name'] as String,
      totalCases: json['total_cases'] as int,
      complianceRate: (json['compliance_rate'] as num).toDouble(),
      averageResponseTime: Duration(milliseconds: json['average_response_time_ms'] as int),
      violations: json['violations'] as int,
      escalations: json['escalations'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lawyer_id': lawyerId,
      'lawyer_name': lawyerName,
      'total_cases': totalCases,
      'compliance_rate': complianceRate,
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'violations': violations,
      'escalations': escalations,
    };
  }

  factory LawyerMetricsModel.fromEntity(LawyerMetrics entity) {
    return LawyerMetricsModel(
      lawyerId: entity.lawyerId,
      lawyerName: entity.lawyerName,
      totalCases: entity.totalCases,
      complianceRate: entity.complianceRate,
      averageResponseTime: entity.averageResponseTime,
      violations: entity.violations,
      escalations: entity.escalations,
    );
  }
}

/// Model para ClientMetrics
@JsonSerializable(explicitToJson: true)
class ClientMetricsModel extends ClientMetrics {
  const ClientMetricsModel({
    required super.clientId,
    required super.clientName,
    required super.totalCases,
    required super.complianceRate,
    required super.averageResponseTime,
    required super.violations,
  });

  factory ClientMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$ClientMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClientMetricsModelToJson(this);

  factory ClientMetricsModel.fromEntity(ClientMetrics entity) {
    return ClientMetricsModel(
      clientId: entity.clientId,
      clientName: entity.clientName,
      totalCases: entity.totalCases,
      complianceRate: entity.complianceRate,
      averageResponseTime: entity.averageResponseTime,
      violations: entity.violations,
    );
  }
}

/// Model para CaseTypeMetrics
@JsonSerializable(explicitToJson: true)
class CaseTypeMetricsModel extends CaseTypeMetrics {
  const CaseTypeMetricsModel({
    required super.caseType,
    required super.totalCases,
    required super.complianceRate,
    required super.averageResponseTime,
    required super.violations,
  });

  factory CaseTypeMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$CaseTypeMetricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$CaseTypeMetricsModelToJson(this);

  factory CaseTypeMetricsModel.fromEntity(CaseTypeMetrics entity) {
    return CaseTypeMetricsModel(
      caseType: entity.caseType,
      totalCases: entity.totalCases,
      complianceRate: entity.complianceRate,
      averageResponseTime: entity.averageResponseTime,
      violations: entity.violations,
    );
  }
} 