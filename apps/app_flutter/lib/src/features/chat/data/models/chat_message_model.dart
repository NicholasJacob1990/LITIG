import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_message_model.g.dart';

@JsonSerializable()
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.senderName,
    required super.senderType,
    required super.content,
    required super.messageType,
    super.attachmentUrl,
    required super.createdAt,
    required super.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      roomId: entity.roomId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderType: entity.senderType,
      content: entity.content,
      messageType: entity.messageType,
      attachmentUrl: entity.attachmentUrl,
      createdAt: entity.createdAt,
      isRead: entity.isRead,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      content: content,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}