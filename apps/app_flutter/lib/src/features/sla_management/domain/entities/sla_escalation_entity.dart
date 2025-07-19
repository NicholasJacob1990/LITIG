import 'package:equatable/equatable.dart';

/// Entidade que representa uma escalação de SLA
/// 
/// Define regras e workflows para escalação automática quando
/// prazos são violados ou estão próximos do vencimento
class SlaEscalationEntity extends Equatable {
  const SlaEscalationEntity({
    required this.id,
    required this.firmId,
    required this.name,
    required this.description,
    required this.isActive,
    required this.triggers,
    required this.levels,
    required this.createdAt,
    required this.updatedAt,
    this.caseId,
    this.priority,
    this.executedAt,
    this.executedBy,
    this.currentLevel,
    this.status,
    this.logs,
    this.metadata,
  });

  /// ID único da escalação
  final String id;

  /// ID da firma
  final String firmId;

  /// Nome da escalação
  final String name;

  /// Descrição da escalação
  final String description;

  /// Se a escalação está ativa
  final bool isActive;

  /// Gatilhos que iniciam a escalação
  final List<EscalationTrigger> triggers;

  /// Níveis de escalação
  final List<EscalationLevel> levels;

  /// Data de criação
  final DateTime createdAt;

  /// Data de atualização
  final DateTime updatedAt;

  /// ID do caso (quando aplicável a caso específico)
  final String? caseId;

  /// Prioridade que desencadeou a escalação
  final String? priority;

  /// Data de execução
  final DateTime? executedAt;

  /// Quem executou a escalação
  final String? executedBy;

  /// Nível atual da escalação
  final int? currentLevel;

  /// Status da escalação
  final EscalationStatus? status;

  /// Logs de execução
  final List<EscalationLog>? logs;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  /// Getter para tipo de trigger (compatibilidade com widgets)
  String get triggerType {
    if (triggers.isEmpty) return 'none';
    return triggers.first.type.toString();
  }

  /// Getter para níveis de escalação (compatibilidade com widgets)
  List<EscalationLevel> get escalationLevels => levels;

  /// Método para escalação baseada em tempo
  static SlaEscalationEntity timeBasedEscalation({
    required String id,
    required String firmId,
    required String name,
    required String description,
    required int delayMinutes,
    required List<EscalationLevel> levels,
  }) {
    return SlaEscalationEntity(
      id: id,
      firmId: firmId,
      name: name,
      description: description,
      isActive: true,
      triggers: [
        EscalationTrigger(
          id: '${id}_trigger_time',
          type: EscalationTriggerType.timeDelay,
          condition: 'delay_minutes',
          value: delayMinutes,
        ),
      ],
      levels: levels,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Método para escalação baseada em prioridade
  static SlaEscalationEntity priorityBasedEscalation({
    required String id,
    required String firmId,
    required String name,
    required String description,
    required String priority,
    required List<EscalationLevel> levels,
  }) {
    return SlaEscalationEntity(
      id: id,
      firmId: firmId,
      name: name,
      description: description,
      isActive: true,
      triggers: [
        EscalationTrigger(
          id: '${id}_trigger_priority',
          type: EscalationTriggerType.priorityBased,
          condition: 'priority',
          value: [priority.toLowerCase()],
        ),
      ],
      levels: levels,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Método toJson para serialização
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firmId': firmId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'triggers': triggers.map((t) => t.toJson()).toList(),
      'levels': levels.map((l) => l.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'caseId': caseId,
      'priority': priority,
      'executedAt': executedAt?.toIso8601String(),
      'executedBy': executedBy,
      'currentLevel': currentLevel,
      'status': status?.toString(),
      'logs': logs?.map((l) => l.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Verifica se a escalação deve ser executada
  bool shouldEscalate(Duration delayDuration, String priority) {
    if (!isActive) return false;

    for (final trigger in triggers) {
      if (trigger.matches(delayDuration, priority)) {
        return true;
      }
    }
    return false;
  }

  /// Obtém o próximo nível de escalação
  EscalationLevel? getNextLevel() {
    if (currentLevel == null) {
      return levels.isNotEmpty ? levels.first : null;
    }

    final nextLevelIndex = levels.indexWhere((l) => l.level > currentLevel!);
    return nextLevelIndex != -1 ? levels[nextLevelIndex] : null;
  }

  /// Verifica se a escalação está completa
  bool get isComplete {
    return status == EscalationStatus.completed ||
           (currentLevel != null && currentLevel! >= levels.last.level);
  }

  /// Obtém estatísticas da escalação
  EscalationStats get stats {
    final completedLevels = levels.where((l) => 
        currentLevel != null && l.level <= currentLevel!).length;
    
    final totalLevels = levels.length;
    final progressPercentage = totalLevels > 0 ? 
        (completedLevels / totalLevels * 100).round() : 0;

    return EscalationStats(
      totalLevels: totalLevels,
      completedLevels: completedLevels,
      currentLevel: currentLevel ?? 0,
      progressPercentage: progressPercentage,
      isActive: status == EscalationStatus.active,
      isComplete: isComplete,
    );
  }

  /// Cria uma cópia com modificações
  SlaEscalationEntity copyWith({
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
    return SlaEscalationEntity(
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

  @override
  List<Object?> get props => [
        id,
        firmId,
        name,
        description,
        isActive,
        triggers,
        levels,
        createdAt,
        updatedAt,
        caseId,
        priority,
        executedAt,
        executedBy,
        currentLevel,
        status,
        logs,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaEscalationEntity('
        'id: $id, '
        'name: $name, '
        'isActive: $isActive, '
        'levels: ${levels.length}, '
        'currentLevel: $currentLevel, '
        'status: $status'
        ')';
  }
}

/// Gatilho de escalação
class EscalationTrigger extends Equatable {
  const EscalationTrigger({
    required this.id,
    required this.type,
    required this.condition,
    required this.value,
    this.priority,
    this.metadata,
  });

  /// ID do gatilho
  final String id;

  /// Tipo do gatilho
  final EscalationTriggerType type;

  /// Condição do gatilho
  final String condition;

  /// Valor do gatilho
  final dynamic value;

  /// Prioridade específica (opcional)
  final String? priority;

  /// Metadados do gatilho
  final Map<String, dynamic>? metadata;

  /// Verifica se o gatilho deve ser acionado
  bool matches(Duration delayDuration, String priority) {
    // Verifica prioridade específica
    if (this.priority != null && this.priority != priority) {
      return false;
    }

    switch (type) {
      case EscalationTriggerType.timeDelay:
        return _checkTimeDelay(delayDuration);
      case EscalationTriggerType.priorityBased:
        return _checkPriority(priority);
      case EscalationTriggerType.combined:
        return _checkCombined(delayDuration, priority);
      default:
        return false;
    }
  }

  bool _checkTimeDelay(Duration delayDuration) {
    final thresholdMinutes = value as int;
    return delayDuration.inMinutes >= thresholdMinutes;
  }

  bool _checkPriority(String priority) {
    final allowedPriorities = value as List<String>;
    return allowedPriorities.contains(priority.toLowerCase());
  }

  bool _checkCombined(Duration delayDuration, String priority) {
    final conditions = value as Map<String, dynamic>;
    final timeCondition = conditions['time'] as int?;
    final priorityCondition = conditions['priorities'] as List<String>?;

    bool timeMatch = timeCondition == null || 
                    delayDuration.inMinutes >= timeCondition;
    bool priorityMatch = priorityCondition == null || 
                        priorityCondition.contains(priority.toLowerCase());

    return timeMatch && priorityMatch;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'condition': condition,
      'value': value,
      'priority': priority,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, type, condition, value, priority, metadata];
}

/// Nível de escalação
class EscalationLevel extends Equatable {
  const EscalationLevel({
    required this.level,
    required this.name,
    required this.description,
    required this.actions,
    required this.recipients,
    this.delayMinutes,
    this.conditions,
    this.metadata,
  });

  /// Número do nível (1, 2, 3, etc.)
  final int level;

  /// Nome do nível
  final String name;

  /// Descrição do nível
  final String description;

  /// Ações a serem executadas
  final List<EscalationAction> actions;

  /// Destinatários das notificações
  final List<EscalationRecipient> recipients;

  /// Atraso em minutos antes de executar este nível
  final int? delayMinutes;

  /// Condições adicionais para execução
  final Map<String, dynamic>? conditions;

  /// Metadados do nível
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'name': name,
      'description': description,
      'actions': actions.map((a) => a.toJson()).toList(),
      'recipients': recipients.map((r) => r.toJson()).toList(),
      'delayMinutes': delayMinutes,
      'conditions': conditions,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        level,
        name,
        description,
        actions,
        recipients,
        delayMinutes,
        conditions,
        metadata,
      ];
}

/// Ação de escalação
class EscalationAction extends Equatable {
  const EscalationAction({
    required this.type,
    required this.description,
    required this.parameters,
    this.isRequired,
    this.metadata,
  });

  /// Tipo da ação
  final EscalationActionType type;

  /// Descrição da ação
  final String description;

  /// Parâmetros da ação
  final Map<String, dynamic> parameters;

  /// Se a ação é obrigatória
  final bool? isRequired;

  /// Metadados da ação
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'description': description,
      'parameters': parameters,
      'isRequired': isRequired,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [type, description, parameters, isRequired, metadata];
}

/// Destinatário da escalação
class EscalationRecipient extends Equatable {
  const EscalationRecipient({
    required this.type,
    required this.identifier,
    this.name,
    this.role,
    this.metadata,
  });

  /// Tipo do destinatário
  final EscalationRecipientType type;

  /// Identificador (user_id, role, email, etc.)
  final String identifier;

  /// Nome do destinatário
  final String? name;

  /// Papel/função
  final String? role;

  /// Metadados do destinatário
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'identifier': identifier,
      'name': name,
      'role': role,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [type, identifier, name, role, metadata];
}

/// Log de escalação
class EscalationLog extends Equatable {
  const EscalationLog({
    required this.id,
    required this.level,
    required this.action,
    required this.executedAt,
    required this.status,
    this.executedBy,
    this.result,
    this.error,
    this.metadata,
  });

  /// ID do log
  final String id;

  /// Nível da escalação
  final int level;

  /// Ação executada
  final String action;

  /// Data de execução
  final DateTime executedAt;

  /// Status da execução
  final String status;

  /// Quem executou
  final String? executedBy;

  /// Resultado da execução
  final Map<String, dynamic>? result;

  /// Erro (se houver)
  final String? error;

  /// Metadados do log
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'action': action,
      'executedAt': executedAt.toIso8601String(),
      'status': status,
      'executedBy': executedBy,
      'result': result,
      'error': error,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        level,
        action,
        executedAt,
        status,
        executedBy,
        result,
        error,
        metadata,
      ];
}

/// Estatísticas da escalação
class EscalationStats extends Equatable {
  const EscalationStats({
    required this.totalLevels,
    required this.completedLevels,
    required this.currentLevel,
    required this.progressPercentage,
    required this.isActive,
    required this.isComplete,
  });

  /// Total de níveis
  final int totalLevels;

  /// Níveis completados
  final int completedLevels;

  /// Nível atual
  final int currentLevel;

  /// Porcentagem de progresso
  final int progressPercentage;

  /// Se está ativa
  final bool isActive;

  /// Se está completa
  final bool isComplete;

  @override
  List<Object?> get props => [
        totalLevels,
        completedLevels,
        currentLevel,
        progressPercentage,
        isActive,
        isComplete,
      ];
}

/// Tipos de gatilho de escalação
enum EscalationTriggerType {
  /// Baseado em tempo de atraso
  timeDelay,
  
  /// Baseado na prioridade do caso
  priorityBased,
  
  /// Combinação de fatores
  combined,
  
  /// Gatilho manual
  manual,
}

/// Tipos de ação de escalação
enum EscalationActionType {
  /// Enviar notificação
  notify,
  
  /// Reatribuir caso
  reassign,
  
  /// Criar tarefa
  createTask,
  
  /// Enviar email
  sendEmail,
  
  /// Enviar SMS
  sendSms,
  
  /// Webhook
  webhook,
  
  /// Ação customizada
  custom,
}

/// Tipos de destinatário
enum EscalationRecipientType {
  /// Usuário específico
  user,
  
  /// Papel/função
  role,
  
  /// Email específico
  email,
  
  /// Grupo
  group,
  
  /// Webhook URL
  webhook,
}

/// Status da escalação
enum EscalationStatus {
  /// Aguardando
  pending,
  
  /// Ativa
  active,
  
  /// Pausada
  paused,
  
  /// Completada
  completed,
  
  /// Cancelada
  cancelled,
  
  /// Com erro
  error,
}