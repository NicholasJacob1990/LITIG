import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/firm_kpi.dart';

part 'firm_kpi_model.g.dart';

/// Modelo de dados para serialização JSON da entidade FirmKPI
/// 
/// Este modelo é responsável por converter os dados da API REST
/// para a entidade de domínio e vice-versa.
@JsonSerializable()
class FirmKPIModel {
  const FirmKPIModel({
    required this.firmId,
    required this.successRate,
    required this.nps,
    required this.reputationScore,
    required this.diversityIndex,
    required this.activeCases,
    required this.updatedAt,
    this.maturityIndex,
  });

  final String firmId;
  final double successRate;
  final double nps;
  final double reputationScore;
  final double diversityIndex;
  final int activeCases;
  final DateTime updatedAt;
  final double? maturityIndex;

  /// Cria uma instância a partir de um Map JSON
  factory FirmKPIModel.fromJson(Map<String, dynamic> json) => _$FirmKPIModelFromJson(json);

  /// Converte a instância para um Map JSON
  Map<String, dynamic> toJson() => _$FirmKPIModelToJson(this);

  /// Converte o modelo para a entidade de domínio
  FirmKPI toEntity() {
    return FirmKPI(
      firmId: firmId,
      successRate: successRate,
      nps: nps,
      reputationScore: reputationScore,
      diversityIndex: diversityIndex,
      activeCases: activeCases,
      updatedAt: updatedAt,
      maturityIndex: maturityIndex,
    );
  }

  /// Cria um modelo a partir da entidade de domínio
  factory FirmKPIModel.fromEntity(FirmKPI entity) {
    return FirmKPIModel(
      firmId: entity.firmId,
      successRate: entity.successRate,
      nps: entity.nps,
      reputationScore: entity.reputationScore,
      diversityIndex: entity.diversityIndex,
      activeCases: entity.activeCases,
      updatedAt: entity.updatedAt,
      maturityIndex: entity.maturityIndex,
    );
  }

  /// Cria um modelo com campos atualizados
  FirmKPIModel copyWith({
    String? firmId,
    double? successRate,
    double? nps,
    double? reputationScore,
    double? diversityIndex,
    int? activeCases,
    double? maturityIndex,
    DateTime? updatedAt,
  }) {
    return FirmKPIModel(
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

  @override
  String toString() {
    return 'FirmKPIModel(firmId: $firmId, successRate: $successRate)';
  }
} 