import 'package:equatable/equatable.dart';

/// Entidade que representa tendências de performance SLA
/// 
/// Contém dados históricos, análises de tendência e
/// previsões de performance futura
class SlaPerformanceTrendsEntity extends Equatable {
  const SlaPerformanceTrendsEntity({
    required this.firmId,
    required this.periodStart,
    required this.periodEnd,
    required this.granularity,
    required this.dataPoints,
    required this.overallTrend,
    required this.metrics,
    required this.seasonalPatterns,
    required this.anomalies,
    required this.generatedAt,
    this.forecasting,
    this.correlations,
    this.metadata,
  });

  /// ID da firma
  final String firmId;

  /// Data de início do período
  final DateTime periodStart;

  /// Data de fim do período
  final DateTime periodEnd;

  /// Granularidade dos dados
  final String granularity;

  /// Pontos de dados temporais
  final List<PerformanceDataPoint> dataPoints;

  /// Tendência geral do período
  final TrendDirection overallTrend;

  /// Métricas agregadas por tipo
  final Map<String, MetricTrend> metrics;

  /// Padrões sazonais identificados
  final SeasonalPatterns seasonalPatterns;

  /// Anomalias detectadas
  final List<PerformanceAnomaly> anomalies;

  /// Data de geração da análise
  final DateTime generatedAt;

  /// Dados de previsão (opcional)
  final ForecastingData? forecasting;

  /// Correlações entre métricas
  final Map<String, double>? correlations;

  /// Metadados da análise
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        firmId,
        periodStart,
        periodEnd,
        granularity,
        dataPoints,
        overallTrend,
        metrics,
        seasonalPatterns,
        anomalies,
        generatedAt,
        forecasting,
        correlations,
        metadata,
      ];

  /// Performance score média do período
  double get averagePerformanceScore {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints.map((p) => p.performanceScore).reduce((a, b) => a + b) / dataPoints.length;
  }

  /// Volatilidade da performance (desvio padrão)
  double get performanceVolatility {
    if (dataPoints.length < 2) return 0.0;
    
    final scores = dataPoints.map((p) => p.performanceScore).toList();
    final mean = averagePerformanceScore;
    final variance = scores.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) / scores.length;
    
    return variance;
  }

  /// Identificar métricas em melhoria
  List<String> get improvingMetrics {
    return metrics.entries
        .where((entry) => entry.value.direction == TrendDirection.improving)
        .map((entry) => entry.key)
        .toList();
  }

  /// Identificar métricas em declínio
  List<String> get decliningMetrics {
    return metrics.entries
        .where((entry) => entry.value.direction == TrendDirection.declining)
        .map((entry) => entry.key)
        .toList();
  }

  /// Calcular taxa de crescimento médio
  double get averageGrowthRate {
    if (dataPoints.length < 2) return 0.0;
    
    final first = dataPoints.first.performanceScore;
    final last = dataPoints.last.performanceScore;
    final periods = dataPoints.length - 1;
    
    if (first == 0) return 0.0;
    return ((last / first) - 1) / periods;
  }

  /// Cria cópia com modificações
  SlaPerformanceTrendsEntity copyWith({
    String? firmId,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? granularity,
    List<PerformanceDataPoint>? dataPoints,
    TrendDirection? overallTrend,
    Map<String, MetricTrend>? metrics,
    SeasonalPatterns? seasonalPatterns,
    List<PerformanceAnomaly>? anomalies,
    DateTime? generatedAt,
    ForecastingData? forecasting,
    Map<String, double>? correlations,
    Map<String, dynamic>? metadata,
  }) {
    return SlaPerformanceTrendsEntity(
      firmId: firmId ?? this.firmId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      granularity: granularity ?? this.granularity,
      dataPoints: dataPoints ?? this.dataPoints,
      overallTrend: overallTrend ?? this.overallTrend,
      metrics: metrics ?? this.metrics,
      seasonalPatterns: seasonalPatterns ?? this.seasonalPatterns,
      anomalies: anomalies ?? this.anomalies,
      generatedAt: generatedAt ?? this.generatedAt,
      forecasting: forecasting ?? this.forecasting,
      correlations: correlations ?? this.correlations,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Ponto de dados de performance temporal
class PerformanceDataPoint extends Equatable {
  const PerformanceDataPoint({
    required this.timestamp,
    required this.complianceRate,
    required this.averageResponseTime,
    required this.totalCases,
    required this.violationCount,
    required this.performanceScore,
    this.customMetrics,
  });

  final DateTime timestamp;
  final double complianceRate;
  final double averageResponseTime;
  final int totalCases;
  final int violationCount;
  final double performanceScore;
  final Map<String, double>? customMetrics;

  @override
  List<Object?> get props => [
        timestamp,
        complianceRate,
        averageResponseTime,
        totalCases,
        violationCount,
        performanceScore,
        customMetrics,
      ];
}

/// Direção de tendência
enum TrendDirection {
  improving,
  stable,
  declining,
  volatile,
}

/// Tendência de uma métrica específica
class MetricTrend extends Equatable {
  const MetricTrend({
    required this.metricName,
    required this.direction,
    required this.changeRate,
    required this.confidence,
    required this.significance,
  });

  final String metricName;
  final TrendDirection direction;
  final double changeRate; // % de mudança por período
  final double confidence; // 0.0 a 1.0
  final String significance; // 'low', 'medium', 'high'

  @override
  List<Object> get props => [metricName, direction, changeRate, confidence, significance];
}

/// Padrões sazonais identificados
class SeasonalPatterns extends Equatable {
  const SeasonalPatterns({
    required this.hasSeasonality,
    this.weeklyPattern,
    this.monthlyPattern,
    this.quarterlyPattern,
    this.yearlyPattern,
  });

  final bool hasSeasonality;
  final Map<int, double>? weeklyPattern; // 1-7 (segunda a domingo)
  final Map<int, double>? monthlyPattern; // 1-31 (dias do mês)
  final Map<int, double>? quarterlyPattern; // 1-4 (trimestres)
  final Map<int, double>? yearlyPattern; // 1-12 (meses do ano)

  @override
  List<Object?> get props => [
        hasSeasonality,
        weeklyPattern,
        monthlyPattern,
        quarterlyPattern,
        yearlyPattern,
      ];
}

/// Anomalia de performance detectada
class PerformanceAnomaly extends Equatable {
  const PerformanceAnomaly({
    required this.timestamp,
    required this.metricName,
    required this.expectedValue,
    required this.actualValue,
    required this.severity,
    required this.confidence,
    this.possibleCauses,
    this.description,
  });

  final DateTime timestamp;
  final String metricName;
  final double expectedValue;
  final double actualValue;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final double confidence;
  final List<String>? possibleCauses;
  final String? description;

  /// Desvio percentual da anomalia
  double get deviationPercentage {
    if (expectedValue == 0) return 0.0;
    return ((actualValue - expectedValue) / expectedValue) * 100;
  }

  @override
  List<Object?> get props => [
        timestamp,
        metricName,
        expectedValue,
        actualValue,
        severity,
        confidence,
        possibleCauses,
        description,
      ];
}

/// Dados de previsão
class ForecastingData extends Equatable {
  const ForecastingData({
    required this.method,
    required this.forecastPeriod,
    required this.predictions,
    required this.confidenceIntervals,
    required this.accuracy,
  });

  final String method; // 'linear', 'exponential', 'arima', 'lstm'
  final int forecastPeriod;
  final List<ForecastPoint> predictions;
  final Map<double, List<double>> confidenceIntervals; // confidence level -> [lower, upper]
  final double accuracy; // 0.0 a 1.0

  @override
  List<Object> get props => [method, forecastPeriod, predictions, confidenceIntervals, accuracy];
}

/// Ponto de previsão
class ForecastPoint extends Equatable {
  const ForecastPoint({
    required this.timestamp,
    required this.predictedValue,
    required this.confidence,
    this.lowerBound,
    this.upperBound,
  });

  final DateTime timestamp;
  final double predictedValue;
  final double confidence;
  final double? lowerBound;
  final double? upperBound;

  @override
  List<Object?> get props => [timestamp, predictedValue, confidence, lowerBound, upperBound];
}