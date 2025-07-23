import 'package:equatable/equatable.dart';

class UnifiedMessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String providerMessageId;
  final String? senderId;
  final String? senderName;
  final String? senderEmail;
  final String? senderAvatarUrl;
  final String messageType;
  final String? content;
  final List<Map<String, dynamic>> attachments;
  final Map<String, List<String>> reactions;
  final bool isOutgoing;
  final bool isRead;
  final bool isDelivered;
  final bool isSent;
  final String? replyToMessageId;
  final String? forwardedFrom;
  final DateTime? editedAt;
  final DateTime sentAt;
  final DateTime? receivedAt;
  final String syncStatus;
  final String? localPath;

  const UnifiedMessageEntity({
    required this.id,
    required this.chatId,
    required this.providerMessageId,
    this.senderId,
    this.senderName,
    this.senderEmail,
    this.senderAvatarUrl,
    this.messageType = 'text',
    this.content,
    this.attachments = const [],
    this.reactions = const {},
    required this.isOutgoing,
    required this.isRead,
    this.isDelivered = false,
    this.isSent = true,
    this.replyToMessageId,
    this.forwardedFrom,
    this.editedAt,
    required this.sentAt,
    this.receivedAt,
    this.syncStatus = 'synced',
    this.localPath,
  });

  UnifiedMessageEntity copyWith({
    String? id,
    String? chatId,
    String? providerMessageId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderAvatarUrl,
    String? messageType,
    String? content,
    List<Map<String, dynamic>>? attachments,
    Map<String, List<String>>? reactions,
    bool? isOutgoing,
    bool? isRead,
    bool? isDelivered,
    bool? isSent,
    String? replyToMessageId,
    String? forwardedFrom,
    DateTime? editedAt,
    DateTime? sentAt,
    DateTime? receivedAt,
    String? syncStatus,
    String? localPath,
  }) {
    return UnifiedMessageEntity(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      providerMessageId: providerMessageId ?? this.providerMessageId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isSent: isSent ?? this.isSent,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      editedAt: editedAt ?? this.editedAt,
      sentAt: sentAt ?? this.sentAt,
      receivedAt: receivedAt ?? this.receivedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localPath: localPath ?? this.localPath,
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;

  bool get hasReactions => reactions.isNotEmpty;

  bool get isEdited => editedAt != null;

  bool get isReply => replyToMessageId != null;

  bool get isForwarded => forwardedFrom != null;

  bool get isPending => syncStatus == 'pending';

  bool get isFailed => syncStatus == 'failed';

  bool get isTextMessage => messageType == 'text';

  bool get isImageMessage => messageType == 'image';

  bool get isVideoMessage => messageType == 'video';

  bool get isAudioMessage => messageType == 'audio';

  bool get isFileMessage => messageType == 'file';

  bool get isLocationMessage => messageType == 'location';

  String get displayContent {
    if (content?.isNotEmpty == true) return content!;
    
    switch (messageType) {
      case 'image':
        return '📷 Imagem';
      case 'video':
        return '🎥 Vídeo';
      case 'audio':
        return '🎵 Áudio';
      case 'file':
        return '📄 Arquivo';
      case 'location':
        return '📍 Localização';
      default:
        return hasAttachments ? '📎 Anexo' : 'Mensagem';
    }
  }

  String? get primaryAttachmentUrl {
    if (attachments.isEmpty) return null;
    return attachments.first['url'] as String?;
  }

  String? get primaryAttachmentType {
    if (attachments.isEmpty) return null;
    return attachments.first['type'] as String?;
  }

  int get totalReactions {
    return reactions.values.fold(0, (sum, userIds) => sum + userIds.length);
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        providerMessageId,
        senderId,
        senderName,
        senderEmail,
        senderAvatarUrl,
        messageType,
        content,
        attachments,
        reactions,
        isOutgoing,
        isRead,
        isDelivered,
        isSent,
        replyToMessageId,
        forwardedFrom,
        editedAt,
        sentAt,
        receivedAt,
        syncStatus,
        localPath,
      ];

  @override
  String toString() {
    return 'UnifiedMessageEntity{id: $id, chatId: $chatId, messageType: $messageType, isOutgoing: $isOutgoing, syncStatus: $syncStatus}';
  }
}