// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'law_firm_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LawFirmModel _$LawFirmModelFromJson(Map<String, dynamic> json) => LawFirmModel(
      id: json['id'] as String,
      name: json['name'] as String,
      teamSize: (json['teamSize'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      mainLat: (json['mainLat'] as num?)?.toDouble(),
      mainLon: (json['mainLon'] as num?)?.toDouble(),
      kpis: json['kpis'] == null
          ? null
          : FirmKPIModel.fromJson(json['kpis'] as Map<String, dynamic>),
      lawyersCount: (json['lawyersCount'] as num?)?.toInt(),
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isBoutique: json['isBoutique'] as bool? ?? false,
    );

Map<String, dynamic> _$LawFirmModelToJson(LawFirmModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'teamSize': instance.teamSize,
      'mainLat': instance.mainLat,
      'mainLon': instance.mainLon,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'kpis': instance.kpis,
      'lawyersCount': instance.lawyersCount,
      'specializations': instance.specializations,
      'rating': instance.rating,
      'isBoutique': instance.isBoutique,
    };
