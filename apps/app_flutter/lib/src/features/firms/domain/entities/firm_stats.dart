import 'package:equatable/equatable.dart';

/// Entidade de domínio representando estatísticas agregadas dos escritórios
/// 
/// Esta entidade contém métricas gerais sobre o ecossistema de escritórios
/// na plataforma, úteis para dashboards e análises.
class FirmStats extends Equatable {
  const FirmStats({
    required this.totalFirms,
    required this.totalLawyers,
    required this.averageTeamSize,
    required this.averageSuccessRate,
    required this.averageNps,
    required this.averageReputationScore,
    required this.totalActiveCases,
    required this.largeFirmsCount,
    required this.updatedAt,
  });

  /// Número total de escritórios cadastrados
  final int totalFirms;

  /// Número total de advogados associados a escritórios
  final int totalLawyers;

  /// Tamanho médio das equipes dos escritórios
  final double averageTeamSize;

  /// Taxa média de sucesso dos escritórios
  final double averageSuccessRate;

  /// NPS médio dos escritórios
  final double averageNps;

  /// Score médio de reputação dos escritórios
  final double averageReputationScore;

  /// Número total de casos ativos em todos os escritórios
  final int totalActiveCases;

  /// Número de escritórios de grande porte (50+ advogados)
  final int largeFirmsCount;

  /// Data da última atualização das estatísticas
  final DateTime updatedAt;

  /// Percentual de escritórios de grande porte
  double get largeFirmsPercentage => 
      totalFirms > 0 ? (largeFirmsCount / totalFirms) * 100 : 0;

  /// Taxa média de sucesso em percentual
  double get averageSuccessRatePercentage => averageSuccessRate * 100;

  /// NPS médio em percentual
  double get averageNpsPercentage => averageNps * 100;

  /// Score médio de reputação em percentual
  double get averageReputationPercentage => averageReputationScore * 100;

  /// Média de casos ativos por escritório
  double get averageActiveCasesPerFirm => 
      totalFirms > 0 ? totalActiveCases / totalFirms : 0;

  /// Média de advogados por escritório
  double get averageLawyersPerFirm => 
      totalFirms > 0 ? totalLawyers / totalFirms : 0;

  @override
  List<Object?> get props => [
        totalFirms,
        totalLawyers,
        averageTeamSize,
        averageSuccessRate,
        averageNps,
        averageReputationScore,
        totalActiveCases,
        largeFirmsCount,
        updatedAt,
      ];

  @override
  String toString() {
    return 'FirmStats(totalFirms: $totalFirms, totalLawyers: $totalLawyers, averageTeamSize: ${averageTeamSize.toStringAsFixed(1)}, averageSuccessRate: ${averageSuccessRatePercentage.toStringAsFixed(1)}%)';
  }

  /// Cria uma cópia da entidade com campos atualizados
  FirmStats copyWith({
    int? totalFirms,
    int? totalLawyers,
    double? averageTeamSize,
    double? averageSuccessRate,
    double? averageNps,
    double? averageReputationScore,
    int? totalActiveCases,
    int? largeFirmsCount,
    DateTime? updatedAt,
  }) {
    return FirmStats(
      totalFirms: totalFirms ?? this.totalFirms,
      totalLawyers: totalLawyers ?? this.totalLawyers,
      averageTeamSize: averageTeamSize ?? this.averageTeamSize,
      averageSuccessRate: averageSuccessRate ?? this.averageSuccessRate,
      averageNps: averageNps ?? this.averageNps,
      averageReputationScore: averageReputationScore ?? this.averageReputationScore,
      totalActiveCases: totalActiveCases ?? this.totalActiveCases,
      largeFirmsCount: largeFirmsCount ?? this.largeFirmsCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 