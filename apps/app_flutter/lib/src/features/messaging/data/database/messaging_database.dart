import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MessagingDatabase {
  static final MessagingDatabase _instance = MessagingDatabase._internal();
  static Database? _database;

  MessagingDatabase._internal();

  factory MessagingDatabase() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'unified_messaging.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE connected_accounts (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        account_id TEXT NOT NULL,
        account_name TEXT,
        account_email TEXT,
        is_active INTEGER DEFAULT 1,
        access_token TEXT,
        refresh_token TEXT,
        token_expires_at INTEGER,
        last_sync_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        error_message TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(provider, account_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE unified_chats (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        provider_chat_id TEXT NOT NULL,
        chat_name TEXT,
        chat_type TEXT DEFAULT 'direct',
        chat_avatar_url TEXT,
        participant_ids TEXT, -- JSON array of participant IDs
        last_message_content TEXT,
        last_message_at INTEGER,
        last_message_id TEXT,
        unread_count INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        is_muted INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        chat_metadata TEXT, -- JSON metadata specific to provider
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(provider, provider_chat_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE unified_messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        provider_message_id TEXT NOT NULL,
        sender_id TEXT,
        sender_name TEXT,
        sender_email TEXT,
        sender_avatar_url TEXT,
        message_type TEXT DEFAULT 'text',
        content TEXT,
        attachments TEXT, -- JSON array of attachments
        reactions TEXT, -- JSON object of reactions
        is_outgoing INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        is_delivered INTEGER DEFAULT 0,
        is_sent INTEGER DEFAULT 1,
        reply_to_message_id TEXT,
        forwarded_from TEXT,
        edited_at INTEGER,
        sent_at INTEGER NOT NULL,
        received_at INTEGER DEFAULT (strftime('%s', 'now')),
        sync_status TEXT DEFAULT 'synced', -- synced, pending, failed
        local_path TEXT, -- For offline attachments
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (chat_id) REFERENCES unified_chats (id) ON DELETE CASCADE,
        UNIQUE(chat_id, provider_message_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE message_drafts (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        content TEXT NOT NULL,
        attachments TEXT, -- JSON array
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (chat_id) REFERENCES unified_chats (id) ON DELETE CASCADE,
        UNIQUE(chat_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL, -- send_message, mark_read, delete_message, etc.
        entity_type TEXT NOT NULL, -- message, chat, account
        entity_id TEXT NOT NULL,
        payload TEXT, -- JSON payload for the operation
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 3,
        next_retry_at INTEGER,
        status TEXT DEFAULT 'pending', -- pending, processing, completed, failed
        error_message TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Índices para performance
    await db.execute('CREATE INDEX idx_messages_chat_id ON unified_messages(chat_id)');
    await db.execute('CREATE INDEX idx_messages_sent_at ON unified_messages(sent_at DESC)');
    await db.execute('CREATE INDEX idx_messages_unread ON unified_messages(is_read) WHERE is_read = 0');
    await db.execute('CREATE INDEX idx_chats_last_message ON unified_chats(last_message_at DESC)');
    await db.execute('CREATE INDEX idx_chats_unread ON unified_chats(unread_count) WHERE unread_count > 0');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(status)');
    await db.execute('CREATE INDEX idx_sync_queue_next_retry ON sync_queue(next_retry_at)');

    // Triggers para atualizar updated_at automaticamente
    await _createUpdateTriggers(db);
  }

  Future<void> _createUpdateTriggers(Database db) async {
    final tables = [
      'connected_accounts',
      'unified_chats', 
      'unified_messages',
      'message_drafts',
      'sync_queue',
      'user_preferences'
    ];

    for (final table in tables) {
      await db.execute('''
        CREATE TRIGGER update_${table}_updated_at 
        AFTER UPDATE ON $table 
        BEGIN
          UPDATE $table SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
        END
      ''');
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE unified_messages ADD COLUMN new_field TEXT');
    }
  }

  // ===============================
  // CONNECTED ACCOUNTS OPERATIONS
  // ===============================

  Future<void> insertConnectedAccount(Map<String, dynamic> account) async {
    final db = await database;
    await db.insert(
      'connected_accounts',
      account,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getConnectedAccounts() async {
    final db = await database;
    return await db.query(
      'connected_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'provider ASC',
    );
  }

  Future<Map<String, dynamic>?> getConnectedAccount(String provider, String accountId) async {
    final db = await database;
    final results = await db.query(
      'connected_accounts',
      where: 'provider = ? AND account_id = ?',
      whereArgs: [provider, accountId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateConnectedAccount(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'connected_accounts',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteConnectedAccount(String provider, String accountId) async {
    final db = await database;
    await db.update(
      'connected_accounts',
      {'is_active': 0},
      where: 'provider = ? AND account_id = ?',
      whereArgs: [provider, accountId],
    );
  }

  // ===============================
  // CHATS OPERATIONS
  // ===============================

  Future<void> insertChat(Map<String, dynamic> chat) async {
    final db = await database;
    await db.insert(
      'unified_chats',
      chat,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getChats({
    int limit = 50,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final db = await database;
    final whereClause = includeArchived ? '' : 'WHERE is_archived = 0';
    
    return await db.rawQuery('''
      SELECT * FROM unified_chats 
      $whereClause
      ORDER BY is_pinned DESC, last_message_at DESC 
      LIMIT ? OFFSET ?
    ''', [limit, offset]);
  }

  Future<Map<String, dynamic>?> getChat(String chatId) async {
    final db = await database;
    final results = await db.query(
      'unified_chats',
      where: 'id = ?',
      whereArgs: [chatId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateChat(String chatId, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'unified_chats',
      updates,
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> updateChatLastMessage(String chatId, String messageContent, int timestamp, String messageId) async {
    final db = await database;
    await db.update(
      'unified_chats',
      {
        'last_message_content': messageContent,
        'last_message_at': timestamp,
        'last_message_id': messageId,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> incrementUnreadCount(String chatId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE unified_chats 
      SET unread_count = unread_count + 1 
      WHERE id = ?
    ''', [chatId]);
  }

  Future<void> clearUnreadCount(String chatId) async {
    final db = await database;
    await db.update(
      'unified_chats',
      {'unread_count': 0},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // ===============================
  // MESSAGES OPERATIONS
  // ===============================

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      'unified_messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Update chat's last message
    if (message['content'] != null && message['sent_at'] != null) {
      await updateChatLastMessage(
        message['chat_id'],
        message['content'],
        message['sent_at'],
        message['id'],
      );
    }
    
    // Increment unread count if incoming message
    if (message['is_outgoing'] == 0) {
      await incrementUnreadCount(message['chat_id']);
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
    String? beforeMessageId,
  }) async {
    final db = await database;
    
    String whereClause = 'chat_id = ?';
    List<dynamic> whereArgs = [chatId];
    
    if (beforeMessageId != null) {
      whereClause += ' AND sent_at < (SELECT sent_at FROM unified_messages WHERE id = ?)';
      whereArgs.add(beforeMessageId);
    }
    
    return await db.query(
      'unified_messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sent_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    final db = await database;
    final results = await db.query(
      'unified_messages',
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateMessage(String messageId, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'unified_messages',
      updates,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    final db = await database;
    await db.update(
      'unified_messages',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markChatMessagesAsRead(String chatId) async {
    final db = await database;
    await db.update(
      'unified_messages',
      {'is_read': 1},
      where: 'chat_id = ? AND is_read = 0',
      whereArgs: [chatId],
    );
    await clearUnreadCount(chatId);
  }

  Future<int> getUnreadMessagesCount({String? provider}) async {
    final db = await database;
    
    if (provider != null) {
      final result = await db.rawQuery('''
        SELECT SUM(unread_count) as total 
        FROM unified_chats 
        WHERE provider = ?
      ''', [provider]);
      return (result.first['total'] as int?) ?? 0;
    } else {
      final result = await db.rawQuery('''
        SELECT SUM(unread_count) as total 
        FROM unified_chats
      ''');
      return (result.first['total'] as int?) ?? 0;
    }
  }

  Future<List<Map<String, dynamic>>> searchMessages(String query, {int limit = 20}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, c.chat_name, c.provider 
      FROM unified_messages m
      JOIN unified_chats c ON m.chat_id = c.id
      WHERE m.content LIKE ? OR c.chat_name LIKE ?
      ORDER BY m.sent_at DESC
      LIMIT ?
    ''', ['%$query%', '%$query%', limit]);
  }

  // ===============================
  // DRAFTS OPERATIONS
  // ===============================

  Future<void> saveDraft(String chatId, String content, {List<Map<String, dynamic>>? attachments}) async {
    final db = await database;
    await db.insert(
      'message_drafts',
      {
        'id': 'draft_$chatId',
        'chat_id': chatId,
        'content': content,
        'attachments': attachments?.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getDraft(String chatId) async {
    final db = await database;
    final results = await db.query(
      'message_drafts',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteDraft(String chatId) async {
    final db = await database;
    await db.delete(
      'message_drafts',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
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
    final db = await database;
    await db.insert('sync_queue', {
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload?.toString(),
      'max_retries': maxRetries,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations({int limit = 10}) async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ? AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: ['pending', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<void> updateSyncOperation(int id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'sync_queue',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSyncOperationCompleted(int id) async {
    await updateSyncOperation(id, {'status': 'completed'});
  }

  Future<void> markSyncOperationFailed(int id, String errorMessage) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE sync_queue 
      SET status = ?, error_message = ?, retry_count = retry_count + 1,
          next_retry_at = ? 
      WHERE id = ?
    ''', [
      'failed',
      errorMessage,
      DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
      id,
    ]);
  }

  // ===============================
  // USER PREFERENCES
  // ===============================

  Future<void> setPreference(String key, dynamic value) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final results = await db.query(
      'user_preferences',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  Future<Map<String, String>> getAllPreferences() async {
    final db = await database;
    final results = await db.query('user_preferences');
    return Map.fromEntries(
      results.map((row) => MapEntry(row['key'] as String, row['value'] as String)),
    );
  }

  // ===============================
  // MAINTENANCE OPERATIONS
  // ===============================

  Future<void> cleanupOldMessages({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep)).millisecondsSinceEpoch ~/ 1000;
    
    await db.delete(
      'unified_messages',
      where: 'sent_at < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<void> cleanupCompletedSyncOperations() async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    
    await db.delete(
      'sync_queue',
      where: 'status = ? AND updated_at < ?',
      whereArgs: ['completed', cutoffTime],
    );
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final results = await Future.wait([
      db.rawQuery('SELECT COUNT(*) as count FROM connected_accounts WHERE is_active = 1'),
      db.rawQuery('SELECT COUNT(*) as count FROM unified_chats WHERE is_archived = 0'),
      db.rawQuery('SELECT COUNT(*) as count FROM unified_messages'),
      db.rawQuery('SELECT COUNT(*) as count FROM sync_queue WHERE status = "pending"'),
      db.rawQuery('SELECT SUM(unread_count) as count FROM unified_chats'),
    ]);
    
    return {
      'connected_accounts': (results[0].first['count'] as int),
      'active_chats': (results[1].first['count'] as int),
      'total_messages': (results[2].first['count'] as int),
      'pending_sync': (results[3].first['count'] as int),
      'unread_messages': (results[4].first['count'] as int?) ?? 0,
    };
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tables = [
      'unified_messages',
      'unified_chats', 
      'message_drafts',
      'sync_queue',
      'connected_accounts',
      'user_preferences'
    ];
    
    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}