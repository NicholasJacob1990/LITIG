import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();
  Future<Either<Failure, ChatRoom>> createChatRoom({
    required String clientId,
    required String lawyerId,
    required String caseId,
    String? contractId,
  });
  Future<Either<Failure, List<ChatMessage>>> getChatMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  });
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  });
  Future<Either<Failure, void>> markMessageAsRead({
    required String roomId,
    required String messageId,
  });
  Future<Either<Failure, int>> getUnreadCount(String roomId);
  
  // WebSocket methods
  Stream<ChatMessage> getMessageStream(String roomId);
  Future<void> connectToRoom(String roomId);
  Future<void> disconnectFromRoom(String roomId);
}