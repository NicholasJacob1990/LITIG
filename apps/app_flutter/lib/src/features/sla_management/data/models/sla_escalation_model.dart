import '../../domain/entities/sla_escalation_entity.dart';

class SlaEscalationModel extends SlaEscalationEntity {
  const SlaEscalationModel({
    required super.id,
    required super.firmId,
    required super.name,
    required super.description,
    required super.isActive,
    required super.triggers,
    required super.levels,
    required super.createdAt,
    required super.updatedAt,
    super.caseId,
    super.priority,
    super.executedAt,
    super.executedBy,
    super.currentLevel,
    super.status,
    super.logs,
    super.metadata,
  });

  factory SlaEscalationModel.fromJson(Map<String, dynamic> json) {
    return SlaEscalationModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isActive: json['is_active'] as bool? ?? true,
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((t) => EscalationTrigger(
                  id: t['id'] as String,
                  type: _parseEscalationTriggerType(t['type'] as String),
                  condition: t['condition'] as String,
                  value: t['value'],
                  priority: t['priority'] as String?,
                  metadata: t['metadata'] as Map<String, dynamic>?))
              .toList() ?? [],
      levels: (json['levels'] as List<dynamic>?)
              ?.map((l) => EscalationLevel(
                  level: l['level'] as int,
                  name: l['name'] as String,
                  description: l['description'] as String,
                  actions: (l['actions'] as List<dynamic>?)
                      ?.map((a) => EscalationAction(
                          type: _parseEscalationActionType(a['type'] as String),
                          description: a['description'] as String,
                          parameters: a['parameters'] as Map<String, dynamic>,
                          isRequired: a['isRequired'] as bool?,
                          metadata: a['metadata'] as Map<String, dynamic>?))
                      .toList() ?? [],
                  recipients: (l['recipients'] as List<dynamic>?)
                      ?.map((r) => EscalationRecipient(
                          type: _parseEscalationRecipientType(r['type'] as String),
                          identifier: r['identifier'] as String,
                          name: r['name'] as String?,
                          role: r['role'] as String?,
                          metadata: r['metadata'] as Map<String, dynamic>?))
                      .toList() ?? [],
                  delayMinutes: l['delayMinutes'] as int?,
                  conditions: l['conditions'] as Map<String, dynamic>?,
                  metadata: l['metadata'] as Map<String, dynamic>?))
              .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      caseId: json['case_id'] as String?,
      priority: json['priority'] as String?,
      executedAt: json['executed_at'] != null ? DateTime.parse(json['executed_at'] as String) : null,
      executedBy: json['executed_by'] as String?,
      currentLevel: json['current_level'] as int?,
      status: json['status'] != null ? _parseEscalationStatus(json['status'] as String) : null,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((log) => EscalationLog(
                  id: log['id'] as String,
                  level: log['level'] as int,
                  action: log['action'] as String,
                  executedAt: DateTime.parse(log['executedAt'] as String),
                  status: log['status'] as String,
                  executedBy: log['executedBy'] as String?,
                  result: log['result'] as Map<String, dynamic>?,
                  error: log['error'] as String?,
                  metadata: log['metadata'] as Map<String, dynamic>?))
              .toList(),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  factory SlaEscalationModel.fromEntity(SlaEscalationEntity entity) {
    return SlaEscalationModel(
      id: entity.id,
      firmId: entity.firmId,
      name: entity.name,
      description: entity.description,
      isActive: entity.isActive,
      triggers: entity.triggers,
      levels: entity.levels,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      caseId: entity.caseId,
      priority: entity.priority,
      executedAt: entity.executedAt,
      executedBy: entity.executedBy,
      currentLevel: entity.currentLevel,
      status: entity.status,
      logs: entity.logs,
      metadata: entity.metadata,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'triggers': triggers.map((t) => t.toJson()).toList(),
      'levels': levels.map((l) => l.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (caseId != null) 'case_id': caseId,
      if (priority != null) 'priority': priority,
      if (executedAt != null) 'executed_at': executedAt!.toIso8601String(),
      if (executedBy != null) 'executed_by': executedBy,
      if (currentLevel != null) 'current_level': currentLevel,
      if (status != null) 'status': status!.name,
      if (logs != null) 'logs': logs!.map((l) => l.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  SlaEscalationModel copyWith({
    String? id,
    String? firmId,
    String? name,
    String? description,
    bool? isActive,
    List<EscalationTrigger>? triggers,
    List<EscalationLevel>? levels,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? caseId,
    String? priority,
    DateTime? executedAt,
    String? executedBy,
    int? currentLevel,
    EscalationStatus? status,
    List<EscalationLog>? logs,
    Map<String, dynamic>? metadata,
  }) {
    return SlaEscalationModel(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      triggers: triggers ?? this.triggers,
      levels: levels ?? this.levels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      caseId: caseId ?? this.caseId,
      priority: priority ?? this.priority,
      executedAt: executedAt ?? this.executedAt,
      executedBy: executedBy ?? this.executedBy,
      currentLevel: currentLevel ?? this.currentLevel,
      status: status ?? this.status,
      logs: logs ?? this.logs,
      metadata: metadata ?? this.metadata,
    );
  }

  static EscalationTriggerType _parseEscalationTriggerType(String type) {
    switch (type.toLowerCase()) {
      case 'timedelay':
      case 'time_delay':
        return EscalationTriggerType.timeDelay;
      case 'prioritybased':
      case 'priority_based':
        return EscalationTriggerType.priorityBased;
      case 'combined':
        return EscalationTriggerType.combined;
      case 'manual':
        return EscalationTriggerType.manual;
      default:
        return EscalationTriggerType.manual;
    }
  }

  static EscalationActionType _parseEscalationActionType(String type) {
    switch (type.toLowerCase()) {
      case 'notify':
        return EscalationActionType.notify;
      case 'reassign':
        return EscalationActionType.reassign;
      case 'createtask':
      case 'create_task':
        return EscalationActionType.createTask;
      case 'sendemail':
      case 'send_email':
        return EscalationActionType.sendEmail;
      case 'sendsms':
      case 'send_sms':
        return EscalationActionType.sendSms;
      case 'webhook':
        return EscalationActionType.webhook;
      case 'custom':
        return EscalationActionType.custom;
      default:
        return EscalationActionType.custom;
    }
  }

  static EscalationRecipientType _parseEscalationRecipientType(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return EscalationRecipientType.user;
      case 'role':
        return EscalationRecipientType.role;
      case 'email':
        return EscalationRecipientType.email;
      case 'group':
        return EscalationRecipientType.group;
      case 'webhook':
        return EscalationRecipientType.webhook;
      default:
        return EscalationRecipientType.user;
    }
  }

  static EscalationStatus _parseEscalationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return EscalationStatus.pending;
      case 'active':
        return EscalationStatus.active;
      case 'paused':
        return EscalationStatus.paused;
      case 'completed':
        return EscalationStatus.completed;
      case 'cancelled':
        return EscalationStatus.cancelled;
      case 'error':
        return EscalationStatus.error;
      default:
        return EscalationStatus.pending;
    }
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