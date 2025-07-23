import 'dart:convert';
import '../database/messaging_database.dart';
import '../../domain/entities/unified_message_entity.dart';
import '../../domain/entities/unified_chat_entity.dart';
import '../../domain/entities/connected_account_entity.dart';

class MessagingCacheRepository {
  final MessagingDatabase _database;

  MessagingCacheRepository(this._database);

  // ===============================
  // ACCOUNT OPERATIONS
  // ===============================

  Future<void> cacheConnectedAccount(ConnectedAccountEntity account) async {
    await _database.insertConnectedAccount({
      'id': account.id,
      'provider': account.provider,
      'account_id': account.accountId,
      'account_name': account.accountName,
      'account_email': account.accountEmail,
      'is_active': account.isActive ? 1 : 0,
      'access_token': account.accessToken,
      'refresh_token': account.refreshToken,
      'token_expires_at': account.tokenExpiresAt?.millisecondsSinceEpoch,
      'last_sync_at': account.lastSyncAt?.millisecondsSinceEpoch,
      'sync_status': account.syncStatus,
      'error_message': account.errorMessage,
    });
  }

  Future<List<ConnectedAccountEntity>> getCachedAccounts() async {
    final accounts = await _database.getConnectedAccounts();
    return accounts.map((account) => _mapToAccountEntity(account)).toList();
  }

  Future<ConnectedAccountEntity?> getCachedAccount(String provider, String accountId) async {
    final account = await _database.getConnectedAccount(provider, accountId);
    return account != null ? _mapToAccountEntity(account) : null;
  }

  Future<void> updateCachedAccount(String id, Map<String, dynamic> updates) async {
    await _database.updateConnectedAccount(id, updates);
  }

  Future<void> removeCachedAccount(String provider, String accountId) async {
    await _database.deleteConnectedAccount(provider, accountId);
  }

  ConnectedAccountEntity _mapToAccountEntity(Map<String, dynamic> data) {
    return ConnectedAccountEntity(
      id: data['id'],
      provider: data['provider'],
      accountId: data['account_id'],
      accountName: data['account_name'],
      accountEmail: data['account_email'],
      isActive: data['is_active'] == 1,
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      tokenExpiresAt: data['token_expires_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['token_expires_at'])
        : null,
      lastSyncAt: data['last_sync_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['last_sync_at'])
        : null,
      syncStatus: data['sync_status'],
      errorMessage: data['error_message'],
    );
  }

  // ===============================
  // CHAT OPERATIONS
  // ===============================

  Future<void> cacheChat(UnifiedChatEntity chat) async {
    await _database.insertChat({
      'id': chat.id,
      'provider': chat.provider,
      'provider_chat_id': chat.providerChatId,
      'chat_name': chat.chatName,
      'chat_type': chat.chatType,
      'chat_avatar_url': chat.avatarUrl,
      'participant_ids': jsonEncode(chat.participantIds),
      'last_message_content': chat.lastMessageContent,
      'last_message_at': chat.lastMessageAt?.millisecondsSinceEpoch,
      'last_message_id': chat.lastMessageId,
      'unread_count': chat.unreadCount,
      'is_archived': chat.isArchived ? 1 : 0,
      'is_muted': chat.isMuted ? 1 : 0,
      'is_pinned': chat.isPinned ? 1 : 0,
      'chat_metadata': chat.metadata != null ? jsonEncode(chat.metadata) : null,
    });
  }

  Future<List<UnifiedChatEntity>> getCachedChats({
    int limit = 50,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final chats = await _database.getChats(
      limit: limit,
      offset: offset,
      includeArchived: includeArchived,
    );
    return chats.map((chat) => _mapToChatEntity(chat)).toList();
  }

  Future<UnifiedChatEntity?> getCachedChat(String chatId) async {
    final chat = await _database.getChat(chatId);
    return chat != null ? _mapToChatEntity(chat) : null;
  }

  Future<void> updateCachedChat(String chatId, Map<String, dynamic> updates) async {
    await _database.updateChat(chatId, updates);
  }

  Future<void> incrementUnreadCount(String chatId) async {
    await _database.incrementUnreadCount(chatId);
  }

  Future<void> clearUnreadCount(String chatId) async {
    await _database.clearUnreadCount(chatId);
  }

  Future<int> getTotalUnreadCount({String? provider}) async {
    return await _database.getUnreadMessagesCount(provider: provider);
  }

  UnifiedChatEntity _mapToChatEntity(Map<String, dynamic> data) {
    List<String> participantIds = [];
    if (data['participant_ids'] != null) {
      try {
        participantIds = List<String>.from(jsonDecode(data['participant_ids']));
      } catch (e) {
        // Handle parsing error
      }
    }

    Map<String, dynamic>? metadata;
    if (data['chat_metadata'] != null) {
      try {
        metadata = jsonDecode(data['chat_metadata']);
      } catch (e) {
        // Handle parsing error
      }
    }

    return UnifiedChatEntity(
      id: data['id'],
      provider: data['provider'],
      providerChatId: data['provider_chat_id'],
      chatName: data['chat_name'],
      chatType: data['chat_type'] ?? 'direct',
      avatarUrl: data['chat_avatar_url'],
      participantIds: participantIds,
      lastMessageContent: data['last_message_content'],
      lastMessageAt: data['last_message_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['last_message_at'])
        : null,
      lastMessageId: data['last_message_id'],
      unreadCount: data['unread_count'] ?? 0,
      isArchived: data['is_archived'] == 1,
      isMuted: data['is_muted'] == 1,
      isPinned: data['is_pinned'] == 1,
      metadata: metadata,
    );
  }

  // ===============================
  // MESSAGE OPERATIONS
  // ===============================

  Future<void> cacheMessage(UnifiedMessageEntity message) async {
    await _database.insertMessage({
      'id': message.id,
      'chat_id': message.chatId,
      'provider_message_id': message.providerMessageId,
      'sender_id': message.senderId,
      'sender_name': message.senderName,
      'sender_email': message.senderEmail,
      'sender_avatar_url': message.senderAvatarUrl,
      'message_type': message.messageType,
      'content': message.content,
      'attachments': message.attachments.isNotEmpty ? jsonEncode(message.attachments) : null,
      'reactions': message.reactions.isNotEmpty ? jsonEncode(message.reactions) : null,
      'is_outgoing': message.isOutgoing ? 1 : 0,
      'is_read': message.isRead ? 1 : 0,
      'is_delivered': message.isDelivered ? 1 : 0,
      'is_sent': message.isSent ? 1 : 0,
      'reply_to_message_id': message.replyToMessageId,
      'forwarded_from': message.forwardedFrom,
      'edited_at': message.editedAt?.millisecondsSinceEpoch,
      'sent_at': message.sentAt.millisecondsSinceEpoch,
      'sync_status': message.syncStatus,
      'local_path': message.localPath,
    });
  }

  Future<List<UnifiedMessageEntity>> getCachedMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
    String? beforeMessageId,
  }) async {
    final messages = await _database.getChatMessages(
      chatId,
      limit: limit,
      offset: offset,
      beforeMessageId: beforeMessageId,
    );
    return messages.map((message) => _mapToMessageEntity(message)).toList();
  }

  Future<UnifiedMessageEntity?> getCachedMessage(String messageId) async {
    final message = await _database.getMessage(messageId);
    return message != null ? _mapToMessageEntity(message) : null;
  }

  Future<void> updateCachedMessage(String messageId, Map<String, dynamic> updates) async {
    await _database.updateMessage(messageId, updates);
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _database.markMessageAsRead(messageId);
  }

  Future<void> markChatMessagesAsRead(String chatId) async {
    await _database.markChatMessagesAsRead(chatId);
  }

  Future<List<UnifiedMessageEntity>> searchMessages(String query, {int limit = 20}) async {
    final messages = await _database.searchMessages(query, limit: limit);
    return messages.map((message) => _mapToMessageEntity(message)).toList();
  }

  UnifiedMessageEntity _mapToMessageEntity(Map<String, dynamic> data) {
    List<Map<String, dynamic>> attachments = [];
    if (data['attachments'] != null) {
      try {
        attachments = List<Map<String, dynamic>>.from(jsonDecode(data['attachments']));
      } catch (e) {
        // Handle parsing error
      }
    }

    Map<String, List<String>> reactions = {};
    if (data['reactions'] != null) {
      try {
        final decoded = jsonDecode(data['reactions']);
        reactions = Map<String, List<String>>.from(
          decoded.map((key, value) => MapEntry(key, List<String>.from(value)))
        );
      } catch (e) {
        // Handle parsing error
      }
    }

    return UnifiedMessageEntity(
      id: data['id'],
      chatId: data['chat_id'],
      providerMessageId: data['provider_message_id'],
      senderId: data['sender_id'],
      senderName: data['sender_name'],
      senderEmail: data['sender_email'],
      senderAvatarUrl: data['sender_avatar_url'],
      messageType: data['message_type'] ?? 'text',
      content: data['content'],
      attachments: attachments,
      reactions: reactions,
      isOutgoing: data['is_outgoing'] == 1,
      isRead: data['is_read'] == 1,
      isDelivered: data['is_delivered'] == 1,
      isSent: data['is_sent'] == 1,
      replyToMessageId: data['reply_to_message_id'],
      forwardedFrom: data['forwarded_from'],
      editedAt: data['edited_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['edited_at'])
        : null,
      sentAt: DateTime.fromMillisecondsSinceEpoch(data['sent_at']),
      receivedAt: data['received_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['received_at'])
        : null,
      syncStatus: data['sync_status'] ?? 'synced',
      localPath: data['local_path'],
    );
  }

  // ===============================
  // DRAFT OPERATIONS
  // ===============================

  Future<void> saveDraft(String chatId, String content, {List<Map<String, dynamic>>? attachments}) async {
    await _database.saveDraft(chatId, content, attachments: attachments);
  }

  Future<MessageDraft?> getDraft(String chatId) async {
    final draft = await _database.getDraft(chatId);
    if (draft == null) return null;

    List<Map<String, dynamic>> attachments = [];
    if (draft['attachments'] != null) {
      try {
        attachments = List<Map<String, dynamic>>.from(jsonDecode(draft['attachments']));
      } catch (e) {
        // Handle parsing error
      }
    }

    return MessageDraft(
      chatId: draft['chat_id'],
      content: draft['content'],
      attachments: attachments,
      createdAt: DateTime.fromMillisecondsSinceEpoch(draft['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(draft['updated_at']),
    );
  }

  Future<void> deleteDraft(String chatId) async {
    await _database.deleteDraft(chatId);
  }

  // ===============================
  // SYNC QUEUE OPERATIONS
  // ===============================

  Future<void> addToSyncQueue({
    required String operationType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    int maxRetries = 3,
  }) async {
    await _database.addToSyncQueue(
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      maxRetries: maxRetries,
    );
  }

  Future<List<SyncOperation>> getPendingSyncOperations({int limit = 10}) async {
    final operations = await _database.getPendingSyncOperations(limit: limit);
    return operations.map((op) => _mapToSyncOperation(op)).toList();
  }

  Future<void> markSyncOperationCompleted(int id) async {
    await _database.markSyncOperationCompleted(id);
  }

  Future<void> markSyncOperationFailed(int id, String errorMessage) async {
    await _database.markSyncOperationFailed(id, errorMessage);
  }

  SyncOperation _mapToSyncOperation(Map<String, dynamic> data) {
    Map<String, dynamic>? payload;
    if (data['payload'] != null) {
      try {
        payload = jsonDecode(data['payload']);
      } catch (e) {
        // Handle parsing error
      }
    }

    return SyncOperation(
      id: data['id'],
      operationType: data['operation_type'],
      entityType: data['entity_type'],
      entityId: data['entity_id'],
      payload: payload,
      retryCount: data['retry_count'],
      maxRetries: data['max_retries'],
      nextRetryAt: data['next_retry_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['next_retry_at'])
        : null,
      status: data['status'],
      errorMessage: data['error_message'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at']),
    );
  }

  // ===============================
  // PREFERENCES OPERATIONS
  // ===============================

  Future<void> setPreference(String key, dynamic value) async {
    await _database.setPreference(key, value);
  }

  Future<T?> getPreference<T>(String key, T Function(String) parser) async {
    final value = await _database.getPreference(key);
    return value != null ? parser(value) : null;
  }

  Future<Map<String, String>> getAllPreferences() async {
    return await _database.getAllPreferences();
  }

  // ===============================
  // MAINTENANCE OPERATIONS
  // ===============================

  Future<void> cleanupOldMessages({int daysToKeep = 30}) async {
    await _database.cleanupOldMessages(daysToKeep: daysToKeep);
  }

  Future<void> cleanupCompletedSyncOperations() async {
    await _database.cleanupCompletedSyncOperations();
  }

  Future<Map<String, int>> getCacheStats() async {
    return await _database.getDatabaseStats();
  }

  Future<void> clearAllCache() async {
    await _database.clearAllData();
  }
}

// ===============================
// HELPER CLASSES
// ===============================

class MessageDraft {
  final String chatId;
  final String content;
  final List<Map<String, dynamic>> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageDraft({
    required this.chatId,
    required this.content,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });
}

class SyncOperation {
  final int id;
  final String operationType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? payload;
  final int retryCount;
  final int maxRetries;
  final DateTime? nextRetryAt;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    this.payload,
    required this.retryCount,
    required this.maxRetries,
    this.nextRetryAt,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
}