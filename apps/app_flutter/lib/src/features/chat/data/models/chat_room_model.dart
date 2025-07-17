import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/chat_room.dart';

part 'chat_room_model.g.dart';

@JsonSerializable()
class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.clientId,
    required super.lawyerId,
    required super.caseId,
    super.contractId,
    required super.status,
    required super.createdAt,
    super.lastMessageAt,
    required super.clientName,
    required super.lawyerName,
    required super.caseTitle,
    super.unreadCount = 0,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomModelToJson(this);

  factory ChatRoomModel.fromEntity(ChatRoom entity) {
    return ChatRoomModel(
      id: entity.id,
      clientId: entity.clientId,
      lawyerId: entity.lawyerId,
      caseId: entity.caseId,
      contractId: entity.contractId,
      status: entity.status,
      createdAt: entity.createdAt,
      lastMessageAt: entity.lastMessageAt,
      clientName: entity.clientName,
      lawyerName: entity.lawyerName,
      caseTitle: entity.caseTitle,
      unreadCount: entity.unreadCount,
    );
  }

  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      clientId: clientId,
      lawyerId: lawyerId,
      caseId: caseId,
      contractId: contractId,
      status: status,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      clientName: clientName,
      lawyerName: lawyerName,
      caseTitle: caseTitle,
      unreadCount: unreadCount,
    );
  }
}