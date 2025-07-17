import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sla_violation_entity.dart';

part 'sla_violation_model.g.dart';

/// Model que implementa serialização JSON para SlaViolationEntity
/// 
/// Responsável pela conversão entre JSON e entidade de domínio,
/// incluindo conversão de enums e tipos complexos
@JsonSerializable(explicitToJson: true)
class SlaViolationModel extends SlaViolationEntity {
  const SlaViolationModel({
    required super.id,
    required super.caseId,
    required super.firmId,
    required super.lawyerId,
    required super.originalDeadline,
    required super.actualCompletionTime,
    required super.violationType,
    required super.priority,
    required super.delayDuration,
    required super.violationReason,
    required super.impact,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.clientId,
    super.resolvedAt,
    super.resolvedBy,
    super.escalationLevel,
    super.actionsInfo,
    super.clientNotified,
    super.clientNotificationTime,
    super.compensationOffered,
    super.compensationDetails,
    super.preventionMeasures,
    super.rootCauseAnalysis,
    super.metadata,
  });

  /// Cria um SlaViolationModel a partir de JSON
  factory SlaViolationModel.fromJson(Map<String, dynamic> json) {
    return SlaViolationModel(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      firmId: json['firm_id'] as String,
      lawyerId: json['lawyer_id'] as String,
      originalDeadline: DateTime.parse(json['original_deadline'] as String),
      actualCompletionTime: json['actual_completion_time'] != null 
          ? DateTime.parse(json['actual_completion_time'] as String)
          : null,
      violationType: SlaViolationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['violation_type'],
      ),
      priority: json['priority'] as String,
      delayDuration: Duration(milliseconds: json['delay_duration_ms'] as int),
      violationReason: json['violation_reason'] as String,
      impact: SlaViolationImpact.values.firstWhere(
        (e) => e.toString().split('.').last == json['impact'],
      ),
      status: SlaViolationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clientId: json['client_id'] as String?,
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      escalationLevel: json['escalation_level'] as int?,
      actionsInfo: json['actions_info'] != null
          ? (json['actions_info'] as List<dynamic>)
              .map((action) => SlaViolationActionModel.fromJson(action))
              .toList()
          : null,
      clientNotified: json['client_notified'] as bool?,
      clientNotificationTime: json['client_notification_time'] != null
          ? DateTime.parse(json['client_notification_time'] as String)
          : null,
      compensationOffered: json['compensation_offered'] as bool?,
      compensationDetails: json['compensation_details'] as Map<String, dynamic>?,
      preventionMeasures: json['prevention_measures'] != null
          ? (json['prevention_measures'] as List<dynamic>).cast<String>()
          : null,
      rootCauseAnalysis: json['root_cause_analysis'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte o SlaViolationModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'firm_id': firmId,
      'lawyer_id': lawyerId,
      'original_deadline': originalDeadline.toIso8601String(),
      'actual_completion_time': actualCompletionTime?.toIso8601String(),
      'violation_type': violationType.toString().split('.').last,
      'priority': priority,
      'delay_duration_ms': delayDuration.inMilliseconds,
      'violation_reason': violationReason,
      'impact': impact.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'client_id': clientId,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'escalation_level': escalationLevel,
      'actions_info': actionsInfo?.map((action) => (action as SlaViolationActionModel).toJson()).toList(),
      'client_notified': clientNotified,
      'client_notification_time': clientNotificationTime?.toIso8601String(),
      'compensation_offered': compensationOffered,
      'compensation_details': compensationDetails,
      'prevention_measures': preventionMeasures,
      'root_cause_analysis': rootCauseAnalysis,
      'metadata': metadata,
    };
  }

  /// Converte uma entidade de domínio para model
  factory SlaViolationModel.fromEntity(SlaViolationEntity entity) {
    return SlaViolationModel(
      id: entity.id,
      caseId: entity.caseId,
      firmId: entity.firmId,
      lawyerId: entity.lawyerId,
      originalDeadline: entity.originalDeadline,
      actualCompletionTime: entity.actualCompletionTime,
      violationType: entity.violationType,
      priority: entity.priority,
      delayDuration: entity.delayDuration,
      violationReason: entity.violationReason,
      impact: entity.impact,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      clientId: entity.clientId,
      resolvedAt: entity.resolvedAt,
      resolvedBy: entity.resolvedBy,
      escalationLevel: entity.escalationLevel,
      actionsInfo: entity.actionsInfo?.map((action) => 
          SlaViolationActionModel.fromEntity(action)).toList(),
      clientNotified: entity.clientNotified,
      clientNotificationTime: entity.clientNotificationTime,
      compensationOffered: entity.compensationOffered,
      compensationDetails: entity.compensationDetails,
      preventionMeasures: entity.preventionMeasures,
      rootCauseAnalysis: entity.rootCauseAnalysis,
      metadata: entity.metadata,
    );
  }

  /// Converte o model para entidade de domínio
  SlaViolationEntity toEntity() {
    return SlaViolationEntity(
      id: id,
      caseId: caseId,
      firmId: firmId,
      lawyerId: lawyerId,
      originalDeadline: originalDeadline,
      actualCompletionTime: actualCompletionTime,
      violationType: violationType,
      priority: priority,
      delayDuration: delayDuration,
      violationReason: violationReason,
      impact: impact,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      clientId: clientId,
      resolvedAt: resolvedAt,
      resolvedBy: resolvedBy,
      escalationLevel: escalationLevel,
      actionsInfo: actionsInfo,
      clientNotified: clientNotified,
      clientNotificationTime: clientNotificationTime,
      compensationOffered: compensationOffered,
      compensationDetails: compensationDetails,
      preventionMeasures: preventionMeasures,
      rootCauseAnalysis: rootCauseAnalysis,
      metadata: metadata,
    );
  }
}

/// Model para SlaViolationAction
@JsonSerializable(explicitToJson: true)
class SlaViolationActionModel extends SlaViolationAction {
  const SlaViolationActionModel({
    required super.id,
    required super.actionType,
    required super.description,
    required super.takenBy,
    required super.takenAt,
    super.result,
    super.metadata,
  });

  /// Cria um SlaViolationActionModel a partir de JSON
  factory SlaViolationActionModel.fromJson(Map<String, dynamic> json) {
    return SlaViolationActionModel(
      id: json['id'] as String,
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      takenBy: json['taken_by'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      result: json['result'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte o SlaViolationActionModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'description': description,
      'taken_by': takenBy,
      'taken_at': takenAt.toIso8601String(),
      'result': result,
      'metadata': metadata,
    };
  }

  /// Converte uma entidade de domínio para model
  factory SlaViolationActionModel.fromEntity(SlaViolationAction entity) {
    return SlaViolationActionModel(
      id: entity.id,
      actionType: entity.actionType,
      description: entity.description,
      takenBy: entity.takenBy,
      takenAt: entity.takenAt,
      result: entity.result,
      metadata: entity.metadata,
    );
  }

  /// Converte o model para entidade de domínio
  SlaViolationAction toEntity() {
    return SlaViolationAction(
      id: id,
      actionType: actionType,
      description: description,
      takenBy: takenBy,
      takenAt: takenAt,
      result: result,
      metadata: metadata,
    );
  }
} 

part 'sla_violation_model.g.dart';

/// Model que implementa serialização JSON para SlaViolationEntity
/// 
/// Responsável pela conversão entre JSON e entidade de domínio,
/// incluindo conversão de enums e tipos complexos
@JsonSerializable(explicitToJson: true)
class SlaViolationModel extends SlaViolationEntity {
  const SlaViolationModel({
    required super.id,
    required super.caseId,
    required super.firmId,
    required super.lawyerId,
    required super.originalDeadline,
    required super.actualCompletionTime,
    required super.violationType,
    required super.priority,
    required super.delayDuration,
    required super.violationReason,
    required super.impact,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.clientId,
    super.resolvedAt,
    super.resolvedBy,
    super.escalationLevel,
    super.actionsInfo,
    super.clientNotified,
    super.clientNotificationTime,
    super.compensationOffered,
    super.compensationDetails,
    super.preventionMeasures,
    super.rootCauseAnalysis,
    super.metadata,
  });

  /// Cria um SlaViolationModel a partir de JSON
  factory SlaViolationModel.fromJson(Map<String, dynamic> json) {
    return SlaViolationModel(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      firmId: json['firm_id'] as String,
      lawyerId: json['lawyer_id'] as String,
      originalDeadline: DateTime.parse(json['original_deadline'] as String),
      actualCompletionTime: json['actual_completion_time'] != null 
          ? DateTime.parse(json['actual_completion_time'] as String)
          : null,
      violationType: SlaViolationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['violation_type'],
      ),
      priority: json['priority'] as String,
      delayDuration: Duration(milliseconds: json['delay_duration_ms'] as int),
      violationReason: json['violation_reason'] as String,
      impact: SlaViolationImpact.values.firstWhere(
        (e) => e.toString().split('.').last == json['impact'],
      ),
      status: SlaViolationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clientId: json['client_id'] as String?,
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      escalationLevel: json['escalation_level'] as int?,
      actionsInfo: json['actions_info'] != null
          ? (json['actions_info'] as List<dynamic>)
              .map((action) => SlaViolationActionModel.fromJson(action))
              .toList()
          : null,
      clientNotified: json['client_notified'] as bool?,
      clientNotificationTime: json['client_notification_time'] != null
          ? DateTime.parse(json['client_notification_time'] as String)
          : null,
      compensationOffered: json['compensation_offered'] as bool?,
      compensationDetails: json['compensation_details'] as Map<String, dynamic>?,
      preventionMeasures: json['prevention_measures'] != null
          ? (json['prevention_measures'] as List<dynamic>).cast<String>()
          : null,
      rootCauseAnalysis: json['root_cause_analysis'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte o SlaViolationModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'firm_id': firmId,
      'lawyer_id': lawyerId,
      'original_deadline': originalDeadline.toIso8601String(),
      'actual_completion_time': actualCompletionTime?.toIso8601String(),
      'violation_type': violationType.toString().split('.').last,
      'priority': priority,
      'delay_duration_ms': delayDuration.inMilliseconds,
      'violation_reason': violationReason,
      'impact': impact.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'client_id': clientId,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'escalation_level': escalationLevel,
      'actions_info': actionsInfo?.map((action) => (action as SlaViolationActionModel).toJson()).toList(),
      'client_notified': clientNotified,
      'client_notification_time': clientNotificationTime?.toIso8601String(),
      'compensation_offered': compensationOffered,
      'compensation_details': compensationDetails,
      'prevention_measures': preventionMeasures,
      'root_cause_analysis': rootCauseAnalysis,
      'metadata': metadata,
    };
  }

  /// Converte uma entidade de domínio para model
  factory SlaViolationModel.fromEntity(SlaViolationEntity entity) {
    return SlaViolationModel(
      id: entity.id,
      caseId: entity.caseId,
      firmId: entity.firmId,
      lawyerId: entity.lawyerId,
      originalDeadline: entity.originalDeadline,
      actualCompletionTime: entity.actualCompletionTime,
      violationType: entity.violationType,
      priority: entity.priority,
      delayDuration: entity.delayDuration,
      violationReason: entity.violationReason,
      impact: entity.impact,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      clientId: entity.clientId,
      resolvedAt: entity.resolvedAt,
      resolvedBy: entity.resolvedBy,
      escalationLevel: entity.escalationLevel,
      actionsInfo: entity.actionsInfo?.map((action) => 
          SlaViolationActionModel.fromEntity(action)).toList(),
      clientNotified: entity.clientNotified,
      clientNotificationTime: entity.clientNotificationTime,
      compensationOffered: entity.compensationOffered,
      compensationDetails: entity.compensationDetails,
      preventionMeasures: entity.preventionMeasures,
      rootCauseAnalysis: entity.rootCauseAnalysis,
      metadata: entity.metadata,
    );
  }

  /// Converte o model para entidade de domínio
  SlaViolationEntity toEntity() {
    return SlaViolationEntity(
      id: id,
      caseId: caseId,
      firmId: firmId,
      lawyerId: lawyerId,
      originalDeadline: originalDeadline,
      actualCompletionTime: actualCompletionTime,
      violationType: violationType,
      priority: priority,
      delayDuration: delayDuration,
      violationReason: violationReason,
      impact: impact,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      clientId: clientId,
      resolvedAt: resolvedAt,
      resolvedBy: resolvedBy,
      escalationLevel: escalationLevel,
      actionsInfo: actionsInfo,
      clientNotified: clientNotified,
      clientNotificationTime: clientNotificationTime,
      compensationOffered: compensationOffered,
      compensationDetails: compensationDetails,
      preventionMeasures: preventionMeasures,
      rootCauseAnalysis: rootCauseAnalysis,
      metadata: metadata,
    );
  }
}

/// Model para SlaViolationAction
@JsonSerializable(explicitToJson: true)
class SlaViolationActionModel extends SlaViolationAction {
  const SlaViolationActionModel({
    required super.id,
    required super.actionType,
    required super.description,
    required super.takenBy,
    required super.takenAt,
    super.result,
    super.metadata,
  });

  /// Cria um SlaViolationActionModel a partir de JSON
  factory SlaViolationActionModel.fromJson(Map<String, dynamic> json) {
    return SlaViolationActionModel(
      id: json['id'] as String,
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      takenBy: json['taken_by'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      result: json['result'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte o SlaViolationActionModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'description': description,
      'taken_by': takenBy,
      'taken_at': takenAt.toIso8601String(),
      'result': result,
      'metadata': metadata,
    };
  }

  /// Converte uma entidade de domínio para model
  factory SlaViolationActionModel.fromEntity(SlaViolationAction entity) {
    return SlaViolationActionModel(
      id: entity.id,
      actionType: entity.actionType,
      description: entity.description,
      takenBy: entity.takenBy,
      takenAt: entity.takenAt,
      result: entity.result,
      metadata: entity.metadata,
    );
  }

  /// Converte o model para entidade de domínio
  SlaViolationAction toEntity() {
    return SlaViolationAction(
      id: id,
      actionType: actionType,
      description: description,
      takenBy: takenBy,
      takenAt: takenAt,
      result: result,
      metadata: metadata,
    );
  }
} 