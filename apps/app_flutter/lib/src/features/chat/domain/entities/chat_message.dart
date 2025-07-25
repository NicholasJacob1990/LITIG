import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String senderType;
  final String content;
  final String messageType;
  final String? attachmentUrl;
  final String? senderAvatarUrl;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.messageType,
    this.attachmentUrl,
    this.senderAvatarUrl,
    required this.createdAt,
    required this.isRead,
  });

  @override
  List<Object?> get props => [
        id,
        roomId,
        senderId,
        senderName,
        senderType,
        content,
        messageType,
        attachmentUrl,
        senderAvatarUrl,
        createdAt,
        isRead,
      ];

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? content,
    String? messageType,
    String? attachmentUrl,
    String? senderAvatarUrl,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isFromCurrentUser => false; // Will be set by BLoC based on current user
}