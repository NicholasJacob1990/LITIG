import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/services/api_service.dart';
import 'chat_triage_event.dart';
import 'chat_triage_state.dart';

class ChatTriageBloc extends Bloc<ChatTriageEvent, ChatTriageState> {
  String? _caseId;

  ChatTriageBloc() : super(ChatTriageInitial()) {
    on<StartConversation>(_onStartConversation);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
  }

  Future<void> _onStartConversation(
      StartConversation event, Emitter<ChatTriageState> emit) async {
    emit(ChatTriageLoading());
    try {
      final response = await ApiService.startIntelligentTriage();
      _caseId = response['case_id'];
      final initialMessage = response['message'] as String;
      
      emit(ChatTriageActive(messages: [ChatMessage(text: initialMessage, isUser: false)]));
    } catch (e) {
      emit(ChatTriageError('Falha ao iniciar conversa: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatTriageState> emit) async {
    if (_caseId == null) {
      emit(const ChatTriageError('A conversa ainda não foi iniciada.'));
      return;
    }

    final currentState = state;
    if (currentState is ChatTriageActive) {
      // Adiciona a mensagem do usuário imediatamente
      final userMessage = ChatMessage(text: event.message, isUser: true);
      final newMessages = List<ChatMessage>.from(currentState.messages)..add(userMessage);

      emit(ChatTriageActive(messages: newMessages, isTyping: true));

      try {
        final response = await ApiService.continueIntelligentTriage(
          caseId: _caseId!,
          message: event.message,
        );

        final aiMessage = response['message'] as String;
        final status = response['status'] as String;

        add(MessageReceived(aiMessage, isUser: false));

        if (status == 'completed') {
          // A triagem terminou, o backend não envia o caseId na resposta do 'continue',
          // então usamos o que já temos.
          emit(ChatTriageFinished(_caseId!));
        }

      } catch (e) {
        add(MessageReceived('Desculpe, ocorreu um erro: ${e.toString()}', isUser: false));
      }
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatTriageState> emit) {
     final currentState = state;
     if (currentState is ChatTriageActive) {
        final message = ChatMessage(text: event.message, isUser: event.isUser);
        final updatedMessages = List<ChatMessage>.from(currentState.messages)..add(message);
        emit(ChatTriageActive(messages: updatedMessages, isTyping: false));
     }
  }
} 