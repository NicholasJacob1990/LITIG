// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hiring_proposal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HiringProposalModel _$HiringProposalModelFromJson(Map<String, dynamic> json) =>
    HiringProposalModel(
      id: json['id'] as String,
      lawyerId: json['lawyerId'] as String,
      clientId: json['clientId'] as String,
      caseId: json['caseId'] as String,
      contractType: json['contractType'] as String,
      budget: (json['budget'] as num).toDouble(),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      responseMessage: json['responseMessage'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$HiringProposalModelToJson(
        HiringProposalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lawyerId': instance.lawyerId,
      'clientId': instance.clientId,
      'caseId': instance.caseId,
      'contractType': instance.contractType,
      'budget': instance.budget,
      'notes': instance.notes,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'responseMessage': instance.responseMessage,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
