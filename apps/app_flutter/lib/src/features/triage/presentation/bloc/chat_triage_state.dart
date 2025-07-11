import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});

  @override
  List<Object> get props => [text, isUser];
}

abstract class ChatTriageState extends Equatable {
  const ChatTriageState();

  @override
  List<Object> get props => [];
}

class ChatTriageInitial extends ChatTriageState {}

class ChatTriageLoading extends ChatTriageState {}

class ChatTriageActive extends ChatTriageState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const ChatTriageActive({this.messages = const [], this.isTyping = false});

  @override
  List<Object> get props => [messages, isTyping];
}

class ChatTriageFinished extends ChatTriageState {
  final String caseId;

  const ChatTriageFinished(this.caseId);

  @override
  List<Object> get props => [caseId];
}

class ChatTriageError extends ChatTriageState {
  final String message;

  const ChatTriageError(this.message);

  @override
  List<Object> get props => [message];
} 