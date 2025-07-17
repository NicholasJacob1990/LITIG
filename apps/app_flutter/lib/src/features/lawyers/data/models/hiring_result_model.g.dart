// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hiring_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HiringResultModel _$HiringResultModelFromJson(Map<String, dynamic> json) =>
    HiringResultModel(
      proposalId: json['proposalId'] as String,
      contractId: json['contractId'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$HiringResultModelToJson(HiringResultModel instance) =>
    <String, dynamic>{
      'proposalId': instance.proposalId,
      'contractId': instance.contractId,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
    };
