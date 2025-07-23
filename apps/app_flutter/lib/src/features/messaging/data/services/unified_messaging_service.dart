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
      AppLogger.error('Erro ao carregar contas conectadas', error: e);
      throw Exception('Erro ao carregar contas conectadas: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> connectAccount({
    required String provider,
    required Map<String, String> credentials,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/v1/unified-messaging/connect'),
        headers: _headers,
        body: jsonEncode({
          'provider': provider,
          'credentials': credentials,
        }),
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/accounts/$provider'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/oauth/start'),
        headers: _headers,
        body: jsonEncode({
          'provider': provider,
          'redirect_uri': 'https://litig.app/oauth/callback',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/oauth/complete'),
        headers: _headers,
        body: jsonEncode({
          'provider': provider,
          'auth_code': authCode,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/chats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
      
      final uri = Uri.parse('$_baseUrl/api/v1/unified-messaging/chats/$chatId/messages')
          .replace(queryParameters: queryParams);

      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/chats/$chatId/messages'),
        headers: _headers,
        body: jsonEncode({
          'provider': provider,
          'content': content,
          'message_type': messageType,
          if (attachments != null) 'attachments': attachments,
        }),
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/messages/$messageId/read'),
        headers: _headers,
        body: jsonEncode({
          'chat_id': chatId,
          'provider': provider,
        }),
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/sync'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/sync/$provider'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/preferences/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/preferences/notifications'),
        headers: _headers,
        body: jsonEncode({'preferences': preferences}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/push-tokens'),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'device_type': deviceType,
        }),
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
        Uri.parse('$_baseUrl/api/v1/chat/internal'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        Uri.parse('$_baseUrl/api/v1/chat/internal/messages'),
        headers: _headers,
        body: jsonEncode({
          'recipient_id': recipientId,
          'content': content,
          'message_type': messageType,
          if (attachments != null) 'attachments': attachments,
        }),
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
        Uri.parse('$_baseUrl/api/v1/unified-messaging/health'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
    _httpClient.close();
  }
}