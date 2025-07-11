import 'package:equatable/equatable.dart';

abstract class ChatTriageEvent extends Equatable {
  const ChatTriageEvent();

  @override
  List<Object> get props => [];
}

class StartConversation extends ChatTriageEvent {}

class SendMessage extends ChatTriageEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object> get props => [message];
}

class MessageReceived extends ChatTriageEvent {
  final String message;
  final bool isUser;

  const MessageReceived(this.message, {this.isUser = false});

  @override
  List<Object> get props => [message, isUser];
} 