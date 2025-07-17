import 'dart:convert';
import '../../domain/entities/sla_escalation_entity.dart';

class SlaEscalationModel extends SlaEscalationEntity {
  const SlaEscalationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.firmId,
    required super.triggerType,
    required super.escalationLevels,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.executionStats,
    required super.metadata,
  });

  factory SlaEscalationModel.fromJson(Map<String, dynamic> json) {
    return SlaEscalationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      firmId: json['firm_id'] as String,
      triggerType: json['trigger_type'] as String,
      escalationLevels: (json['escalation_levels'] as List<dynamic>)
          .map((level) => EscalationLevelModel.fromJson(level as Map<String, dynamic>))
          .toList(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
      executionStats: ExecutionStatsModel.fromJson(json['execution_stats'] as Map<String, dynamic>),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  factory SlaEscalationModel.fromEntity(SlaEscalationEntity entity) {
    return SlaEscalationModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      firmId: entity.firmId,
      triggerType: entity.triggerType,
      escalationLevels: entity.escalationLevels,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
      executionStats: entity.executionStats,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'firm_id': firmId,
      'trigger_type': triggerType,
      'escalation_levels': escalationLevels
          .map((level) => EscalationLevelModel.fromEntity(level).toJson())
          .toList(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'execution_stats': ExecutionStatsModel.fromEntity(executionStats).toJson(),
      'metadata': metadata,
    };
  }

  SlaEscalationModel copyWith({
    String? id,
    String? name,
    String? description,
    String? firmId,
    String? triggerType,
    List<dynamic>? escalationLevels,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    dynamic executionStats,
    Map<String, dynamic>? metadata,
  }) {
    return SlaEscalationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      firmId: firmId ?? this.firmId,
      triggerType: triggerType ?? this.triggerType,
      escalationLevels: escalationLevels ?? this.escalationLevels,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      executionStats: executionStats ?? this.executionStats,
      metadata: metadata ?? this.metadata,
    );
  }
}

class EscalationLevelModel {
  final int level;
  final String name;
  final String description;
  final List<EscalationActionModel> actions;
  final Duration delay;
  final Map<String, dynamic> conditions;

  const EscalationLevelModel({
    required this.level,
    required this.name,
    required this.description,
    required this.actions,
    required this.delay,
    required this.conditions,
  });

  factory EscalationLevelModel.fromJson(Map<String, dynamic> json) {
    return EscalationLevelModel(
      level: json['level'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((action) => EscalationActionModel.fromJson(action as Map<String, dynamic>))
          .toList(),
      delay: Duration(minutes: json['delay_minutes'] as int),
      conditions: Map<String, dynamic>.from(json['conditions'] as Map),
    );
  }

  factory EscalationLevelModel.fromEntity(dynamic entity) {
    return EscalationLevelModel(
      level: entity.level,
      name: entity.name,
      description: entity.description,
      actions: entity.actions.map((action) => EscalationActionModel.fromEntity(action)).toList(),
      delay: entity.delay,
      conditions: entity.conditions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'name': name,
      'description': description,
      'actions': actions.map((action) => action.toJson()).toList(),
      'delay_minutes': delay.inMinutes,
      'conditions': conditions,
    };
  }
}

class EscalationActionModel {
  final String type;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final bool isEnabled;

  const EscalationActionModel({
    required this.type,
    required this.name,
    required this.description,
    required this.parameters,
    required this.isEnabled,
  });

  factory EscalationActionModel.fromJson(Map<String, dynamic> json) {
    return EscalationActionModel(
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  factory EscalationActionModel.fromEntity(dynamic entity) {
    return EscalationActionModel(
      type: entity.type,
      name: entity.name,
      description: entity.description,
      parameters: entity.parameters,
      isEnabled: entity.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'description': description,
      'parameters': parameters,
      'is_enabled': isEnabled,
    };
  }
}

class ExecutionStatsModel {
  final int totalExecutions;
  final int successfulExecutions;
  final int failedExecutions;
  final DateTime lastExecution;
  final Duration averageExecutionTime;
  final Map<String, int> executionsByLevel;

  const ExecutionStatsModel({
    required this.totalExecutions,
    required this.successfulExecutions,
    required this.failedExecutions,
    required this.lastExecution,
    required this.averageExecutionTime,
    required this.executionsByLevel,
  });

  factory ExecutionStatsModel.fromJson(Map<String, dynamic> json) {
    return ExecutionStatsModel(
      totalExecutions: json['total_executions'] as int? ?? 0,
      successfulExecutions: json['successful_executions'] as int? ?? 0,
      failedExecutions: json['failed_executions'] as int? ?? 0,
      lastExecution: DateTime.parse(json['last_execution'] as String),
      averageExecutionTime: Duration(milliseconds: json['average_execution_time_ms'] as int? ?? 0),
      executionsByLevel: Map<String, int>.from(json['executions_by_level'] as Map? ?? {}),
    );
  }

  factory ExecutionStatsModel.fromEntity(dynamic entity) {
    return ExecutionStatsModel(
      totalExecutions: entity.totalExecutions,
      successfulExecutions: entity.successfulExecutions,
      failedExecutions: entity.failedExecutions,
      lastExecution: entity.lastExecution,
      averageExecutionTime: entity.averageExecutionTime,
      executionsByLevel: entity.executionsByLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_executions': totalExecutions,
      'successful_executions': successfulExecutions,
      'failed_executions': failedExecutions,
      'last_execution': lastExecution.toIso8601String(),
      'average_execution_time_ms': averageExecutionTime.inMilliseconds,
      'executions_by_level': executionsByLevel,
    };
  }
} 