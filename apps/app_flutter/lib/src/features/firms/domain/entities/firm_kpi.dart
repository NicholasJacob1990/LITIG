import 'package:equatable/equatable.dart';

/// Entidade de domínio representando os KPIs agregados de um escritório
/// 
/// Esta entidade contém métricas de performance e reputação do escritório,
/// utilizadas pelo algoritmo de matching B2B (Feature-E).

const double defaultMaturityIndex = 0.5;

class FirmKPI extends Equatable {
  const FirmKPI({
    required this.firmId,
    required this.successRate,
    required this.nps,
    required this.reputationScore,
    required this.diversityIndex,
    required this.activeCases,
    required this.updatedAt,
    this.maturityIndex,
  }) : assert(nps >= -1.0 && nps <= 1.0, 'NPS must be between -1.0 and 1.0');

  /// ID do escritório ao qual estes KPIs pertencem
  final String firmId;

  /// Taxa de sucesso do escritório (0.0 a 1.0)
  final double successRate;

  /// Net Promoter Score do escritório (-1.0 a 1.0)
  final double nps;

  /// Score de reputação no mercado (0.0 a 1.0)
  final double reputationScore;

  /// Índice de diversidade corporativa (0.0 a 1.0)
  final double diversityIndex;

  /// Número de casos ativos do escritório
  final int activeCases;

  /// Índice de maturidade agregado (0.0 a 1.0) - v2.8
  final double? maturityIndex;

  /// Data da última atualização dos KPIs
  final DateTime updatedAt;

  /// Taxa de sucesso em percentual (0-100)
  double get successRatePercentage => successRate * 100;

  /// NPS em percentual (-100 a 100)
  double get npsPercentage => nps * 100;

  /// Score de reputação em percentual (0-100)
  double get reputationPercentage => reputationScore * 100;

  /// Índice de diversidade em percentual (0-100)
  double get diversityPercentage => diversityIndex * 100;

  /// Verifica se o escritório tem alta taxa de sucesso (>= 80%)
  bool get hasHighSuccessRate => successRate >= 0.8;

  /// Verifica se o escritório tem NPS positivo
  bool get hasPositiveNps => nps > 0;

  /// Verifica se o escritório tem alta reputação (>= 85%)
  bool get hasHighReputation => reputationScore >= 0.85;

  /// Score geral do escritório (média ponderada dos KPIs principais)
  double get overallScore {
    return (successRate * 0.35) +
           (((nps + 1) / 2) * 0.20) + // Normalizar NPS de [-1,1] para [0,1]
           (reputationScore * 0.15) +
           (diversityIndex * 0.10) +
           ((maturityIndex ?? defaultMaturityIndex) * 0.20);
  }

  /// Score geral em percentual (0-100)
  double get overallScorePercentage => overallScore * 100;

  @override
  List<Object?> get props => [
        firmId,
        successRate,
        nps,
        reputationScore,
        diversityIndex,
        activeCases,
        maturityIndex,
        updatedAt,
      ];

  @override
  String toString() {
    return 'FirmKPI(firmId: $firmId, successRate: ${successRatePercentage.toStringAsFixed(1)}%, nps: ${npsPercentage.toStringAsFixed(1)}%, overallScore: ${overallScorePercentage.toStringAsFixed(1)}%)';
  }

  /// Cria uma cópia da entidade com campos atualizados
  FirmKPI copyWith({
    String? firmId,
    double? successRate,
    double? nps,
    double? reputationScore,
    double? diversityIndex,
    int? activeCases,
    double? maturityIndex,
    DateTime? updatedAt,
  }) {
    return FirmKPI(
      firmId: firmId ?? this.firmId,
      successRate: successRate ?? this.successRate,
      nps: nps ?? this.nps,
      reputationScore: reputationScore ?? this.reputationScore,
      diversityIndex: diversityIndex ?? this.diversityIndex,
      activeCases: activeCases ?? this.activeCases,
      maturityIndex: maturityIndex ?? this.maturityIndex,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 