import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/firm_stats.dart';

part 'firm_stats_model.g.dart';

/// Modelo de dados para serialização JSON da entidade FirmStats
/// 
/// Este modelo é responsável por converter os dados da API REST
/// para a entidade de domínio e vice-versa.
@JsonSerializable()
class FirmStatsModel extends FirmStats {
  const FirmStatsModel({
    required super.totalFirms,
    required super.totalLawyers,
    required super.averageTeamSize,
    required super.averageSuccessRate,
    required super.averageNps,
    required super.averageReputationScore,
    required super.totalActiveCases,
    required super.largeFirmsCount,
    required super.updatedAt,
  });

  /// Cria uma instância a partir de um Map JSON
  factory FirmStatsModel.fromJson(Map<String, dynamic> json) => _$FirmStatsModelFromJson(json);

  /// Converte a instância para um Map JSON
  Map<String, dynamic> toJson() => _$FirmStatsModelToJson(this);

  /// Converte o modelo para a entidade de domínio
  FirmStats toEntity() {
    return FirmStats(
      totalFirms: totalFirms,
      totalLawyers: totalLawyers,
      averageTeamSize: averageTeamSize,
      averageSuccessRate: averageSuccessRate,
      averageNps: averageNps,
      averageReputationScore: averageReputationScore,
      totalActiveCases: totalActiveCases,
      largeFirmsCount: largeFirmsCount,
      updatedAt: updatedAt,
    );
  }

  /// Cria um modelo a partir da entidade de domínio
  factory FirmStatsModel.fromEntity(FirmStats entity) {
    return FirmStatsModel(
      totalFirms: entity.totalFirms,
      totalLawyers: entity.totalLawyers,
      averageTeamSize: entity.averageTeamSize,
      averageSuccessRate: entity.averageSuccessRate,
      averageNps: entity.averageNps,
      averageReputationScore: entity.averageReputationScore,
      totalActiveCases: entity.totalActiveCases,
      largeFirmsCount: entity.largeFirmsCount,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FirmStatsModel(totalFirms: $totalFirms, totalLawyers: $totalLawyers, averageTeamSize: ${averageTeamSize.toStringAsFixed(1)}, averageSuccessRate: ${averageSuccessRatePercentage.toStringAsFixed(1)}%)';
  }
} 