// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firm_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FirmStatsModel _$FirmStatsModelFromJson(Map<String, dynamic> json) =>
    FirmStatsModel(
      totalFirms: (json['totalFirms'] as num).toInt(),
      totalLawyers: (json['totalLawyers'] as num).toInt(),
      averageTeamSize: (json['averageTeamSize'] as num).toDouble(),
      averageSuccessRate: (json['averageSuccessRate'] as num).toDouble(),
      averageNps: (json['averageNps'] as num).toDouble(),
      averageReputationScore:
          (json['averageReputationScore'] as num).toDouble(),
      totalActiveCases: (json['totalActiveCases'] as num).toInt(),
      largeFirmsCount: (json['largeFirmsCount'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FirmStatsModelToJson(FirmStatsModel instance) =>
    <String, dynamic>{
      'totalFirms': instance.totalFirms,
      'totalLawyers': instance.totalLawyers,
      'averageTeamSize': instance.averageTeamSize,
      'averageSuccessRate': instance.averageSuccessRate,
      'averageNps': instance.averageNps,
      'averageReputationScore': instance.averageReputationScore,
      'totalActiveCases': instance.totalActiveCases,
      'largeFirmsCount': instance.largeFirmsCount,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
