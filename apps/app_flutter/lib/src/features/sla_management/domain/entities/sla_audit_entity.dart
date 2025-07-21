import 'package:equatable/equatable.dart';
import 'sla_enums.dart';

/// Entidade que representa um evento de auditoria SLA
/// 
/// Registra todas as ações relacionadas ao sistema SLA
/// para compliance, rastreabilidade e análise
class SlaAuditEntity extends Equatable {
  const SlaAuditEntity({
    required this.id,
    required this.firmId,
    required this.eventType,
    required this.eventCategory,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.userId,
    required this.userRole,
    required this.ipAddress,
    required this.userAgent,
    this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.affectedEntities,
    this.severity,
    this.complianceStatus,
    this.riskLevel,
    this.context,
    this.metadata,
    this.tags,
  });

  /// ID único do evento de auditoria
  final String id;

  /// ID da firma
  final String firmId;

  /// Tipo do evento
  final AuditEventType eventType;

  /// Categoria do evento
  final AuditEventCategory eventCategory;

  /// Ação executada
  final String action;

  /// Descrição detalhada do evento
  final String description;

  /// Timestamp do evento
  final DateTime timestamp;

  /// ID do usuário que executou a ação
  final String userId;

  /// Papel/função do usuário
  final String userRole;

  /// Endereço IP de origem
  final String ipAddress;

  /// User agent (navegador/app)
  final String userAgent;

  /// Tipo da entidade afetada
  final String? entityType;

  /// ID da entidade afetada
  final String? entityId;

  /// Valores anteriores (para updates)
  final Map<String, dynamic>? oldValues;

  /// Novos valores (para updates)
  final Map<String, dynamic>? newValues;

  /// Entidades relacionadas afetadas
  final List<AffectedEntity>? affectedEntities;

  /// Severidade do evento
  final AuditSeverity? severity;

  /// Status de compliance do evento
  final ComplianceStatus? complianceStatus;

  /// Nível de risco
  final RiskLevel? riskLevel;

  /// Contexto adicional da ação
  final AuditContext? context;

  /// Metadados específicos do evento
  final Map<String, dynamic>? metadata;

  /// Tags para categorização
  final List<String>? tags;

  /// Calcula o tempo desde o evento
  Duration get timeSinceEvent {
    return DateTime.now().difference(timestamp);
  }

  /// Verifica se o evento é recente (menos de 24h)
  bool get isRecent {
    return timeSinceEvent.inHours < 24;
  }

  /// Verifica se o evento é crítico
  bool get isCritical {
    return severity == AuditSeverity.critical ||
           riskLevel == RiskLevel.high ||
           complianceStatus == ComplianceStatus.violation;
  }

  /// Obtém resumo das mudanças
  List<ChangeRecord> get changes {
    if (oldValues == null || newValues == null) return [];

    List<ChangeRecord> changes = [];
    
    // Compara valores antigos e novos
    for (final key in newValues!.keys) {
      final oldValue = oldValues![key];
      final newValue = newValues![key];
      
      if (oldValue != newValue) {
        changes.add(ChangeRecord(
          field: key,
          oldValue: oldValue,
          newValue: newValue,
          changeType: _determineChangeType(oldValue, newValue),
        ));
      }
    }

    // Verifica campos removidos
    for (final key in oldValues!.keys) {
      if (!newValues!.containsKey(key)) {
        changes.add(ChangeRecord(
          field: key,
          oldValue: oldValues![key],
          newValue: null,
          changeType: ChangeType.deleted,
        ));
      }
    }

    return changes;
  }

  ChangeType _determineChangeType(dynamic oldValue, dynamic newValue) {
    if (oldValue == null && newValue != null) return ChangeType.added;
    if (oldValue != null && newValue == null) return ChangeType.deleted;
    return ChangeType.modified;
  }

  /// Gera hash de integridade do evento
  String get integrityHash {
    final data = [
      id,
      firmId,
      eventType.toString(),
      action,
      timestamp.toIso8601String(),
      userId,
      entityType ?? '',
      entityId ?? '',
    ].join('|');
    
    // Em implementação real, usar algoritmo de hash seguro
    return data.hashCode.toString();
  }

  /// Verifica se o evento requer atenção
  bool get requiresAttention {
    return isCritical ||
           complianceStatus == ComplianceStatus.violation ||
           eventType == AuditEventType.securityBreach ||
           eventType == AuditEventType.dataExport;
  }

  /// Cria uma cópia com modificações
  SlaAuditEntity copyWith({
    String? id,
    String? firmId,
    AuditEventType? eventType,
    AuditEventCategory? eventCategory,
    String? action,
    String? description,
    DateTime? timestamp,
    String? userId,
    String? userRole,
    String? ipAddress,
    String? userAgent,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    List<AffectedEntity>? affectedEntities,
    AuditSeverity? severity,
    ComplianceStatus? complianceStatus,
    RiskLevel? riskLevel,
    AuditContext? context,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return SlaAuditEntity(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      eventType: eventType ?? this.eventType,
      eventCategory: eventCategory ?? this.eventCategory,
      action: action ?? this.action,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      affectedEntities: affectedEntities ?? this.affectedEntities,
      severity: severity ?? this.severity,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      riskLevel: riskLevel ?? this.riskLevel,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firmId,
        eventType,
        eventCategory,
        action,
        description,
        timestamp,
        userId,
        userRole,
        ipAddress,
        userAgent,
        entityType,
        entityId,
        oldValues,
        newValues,
        affectedEntities,
        severity,
        complianceStatus,
        riskLevel,
        context,
        metadata,
        tags,
      ];

  @override
  String toString() {
    return 'SlaAuditEntity('
        'id: $id, '
        'eventType: $eventType, '
        'action: $action, '
        'user: $userId, '
        'timestamp: $timestamp, '
        'severity: $severity'
        ')';
  }
}

/// Tipos de evento de auditoria
extension SlaAuditEntityFactory on SlaAuditEntity {
  /// Cria evento de alteração de configuração
  static SlaAuditEntity configurationChanged({
    required String firmId,
    required String userId,
    required String userRole,
    required String ipAddress,
    required String userAgent,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> oldValues,
    required Map<String, dynamic> newValues,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return SlaAuditEntity(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      firmId: firmId,
      eventType: AuditEventType.configurationChange,
      eventCategory: AuditEventCategory.configuration,
      action: 'UPDATE',
      description: description ?? 'Configuração SLA alterada',
      timestamp: DateTime.now(),
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      entityType: entityType,
      entityId: entityId,
      oldValues: oldValues,
      newValues: newValues,
      severity: AuditSeverity.info,
      complianceStatus: ComplianceStatus.compliant,
      riskLevel: RiskLevel.low,
      metadata: metadata,
    );
  }

  /// Cria evento de violação de SLA
  static SlaAuditEntity slaViolationOccurred({
    required String firmId,
    required String userId,
    required String userRole,
    required String ipAddress,
    required String userAgent,
    required String caseId,
    required String violationReason,
    required Duration delayDuration,
    Map<String, dynamic>? metadata,
  }) {
    return SlaAuditEntity(
      id: 'audit_violation_${DateTime.now().millisecondsSinceEpoch}',
      firmId: firmId,
      eventType: AuditEventType.slaViolation,
      eventCategory: AuditEventCategory.business,
      action: 'SLA_VIOLATION',
      description: 'Violação de SLA detectada: $violationReason',
      timestamp: DateTime.now(),
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      entityType: 'case',
      entityId: caseId,
      severity: AuditSeverity.warning,
      complianceStatus: ComplianceStatus.violation,
      riskLevel: RiskLevel.medium,
      metadata: {
        'violation_reason': violationReason,
        'delay_hours': delayDuration.inHours,
        ...?metadata,
      },
    );
  }

  /// Cria evento de escalação
  static SlaAuditEntity escalationExecuted({
    required String firmId,
    required String userId,
    required String userRole,
    required String ipAddress,
    required String userAgent,
    required String escalationId,
    required int escalationLevel,
    required List<String> notifiedUsers,
    Map<String, dynamic>? metadata,
  }) {
    return SlaAuditEntity(
      id: 'audit_escalation_${DateTime.now().millisecondsSinceEpoch}',
      firmId: firmId,
      eventType: AuditEventType.escalationExecuted,
      eventCategory: AuditEventCategory.business,
      action: 'ESCALATION',
      description: 'Escalação de SLA executada - Nível $escalationLevel',
      timestamp: DateTime.now(),
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      entityType: 'escalation',
      entityId: escalationId,
      severity: AuditSeverity.warning,
      complianceStatus: ComplianceStatus.compliant,
      riskLevel: RiskLevel.medium,
      metadata: {
        'escalation_level': escalationLevel,
        'notified_users': notifiedUsers,
        ...?metadata,
      },
    );
  }
} 
