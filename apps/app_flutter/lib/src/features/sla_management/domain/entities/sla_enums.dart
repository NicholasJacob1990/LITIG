/// Enumerações para o sistema SLA
/// 
/// Define todos os tipos e estados usados no sistema de auditoria e gerenciamento SLA

/// Tipos de eventos de auditoria
enum AuditEventType {
  create,
  read,
  update,
  delete,
  export,
  import,
  login,
  logout,
  accessDenied,
  configChange,
  configurationChange,
  complianceCheck,
  slaViolation,
  escalation,
  escalationExecuted,
  systemError,
  userAction,
  systemEvent,
  reportGenerated,
  thresholdReached,
  recoveryCompleted,
  securityBreach,
  dataExport,
  other
}

/// Categorias de eventos de auditoria
enum AuditEventCategory {
  authentication,
  authorization,
  dataAccess,
  dataModification,
  systemConfiguration,
  slaManagement,
  configuration,
  business,
  security,
  system,
  compliance,
  performance,
  maintenance,
  errorHandling,
  other
}

/// Severidade do evento de auditoria
enum AuditSeverity {
  info,
  warning,
  error,
  critical,
  high
}

/// Status de compliance
enum ComplianceStatus {
  compliant,
  violation,
  pending,
  unknown
}

/// Nível de risco
enum RiskLevel {
  low,
  medium,
  high,
  critical
}

/// Tipo de mudança
enum ChangeType {
  created,
  updated,
  deleted,
  moved,
  archived,
  added,
  modified
}

/// Entidade afetada em um evento de auditoria
class AffectedEntity {
  final String entityType;
  final String entityId;
  final ChangeType changeType;
  final String? entityName;
  final String? relationshipType;
  final Map<String, dynamic>? metadata;

  const AffectedEntity({
    required this.entityType,
    required this.entityId,
    required this.changeType,
    this.entityName,
    this.relationshipType,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'change_type': changeType.toStringValue(),
      if (entityName != null) 'entity_name': entityName,
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AffectedEntity.fromJson(Map<String, dynamic> json) {
    return AffectedEntity(
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      changeType: ChangeTypeExtension.fromString(json['change_type'] as String),
      entityName: json['entity_name'] as String?,
      relationshipType: json['relationship_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Registro de mudança
class ChangeRecord {
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final ChangeType changeType;

  const ChangeRecord({
    required this.field,
    this.oldValue,
    this.newValue,
    required this.changeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'old_value': oldValue,
      'new_value': newValue,
      'change_type': changeType.name,
    };
  }

  factory ChangeRecord.fromJson(Map<String, dynamic> json) {
    return ChangeRecord(
      field: json['field'] as String,
      oldValue: json['old_value'],
      newValue: json['new_value'],
      changeType: ChangeType.values.firstWhere(
        (e) => e.name == json['change_type'],
        orElse: () => ChangeType.updated,
      ),
    );
  }
}

/// Extensões para conversão de strings para enums
extension AuditSeverityExtension on AuditSeverity {
  static AuditSeverity? fromString(String? value) {
    if (value == null) return null;
    return AuditSeverity.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AuditSeverity.info,
    );
  }
}

extension ComplianceStatusExtension on ComplianceStatus {
  static ComplianceStatus? fromString(String? value) {
    if (value == null) return null;
    return ComplianceStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ComplianceStatus.unknown,
    );
  }
}

extension RiskLevelExtension on RiskLevel {
  static RiskLevel? fromString(String? value) {
    if (value == null) return null;
    return RiskLevel.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RiskLevel.low,
    );
  }
}

extension AuditEventTypeExtension on AuditEventType {
  static AuditEventType fromString(String value) {
    return AuditEventType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AuditEventType.systemEvent,
    );
  }
}

extension AuditEventCategoryExtension on AuditEventCategory {
  static AuditEventCategory fromString(String value) {
    return AuditEventCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AuditEventCategory.system,
    );
  }
}

extension ChangeTypeExtension on ChangeType {
  static ChangeType fromString(String value) {
    return ChangeType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChangeType.updated,
    );
  }
  
  String toStringValue() {
    return name;
  }
}

extension AuditSeverityStringExtension on AuditSeverity {
  String toStringValue() {
    return name;
  }
}

extension ComplianceStatusStringExtension on ComplianceStatus {
  String toStringValue() {
    return name;
  }
}

extension RiskLevelStringExtension on RiskLevel {
  String toStringValue() {
    return name;
  }
}

/// Contexto de auditoria
class AuditContext {
  final String sessionId;
  final Map<String, dynamic> deviceInfo;
  final String? location;
  final String? referrer;
  final String? requestId;
  final String? correlationId;
  final Map<String, dynamic>? businessContext;
  final Map<String, dynamic>? additionalData;

  const AuditContext({
    required this.sessionId,
    required this.deviceInfo,
    this.location,
    this.referrer,
    this.requestId,
    this.correlationId,
    this.businessContext,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'device_info': deviceInfo,
      if (location != null) 'location': location,
      if (referrer != null) 'referrer': referrer,
      if (requestId != null) 'request_id': requestId,
      if (correlationId != null) 'correlation_id': correlationId,
      if (businessContext != null) 'business_context': businessContext,
      if (additionalData != null) 'additional_data': additionalData,
    };
  }

  factory AuditContext.fromJson(Map<String, dynamic> json) {
    return AuditContext(
      sessionId: json['session_id'] as String,
      deviceInfo: json['device_info'] as Map<String, dynamic>,
      location: json['location'] as String?,
      referrer: json['referrer'] as String?,
      requestId: json['request_id'] as String?,
      correlationId: json['correlation_id'] as String?,
      businessContext: json['business_context'] as Map<String, dynamic>?,
      additionalData: json['additional_data'] as Map<String, dynamic>?,
    );
  }
}