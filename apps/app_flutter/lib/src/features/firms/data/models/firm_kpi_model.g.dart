// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firm_kpi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FirmKPIModel _$FirmKPIModelFromJson(Map<String, dynamic> json) => FirmKPIModel(
      firmId: json['firmId'] as String,
      successRate: (json['successRate'] as num).toDouble(),
      nps: (json['nps'] as num).toDouble(),
      reputationScore: (json['reputationScore'] as num).toDouble(),
      diversityIndex: (json['diversityIndex'] as num).toDouble(),
      activeCases: (json['activeCases'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      maturityIndex: (json['maturityIndex'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FirmKPIModelToJson(FirmKPIModel instance) =>
    <String, dynamic>{
      'firmId': instance.firmId,
      'successRate': instance.successRate,
      'nps': instance.nps,
      'reputationScore': instance.reputationScore,
      'diversityIndex': instance.diversityIndex,
      'activeCases': instance.activeCases,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'maturityIndex': instance.maturityIndex,
    };
