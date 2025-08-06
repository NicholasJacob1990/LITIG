import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app/src/core/services/dio_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:flutter/foundation.dart';

class UnifiedMessagingService {
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  
  // HTTP client e configurações
  final Dio _httpClient = DioService.instance.dio;
  
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8080';
    }
    return 'http://localhost:8080';
  }
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_getAuthToken()}',
  };
  
  // Usar a mesma lógica de detecção de plataforma do DioService
  String get _wsUrl {
    if (kIsWeb) {
      return 'ws://127.0.0.1:8080';
    }
    // Para outras plataformas, seguir a mesma lógica do DioService
    return 'ws://localhost:8080';
  }
  
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams públicos
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  // Usar token do Supabase como no DioService
  String _getAuthToken() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return session?.accessToken ?? '';
    } catch (e) {
      AppLogger.warning('Sem token de autenticação disponível');
      return '';
    }
  }

  // ===============================
  // CONEXÃO WEBSOCKET
  // ===============================

  Future<void> connectWebSocket() async {
    try {
      final wsUrl = '$_wsUrl/ws/unified-messaging';
      AppLogger.info('Conectando WebSocket em: $wsUrl');
      
      _wsChannel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['echo-protocol'],
      );

      _wsSubscription = _wsChannel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            _handleWebSocketMessage(message);
          } catch (e) {
            AppLogger.error('Erro ao decodificar mensagem WebSocket', error: e);
          }
        },
        onError: (error) {
          AppLogger.error('Erro WebSocket', error: error);
          _reconnectWebSocket();
        },
        onDone: () {
          AppLogger.info('Conexão WebSocket fechada');
          _reconnectWebSocket();
        },
      );

      // Enviar autenticação
      _wsChannel!.sink.add(jsonEncode({
        'type': 'auth',
        'token': _getAuthToken(),
      }));

      AppLogger.info('WebSocket conectado com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao conectar WebSocket', error: e);
      _reconnectWebSocket();
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'new_message':
        _messageStreamController.add(message['data']);
        break;
      case 'message_status_update':
        _messageStreamController.add(message['data']);
        break;
      case 'typing_indicator':
        _messageStreamController.add(message['data']);
        break;
      case 'notification':
        _notificationStreamController.add(message['data']);
        break;
      default:
        AppLogger.warning('Tipo de mensagem WebSocket não reconhecido: ${message['type']}');
    }
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      connectWebSocket();
    });
  }

  void disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close(status.normalClosure);
    _wsChannel = null;
  }

  // ===============================
  // GESTÃO DE CONTAS
  // ===============================

  Future<Map<String, dynamic>> getConnectedAccounts() async {
    try {
      final response = await DioService.get('/unified-messaging/accounts');
      return response.data;
    } on DioException catch (e) {
      AppLogger.warning('Backend não disponível, usando dados mock', error: e);
      // Fallback para dados mock quando backend não está disponível
      return _getMockConnectedAccounts();
    } catch (e) {
      AppLogger.warning('Erro de conexão, usando dados mock', error: e);
      return _getMockConnectedAccounts();
    }
  }

  Map<String, dynamic> _getMockConnectedAccounts() {
    return {
      'accounts': [
        {
          'id': 'demo_internal',
          'provider': 'internal',
          'name': 'Chat Interno LITIG-1',
          'email': 'internal@litig1.com',
          'connected_at': DateTime.now().toIso8601String(),
          'status': 'active',
        },
        {
          'id': 'demo_linkedin',
          'provider': 'linkedin',
          'name': 'LinkedIn Demo',
          'email': 'demo@linkedin.com',
          'connected_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'status': 'demo',
        }
      ],
      'total': 2,
      'has_email_account': false,
      'has_calendar_account': false,
      'has_messaging_account': true,
    };
  }

  // ===============================
  // DADOS MOCK PARA CHATS E MENSAGENS
  // ===============================

  Future<List<Map<String, dynamic>>> getInternalChats() async {
    try {
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/chat/internal/chats',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['chats'] ?? []);
      } else {
        throw Exception('Erro ao carregar chats internos: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.warning('Backend não disponível para chats internos, usando dados mock', error: e);
      return _getMockInternalChats();
    }
  }

  List<Map<String, dynamic>> _getMockInternalChats() {
    return [
      {
        'id': 'internal_chat_1',
        'type': 'direct',
        'name': 'Dr. João Silva',
        'participants': [
          {
            'id': 'user_current',
            'name': 'Você',
            'role': 'lawyer_individual',
          },
          {
            'id': 'lawyer_2',
            'name': 'Dr. João Silva',
            'role': 'lawyer_firm_member',
            'avatar': 'https://ui-avatars.com/api/?name=João+Silva&background=2563EB&color=fff',
          }
        ],
        'last_message': {
          'id': 'msg_1',
          'content': 'Oi! Podemos conversar sobre o caso de divórcio?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          'sender_id': 'lawyer_2',
          'sender_name': 'Dr. João Silva',
          'message_type': 'text',
          'is_read': false,
        },
        'unread_count': 1,
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'updated_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'id': 'internal_chat_2',
        'type': 'direct',
        'name': 'Dra. Maria Santos',
        'participants': [
          {
            'id': 'user_current',
            'name': 'Você',
            'role': 'lawyer_individual',
          },
          {
            'id': 'lawyer_3',
            'name': 'Dra. Maria Santos',
            'role': 'lawyer_individual',
            'avatar': 'https://ui-avatars.com/api/?name=Maria+Santos&background=10B981&color=fff',
          }
        ],
        'last_message': {
          'id': 'msg_2',
          'content': 'Perfeito! Vou enviar os documentos ainda hoje.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'sender_id': 'user_current',
          'sender_name': 'Você',
          'message_type': 'text',
          'is_read': true,
        },
        'unread_count': 0,
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'updated_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'internal_chat_3',
        'type': 'direct',
        'name': 'Cliente: Ana Costa',
        'participants': [
          {
            'id': 'user_current',
            'name': 'Você',
            'role': 'lawyer_individual',
          },
          {
            'id': 'client_1',
            'name': 'Ana Costa',
            'role': 'client',
            'avatar': 'https://ui-avatars.com/api/?name=Ana+Costa&background=F59E0B&color=fff',
          }
        ],
        'last_message': {
          'id': 'msg_3',
          'content': 'Dr., quando será a próxima audiência?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          'sender_id': 'client_1',
          'sender_name': 'Ana Costa',
          'message_type': 'text',
          'is_read': false,
        },
        'unread_count': 1,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'updated_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      }
    ];
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    try {
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/chat/internal/chats/$chatId/messages',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
      } else {
        throw Exception('Erro ao carregar mensagens: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.warning('Backend não disponível para mensagens, usando dados mock', error: e);
      return _getMockChatMessages(chatId);
    }
  }

  List<Map<String, dynamic>> _getMockChatMessages(String chatId) {
    switch (chatId) {
      case 'internal_chat_1':
        return [
          {
            'id': 'msg_1_1',
            'chat_id': chatId,
            'content': 'Olá! Como está?',
            'sender_id': 'lawyer_2',
            'sender_name': 'Dr. João Silva',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'is_read': true,
            'is_outgoing': false,
          },
          {
            'id': 'msg_1_2',
            'chat_id': chatId,
            'content': 'Oi Dr. João! Tudo bem, obrigado. E você?',
            'sender_id': 'user_current',
            'sender_name': 'Você',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
            'is_read': true,
            'is_outgoing': true,
          },
          {
            'id': 'msg_1_3',
            'chat_id': chatId,
            'content': 'Oi! Podemos conversar sobre o caso de divórcio?',
            'sender_id': 'lawyer_2',
            'sender_name': 'Dr. João Silva',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
            'is_read': false,
            'is_outgoing': false,
          },
        ];
      case 'internal_chat_2':
        return [
          {
            'id': 'msg_2_1',
            'chat_id': chatId,
            'content': 'Você pode me enviar aqueles documentos que conversamos?',
            'sender_id': 'lawyer_3',
            'sender_name': 'Dra. Maria Santos',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            'is_read': true,
            'is_outgoing': false,
          },
          {
            'id': 'msg_2_2',
            'chat_id': chatId,
            'content': 'Perfeito! Vou enviar os documentos ainda hoje.',
            'sender_id': 'user_current',
            'sender_name': 'Você',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'is_read': true,
            'is_outgoing': true,
          },
        ];
      case 'internal_chat_3':
        return [
          {
            'id': 'msg_3_1',
            'chat_id': chatId,
            'content': 'Boa tarde, Dr.! Como está o andamento do meu processo?',
            'sender_id': 'client_1',
            'sender_name': 'Ana Costa',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
            'is_read': true,
            'is_outgoing': false,
          },
          {
            'id': 'msg_3_2',
            'chat_id': chatId,
            'content': 'Boa tarde, Ana! O processo está correndo bem. Tivemos uma decisão favorável na semana passada.',
            'sender_id': 'user_current',
            'sender_name': 'Você',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(hours: 7)).toIso8601String(),
            'is_read': true,
            'is_outgoing': true,
          },
          {
            'id': 'msg_3_3',
            'chat_id': chatId,
            'content': 'Dr., quando será a próxima audiência?',
            'sender_id': 'client_1',
            'sender_name': 'Ana Costa',
            'message_type': 'text',
            'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
            'is_read': false,
            'is_outgoing': false,
          },
        ];
      default:
        return [];
    }
  }

  Future<Map<String, dynamic>> connectAccount({
    required String provider,
    required Map<String, String> credentials,
  }) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/connect',
        options: Options(headers: _headers),
        data: {
          'provider': provider,
          'credentials': credentials,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao conectar conta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar conta $provider: $e');
    }
  }

  Future<Map<String, dynamic>> disconnectAccount(String provider) async {
    try {
      final response = await _httpClient.delete(
        '$_baseUrl/api/v1/unified-messaging/accounts/$provider',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao desconectar conta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao desconectar conta $provider: $e');
    }
  }

  // ===============================
  // OAUTH FLOWS
  // ===============================

  Future<Map<String, dynamic>> startOAuthFlow(String provider) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/oauth/start',
        options: Options(headers: _headers),
        data: {
          'provider': provider,
          'redirect_uri': 'https://litig.app/oauth/callback',
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao iniciar OAuth: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao iniciar OAuth para $provider: $e');
    }
  }

  Future<Map<String, dynamic>> completeOAuthFlow({
    required String provider,
    required String authCode,
    required String state,
  }) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/oauth/complete',
        options: Options(headers: _headers),
        data: {
          'provider': provider,
          'auth_code': authCode,
          'state': state,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao completar OAuth: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao completar OAuth para $provider: $e');
    }
  }

  // ===============================
  // GESTÃO DE CHATS
  // ===============================

  Future<Map<String, dynamic>> getAllChats() async {
    try {
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/unified-messaging/chats',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao carregar chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar chats: $e');
    }
  }

  Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    required String provider,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
      };
      
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/unified-messaging/chats/$chatId/messages',
        queryParameters: queryParams,
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao carregar mensagens: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar mensagens do chat $chatId: $e');
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String provider,
    required String content,
    String messageType = 'text',
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/chats/$chatId/messages',
        options: Options(headers: _headers),
        data: {
          'provider': provider,
          'content': content,
          'message_type': messageType,
          if (attachments != null) 'attachments': attachments,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Também enviar via WebSocket para atualização em tempo real
        _wsChannel?.sink.add(jsonEncode({
          'type': 'send_message',
          'data': {
            'chat_id': chatId,
            'provider': provider,
            'content': content,
            'message_type': messageType,
            'attachments': attachments,
          }
        }));

        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao enviar mensagem: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String provider,
  }) async {
    try {
      final response = await _httpClient.patch(
        '$_baseUrl/api/v1/unified-messaging/messages/$messageId/read',
        options: Options(headers: _headers),
        data: {
          'chat_id': chatId,
          'provider': provider,
        },
      );

      if (response.statusCode == 200) {
        // Notificar via WebSocket
        _wsChannel?.sink.add(jsonEncode({
          'type': 'mark_read',
          'data': {
            'chat_id': chatId,
            'message_id': messageId,
            'provider': provider,
          }
        }));
      }
    } catch (e) {
      AppLogger.error('Erro ao marcar mensagem como lida', error: e);
    }
  }

  Future<void> sendTypingIndicator({
    required String chatId,
    required String provider,
    required bool isTyping,
  }) async {
    _wsChannel?.sink.add(jsonEncode({
      'type': 'typing',
      'data': {
        'chat_id': chatId,
        'provider': provider,
        'is_typing': isTyping,
      }
    }));
  }

  // ===============================
  // SINCRONIZAÇÃO
  // ===============================

  Future<Map<String, dynamic>> syncAllMessages() async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/sync',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha na sincronização: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na sincronização: $e');
    }
  }

  Future<Map<String, dynamic>> syncProvider(String provider) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/sync/$provider',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha na sincronização do $provider: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na sincronização do $provider: $e');
    }
  }

  // ===============================
  // CONFIGURAÇÕES E NOTIFICAÇÕES
  // ===============================

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/unified-messaging/preferences/notifications',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao carregar preferências: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar preferências de notificação: $e');
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences({
    required Map<String, bool> preferences,
  }) async {
    try {
      final response = await _httpClient.patch(
        '$_baseUrl/api/v1/unified-messaging/preferences/notifications',
        options: Options(headers: _headers),
        data: {'preferences': preferences},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao atualizar preferências: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar preferências de notificação: $e');
    }
  }

  Future<void> registerPushToken({
    required String token,
    required String deviceType,
  }) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/unified-messaging/push-tokens',
        options: Options(headers: _headers),
        data: {
          'token': token,
          'device_type': deviceType,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao registrar token push: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Erro ao registrar token push', error: e);
    }
  }

  // ===============================
  // CHAT INTERNO
  // ===============================

  Future<Map<String, dynamic>> getInternalChats() async {
    try {
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/chat/internal',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao carregar chats internos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar chats internos: $e');
    }
  }

  Future<Map<String, dynamic>> sendInternalMessage({
    required String recipientId,
    required String content,
    String messageType = 'text',
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/v1/chat/internal/messages',
        options: Options(headers: _headers),
        data: {
          'recipient_id': recipientId,
          'content': content,
          'message_type': messageType,
          if (attachments != null) 'attachments': attachments,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Enviar via WebSocket
        _wsChannel?.sink.add(jsonEncode({
          'type': 'internal_message',
          'data': {
            'recipient_id': recipientId,
            'content': content,
            'message_type': messageType,
            'attachments': attachments,
          }
        }));

        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao enviar mensagem interna: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao enviar mensagem interna: $e');
    }
  }

  // ===============================
  // HEALTH CHECK
  // ===============================

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _httpClient.get(
        '$_baseUrl/api/v1/unified-messaging/health',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Health check falhou: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro no health check: $e');
    }
  }

  // ===============================
  // LIMPEZA
  // ===============================

  void dispose() {
    disconnectWebSocket();
    _messageStreamController.close();
    _notificationStreamController.close();
    // Dio não precisa ser fechado manualmente
  }
}