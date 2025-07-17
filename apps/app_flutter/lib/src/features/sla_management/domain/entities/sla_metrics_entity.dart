import 'package:equatable/equatable.dart';

/// Entidade que representa métricas de SLA
/// 
/// Contém todas as métricas, analytics e dados estatísticos
/// relacionados ao desempenho de SLA da firma
class SlaMetricsEntity extends Equatable {
  const SlaMetricsEntity({
    required this.id,
    required this.firmId,
    required this.periodStart,
    required this.periodEnd,
    required this.complianceMetrics,
    required this.performanceMetrics,
    required this.violationMetrics,
    required this.escalationMetrics,
    required this.trendsData,
    required this.generatedAt,
    this.lawyerMetrics,
    this.clientMetrics,
    this.caseTypeMetrics,
    this.customMetrics,
    this.metadata,
  });

  /// ID único das métricas
  final String id;

  /// ID da firma
  final String firmId;

  /// Início do período analisado
  final DateTime periodStart;

  /// Fim do período analisado
  final DateTime periodEnd;

  /// Métricas de compliance
  final ComplianceMetrics complianceMetrics;

  /// Métricas de performance
  final PerformanceMetrics performanceMetrics;

  /// Métricas de violações
  final ViolationMetrics violationMetrics;

  /// Métricas de escalação
  final EscalationMetrics escalationMetrics;

  /// Dados de tendências
  final TrendsData trendsData;

  /// Data de geração das métricas
  final DateTime generatedAt;

  /// Métricas por advogado
  final Map<String, LawyerMetrics>? lawyerMetrics;

  /// Métricas por cliente
  final Map<String, ClientMetrics>? clientMetrics;

  /// Métricas por tipo de caso
  final Map<String, CaseTypeMetrics>? caseTypeMetrics;

  /// Métricas customizadas
  final Map<String, dynamic>? customMetrics;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  /// Calcula a duração do período em dias
  int get periodDurationDays {
    return periodEnd.difference(periodStart).inDays + 1;
  }

  /// Verifica se as métricas estão atualizadas (menos de 1 hora)
  bool get isUpToDate {
    final now = DateTime.now();
    return now.difference(generatedAt).inHours < 1;
  }

  /// Obtém o score geral de SLA (0-100)
  double get overallSlaScore {
    double complianceWeight = 0.4;
    double performanceWeight = 0.3;
    double violationWeight = 0.2;
    double escalationWeight = 0.1;

    double complianceScore = complianceMetrics.overallRate * 100;
    double performanceScore = _calculatePerformanceScore();
    double violationScore = _calculateViolationScore();
    double escalationScore = _calculateEscalationScore();

    return (complianceScore * complianceWeight +
            performanceScore * performanceWeight +
            violationScore * violationWeight +
            escalationScore * escalationWeight);
  }

  /// Obtém o status geral baseado no score
  SlaStatus get overallStatus {
    final score = overallSlaScore;
    if (score >= 95) return SlaStatus.excellent;
    if (score >= 85) return SlaStatus.good;
    if (score >= 70) return SlaStatus.acceptable;
    if (score >= 50) return SlaStatus.poor;
    return SlaStatus.critical;
  }

  /// Identifica áreas que precisam de atenção
  List<SlaAlert> get alerts {
    List<SlaAlert> alerts = [];

    // Compliance baixo
    if (complianceMetrics.overallRate < 0.8) {
      alerts.add(SlaAlert(
        type: SlaAlertType.lowCompliance,
        severity: complianceMetrics.overallRate < 0.6 ? 
                  SlaAlertSeverity.critical : SlaAlertSeverity.warning,
        message: 'Taxa de compliance SLA baixa: ${(complianceMetrics.overallRate * 100).toStringAsFixed(1)}%',
        value: complianceMetrics.overallRate,
      ));
    }

    // Muitas violações
    if (violationMetrics.totalViolations > periodDurationDays * 2) {
      alerts.add(SlaAlert(
        type: SlaAlertType.highViolations,
        severity: SlaAlertSeverity.warning,
        message: 'Alto número de violações: ${violationMetrics.totalViolations}',
        value: violationMetrics.totalViolations.toDouble(),
      ));
    }

    // Muitas escalações
    if (escalationMetrics.totalEscalations > periodDurationDays) {
      alerts.add(SlaAlert(
        type: SlaAlertType.frequentEscalations,
        severity: SlaAlertSeverity.warning,
        message: 'Escalações frequentes: ${escalationMetrics.totalEscalations}',
        value: escalationMetrics.totalEscalations.toDouble(),
      ));
    }

    // Performance degradando
    if (trendsData.complianceTrend.isNotEmpty && 
        trendsData.complianceTrend.length >= 2) {
      final latest = trendsData.complianceTrend.last.value;
      final previous = trendsData.complianceTrend[trendsData.complianceTrend.length - 2].value;
      
      if (latest < previous - 0.1) {
        alerts.add(SlaAlert(
          type: SlaAlertType.performanceDegrading,
          severity: SlaAlertSeverity.info,
          message: 'Performance SLA em declínio',
          value: latest - previous,
        ));
      }
    }

    return alerts;
  }

  double _calculatePerformanceScore() {
    // Score baseado no tempo médio de resposta vs. SLA
    final avgResponseHours = performanceMetrics.averageResponseTime.inHours;
    const maxSlaHours = 48; // Assumindo SLA padrão de 48h
    
    if (avgResponseHours <= maxSlaHours * 0.5) return 100;
    if (avgResponseHours <= maxSlaHours * 0.7) return 85;
    if (avgResponseHours <= maxSlaHours * 0.9) return 70;
    if (avgResponseHours <= maxSlaHours) return 50;
    return 25;
  }

  double _calculateViolationScore() {
    // Score inverso baseado na taxa de violação
    final violationRate = violationMetrics.violationRate;
    return (1 - violationRate) * 100;
  }

  double _calculateEscalationScore() {
    // Score baseado na taxa de escalação
    final escalationRate = escalationMetrics.escalationRate;
    if (escalationRate <= 0.05) return 100;
    if (escalationRate <= 0.1) return 85;
    if (escalationRate <= 0.2) return 70;
    if (escalationRate <= 0.3) return 50;
    return 25;
  }

  /// Cria uma cópia com modificações
  SlaMetricsEntity copyWith({
    String? id,
    String? firmId,
    DateTime? periodStart,
    DateTime? periodEnd,
    ComplianceMetrics? complianceMetrics,
    PerformanceMetrics? performanceMetrics,
    ViolationMetrics? violationMetrics,
    EscalationMetrics? escalationMetrics,
    TrendsData? trendsData,
    DateTime? generatedAt,
    Map<String, LawyerMetrics>? lawyerMetrics,
    Map<String, ClientMetrics>? clientMetrics,
    Map<String, CaseTypeMetrics>? caseTypeMetrics,
    Map<String, dynamic>? customMetrics,
    Map<String, dynamic>? metadata,
  }) {
    return SlaMetricsEntity(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      complianceMetrics: complianceMetrics ?? this.complianceMetrics,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      violationMetrics: violationMetrics ?? this.violationMetrics,
      escalationMetrics: escalationMetrics ?? this.escalationMetrics,
      trendsData: trendsData ?? this.trendsData,
      generatedAt: generatedAt ?? this.generatedAt,
      lawyerMetrics: lawyerMetrics ?? this.lawyerMetrics,
      clientMetrics: clientMetrics ?? this.clientMetrics,
      caseTypeMetrics: caseTypeMetrics ?? this.caseTypeMetrics,
      customMetrics: customMetrics ?? this.customMetrics,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firmId,
        periodStart,
        periodEnd,
        complianceMetrics,
        performanceMetrics,
        violationMetrics,
        escalationMetrics,
        trendsData,
        generatedAt,
        lawyerMetrics,
        clientMetrics,
        caseTypeMetrics,
        customMetrics,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaMetricsEntity('
        'id: $id, '
        'firmId: $firmId, '
        'period: ${periodStart.day}/${periodStart.month} - ${periodEnd.day}/${periodEnd.month}, '
        'overallScore: ${overallSlaScore.toStringAsFixed(1)}, '
        'status: $overallStatus'
        ')';
  }
}

/// Métricas de compliance
class ComplianceMetrics extends Equatable {
  const ComplianceMetrics({
    required this.overallRate,
    required this.byPriority,
    required this.totalCases,
    required this.compliantCases,
    required this.nonCompliantCases,
  });

  /// Taxa geral de compliance (0.0 - 1.0)
  final double overallRate;

  /// Taxa de compliance por prioridade
  final Map<String, double> byPriority;

  /// Total de casos no período
  final int totalCases;

  /// Casos em compliance
  final int compliantCases;

  /// Casos fora de compliance
  final int nonCompliantCases;

  @override
  List<Object?> get props => [
        overallRate,
        byPriority,
        totalCases,
        compliantCases,
        nonCompliantCases,
      ];
}

/// Métricas de performance
class PerformanceMetrics extends Equatable {
  const PerformanceMetrics({
    required this.averageResponseTime,
    required this.medianResponseTime,
    required this.fastestResponseTime,
    required this.slowestResponseTime,
    required this.responseTimeByPriority,
    required this.responseTimeDistribution,
  });

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Tempo mediano de resposta
  final Duration medianResponseTime;

  /// Resposta mais rápida
  final Duration fastestResponseTime;

  /// Resposta mais lenta
  final Duration slowestResponseTime;

  /// Tempo de resposta por prioridade
  final Map<String, Duration> responseTimeByPriority;

  /// Distribuição de tempos de resposta
  final Map<String, int> responseTimeDistribution;

  @override
  List<Object?> get props => [
        averageResponseTime,
        medianResponseTime,
        fastestResponseTime,
        slowestResponseTime,
        responseTimeByPriority,
        responseTimeDistribution,
      ];
}

/// Métricas de violações
class ViolationMetrics extends Equatable {
  const ViolationMetrics({
    required this.totalViolations,
    required this.violationRate,
    required this.violationsByPriority,
    required this.violationsByReason,
    required this.averageDelayTime,
    required this.totalDelayTime,
  });

  /// Total de violações
  final int totalViolations;

  /// Taxa de violação (0.0 - 1.0)
  final double violationRate;

  /// Violações por prioridade
  final Map<String, int> violationsByPriority;

  /// Violações por motivo
  final Map<String, int> violationsByReason;

  /// Tempo médio de atraso
  final Duration averageDelayTime;

  /// Tempo total de atraso
  final Duration totalDelayTime;

  @override
  List<Object?> get props => [
        totalViolations,
        violationRate,
        violationsByPriority,
        violationsByReason,
        averageDelayTime,
        totalDelayTime,
      ];
}

/// Métricas de escalação
class EscalationMetrics extends Equatable {
  const EscalationMetrics({
    required this.totalEscalations,
    required this.escalationRate,
    required this.escalationsByLevel,
    required this.averageEscalationTime,
    required this.resolvedEscalations,
  });

  /// Total de escalações
  final int totalEscalations;

  /// Taxa de escalação (0.0 - 1.0)
  final double escalationRate;

  /// Escalações por nível
  final Map<int, int> escalationsByLevel;

  /// Tempo médio até escalação
  final Duration averageEscalationTime;

  /// Escalações resolvidas
  final int resolvedEscalations;

  @override
  List<Object?> get props => [
        totalEscalations,
        escalationRate,
        escalationsByLevel,
        averageEscalationTime,
        resolvedEscalations,
      ];
}

/// Dados de tendências
class TrendsData extends Equatable {
  const TrendsData({
    required this.complianceTrend,
    required this.violationTrend,
    required this.performanceTrend,
    required this.volumeTrend,
  });

  /// Tendência de compliance
  final List<DataPoint> complianceTrend;

  /// Tendência de violações
  final List<DataPoint> violationTrend;

  /// Tendência de performance
  final List<DataPoint> performanceTrend;

  /// Tendência de volume
  final List<DataPoint> volumeTrend;

  @override
  List<Object?> get props => [
        complianceTrend,
        violationTrend,
        performanceTrend,
        volumeTrend,
      ];
}

/// Ponto de dados para tendências
class DataPoint extends Equatable {
  const DataPoint({
    required this.timestamp,
    required this.value,
    this.metadata,
  });

  /// Timestamp do ponto
  final DateTime timestamp;

  /// Valor do ponto
  final double value;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [timestamp, value, metadata];
}

/// Métricas por advogado
class LawyerMetrics extends Equatable {
  const LawyerMetrics({
    required this.lawyerId,
    required this.lawyerName,
    required this.totalCases,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.violations,
    required this.escalations,
  });

  /// ID do advogado
  final String lawyerId;

  /// Nome do advogado
  final String lawyerName;

  /// Total de casos
  final int totalCases;

  /// Taxa de compliance
  final double complianceRate;

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Número de violações
  final int violations;

  /// Número de escalações
  final int escalations;

  @override
  List<Object?> get props => [
        lawyerId,
        lawyerName,
        totalCases,
        complianceRate,
        averageResponseTime,
        violations,
        escalations,
      ];
}

/// Métricas por cliente
class ClientMetrics extends Equatable {
  const ClientMetrics({
    required this.clientId,
    required this.clientName,
    required this.totalCases,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.violations,
  });

  /// ID do cliente
  final String clientId;

  /// Nome do cliente
  final String clientName;

  /// Total de casos
  final int totalCases;

  /// Taxa de compliance
  final double complianceRate;

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Número de violações
  final int violations;

  @override
  List<Object?> get props => [
        clientId,
        clientName,
        totalCases,
        complianceRate,
        averageResponseTime,
        violations,
      ];
}

/// Métricas por tipo de caso
class CaseTypeMetrics extends Equatable {
  const CaseTypeMetrics({
    required this.caseType,
    required this.totalCases,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.violations,
  });

  /// Tipo de caso
  final String caseType;

  /// Total de casos
  final int totalCases;

  /// Taxa de compliance
  final double complianceRate;

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Número de violações
  final int violations;

  @override
  List<Object?> get props => [
        caseType,
        totalCases,
        complianceRate,
        averageResponseTime,
        violations,
      ];
}

/// Alerta de SLA
class SlaAlert extends Equatable {
  const SlaAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.value,
    this.metadata,
  });

  /// Tipo do alerta
  final SlaAlertType type;

  /// Severidade do alerta
  final SlaAlertSeverity severity;

  /// Mensagem do alerta
  final String message;

  /// Valor relacionado
  final double value;

  /// Metadados do alerta
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [type, severity, message, value, metadata];
}

/// Status geral de SLA
enum SlaStatus {
  /// Excelente (95%+)
  excellent,
  
  /// Bom (85-94%)
  good,
  
  /// Aceitável (70-84%)
  acceptable,
  
  /// Ruim (50-69%)
  poor,
  
  /// Crítico (<50%)
  critical,
}

/// Tipos de alerta
enum SlaAlertType {
  /// Compliance baixo
  lowCompliance,
  
  /// Muitas violações
  highViolations,
  
  /// Escalações frequentes
  frequentEscalations,
  
  /// Performance degradando
  performanceDegrading,
  
  /// Tempo de resposta alto
  highResponseTime,
}

/// Severidade do alerta
enum SlaAlertSeverity {
  /// Informação
  info,
  
  /// Aviso
  warning,
  
  /// Crítico
  critical,
} 

/// Entidade que representa métricas de SLA
/// 
/// Contém todas as métricas, analytics e dados estatísticos
/// relacionados ao desempenho de SLA da firma
class SlaMetricsEntity extends Equatable {
  const SlaMetricsEntity({
    required this.id,
    required this.firmId,
    required this.periodStart,
    required this.periodEnd,
    required this.complianceMetrics,
    required this.performanceMetrics,
    required this.violationMetrics,
    required this.escalationMetrics,
    required this.trendsData,
    required this.generatedAt,
    this.lawyerMetrics,
    this.clientMetrics,
    this.caseTypeMetrics,
    this.customMetrics,
    this.metadata,
  });

  /// ID único das métricas
  final String id;

  /// ID da firma
  final String firmId;

  /// Início do período analisado
  final DateTime periodStart;

  /// Fim do período analisado
  final DateTime periodEnd;

  /// Métricas de compliance
  final ComplianceMetrics complianceMetrics;

  /// Métricas de performance
  final PerformanceMetrics performanceMetrics;

  /// Métricas de violações
  final ViolationMetrics violationMetrics;

  /// Métricas de escalação
  final EscalationMetrics escalationMetrics;

  /// Dados de tendências
  final TrendsData trendsData;

  /// Data de geração das métricas
  final DateTime generatedAt;

  /// Métricas por advogado
  final Map<String, LawyerMetrics>? lawyerMetrics;

  /// Métricas por cliente
  final Map<String, ClientMetrics>? clientMetrics;

  /// Métricas por tipo de caso
  final Map<String, CaseTypeMetrics>? caseTypeMetrics;

  /// Métricas customizadas
  final Map<String, dynamic>? customMetrics;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  /// Calcula a duração do período em dias
  int get periodDurationDays {
    return periodEnd.difference(periodStart).inDays + 1;
  }

  /// Verifica se as métricas estão atualizadas (menos de 1 hora)
  bool get isUpToDate {
    final now = DateTime.now();
    return now.difference(generatedAt).inHours < 1;
  }

  /// Obtém o score geral de SLA (0-100)
  double get overallSlaScore {
    double complianceWeight = 0.4;
    double performanceWeight = 0.3;
    double violationWeight = 0.2;
    double escalationWeight = 0.1;

    double complianceScore = complianceMetrics.overallRate * 100;
    double performanceScore = _calculatePerformanceScore();
    double violationScore = _calculateViolationScore();
    double escalationScore = _calculateEscalationScore();

    return (complianceScore * complianceWeight +
            performanceScore * performanceWeight +
            violationScore * violationWeight +
            escalationScore * escalationWeight);
  }

  /// Obtém o status geral baseado no score
  SlaStatus get overallStatus {
    final score = overallSlaScore;
    if (score >= 95) return SlaStatus.excellent;
    if (score >= 85) return SlaStatus.good;
    if (score >= 70) return SlaStatus.acceptable;
    if (score >= 50) return SlaStatus.poor;
    return SlaStatus.critical;
  }

  /// Identifica áreas que precisam de atenção
  List<SlaAlert> get alerts {
    List<SlaAlert> alerts = [];

    // Compliance baixo
    if (complianceMetrics.overallRate < 0.8) {
      alerts.add(SlaAlert(
        type: SlaAlertType.lowCompliance,
        severity: complianceMetrics.overallRate < 0.6 ? 
                  SlaAlertSeverity.critical : SlaAlertSeverity.warning,
        message: 'Taxa de compliance SLA baixa: ${(complianceMetrics.overallRate * 100).toStringAsFixed(1)}%',
        value: complianceMetrics.overallRate,
      ));
    }

    // Muitas violações
    if (violationMetrics.totalViolations > periodDurationDays * 2) {
      alerts.add(SlaAlert(
        type: SlaAlertType.highViolations,
        severity: SlaAlertSeverity.warning,
        message: 'Alto número de violações: ${violationMetrics.totalViolations}',
        value: violationMetrics.totalViolations.toDouble(),
      ));
    }

    // Muitas escalações
    if (escalationMetrics.totalEscalations > periodDurationDays) {
      alerts.add(SlaAlert(
        type: SlaAlertType.frequentEscalations,
        severity: SlaAlertSeverity.warning,
        message: 'Escalações frequentes: ${escalationMetrics.totalEscalations}',
        value: escalationMetrics.totalEscalations.toDouble(),
      ));
    }

    // Performance degradando
    if (trendsData.complianceTrend.isNotEmpty && 
        trendsData.complianceTrend.length >= 2) {
      final latest = trendsData.complianceTrend.last.value;
      final previous = trendsData.complianceTrend[trendsData.complianceTrend.length - 2].value;
      
      if (latest < previous - 0.1) {
        alerts.add(SlaAlert(
          type: SlaAlertType.performanceDegrading,
          severity: SlaAlertSeverity.info,
          message: 'Performance SLA em declínio',
          value: latest - previous,
        ));
      }
    }

    return alerts;
  }

  double _calculatePerformanceScore() {
    // Score baseado no tempo médio de resposta vs. SLA
    final avgResponseHours = performanceMetrics.averageResponseTime.inHours;
    const maxSlaHours = 48; // Assumindo SLA padrão de 48h
    
    if (avgResponseHours <= maxSlaHours * 0.5) return 100;
    if (avgResponseHours <= maxSlaHours * 0.7) return 85;
    if (avgResponseHours <= maxSlaHours * 0.9) return 70;
    if (avgResponseHours <= maxSlaHours) return 50;
    return 25;
  }

  double _calculateViolationScore() {
    // Score inverso baseado na taxa de violação
    final violationRate = violationMetrics.violationRate;
    return (1 - violationRate) * 100;
  }

  double _calculateEscalationScore() {
    // Score baseado na taxa de escalação
    final escalationRate = escalationMetrics.escalationRate;
    if (escalationRate <= 0.05) return 100;
    if (escalationRate <= 0.1) return 85;
    if (escalationRate <= 0.2) return 70;
    if (escalationRate <= 0.3) return 50;
    return 25;
  }

  /// Cria uma cópia com modificações
  SlaMetricsEntity copyWith({
    String? id,
    String? firmId,
    DateTime? periodStart,
    DateTime? periodEnd,
    ComplianceMetrics? complianceMetrics,
    PerformanceMetrics? performanceMetrics,
    ViolationMetrics? violationMetrics,
    EscalationMetrics? escalationMetrics,
    TrendsData? trendsData,
    DateTime? generatedAt,
    Map<String, LawyerMetrics>? lawyerMetrics,
    Map<String, ClientMetrics>? clientMetrics,
    Map<String, CaseTypeMetrics>? caseTypeMetrics,
    Map<String, dynamic>? customMetrics,
    Map<String, dynamic>? metadata,
  }) {
    return SlaMetricsEntity(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      complianceMetrics: complianceMetrics ?? this.complianceMetrics,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      violationMetrics: violationMetrics ?? this.violationMetrics,
      escalationMetrics: escalationMetrics ?? this.escalationMetrics,
      trendsData: trendsData ?? this.trendsData,
      generatedAt: generatedAt ?? this.generatedAt,
      lawyerMetrics: lawyerMetrics ?? this.lawyerMetrics,
      clientMetrics: clientMetrics ?? this.clientMetrics,
      caseTypeMetrics: caseTypeMetrics ?? this.caseTypeMetrics,
      customMetrics: customMetrics ?? this.customMetrics,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firmId,
        periodStart,
        periodEnd,
        complianceMetrics,
        performanceMetrics,
        violationMetrics,
        escalationMetrics,
        trendsData,
        generatedAt,
        lawyerMetrics,
        clientMetrics,
        caseTypeMetrics,
        customMetrics,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaMetricsEntity('
        'id: $id, '
        'firmId: $firmId, '
        'period: ${periodStart.day}/${periodStart.month} - ${periodEnd.day}/${periodEnd.month}, '
        'overallScore: ${overallSlaScore.toStringAsFixed(1)}, '
        'status: $overallStatus'
        ')';
  }
}

/// Métricas de compliance
class ComplianceMetrics extends Equatable {
  const ComplianceMetrics({
    required this.overallRate,
    required this.byPriority,
    required this.totalCases,
    required this.compliantCases,
    required this.nonCompliantCases,
  });

  /// Taxa geral de compliance (0.0 - 1.0)
  final double overallRate;

  /// Taxa de compliance por prioridade
  final Map<String, double> byPriority;

  /// Total de casos no período
  final int totalCases;

  /// Casos em compliance
  final int compliantCases;

  /// Casos fora de compliance
  final int nonCompliantCases;

  @override
  List<Object?> get props => [
        overallRate,
        byPriority,
        totalCases,
        compliantCases,
        nonCompliantCases,
      ];
}

/// Métricas de performance
class PerformanceMetrics extends Equatable {
  const PerformanceMetrics({
    required this.averageResponseTime,
    required this.medianResponseTime,
    required this.fastestResponseTime,
    required this.slowestResponseTime,
    required this.responseTimeByPriority,
    required this.responseTimeDistribution,
  });

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Tempo mediano de resposta
  final Duration medianResponseTime;

  /// Resposta mais rápida
  final Duration fastestResponseTime;

  /// Resposta mais lenta
  final Duration slowestResponseTime;

  /// Tempo de resposta por prioridade
  final Map<String, Duration> responseTimeByPriority;

  /// Distribuição de tempos de resposta
  final Map<String, int> responseTimeDistribution;

  @override
  List<Object?> get props => [
        averageResponseTime,
        medianResponseTime,
        fastestResponseTime,
        slowestResponseTime,
        responseTimeByPriority,
        responseTimeDistribution,
      ];
}

/// Métricas de violações
class ViolationMetrics extends Equatable {
  const ViolationMetrics({
    required this.totalViolations,
    required this.violationRate,
    required this.violationsByPriority,
    required this.violationsByReason,
    required this.averageDelayTime,
    required this.totalDelayTime,
  });

  /// Total de violações
  final int totalViolations;

  /// Taxa de violação (0.0 - 1.0)
  final double violationRate;

  /// Violações por prioridade
  final Map<String, int> violationsByPriority;

  /// Violações por motivo
  final Map<String, int> violationsByReason;

  /// Tempo médio de atraso
  final Duration averageDelayTime;

  /// Tempo total de atraso
  final Duration totalDelayTime;

  @override
  List<Object?> get props => [
        totalViolations,
        violationRate,
        violationsByPriority,
        violationsByReason,
        averageDelayTime,
        totalDelayTime,
      ];
}

/// Métricas de escalação
class EscalationMetrics extends Equatable {
  const EscalationMetrics({
    required this.totalEscalations,
    required this.escalationRate,
    required this.escalationsByLevel,
    required this.averageEscalationTime,
    required this.resolvedEscalations,
  });

  /// Total de escalações
  final int totalEscalations;

  /// Taxa de escalação (0.0 - 1.0)
  final double escalationRate;

  /// Escalações por nível
  final Map<int, int> escalationsByLevel;

  /// Tempo médio até escalação
  final Duration averageEscalationTime;

  /// Escalações resolvidas
  final int resolvedEscalations;

  @override
  List<Object?> get props => [
        totalEscalations,
        escalationRate,
        escalationsByLevel,
        averageEscalationTime,
        resolvedEscalations,
      ];
}

/// Dados de tendências
class TrendsData extends Equatable {
  const TrendsData({
    required this.complianceTrend,
    required this.violationTrend,
    required this.performanceTrend,
    required this.volumeTrend,
  });

  /// Tendência de compliance
  final List<DataPoint> complianceTrend;

  /// Tendência de violações
  final List<DataPoint> violationTrend;

  /// Tendência de performance
  final List<DataPoint> performanceTrend;

  /// Tendência de volume
  final List<DataPoint> volumeTrend;

  @override
  List<Object?> get props => [
        complianceTrend,
        violationTrend,
        performanceTrend,
        volumeTrend,
      ];
}

/// Ponto de dados para tendências
class DataPoint extends Equatable {
  const DataPoint({
    required this.timestamp,
    required this.value,
    this.metadata,
  });

  /// Timestamp do ponto
  final DateTime timestamp;

  /// Valor do ponto
  final double value;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [timestamp, value, metadata];
}

/// Métricas por advogado
class LawyerMetrics extends Equatable {
  const LawyerMetrics({
    required this.lawyerId,
    required this.lawyerName,
    required this.totalCases,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.violations,
    required this.escalations,
  });

  /// ID do advogado
  final String lawyerId;

  /// Nome do advogado
  final String lawyerName;

  /// Total de casos
  final int totalCases;

  /// Taxa de compliance
  final double complianceRate;

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Número de violações
  final int violations;

  /// Número de escalações
  final int escalations;

  @override
  List<Object?> get props => [
        lawyerId,
        lawyerName,
        totalCases,
        complianceRate,
        averageResponseTime,
        violations,
        escalations,
      ];
}

/// Métricas por cliente
class ClientMetrics extends Equatable {
  const ClientMetrics({
    required this.clientId,
    required this.clientName,
    required this.totalCases,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.violations,
  });

  /// ID do cliente
  final String clientId;

  /// Nome do cliente
  final String clientName;

  /// Total de casos
  final int totalCases;

  /// Taxa de compliance
  final double complianceRate;

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Número de violações
  final int violations;

  @override
  List<Object?> get props => [
        clientId,
        clientName,
        totalCases,
        complianceRate,
        averageResponseTime,
        violations,
      ];
}

/// Métricas por tipo de caso
class CaseTypeMetrics extends Equatable {
  const CaseTypeMetrics({
    required this.caseType,
    required this.totalCases,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.violations,
  });

  /// Tipo de caso
  final String caseType;

  /// Total de casos
  final int totalCases;

  /// Taxa de compliance
  final double complianceRate;

  /// Tempo médio de resposta
  final Duration averageResponseTime;

  /// Número de violações
  final int violations;

  @override
  List<Object?> get props => [
        caseType,
        totalCases,
        complianceRate,
        averageResponseTime,
        violations,
      ];
}

/// Alerta de SLA
class SlaAlert extends Equatable {
  const SlaAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.value,
    this.metadata,
  });

  /// Tipo do alerta
  final SlaAlertType type;

  /// Severidade do alerta
  final SlaAlertSeverity severity;

  /// Mensagem do alerta
  final String message;

  /// Valor relacionado
  final double value;

  /// Metadados do alerta
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [type, severity, message, value, metadata];
}

/// Status geral de SLA
enum SlaStatus {
  /// Excelente (95%+)
  excellent,
  
  /// Bom (85-94%)
  good,
  
  /// Aceitável (70-84%)
  acceptable,
  
  /// Ruim (50-69%)
  poor,
  
  /// Crítico (<50%)
  critical,
}

/// Tipos de alerta
enum SlaAlertType {
  /// Compliance baixo
  lowCompliance,
  
  /// Muitas violações
  highViolations,
  
  /// Escalações frequentes
  frequentEscalations,
  
  /// Performance degradando
  performanceDegrading,
  
  /// Tempo de resposta alto
  highResponseTime,
}

/// Severidade do alerta
enum SlaAlertSeverity {
  /// Informação
  info,
  
  /// Aviso
  warning,
  
  /// Crítico
  critical,
} 