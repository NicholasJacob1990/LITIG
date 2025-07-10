import 'package:equatable/equatable.dart';

abstract class TriageEvent extends Equatable {
  const TriageEvent();

  @override
  List<Object> get props => [];
}

class StartConversation extends TriageEvent {}

class SendMessage extends TriageEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object> get props => [message];
} 