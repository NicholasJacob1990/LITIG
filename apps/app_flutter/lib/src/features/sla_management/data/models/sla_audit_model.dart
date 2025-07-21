import '../../domain/entities/sla_audit_entity.dart';
import '../../domain/entities/sla_enums.dart';

/// Modelo de dados para auditoria SLA
/// 
/// Implementa a conversão entre JSON da API e a entidade de domínio,
/// seguindo os princípios de Clean Architecture para o melhor sistema SLA.
class SlaAuditModel extends SlaAuditEntity {
  const SlaAuditModel({
    required super.id,
    required super.firmId,
    required super.eventType,
    required super.eventCategory,
    required super.action,
    required super.description,
    required super.timestamp,
    required super.userId,
    required super.userRole,
    required super.ipAddress,
    required super.userAgent,
    super.entityType,
    super.entityId,
    super.oldValues,
    super.newValues,
    super.affectedEntities,
    super.severity,
    super.complianceStatus,
    super.riskLevel,
    super.context,
    super.metadata,
    super.tags,
  });

  /// Cria instância a partir de JSON da API
  factory SlaAuditModel.fromJson(Map<String, dynamic> json) {
    return SlaAuditModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      eventType: _parseEventType(json['event_type'] as String),
      eventCategory: _parseEventCategory(json['event_category'] as String),
      action: json['action'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String,
      userRole: json['user_role'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      affectedEntities: (json['affected_entities'] as List<dynamic>?)
          ?.map((e) => AffectedEntity(
              entityType: e['entity_type'] as String,
              entityId: e['entity_id'] as String,
              changeType: ChangeTypeExtension.fromString(e['change_type'] as String),
              entityName: e['entity_name'] as String?,
              relationshipType: e['relationship_type'] as String?,
              metadata: e['metadata'] as Map<String, dynamic>?))
          .toList(),
      severity: _parseAuditSeverity(json['severity'] as String?),
      complianceStatus: _parseComplianceStatus(json['compliance_status'] as String?),
      riskLevel: _parseRiskLevel(json['risk_level'] as String?),
      context: json['context'] != null 
          ? AuditContext(
              sessionId: json['context']['session_id'] as String,
              deviceInfo: json['context']['device_info'] as Map<String, dynamic>,
              location: json['context']['location'] as String?,
              referrer: json['context']['referrer'] as String?,
              requestId: json['context']['request_id'] as String?,
              correlationId: json['context']['correlation_id'] as String?,
              businessContext: json['context']['business_context'] as Map<String, dynamic>?,
              additionalData: json['context']['additional_data'] as Map<String, dynamic>?)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Converte para JSON para envio à API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'event_type': eventType.toString().split('.').last,
      'event_category': eventCategory.toString().split('.').last,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_role': userRole,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (oldValues != null) 'old_values': oldValues,
      if (newValues != null) 'new_values': newValues,
      if (affectedEntities != null) 'affected_entities': affectedEntities?.map((e) => {
        'entity_type': e.entityType,
        'entity_id': e.entityId,
        'change_type': e.changeType.toStringValue(),
        if (e.entityName != null) 'entity_name': e.entityName,
        if (e.relationshipType != null) 'relationship_type': e.relationshipType,
        if (e.metadata != null) 'metadata': e.metadata,
      }).toList(),
      if (severity != null) 'severity': severity!.toStringValue(),
      if (complianceStatus != null) 'compliance_status': complianceStatus!.toStringValue(),
      if (riskLevel != null) 'risk_level': riskLevel!.toStringValue(),
      if (context != null) 'context': {
        'session_id': context!.sessionId,
        'device_info': context!.deviceInfo,
        if (context!.location != null) 'location': context!.location,
        if (context!.referrer != null) 'referrer': context!.referrer,
        if (context!.requestId != null) 'request_id': context!.requestId,
        if (context!.correlationId != null) 'correlation_id': context!.correlationId,
        if (context!.businessContext != null) 'business_context': context!.businessContext,
        if (context!.additionalData != null) 'additional_data': context!.additionalData,
      },
      if (metadata != null) 'metadata': metadata,
      if (tags != null) 'tags': tags,
    };
  }

  /// Parse do tipo de evento a partir de string
  static AuditEventType _parseEventType(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'create':
        return AuditEventType.create;
      case 'read':
        return AuditEventType.read;
      case 'update':
        return AuditEventType.update;
      case 'delete':
        return AuditEventType.delete;
      case 'export':
        return AuditEventType.export;
      case 'import':
        return AuditEventType.import;
      case 'login':
        return AuditEventType.login;
      case 'logout':
        return AuditEventType.logout;
      case 'access_denied':
        return AuditEventType.accessDenied;
      case 'config_change':
        return AuditEventType.configChange;
      case 'compliance_check':
        return AuditEventType.complianceCheck;
      case 'sla_violation':
        return AuditEventType.slaViolation;
      case 'escalation':
        return AuditEventType.escalation;
      case 'system_error':
        return AuditEventType.systemError;
      default:
        return AuditEventType.other;
    }
  }

  /// Parse da categoria de evento a partir de string
  static AuditEventCategory _parseEventCategory(String category) {
    switch (category.toLowerCase()) {
      case 'authentication':
        return AuditEventCategory.authentication;
      case 'authorization':
        return AuditEventCategory.authorization;
      case 'data_access':
        return AuditEventCategory.dataAccess;
      case 'data_modification':
        return AuditEventCategory.dataModification;
      case 'system_configuration':
        return AuditEventCategory.systemConfiguration;
      case 'sla_management':
        return AuditEventCategory.slaManagement;
      case 'compliance':
        return AuditEventCategory.compliance;
      case 'security':
        return AuditEventCategory.security;
      case 'performance':
        return AuditEventCategory.performance;
      case 'error_handling':
        return AuditEventCategory.errorHandling;
      default:
        return AuditEventCategory.other;
    }
  }

  /// Cria entrada de auditoria para violação SLA
  factory SlaAuditModel.slaViolation({
    required String firmId,
    required String entityId,
    required String userId,
    required String userRole,
    required String ipAddress,
    required String userAgent,
    required String description,
    Map<String, dynamic>? metadata,
    AuditSeverity? severity,
  }) {
    return SlaAuditModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firmId: firmId,
      eventType: AuditEventType.slaViolation,
      eventCategory: AuditEventCategory.slaManagement,
      action: 'SLA_VIOLATION_DETECTED',
      description: description,
      timestamp: DateTime.now(),
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      entityType: 'case',
      entityId: entityId,
      severity: severity ?? AuditSeverity.high,
      complianceStatus: ComplianceStatus.violation,
      riskLevel: RiskLevel.high,
      metadata: metadata,
      tags: const ['sla', 'violation', 'compliance'],
    );
  }

  /// Cria entrada de auditoria para escalação
  factory SlaAuditModel.escalation({
    required String firmId,
    required String entityId,
    required String userId,
    required String userRole,
    required String ipAddress,
    required String userAgent,
    required String description,
    required String escalationLevel,
    Map<String, dynamic>? metadata,
  }) {
    return SlaAuditModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firmId: firmId,
      eventType: AuditEventType.escalation,
      eventCategory: AuditEventCategory.slaManagement,
      action: 'SLA_ESCALATION_TRIGGERED',
      description: description,
      timestamp: DateTime.now(),
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      entityType: 'case',
      entityId: entityId,
      severity: AuditSeverity.warning,
      complianceStatus: ComplianceStatus.compliant,
      riskLevel: RiskLevel.medium,
      metadata: {
        'escalation_level': escalationLevel,
        ...?metadata,
      },
      tags: const ['sla', 'escalation', 'management'],
    );
  }

  /// Parse da severidade de auditoria
  static AuditSeverity? _parseAuditSeverity(String? severity) {
    if (severity == null) return null;
    return AuditSeverityExtension.fromString(severity);
  }

  /// Parse do status de compliance
  static ComplianceStatus? _parseComplianceStatus(String? status) {
    if (status == null) return null;
    return ComplianceStatusExtension.fromString(status);
  }

  /// Parse do nível de risco
  static RiskLevel? _parseRiskLevel(String? level) {
    if (level == null) return null;
    return RiskLevelExtension.fromString(level);
  }

  @override
  String toString() {
    return 'SlaAuditModel(id: $id, firmId: $firmId, eventType: $eventType, '
        'action: $action, timestamp: $timestamp, userId: $userId)';
  }
}