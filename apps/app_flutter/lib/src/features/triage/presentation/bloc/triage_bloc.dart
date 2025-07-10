import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/services/api_service.dart';
import 'package:meu_app/src/features/triage/domain/entities/message.dart';
import 'triage_event.dart';
import 'triage_state.dart';

class TriageBloc extends Bloc<TriageEvent, TriageState> {
  TriageBloc() : super(TriageInitial()) {
    on<StartConversation>(_onStartConversation);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onStartConversation(StartConversation event, Emitter<TriageState> emit) async {
    emit(const TriageLoading(messages: []));
    try {
      final response = await ApiService.startTriageConversation();
      final caseId = response['case_id'] as String?;
      final messageText = response['message'] as String?;
      
      if (caseId == null || messageText == null) {
        throw Exception('Resposta inválida do servidor: case_id ou message está nulo');
      }
      
      final initialMessage = Message(messageText);
      
      emit(TriageInProgress(messages: [initialMessage], caseId: caseId));
    } catch (e) {
      emit(TriageError(messages: const [], errorMessage: 'Erro ao iniciar conversa: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<TriageState> emit) async {
    final currentState = state;
    if (currentState is! TriageInProgress) return;

    final userMessage = Message(event.message, isUser: true);
    final currentMessages = List<Message>.from(currentState.messages)..add(userMessage);

    emit(TriageLoading(messages: currentMessages));

    try {
      final replyData = await ApiService.continueTriageConversation(currentState.caseId, userMessage.text);
      final replyMessage = replyData['message'] as String?;
      
      if (replyMessage == null) {
        throw Exception('Resposta inválida do servidor: message está nulo');
      }
      
      final reply = Message(replyMessage);
      final updatedMessages = List<Message>.from(currentMessages)..add(reply);

      if (replyData['status'] == 'completed' || reply.text.contains('[END_OF_TRIAGE]')) {
        final finalMessageText = reply.text.replaceAll('[END_OF_TRIAGE]', '').trim();
        if (finalMessageText.isNotEmpty) {
           final finalMessage = Message(finalMessageText);
           updatedMessages[updatedMessages.length -1] = finalMessage;
        } else {
          updatedMessages.removeLast();
        }
        emit(TriageEnded(messages: updatedMessages, caseId: currentState.caseId));
      } else {
        emit(TriageInProgress(messages: updatedMessages, caseId: currentState.caseId));
      }
    } catch (e) {
      final updatedMessages = List<Message>.from(currentMessages)
        ..add(Message('Desculpe, ocorreu um erro: ${e.toString()}'));
      emit(TriageError(messages: updatedMessages, errorMessage: e.toString()));
    }
  }
} 