import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/triage/domain/entities/message.dart';

abstract class TriageState extends Equatable {
  final List<Message> messages;

  const TriageState({this.messages = const []});

  @override
  List<Object?> get props => [messages];
}

class TriageInitial extends TriageState {}

class TriageLoading extends TriageState {
  const TriageLoading({required List<Message> messages}) : super(messages: messages);
}

class TriageInProgress extends TriageState {
  final String caseId;

  const TriageInProgress({
    required List<Message> messages,
    required this.caseId,
  }) : super(messages: messages);

  @override
  List<Object?> get props => [messages, caseId];
}

class TriageEnded extends TriageState {
  final String caseId;

  const TriageEnded({
    required List<Message> messages,
    required this.caseId,
  }) : super(messages: messages);

  @override
  List<Object?> get props => [messages, caseId];
}

class TriageError extends TriageState {
  final String errorMessage;

  const TriageError({
    required List<Message> messages,
    required this.errorMessage,
  }) : super(messages: messages);

  @override
  List<Object?> get props => [messages, errorMessage];
} 