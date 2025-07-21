// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomModel _$ChatRoomModelFromJson(Map<String, dynamic> json) =>
    ChatRoomModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      lawyerId: json['lawyerId'] as String,
      caseId: json['caseId'] as String,
      contractId: json['contractId'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      clientName: json['clientName'] as String,
      lawyerName: json['lawyerName'] as String,
      caseTitle: json['caseTitle'] as String,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChatRoomModelToJson(ChatRoomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'lawyerId': instance.lawyerId,
      'caseId': instance.caseId,
      'contractId': instance.contractId,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'clientName': instance.clientName,
      'lawyerName': instance.lawyerName,
      'caseTitle': instance.caseTitle,
      'unreadCount': instance.unreadCount,
    };
