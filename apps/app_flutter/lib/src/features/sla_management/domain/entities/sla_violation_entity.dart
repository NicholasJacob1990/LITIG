import 'package:equatable/equatable.dart';

/// Entidade que representa uma violação de SLA
/// 
/// Registra quando um caso ultrapassa o prazo estabelecido,
/// incluindo detalhes sobre a violação, impacto e ações tomadas
class SlaViolationEntity extends Equatable {
  const SlaViolationEntity({
    required this.id,
    required this.caseId,
    required this.firmId,
    required this.lawyerId,
    required this.originalDeadline,
    required this.actualCompletionTime,
    required this.violationType,
    required this.priority,
    required this.delayDuration,
    required this.violationReason,
    required this.impact,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.resolvedAt,
    this.resolvedBy,
    this.escalationLevel,
    this.actionsInfo,
    this.clientNotified,
    this.clientNotificationTime,
    this.compensationOffered,
    this.compensationDetails,
    this.preventionMeasures,
    this.rootCauseAnalysis,
    this.metadata,
  });

  /// ID único da violação
  final String id;

  /// ID do caso relacionado
  final String caseId;

  /// ID da firma
  final String firmId;

  /// ID do advogado responsável
  final String lawyerId;

  /// Data/hora original do deadline
  final DateTime originalDeadline;

  /// Data/hora real de conclusão (se concluído)
  final DateTime? actualCompletionTime;

  /// Tipo da violação
  final SlaViolationType violationType;

  /// Prioridade do caso no momento da violação
  final String priority;

  /// Duração do atraso
  final Duration delayDuration;

  /// Razão da violação (categorizada)
  final String violationReason;

  /// Nível de impacto da violação
  final SlaViolationImpact impact;

  /// Status atual da violação
  final SlaViolationStatus status;

  /// Data/hora de criação da violação
  final DateTime createdAt;

  /// Data/hora da última atualização
  final DateTime updatedAt;

  /// ID do cliente (se aplicável)
  final String? clientId;

  /// Data/hora de resolução
  final DateTime? resolvedAt;

  /// ID de quem resolveu a violação
  final String? resolvedBy;

  /// Nível de escalação atingido
  final int? escalationLevel;

  /// Informações sobre ações tomadas
  final List<SlaViolationAction>? actionsInfo;

  /// Se o cliente foi notificado
  final bool? clientNotified;

  /// Data/hora da notificação ao cliente
  final DateTime? clientNotificationTime;

  /// Se compensação foi oferecida
  final bool? compensationOffered;

  /// Detalhes da compensação
  final Map<String, dynamic>? compensationDetails;

  /// Medidas preventivas implementadas
  final List<String>? preventionMeasures;

  /// Análise de causa raiz
  final Map<String, dynamic>? rootCauseAnalysis;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  /// Calcula severidade da violação baseada em múltiplos fatores
  SlaViolationSeverity get severity {
    int severityScore = 0;

    // Duração do atraso
    if (delayDuration.inHours >= 24) {
      severityScore += 3;
    } else if (delayDuration.inHours >= 6) severityScore += 2;
    else severityScore += 1;

    // Prioridade do caso
    switch (priority.toLowerCase()) {
      case 'emergency':
        severityScore += 3;
        break;
      case 'urgent':
        severityScore += 2;
        break;
      default:
        severityScore += 1;
    }

    // Impacto
    switch (impact) {
      case SlaViolationImpact.critical:
        severityScore += 3;
        break;
      case SlaViolationImpact.high:
        severityScore += 2;
        break;
      case SlaViolationImpact.medium:
        severityScore += 1;
        break;
      default:
        break;
    }

    // Escalação
    if (escalationLevel != null && escalationLevel! >= 3) {
      severityScore += 2;
    } else if (escalationLevel != null && escalationLevel! >= 2) severityScore += 1;

    // Determina severidade final
    if (severityScore >= 8) return SlaViolationSeverity.critical;
    if (severityScore >= 6) return SlaViolationSeverity.high;
    if (severityScore >= 4) return SlaViolationSeverity.medium;
    return SlaViolationSeverity.low;
  }

  /// Verifica se a violação está resolvida
  bool get isResolved => status == SlaViolationStatus.resolved;

  /// Verifica se precisa de escalação
  bool get needsEscalation {
    return status == SlaViolationStatus.active &&
           delayDuration.inHours >= 6 &&
           (escalationLevel == null || escalationLevel! < 3);
  }

  /// Calcula tempo desde a violação
  Duration get timeSinceViolation {
    return DateTime.now().difference(createdAt);
  }

  /// Cria uma cópia com modificações
  SlaViolationEntity copyWith({
    String? id,
    String? caseId,
    String? firmId,
    String? lawyerId,
    DateTime? originalDeadline,
    DateTime? actualCompletionTime,
    SlaViolationType? violationType,
    String? priority,
    Duration? delayDuration,
    String? violationReason,
    SlaViolationImpact? impact,
    SlaViolationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientId,
    DateTime? resolvedAt,
    String? resolvedBy,
    int? escalationLevel,
    List<SlaViolationAction>? actionsInfo,
    bool? clientNotified,
    DateTime? clientNotificationTime,
    bool? compensationOffered,
    Map<String, dynamic>? compensationDetails,
    List<String>? preventionMeasures,
    Map<String, dynamic>? rootCauseAnalysis,
    Map<String, dynamic>? metadata,
  }) {
    return SlaViolationEntity(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      firmId: firmId ?? this.firmId,
      lawyerId: lawyerId ?? this.lawyerId,
      originalDeadline: originalDeadline ?? this.originalDeadline,
      actualCompletionTime: actualCompletionTime ?? this.actualCompletionTime,
      violationType: violationType ?? this.violationType,
      priority: priority ?? this.priority,
      delayDuration: delayDuration ?? this.delayDuration,
      violationReason: violationReason ?? this.violationReason,
      impact: impact ?? this.impact,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientId: clientId ?? this.clientId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      actionsInfo: actionsInfo ?? this.actionsInfo,
      clientNotified: clientNotified ?? this.clientNotified,
      clientNotificationTime: clientNotificationTime ?? this.clientNotificationTime,
      compensationOffered: compensationOffered ?? this.compensationOffered,
      compensationDetails: compensationDetails ?? this.compensationDetails,
      preventionMeasures: preventionMeasures ?? this.preventionMeasures,
      rootCauseAnalysis: rootCauseAnalysis ?? this.rootCauseAnalysis,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        caseId,
        firmId,
        lawyerId,
        originalDeadline,
        actualCompletionTime,
        violationType,
        priority,
        delayDuration,
        violationReason,
        impact,
        status,
        createdAt,
        updatedAt,
        clientId,
        resolvedAt,
        resolvedBy,
        escalationLevel,
        actionsInfo,
        clientNotified,
        clientNotificationTime,
        compensationOffered,
        compensationDetails,
        preventionMeasures,
        rootCauseAnalysis,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaViolationEntity('
        'id: $id, '
        'caseId: $caseId, '
        'violationType: $violationType, '
        'priority: $priority, '
        'delayDuration: ${delayDuration.inHours}h, '
        'severity: $severity, '
        'status: $status'
        ')';
  }
}

/// Tipos de violação de SLA
enum SlaViolationType {
  /// Violação simples - atraso no prazo
  simple,
  
  /// Violação com escalação - atraso com escalação automática
  escalated,
  
  /// Violação crítica - atraso em caso crítico
  critical,
  
  /// Violação recorrente - múltiplas violações do mesmo advogado/caso
  recurring,
  
  /// Violação sistêmica - problema no sistema/processo
  systemic,
}

/// Níveis de impacto da violação
enum SlaViolationImpact {
  /// Impacto baixo - sem consequências significativas
  low,
  
  /// Impacto médio - possível insatisfação do cliente
  medium,
  
  /// Impacto alto - risco de perda de cliente
  high,
  
  /// Impacto crítico - danos reputacionais ou legais
  critical,
}

/// Status da violação
enum SlaViolationStatus {
  /// Violação ativa - ainda não resolvida
  active,
  
  /// Em investigação - sendo analisada
  investigating,
  
  /// Em resolução - ações sendo tomadas
  resolving,
  
  /// Resolvida - violação tratada
  resolved,
  
  /// Dispensada - violação considerada não aplicável
  dismissed,
}

/// Severidade calculada da violação
enum SlaViolationSeverity {
  /// Severidade baixa
  low,
  
  /// Severidade média
  medium,
  
  /// Severidade alta
  high,
  
  /// Severidade crítica
  critical,
}

/// Ação tomada em resposta à violação
class SlaViolationAction extends Equatable {
  const SlaViolationAction({
    required this.id,
    required this.actionType,
    required this.description,
    required this.takenBy,
    required this.takenAt,
    this.result,
    this.metadata,
  });

  /// ID da ação
  final String id;

  /// Tipo da ação
  final String actionType;

  /// Descrição da ação
  final String description;

  /// Quem tomou a ação
  final String takenBy;

  /// Quando a ação foi tomada
  final DateTime takenAt;

  /// Resultado da ação
  final String? result;

  /// Metadados da ação
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        actionType,
        description,
        takenBy,
        takenAt,
        result,
        metadata,
      ];
} 

/// Entidade que representa uma violação de SLA
/// 
/// Registra quando um caso ultrapassa o prazo estabelecido,
/// incluindo detalhes sobre a violação, impacto e ações tomadas
class SlaViolationEntity extends Equatable {
  const SlaViolationEntity({
    required this.id,
    required this.caseId,
    required this.firmId,
    required this.lawyerId,
    required this.originalDeadline,
    required this.actualCompletionTime,
    required this.violationType,
    required this.priority,
    required this.delayDuration,
    required this.violationReason,
    required this.impact,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.resolvedAt,
    this.resolvedBy,
    this.escalationLevel,
    this.actionsInfo,
    this.clientNotified,
    this.clientNotificationTime,
    this.compensationOffered,
    this.compensationDetails,
    this.preventionMeasures,
    this.rootCauseAnalysis,
    this.metadata,
  });

  /// ID único da violação
  final String id;

  /// ID do caso relacionado
  final String caseId;

  /// ID da firma
  final String firmId;

  /// ID do advogado responsável
  final String lawyerId;

  /// Data/hora original do deadline
  final DateTime originalDeadline;

  /// Data/hora real de conclusão (se concluído)
  final DateTime? actualCompletionTime;

  /// Tipo da violação
  final SlaViolationType violationType;

  /// Prioridade do caso no momento da violação
  final String priority;

  /// Duração do atraso
  final Duration delayDuration;

  /// Razão da violação (categorizada)
  final String violationReason;

  /// Nível de impacto da violação
  final SlaViolationImpact impact;

  /// Status atual da violação
  final SlaViolationStatus status;

  /// Data/hora de criação da violação
  final DateTime createdAt;

  /// Data/hora da última atualização
  final DateTime updatedAt;

  /// ID do cliente (se aplicável)
  final String? clientId;

  /// Data/hora de resolução
  final DateTime? resolvedAt;

  /// ID de quem resolveu a violação
  final String? resolvedBy;

  /// Nível de escalação atingido
  final int? escalationLevel;

  /// Informações sobre ações tomadas
  final List<SlaViolationAction>? actionsInfo;

  /// Se o cliente foi notificado
  final bool? clientNotified;

  /// Data/hora da notificação ao cliente
  final DateTime? clientNotificationTime;

  /// Se compensação foi oferecida
  final bool? compensationOffered;

  /// Detalhes da compensação
  final Map<String, dynamic>? compensationDetails;

  /// Medidas preventivas implementadas
  final List<String>? preventionMeasures;

  /// Análise de causa raiz
  final Map<String, dynamic>? rootCauseAnalysis;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  /// Calcula severidade da violação baseada em múltiplos fatores
  SlaViolationSeverity get severity {
    int severityScore = 0;

    // Duração do atraso
    if (delayDuration.inHours >= 24) {
      severityScore += 3;
    } else if (delayDuration.inHours >= 6) severityScore += 2;
    else severityScore += 1;

    // Prioridade do caso
    switch (priority.toLowerCase()) {
      case 'emergency':
        severityScore += 3;
        break;
      case 'urgent':
        severityScore += 2;
        break;
      default:
        severityScore += 1;
    }

    // Impacto
    switch (impact) {
      case SlaViolationImpact.critical:
        severityScore += 3;
        break;
      case SlaViolationImpact.high:
        severityScore += 2;
        break;
      case SlaViolationImpact.medium:
        severityScore += 1;
        break;
      default:
        break;
    }

    // Escalação
    if (escalationLevel != null && escalationLevel! >= 3) {
      severityScore += 2;
    } else if (escalationLevel != null && escalationLevel! >= 2) severityScore += 1;

    // Determina severidade final
    if (severityScore >= 8) return SlaViolationSeverity.critical;
    if (severityScore >= 6) return SlaViolationSeverity.high;
    if (severityScore >= 4) return SlaViolationSeverity.medium;
    return SlaViolationSeverity.low;
  }

  /// Verifica se a violação está resolvida
  bool get isResolved => status == SlaViolationStatus.resolved;

  /// Verifica se precisa de escalação
  bool get needsEscalation {
    return status == SlaViolationStatus.active &&
           delayDuration.inHours >= 6 &&
           (escalationLevel == null || escalationLevel! < 3);
  }

  /// Calcula tempo desde a violação
  Duration get timeSinceViolation {
    return DateTime.now().difference(createdAt);
  }

  /// Cria uma cópia com modificações
  SlaViolationEntity copyWith({
    String? id,
    String? caseId,
    String? firmId,
    String? lawyerId,
    DateTime? originalDeadline,
    DateTime? actualCompletionTime,
    SlaViolationType? violationType,
    String? priority,
    Duration? delayDuration,
    String? violationReason,
    SlaViolationImpact? impact,
    SlaViolationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientId,
    DateTime? resolvedAt,
    String? resolvedBy,
    int? escalationLevel,
    List<SlaViolationAction>? actionsInfo,
    bool? clientNotified,
    DateTime? clientNotificationTime,
    bool? compensationOffered,
    Map<String, dynamic>? compensationDetails,
    List<String>? preventionMeasures,
    Map<String, dynamic>? rootCauseAnalysis,
    Map<String, dynamic>? metadata,
  }) {
    return SlaViolationEntity(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      firmId: firmId ?? this.firmId,
      lawyerId: lawyerId ?? this.lawyerId,
      originalDeadline: originalDeadline ?? this.originalDeadline,
      actualCompletionTime: actualCompletionTime ?? this.actualCompletionTime,
      violationType: violationType ?? this.violationType,
      priority: priority ?? this.priority,
      delayDuration: delayDuration ?? this.delayDuration,
      violationReason: violationReason ?? this.violationReason,
      impact: impact ?? this.impact,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientId: clientId ?? this.clientId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      actionsInfo: actionsInfo ?? this.actionsInfo,
      clientNotified: clientNotified ?? this.clientNotified,
      clientNotificationTime: clientNotificationTime ?? this.clientNotificationTime,
      compensationOffered: compensationOffered ?? this.compensationOffered,
      compensationDetails: compensationDetails ?? this.compensationDetails,
      preventionMeasures: preventionMeasures ?? this.preventionMeasures,
      rootCauseAnalysis: rootCauseAnalysis ?? this.rootCauseAnalysis,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        caseId,
        firmId,
        lawyerId,
        originalDeadline,
        actualCompletionTime,
        violationType,
        priority,
        delayDuration,
        violationReason,
        impact,
        status,
        createdAt,
        updatedAt,
        clientId,
        resolvedAt,
        resolvedBy,
        escalationLevel,
        actionsInfo,
        clientNotified,
        clientNotificationTime,
        compensationOffered,
        compensationDetails,
        preventionMeasures,
        rootCauseAnalysis,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaViolationEntity('
        'id: $id, '
        'caseId: $caseId, '
        'violationType: $violationType, '
        'priority: $priority, '
        'delayDuration: ${delayDuration.inHours}h, '
        'severity: $severity, '
        'status: $status'
        ')';
  }
}

/// Tipos de violação de SLA

/// Níveis de impacto da violação
enum SlaViolationImpact {
  /// Impacto baixo - sem consequências significativas
  low,
  
  /// Impacto médio - possível insatisfação do cliente
  medium,
  
  /// Impacto alto - risco de perda de cliente
  high,
  
  /// Impacto crítico - danos reputacionais ou legais
  critical,
}

/// Status da violação
enum SlaViolationStatus {
  /// Violação ativa - ainda não resolvida
  active,
  
  /// Em investigação - sendo analisada
  investigating,
  
  /// Em resolução - ações sendo tomadas
  resolving,
  
  /// Resolvida - violação tratada
  resolved,
  
  /// Dispensada - violação considerada não aplicável
  dismissed,
}

/// Severidade calculada da violação
enum SlaViolationSeverity {
  /// Severidade baixa
  low,
  
  /// Severidade média
  medium,
  
  /// Severidade alta
  high,
  
  /// Severidade crítica
  critical,
}

/// Ação tomada em resposta à violação
class SlaViolationAction extends Equatable {
  const SlaViolationAction({
    required this.id,
    required this.actionType,
    required this.description,
    required this.takenBy,
    required this.takenAt,
    this.result,
    this.metadata,
  });

  /// ID da ação
  final String id;

  /// Tipo da ação
  final String actionType;

  /// Descrição da ação
  final String description;

  /// Quem tomou a ação
  final String takenBy;

  /// Quando a ação foi tomada
  final DateTime takenAt;

  /// Resultado da ação
  final String? result;

  /// Metadados da ação
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        actionType,
        description,
        takenBy,
        takenAt,
        result,
        metadata,
      ];
} 