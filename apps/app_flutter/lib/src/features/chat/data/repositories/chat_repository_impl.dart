import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteRooms = await remoteDataSource.getChatRooms();
        return Right(remoteRooms.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom({
    required String clientId,
    required String lawyerId,
    required String caseId,
    String? contractId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteRoom = await remoteDataSource.createChatRoom(
          clientId: clientId,
          lawyerId: lawyerId,
          caseId: caseId,
          contractId: contractId,
        );
        return Right(remoteRoom.toEntity());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMessages = await remoteDataSource.getChatMessages(
          roomId: roomId,
          limit: limit,
          offset: offset,
        );
        return Right(remoteMessages.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMessage = await remoteDataSource.sendMessage(
          roomId: roomId,
          content: content,
          messageType: messageType,
          attachmentUrl: attachmentUrl,
        );
        return Right(remoteMessage.toEntity());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead({
    required String roomId,
    required String messageId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markMessageAsRead(
          roomId: roomId,
          messageId: messageId,
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String roomId) async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadCount(roomId);
        return Right(count);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Stream<ChatMessage> getMessageStream(String roomId) {
    return remoteDataSource.getMessageStream(roomId)
        .map((model) => model.toEntity());
  }

  @override
  Future<void> connectToRoom(String roomId) async {
    await remoteDataSource.connectToRoom(roomId);
  }

  @override
  Future<void> disconnectFromRoom(String roomId) async {
    await remoteDataSource.disconnectFromRoom(roomId);
  }
}