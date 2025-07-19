import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../../../../core/services/simple_api_service.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatRoomModel>> getChatRooms();
  Future<ChatRoomModel> createChatRoom({
    required String clientId,
    required String lawyerId,
    required String caseId,
    String? contractId,
  });
  Future<List<ChatMessageModel>> getChatMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  });
  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  });
  Future<void> markMessageAsRead({
    required String roomId,
    required String messageId,
  });
  Future<int> getUnreadCount(String roomId);
  
  // WebSocket methods
  Stream<ChatMessageModel> getMessageStream(String roomId);
  Future<void> connectToRoom(String roomId);
  Future<void> disconnectFromRoom(String roomId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SimpleApiService apiService;
  WebSocketChannel? _webSocketChannel;
  final Map<String, StreamController<ChatMessageModel>> _messageControllers = {};

  ChatRemoteDataSourceImpl({required this.apiService});

  @override
  Future<List<ChatRoomModel>> getChatRooms() async {
    try {
      final response = await apiService.get('/chat/rooms');
      final List<dynamic> data = response.data;
      return data.map((json) => ChatRoomModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get chat rooms: $e');
    }
  }

  @override
  Future<ChatRoomModel> createChatRoom({
    required String clientId,
    required String lawyerId,
    required String caseId,
    String? contractId,
  }) async {
    try {
      final response = await apiService.post('/chat/rooms', data: {
        'client_id': clientId,
        'lawyer_id': lawyerId,
        'case_id': caseId,
        if (contractId != null) 'contract_id': contractId,
      });
      
      // Get the created room
      final roomId = response.data['room_id'];
      final roomResponse = await apiService.get('/chat/rooms/$roomId');
      return ChatRoomModel.fromJson(roomResponse.data);
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  @override
  Future<List<ChatMessageModel>> getChatMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await apiService.get('/chat/rooms/$roomId/messages', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      final List<dynamic> data = response.data;
      return data.map((json) => ChatMessageModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get chat messages: $e');
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    try {
      final response = await apiService.post('/chat/rooms/$roomId/messages', data: {
        'content': content,
        'message_type': messageType,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      });
      
      // Get the sent message
      final messageId = response.data['message_id'];
      final messageResponse = await apiService.get('/chat/rooms/$roomId/messages/$messageId');
      return ChatMessageModel.fromJson(messageResponse.data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> markMessageAsRead({
    required String roomId,
    required String messageId,
  }) async {
    try {
      await apiService.patch('/chat/rooms/$roomId/messages/$messageId/read');
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String roomId) async {
    try {
      final response = await apiService.get('/chat/rooms/$roomId/unread-count');
      return response.data['unread_count'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Stream<ChatMessageModel> getMessageStream(String roomId) {
    if (!_messageControllers.containsKey(roomId)) {
      _messageControllers[roomId] = StreamController<ChatMessageModel>.broadcast();
    }
    return _messageControllers[roomId]!.stream;
  }

  @override
  Future<void> connectToRoom(String roomId) async {
    try {
      // Get WebSocket URL from environment or config
      final wsUrl = '${apiService.baseUrl.replaceFirst('http', 'ws')}/chat/ws/$roomId';
      
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _webSocketChannel!.stream.listen(
        (message) {
          try {
            final messageData = json.decode(message);
            final chatMessage = ChatMessageModel.fromJson(messageData);
            
            if (_messageControllers.containsKey(roomId)) {
              _messageControllers[roomId]!.add(chatMessage);
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      throw Exception('Failed to connect to room: $e');
    }
  }

  @override
  Future<void> disconnectFromRoom(String roomId) async {
    try {
      await _webSocketChannel?.sink.close();
      _webSocketChannel = null;
      
      if (_messageControllers.containsKey(roomId)) {
        await _messageControllers[roomId]!.close();
        _messageControllers.remove(roomId);
      }
    } catch (e) {
      throw Exception('Failed to disconnect from room: $e');
    }
  }

  void dispose() {
    _webSocketChannel?.sink.close();
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }
}