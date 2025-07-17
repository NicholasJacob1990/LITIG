import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetChatMessages implements UseCase<List<ChatMessage>, GetChatMessagesParams> {
  final ChatRepository repository;

  GetChatMessages(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(GetChatMessagesParams params) async {
    return await repository.getChatMessages(
      roomId: params.roomId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetChatMessagesParams extends Equatable {
  final String roomId;
  final int limit;
  final int offset;

  const GetChatMessagesParams({
    required this.roomId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [roomId, limit, offset];
}