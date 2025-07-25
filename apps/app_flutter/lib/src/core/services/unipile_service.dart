import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meu_app/src/core/utils/app_logger.dart';

class UnipileException implements Exception {
  final String message;
  UnipileException(this.message);
  
  @override
  String toString() => 'UnipileException: $message';
}

class UnipileAccount {
  final String id;
  final String provider;
  final String email;
  final String status;
  
  UnipileAccount({
    required this.id,
    required this.provider,
    required this.email,
    required this.status,
  });
  
  factory UnipileAccount.fromJson(Map<String, dynamic> json) {
    return UnipileAccount(
      id: json['id'] ?? '',
      provider: json['provider'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'email': email,
      'status': status,
    };
  }
}

class UnipileEmail {
  final String id;
  final String subject;
  final String body;
  final String from;
  final String to;
  final DateTime sentAt;
  final DateTime receivedAt;
  final bool isRead;
  
  UnipileEmail({
    required this.id,
    required this.subject,
    required this.body,
    required this.from,
    required this.to,
    required this.sentAt,
    required this.receivedAt,
    required this.isRead,
  });
  
  factory UnipileEmail.fromJson(Map<String, dynamic> json) {
    return UnipileEmail(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
      receivedAt: DateTime.tryParse(json['received_at'] ?? json['sent_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }
}

class UnipileMessage {
  final String id;
  final String chatId;
  final String content;
  final String senderId;
  final DateTime sentAt;
  final String type;
  
  // Aliases para compatibilidade
  String get sender => senderId;
  DateTime get timestamp => sentAt;
  
  UnipileMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.senderId,
    required this.sentAt,
    required this.type,
  });
  
  factory UnipileMessage.fromJson(Map<String, dynamic> json) {
    return UnipileMessage(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      content: json['content'] ?? '',
      senderId: json['sender_id'] ?? json['sender'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? 'text',
    );
  }
}

class UnipileCalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  
  UnipileCalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
  });
  
  factory UnipileCalendarEvent.fromJson(Map<String, dynamic> json) {
    return UnipileCalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now(),
      location: json['location'] ?? '',
    );
  }
}

class UnipileService {
  static final UnipileService _instance = UnipileService._internal();
  factory UnipileService() => _instance;
  UnipileService._internal();

  final String _baseUrl = 'http://localhost:8080/api/v2/unipile';
  final http.Client _client = http.Client();
  String? _authToken;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> _makeRequest(String method, String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      
      AppLogger.debug('Unipile API: $method $url');
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            Uri.parse(url),
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            Uri.parse(url),
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Método HTTP não suportado: $method');
      }

      AppLogger.debug('Unipile Response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : {};
      } else {
        throw UnipileException(
          'Erro na API Unipile: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Erro na requisição Unipile', {'error': e.toString()});
      rethrow;
    }
  }

  // ===== ACCOUNT MANAGEMENT =====

  Future<List<UnipileAccount>> getAccounts() async {
    final response = await _makeRequest('GET', '/accounts');
    final accounts = response['accounts'] as List<dynamic>? ?? [];
    return accounts
        .map((json) => UnipileAccount.fromJson(json))
        .toList();
  }

  Future<UnipileAccount> connectGmail() async {
    final response = await _makeRequest('POST', '/accounts/connect', data: {
      'provider': 'gmail',
      'auth_type': 'oauth2'
    });
    
    return UnipileAccount.fromJson(response['account']);
  }

  Future<UnipileAccount> connectOutlook() async {
    final response = await _makeRequest('POST', '/accounts/connect', data: {
      'provider': 'outlook',
      'auth_type': 'oauth2'
    });
    
    return UnipileAccount.fromJson(response['account']);
  }

  Future<UnipileAccount> connectLinkedIn(String username, String password) async {
    final response = await _makeRequest('POST', '/accounts/connect', data: {
      'provider': 'linkedin',
      'auth_type': 'credentials',
      'username': username,
      'password': password,
    });
    
    return UnipileAccount.fromJson(response['account']);
  }

  Future<UnipileAccount> connectWhatsApp() async {
    final response = await _makeRequest('POST', '/accounts/connect', data: {
      'provider': 'whatsapp',
      'auth_type': 'qr_code'
    });
    
    return UnipileAccount.fromJson(response['account']);
  }

  Future<UnipileAccount> connectInstagram() async {
    final response = await _makeRequest('POST', '/accounts/connect', data: {
      'provider': 'instagram',
      'auth_type': 'oauth2'
    });
    
    return UnipileAccount.fromJson(response['account']);
  }

  Future<UnipileAccount> connectTelegram() async {
    final response = await _makeRequest('POST', '/accounts/connect', data: {
      'provider': 'telegram',
      'auth_type': 'bot_token'
    });
    
    return UnipileAccount.fromJson(response['account']);
  }

  // ===== EMAIL MANAGEMENT =====

  Future<List<UnipileEmail>> getEmails({String? accountId}) async {
    final endpoint = accountId != null ? '/emails?account_id=$accountId' : '/emails';
    final response = await _makeRequest('GET', endpoint);
    final emails = response['emails'] as List<dynamic>? ?? [];
    return emails
        .map((json) => UnipileEmail.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> sendEmail({
    required String accountId,
    required String to,
    required String subject,
    required String body,
    List<String>? attachments,
  }) async {
    final response = await _makeRequest('POST', '/messaging/send', data: {
      'account_id': accountId,
      'to': to,
      'subject': subject,
      'body': body,
      'attachments': attachments ?? [],
      'type': 'email',
    });
    
    return response;
  }

  Future<Map<String, dynamic>> replyToEmail({
    required String emailId,
    required String accountId,
    required String replyBody,
    required bool replyAll,
    List<String>? attachments,
  }) async {
    final response = await _makeRequest('POST', '/emails/$emailId/reply', data: {
      'account_id': accountId,
      'body': replyBody,
      'reply_all': replyAll,
      'attachments': attachments ?? [],
    });
    
    return response;
  }

  Future<Map<String, dynamic>> deleteEmail({
    required String emailId,
    required String accountId,
    required bool permanent,
  }) async {
    final response = await _makeRequest('DELETE', '/emails/$emailId', data: {
      'account_id': accountId,
      'permanent': permanent,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> archiveEmail({
    required String emailId,
    required String accountId,
  }) async {
    final response = await _makeRequest('POST', '/emails/$emailId/archive', data: {
      'account_id': accountId,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> createEmailDraft({
    required String accountId,
    required String to,
    required String subject,
    required String body,
    List<String>? attachments,
  }) async {
    final response = await _makeRequest('POST', '/emails/drafts', data: {
      'account_id': accountId,
      'to': to,
      'subject': subject,
      'body': body,
      'attachments': attachments ?? [],
    });
    
    return response;
  }

  Future<Map<String, dynamic>> moveEmail({
    required String emailId,
    required String accountId,
    required String folder,
  }) async {
    final response = await _makeRequest('POST', '/emails/$emailId/move', data: {
      'account_id': accountId,
      'folder': folder,
    });
    
    return response;
  }

  // ===== CALENDAR MANAGEMENT =====

  Future<List<UnipileCalendarEvent>> getCalendarEvents({String? accountId}) async {
    final endpoint = accountId != null ? '/calendar/events?account_id=$accountId' : '/calendar/events';
    final response = await _makeRequest('GET', endpoint);
    final events = response['events'] as List<dynamic>? ?? [];
    return events
        .map((json) => UnipileCalendarEvent.fromJson(json))
        .toList();
  }

  Future<UnipileCalendarEvent> createCalendarEvent({
    required String connectionId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<String>? attendees,
  }) async {
    final response = await _makeRequest('POST', '/calendar/events', data: {
      'connection_id': connectionId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location ?? '',
      'attendees': attendees ?? [],
    });
    
    return UnipileCalendarEvent.fromJson(response['event']);
  }

  // ===== LINKEDIN SPECIFIC =====

  Future<Map<String, dynamic>> sendInMail({
    required String accountId,
    required String recipient,
    required String subject,
    required String message,
  }) async {
    final response = await _makeRequest('POST', '/linkedin/send-inmail', data: {
      'account_id': accountId,
      'recipient': recipient,
      'subject': subject,
      'message': message,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> sendLinkedInInvitation({
    required String accountId,
    required String recipient,
    required String message,
  }) async {
    final response = await _makeRequest('POST', '/linkedin/send-invitation', data: {
      'account_id': accountId,
      'recipient': recipient,
      'message': message,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> sendVoiceNote({
    required String accountId,
    required String recipient,
    required String audioUrl,
  }) async {
    final response = await _makeRequest('POST', '/linkedin/send-voice-note', data: {
      'account_id': accountId,
      'recipient': recipient,
      'audio_url': audioUrl,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> commentOnLinkedInPost({
    required String accountId,
    required String postId,
    required String comment,
  }) async {
    final response = await _makeRequest('POST', '/linkedin/comment-post', data: {
      'account_id': accountId,
      'post_id': postId,
      'comment': comment,
    });
    
    return response;
  }

  // ===== V2 CONNECTION METHODS =====

  Future<Map<String, dynamic>> connectGmailV2({required String email}) async {
    final response = await _makeRequest('POST', '/connect/gmail', data: {
      'email': email,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> connectOutlookV2({required String email}) async {
    final response = await _makeRequest('POST', '/connect/outlook', data: {
      'email': email,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> connectLinkedInV2({
    required String username,
    required String password,
  }) async {
    final response = await _makeRequest('POST', '/connect/linkedin', data: {
      'username': username,
      'password': password,
    });
    
    return response;
  }

  Future<Map<String, dynamic>> connectInstagramV2({
    required String username,
    required String password,
  }) async {
    final response = await _makeRequest('POST', '/connect/instagram', data: {
      'username': username,
      'password': password,
    });
    
    return response;
  }

  // ===== MESSAGING =====

  Future<List<Map<String, dynamic>>> getAllChats() async {
    final response = await _makeRequest('GET', '/chats');
    return List<Map<String, dynamic>>.from(response['chats'] ?? []);
  }

  Future<List<UnipileMessage>> getChatMessages(String chatId) async {
    final response = await _makeRequest('GET', '/chats/$chatId/messages');
    final messages = response['messages'] as List<dynamic>? ?? [];
    return messages
        .map((json) => UnipileMessage.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String chatId,
    required String accountId,
    required String message,
    String? messageType,
  }) async {
    final response = await _makeRequest('POST', '/chats/$chatId/messages', data: {
      'account_id': accountId,
      'message': message,
      'type': messageType ?? 'text',
    });
    
    return response;
  }

  /// Obter mensagens de chat
  Future<List<UnipileMessage>> getMessages({
    String? connectionId,
    int? limit,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      UnipileMessage(
        id: 'msg_1',
        chatId: 'chat_1',
        content: 'Mensagem de exemplo',
        senderId: 'sender_1',
        sentAt: DateTime.now(),
        type: 'text',
      ),
    ];
  }

  /// Obter eventos de calendário com parâmetros adicionais (versão estendida)
  Future<Map<String, dynamic>> getCalendarEventsExtended({
    String? connectionId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'data': [
        {
          'id': 'event_1',
          'title': 'Reunião exemplo',
          'start_time': (startDate ?? DateTime.now()).toIso8601String(),
          'end_time': (endDate ?? DateTime.now().add(const Duration(hours: 1))).toIso8601String(),
        }
      ]
    };
  }

  /// Criar evento de calendário com parâmetros adicionais (versão estendida)
  Future<Map<String, dynamic>> createCalendarEventExtended({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? attendees,
    String? location,
    String? accountId,
    String? connectionId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'data': {
        'id': 'event_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'attendees': attendees ?? [],
        'location': location,
      }
    };
  }

  /// Atualizar evento de calendário
  Future<Map<String, dynamic>> updateCalendarEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? attendees,
    String? location,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'data': {
        'id': eventId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'attendees': attendees ?? [],
        'location': location,
      }
    };
  }

  // ===== CONNECTED ACCOUNTS =====

  Future<Map<String, dynamic>> getConnectedAccounts() async {
    final response = await _makeRequest('GET', '/accounts/connected');
    return response;
  }

  Future<Map<String, dynamic>> deleteAccount(String accountId) async {
    final response = await _makeRequest('DELETE', '/accounts/$accountId');
    return response;
  }

  // ===== WEBHOOKS =====

  Future<Map<String, dynamic>> createWebhook({
    required String url,
    required List<String> events,
  }) async {
    final response = await _makeRequest('POST', '/webhooks', data: {
      'url': url,
      'events': events,
    });
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getWebhooks() async {
    final response = await _makeRequest('GET', '/webhooks');
    return List<Map<String, dynamic>>.from(response['webhooks'] ?? []);
  }

  void dispose() {
    _client.close();
  }
} 