import '../../domain/entities/sla_audit_entity.dart';

class SlaAuditModel extends SlaAuditEntity {
  const SlaAuditModel({
    required super.id,
    required super.firmId,
    required super.eventType,
    required super.entityId,
    required super.entityType,
    required super.userId,
    required super.timestamp,
    required super.changes,
    required super.metadata,
    required super.ipAddress,
    required super.userAgent,
    required super.sessionId,
    required super.integrityHash,
  });

  factory SlaAuditModel.fromJson(Map<String, dynamic> json) {
    return SlaAuditModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      eventType: _parseEventType(json['event_type'] as String),
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      changes: Map<String, dynamic>.from(json['changes'] as Map),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      sessionId: json['session_id'] as String,
      integrityHash: json['integrity_hash'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'event_type': eventType.toString().split('.').last,
      'entity_id': entityId,
      'entity_type': entityType,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'changes': changes,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'session_id': sessionId,
      'integrity_hash': integrityHash,
    };
  }

  static SlaAuditEventType _parseEventType(String eventType) {
    switch (eventType) {
      case 'settings_created':
        return SlaAuditEventType.settingsCreated;
      case 'settings_updated':
        return SlaAuditEventType.settingsUpdated;
      case 'settings_deleted':
        return SlaAuditEventType.settingsDeleted;
      case 'preset_applied':
        return SlaAuditEventType.presetApplied;
      case 'deadline_calculated':
        return SlaAuditEventType.deadlineCalculated;
      case 'violation_detected':
        return SlaAuditEventType.violationDetected;
      case 'escalation_triggered':
        return SlaAuditEventType.escalationTriggered;
      case 'notification_sent':
        return SlaAuditEventType.notificationSent;
      case 'override_applied':
        return SlaAuditEventType.overrideApplied;
      case 'compliance_check':
        return SlaAuditEventType.complianceCheck;
      case 'security_event':
        return SlaAuditEventType.securityEvent;
      case 'data_export':
        return SlaAuditEventType.dataExport;
      case 'data_import':
        return SlaAuditEventType.dataImport;
      case 'system_error':
        return SlaAuditEventType.systemError;
      case 'user_action':
        return SlaAuditEventType.userAction;
      default:
        throw ArgumentError('Tipo de evento desconhecido: $eventType');
    }
  }

  factory SlaAuditModel.fromEntity(SlaAuditEntity entity) {
    return SlaAuditModel(
      id: entity.id,
      firmId: entity.firmId,
      eventType: entity.eventType,
      entityId: entity.entityId,
      entityType: entity.entityType,
      userId: entity.userId,
      timestamp: entity.timestamp,
      changes: entity.changes,
      metadata: entity.metadata,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      sessionId: entity.sessionId,
      integrityHash: entity.integrityHash,
    );
  }

  SlaAuditEntity toEntity() {
    return SlaAuditEntity(
      id: id,
      firmId: firmId,
      eventType: eventType,
      entityId: entityId,
      entityType: entityType,
      userId: userId,
      timestamp: timestamp,
      changes: changes,
      metadata: metadata,
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
      integrityHash: integrityHash,
    );
  }

  SlaAuditModel copyWith({
    String? id,
    String? firmId,
    SlaAuditEventType? eventType,
    String? entityId,
    String? entityType,
    String? userId,
    DateTime? timestamp,
    Map<String, dynamic>? changes,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    String? integrityHash,
  }) {
    return SlaAuditModel(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      eventType: eventType ?? this.eventType,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      changes: changes ?? this.changes,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      sessionId: sessionId ?? this.sessionId,
      integrityHash: integrityHash ?? this.integrityHash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SlaAuditModel &&
        other.id == id &&
        other.firmId == firmId &&
        other.eventType == eventType &&
        other.entityId == entityId &&
        other.entityType == entityType &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.integrityHash == integrityHash;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      firmId,
      eventType,
      entityId,
      entityType,
      userId,
      timestamp,
      integrityHash,
    );
  }

  @override
  String toString() {
    return 'SlaAuditModel(id: $id, firmId: $firmId, eventType: $eventType, '
        'entityId: $entityId, entityType: $entityType, userId: $userId, '
        'timestamp: $timestamp, integrityHash: $integrityHash)';
  }
} 

class SlaAuditModel extends SlaAuditEntity {
  const SlaAuditModel({
    required super.id,
    required super.firmId,
    required super.eventType,
    required super.entityId,
    required super.entityType,
    required super.userId,
    required super.timestamp,
    required super.changes,
    required super.metadata,
    required super.ipAddress,
    required super.userAgent,
    required super.sessionId,
    required super.integrityHash,
  });

  factory SlaAuditModel.fromJson(Map<String, dynamic> json) {
    return SlaAuditModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      eventType: _parseEventType(json['event_type'] as String),
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      changes: Map<String, dynamic>.from(json['changes'] as Map),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      sessionId: json['session_id'] as String,
      integrityHash: json['integrity_hash'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'event_type': eventType.toString().split('.').last,
      'entity_id': entityId,
      'entity_type': entityType,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'changes': changes,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'session_id': sessionId,
      'integrity_hash': integrityHash,
    };
  }

  static SlaAuditEventType _parseEventType(String eventType) {
    switch (eventType) {
      case 'settings_created':
        return SlaAuditEventType.settingsCreated;
      case 'settings_updated':
        return SlaAuditEventType.settingsUpdated;
      case 'settings_deleted':
        return SlaAuditEventType.settingsDeleted;
      case 'preset_applied':
        return SlaAuditEventType.presetApplied;
      case 'deadline_calculated':
        return SlaAuditEventType.deadlineCalculated;
      case 'violation_detected':
        return SlaAuditEventType.violationDetected;
      case 'escalation_triggered':
        return SlaAuditEventType.escalationTriggered;
      case 'notification_sent':
        return SlaAuditEventType.notificationSent;
      case 'override_applied':
        return SlaAuditEventType.overrideApplied;
      case 'compliance_check':
        return SlaAuditEventType.complianceCheck;
      case 'security_event':
        return SlaAuditEventType.securityEvent;
      case 'data_export':
        return SlaAuditEventType.dataExport;
      case 'data_import':
        return SlaAuditEventType.dataImport;
      case 'system_error':
        return SlaAuditEventType.systemError;
      case 'user_action':
        return SlaAuditEventType.userAction;
      default:
        throw ArgumentError('Tipo de evento desconhecido: $eventType');
    }
  }

  factory SlaAuditModel.fromEntity(SlaAuditEntity entity) {
    return SlaAuditModel(
      id: entity.id,
      firmId: entity.firmId,
      eventType: entity.eventType,
      entityId: entity.entityId,
      entityType: entity.entityType,
      userId: entity.userId,
      timestamp: entity.timestamp,
      changes: entity.changes,
      metadata: entity.metadata,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      sessionId: entity.sessionId,
      integrityHash: entity.integrityHash,
    );
  }

  SlaAuditEntity toEntity() {
    return SlaAuditEntity(
      id: id,
      firmId: firmId,
      eventType: eventType,
      entityId: entityId,
      entityType: entityType,
      userId: userId,
      timestamp: timestamp,
      changes: changes,
      metadata: metadata,
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
      integrityHash: integrityHash,
    );
  }

  SlaAuditModel copyWith({
    String? id,
    String? firmId,
    SlaAuditEventType? eventType,
    String? entityId,
    String? entityType,
    String? userId,
    DateTime? timestamp,
    Map<String, dynamic>? changes,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    String? integrityHash,
  }) {
    return SlaAuditModel(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      eventType: eventType ?? this.eventType,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      changes: changes ?? this.changes,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      sessionId: sessionId ?? this.sessionId,
      integrityHash: integrityHash ?? this.integrityHash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SlaAuditModel &&
        other.id == id &&
        other.firmId == firmId &&
        other.eventType == eventType &&
        other.entityId == entityId &&
        other.entityType == entityType &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.integrityHash == integrityHash;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      firmId,
      eventType,
      entityId,
      entityType,
      userId,
      timestamp,
      integrityHash,
    );
  }

  @override
  String toString() {
    return 'SlaAuditModel(id: $id, firmId: $firmId, eventType: $eventType, '
        'entityId: $entityId, entityType: $entityType, userId: $userId, '
        'timestamp: $timestamp, integrityHash: $integrityHash)';
  }
} 