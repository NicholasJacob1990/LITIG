import 'package:equatable/equatable.dart';

class UnifiedChatEntity extends Equatable {
  final String id;
  final String provider;
  final String providerChatId;
  final String chatName;
  final String chatType;
  final String? avatarUrl;
  final List<String> participantIds;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final String? lastMessageId;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final Map<String, dynamic>? metadata;

  const UnifiedChatEntity({
    required this.id,
    required this.provider,
    required this.providerChatId,
    required this.chatName,
    this.chatType = 'direct',
    this.avatarUrl,
    this.participantIds = const [],
    this.lastMessageContent,
    this.lastMessageAt,
    this.lastMessageId,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.metadata,
  });

  UnifiedChatEntity copyWith({
    String? id,
    String? provider,
    String? providerChatId,
    String? chatName,
    String? chatType,
    String? avatarUrl,
    List<String>? participantIds,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    String? lastMessageId,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedChatEntity(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerChatId: providerChatId ?? this.providerChatId,
      chatName: chatName ?? this.chatName,
      chatType: chatType ?? this.chatType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      participantIds: participantIds ?? this.participantIds,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;

  bool get isGroupChat => chatType == 'group' || participantIds.length > 2;

  String get displayName {
    if (chatName.isNotEmpty) return chatName;
    if (participantIds.length == 1) {
      return participantIds.first;
    } else if (participantIds.length > 1) {
      return '${participantIds.take(2).join(', ')}${participantIds.length > 2 ? ' e mais ${participantIds.length - 2}' : ''}';
    }
    return 'Chat sem nome';
  }

  @override
  List<Object?> get props => [
        id,
        provider,
        providerChatId,
        chatName,
        chatType,
        avatarUrl,
        participantIds,
        lastMessageContent,
        lastMessageAt,
        lastMessageId,
        unreadCount,
        isArchived,
        isMuted,
        isPinned,
        metadata,
      ];

  @override
  String toString() {
    return 'UnifiedChatEntity{id: $id, provider: $provider, chatName: $chatName, unreadCount: $unreadCount}';
  }
}