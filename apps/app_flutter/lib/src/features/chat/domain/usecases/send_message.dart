import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      roomId: params.roomId,
      content: params.content,
      messageType: params.messageType,
      attachmentUrl: params.attachmentUrl,
    );
  }
}

class SendMessageParams extends Equatable {
  final String roomId;
  final String content;
  final String messageType;
  final String? attachmentUrl;

  const SendMessageParams({
    required this.roomId,
    required this.content,
    this.messageType = 'text',
    this.attachmentUrl,
  });

  @override
  List<Object?> get props => [roomId, content, messageType, attachmentUrl];
}